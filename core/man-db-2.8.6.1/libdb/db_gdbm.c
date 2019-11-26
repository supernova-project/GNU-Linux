/*
 * db_gdbm.c: low level gdbm interface routines for man.
 *
 * Copyright (C) 1994, 1995 Graeme W. Wilford. (Wilf.)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Mon Aug  8 20:35:30 BST 1994  Wilf. (G.Wilford@ee.surrey.ac.uk)
 */

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif /* HAVE_CONFIG_H */

#ifdef GDBM

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "gl_hash_map.h"
#include "gl_rbtree_list.h"
#include "gl_xlist.h"
#include "gl_xmap.h"
#include "hash-pjw-bare.h"
#include "stat-time.h"
#include "timespec.h"

#include "manconfig.h"

#include "cleanup.h"
#include "glcontainers.h"

#include "mydbm.h"

static gl_map_t parent_keys;

/* setjmp/longjmp handling to defend against _gdbm_fatal exiting under our
 * feet.  Not thread-safe, but there is no plan for man-db to ever use
 * threads.
 */
static jmp_buf open_env;
static int opening;

/* Mimic _gdbm_fatal's error output, but handle errors during open more
 * gracefully than exiting.
 */
static void trap_error (const char *val)
{
	if (opening) {
		debug ("gdbm error: %s\n", val);
		longjmp (open_env, 1);
	} else
		fprintf (stderr, "gdbm fatal: %s\n", val);
}

man_gdbm_wrapper man_gdbm_open_wrapper (const char *name, int flags)
{
	man_gdbm_wrapper wrap;
	GDBM_FILE file;
	datum key, content;

	opening = 1;
	if (setjmp (open_env))
		return NULL;
	file = gdbm_open ((char *) name, BLK_SIZE, flags, DBMODE, trap_error);
	if (!file)
		return NULL;

	wrap = xmalloc (sizeof *wrap);
	wrap->name = xstrdup (name);
	wrap->file = file;

	if ((flags & ~GDBM_FAST) != GDBM_NEWDB) {
		/* While the setjmp/longjmp guard is in effect, make sure we
		 * can read from the database at all.
		 */
		memset (&key, 0, sizeof key);
		MYDBM_SET (key, xstrdup (VER_KEY));
		content = MYDBM_FETCH (wrap, key);
		MYDBM_FREE_DPTR (key);
		MYDBM_FREE_DPTR (content);
	}

	opening = 0;

	return wrap;
}

static int datum_compare (const void *a, const void *b)
{
	const datum *left = (const datum *) a;
	const datum *right = (const datum *) b;
	int cmp;
	size_t minsize;

	/* Sentinel NULL elements sort to the end. */
	if (!MYDBM_DPTR (*left))
		return 1;
	else if (!MYDBM_DPTR (*right))
		return -1;

	if (MYDBM_DSIZE (*left) < MYDBM_DSIZE (*right))
		minsize = MYDBM_DSIZE (*left);
	else
		minsize = MYDBM_DSIZE (*right);
	cmp = strncmp (MYDBM_DPTR (*left), MYDBM_DPTR (*right), minsize);
	if (cmp)
		return cmp;
	else if (MYDBM_DSIZE (*left) < MYDBM_DSIZE (*right))
		return 1;
	else if (MYDBM_DSIZE (*left) > MYDBM_DSIZE (*right))
		return -1;
	else
		return 0;
}

static bool datum_equals (const void *a, const void *b)
{
	return datum_compare (a, b) == 0;
}

static size_t datum_hash (const void *value)
{
	const datum *d = value;
	return hash_pjw_bare (MYDBM_DPTR (*d), MYDBM_DSIZE (*d));
}

static void datum_free (const void *value)
{
	MYDBM_FREE_DPTR (*(datum *) value);
}

static datum empty_datum = { NULL, 0 };

/* We keep a map of filenames to sorted lists of keys.  Each list is stored
 * using a hash-based implementation that allows lookup by name and
 * traversal to the next item in O(log n) time, which is necessary for a
 * reasonable ordered implementation of nextkey.
 */
datum man_gdbm_firstkey (man_gdbm_wrapper wrap)
{
	gl_list_t keys;
	datum *key;

	/* Build the raw sorted list of keys. */
	keys = gl_list_create_empty (GL_RBTREE_LIST, datum_equals, datum_hash,
				     datum_free, false);
	key = XMALLOC (datum);
	*key = gdbm_firstkey (wrap->file);
	while (MYDBM_DPTR (*key)) {
		datum *next;

		gl_sortedlist_add (keys, datum_compare, key);
		next = XMALLOC (datum);
		*next = gdbm_nextkey (wrap->file, *key);
		key = next;
	}

	if (!parent_keys) {
		parent_keys = new_string_map (GL_HASH_MAP,
					      (gl_listelement_dispose_fn)
					      gl_list_free);
		push_cleanup ((cleanup_fun) gl_map_free, parent_keys, 0);
	}

	/* Remember this structure for use by nextkey. */
	gl_map_put (parent_keys, xstrdup (wrap->name), keys);

	if (gl_list_size (keys))
		return copy_datum (*(datum *) gl_list_get_at (keys, 0));
	else
		return empty_datum;
}

datum man_gdbm_nextkey (man_gdbm_wrapper wrap, datum key)
{
	gl_list_t keys;
	gl_list_node_t node, next_node;

	if (!parent_keys)
		return empty_datum;
	keys = (gl_list_t) gl_map_get (parent_keys, wrap->name);
	if (!keys)
		return empty_datum;

	node = gl_sortedlist_search (keys, datum_compare, &key);
	if (!node)
		return empty_datum;
	next_node = gl_list_next_node (keys, node);
	if (!next_node)
		return empty_datum;

	return copy_datum (*(datum *) gl_list_node_value (keys, next_node));
}

struct timespec man_gdbm_get_time (man_gdbm_wrapper wrap)
{
	struct stat st;

	if (fstat (gdbm_fdesc (wrap->file), &st) < 0) {
		struct timespec t;
		t.tv_sec = -1;
		t.tv_nsec = -1;
		return t;
	}
	return get_stat_mtime (&st);
}

void man_gdbm_set_time (man_gdbm_wrapper wrap, const struct timespec time)
{
	struct timespec times[2];

	times[0] = time;
	times[1] = time;
	futimens (gdbm_fdesc (wrap->file), times);
}

void man_gdbm_close (man_gdbm_wrapper wrap)
{
	if (!wrap)
		return;

	if (parent_keys)
		gl_map_remove (parent_keys, wrap->name);

	free (wrap->name);
	gdbm_close (wrap->file);
	free (wrap);
}

#ifndef HAVE_GDBM_EXISTS

int gdbm_exists (GDBM_FILE file, datum key)
{
	char *memory;

	memory = MYDBM_DPTR (gdbm_fetch (file, key));
	if (memory) {
		free (memory);
		return 1;
	}

	return 0;
}

#endif /* !HAVE_GDBM_EXISTS */

#endif /* GDBM */
