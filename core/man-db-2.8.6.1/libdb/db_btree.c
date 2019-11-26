/*
 * db_btree.c: low level btree interface routines for man.
 *
 * Copyright (C) 1994, 1995 Graeme W. Wilford. (Wilf.)
 * Copyright (C) 2002 Colin Watson.
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

/* below this line are routines only useful for the BTREE interface */
#ifdef BTREE

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#include <sys/file.h> /* for flock() */
#include <sys/types.h> /* for open() */
#include <sys/stat.h>

#include "gl_hash_set.h"
#include "gl_xset.h"
#include "stat-time.h"
#include "timespec.h"

#include "manconfig.h"

#include "error.h"
#include "glcontainers.h"

#include "mydbm.h"
#include "db_storage.h"

gl_set_t loop_check;

/* the Berkeley database libraries do nothing to arbitrate between concurrent
   database accesses, so we do a simple flock(). If the db is opened in
   anything but O_RDONLY mode, an exclusive lock is enabled. Otherwise, the
   lock is shared. A file cannot have both locks at once, and the non
   blocking method is used ": Try again". This adopts GNU dbm's approach. */

/* release the lock and close the database */
int btree_close (DB *db)
{
	(void) flock ((db->fd) (db), LOCK_UN);
	return (db->close) (db);
}

/* open a btree type database, with file locking. */
DB *btree_flopen (char *filename, int flags, int mode)
{
	DB *db;
	BTREEINFO b;
	int lock_op;
	int lock_failed;

	b.flags = 0;		/* do not allow any duplicate keys */

	b.cachesize = 0;	/* default size */
	b.maxkeypage = 0;	/* default */
	b.minkeypage = 0;	/* default */
	b.psize = 0;		/* default page size (2048?) */
	b.compare = NULL;	/* builtin compare() function */
	b.prefix = NULL;	/* builtin function */
	b.lorder = 0;		/* byte order of host */

	if (flags & ~O_RDONLY) {
		/* flags includes O_RDWR or O_WRONLY, need an exclusive lock */
		lock_op = LOCK_EX | LOCK_NB;
	} else {
		lock_op = LOCK_SH | LOCK_NB;
	}

	if (!(flags & O_CREAT)) {
		/* Berkeley DB thinks that a zero-length file means that
		 * somebody else is writing it, and sleeps for a few
		 * seconds to give the writer a chance. All very well, but
		 * the common case is that the database is just zero-length
		 * because mandb was interrupted or ran out of disk space or
		 * something like that - so we check for this case by hand
		 * and ignore the database if it's zero-length.
		 */
		struct stat iszero;
		if (stat (filename, &iszero) < 0)
			return NULL;
		if (iszero.st_size == 0) {
			errno = EINVAL;
			return NULL;
		}
	}

	if (flags & O_TRUNC) {
		/* opening the db is destructive, need to lock first */
		int fd;

		db = NULL;
		lock_failed = 1;
		fd = open (filename, flags & ~O_TRUNC, mode);
		if (fd != -1) {
			if (!(lock_failed = flock (fd, lock_op)))
				db = dbopen (filename, flags, mode,
					     DB_BTREE, &b);
			close (fd);
		}
	} else {
		db = dbopen (filename, flags, mode, DB_BTREE, &b);
		if (db)
			lock_failed = flock ((db->fd) (db), lock_op);
	}

	if (!db)
		return NULL;

	if (lock_failed) {
		gripe_lock (filename);
		btree_close (db);
		return NULL;
	}

	return db;
}

/* do a replace when we have the duplicate flag set on the database -
   we must do a del and insert, as a direct insert will not wipe out the
   old entry */
int btree_replace (DB *db, datum key, datum cont)
{
	return (db->put) (db, (DBT *) &key, (DBT *) &cont, 0);
}

int btree_insert (DB *db, datum key, datum cont)
{
	return (db->put) (db, (DBT *) &key, (DBT *) &cont, R_NOOVERWRITE);
}

/* generic fetch routine for the btree database */
datum btree_fetch (DB *db, datum key)
{
	datum data;

	memset (&data, 0, sizeof data);

	if ((db->get) (db, (DBT *) &key, (DBT *) &data, 0)) {
		memset (&data, 0, sizeof data);
		return data;
	}

	return copy_datum (data);
}

/* return 1 if the key exists, 0 otherwise */
int btree_exists (DB *db, datum key)
{
	datum data;
	return ((db->get) (db, (DBT *) &key, (DBT *) &data, 0) ? 0 : 1);
}

/* initiate a sequential access */
static datum btree_findkey (DB *db, u_int flags)
{
	datum key, data;
	char *loop_check_key;

	memset (&key, 0, sizeof key);
	memset (&data, 0, sizeof data);

	if (flags == R_FIRST) {
		if (loop_check) {
			gl_set_free (loop_check);
			loop_check = NULL;
		}
	}
	if (!loop_check)
		loop_check = new_string_set (GL_HASH_SET);

	if (((db->seq) (db, (DBT *) &key, (DBT *) &data, flags))) {
		memset (&key, 0, sizeof key);
		return key;
	}

	loop_check_key = xstrndup (MYDBM_DPTR (key), MYDBM_DSIZE (key));
	if (gl_set_search (loop_check, loop_check_key)) {
		/* We've seen this key already, which is broken. Return NULL
		 * so the caller doesn't go round in circles.
		 */
		debug ("Corrupt database! Already seen %*s. "
		       "Attempting to recover ...\n",
		       (int) MYDBM_DSIZE (key), MYDBM_DPTR (key));
		memset (&key, 0, sizeof key);
		free (loop_check_key);
		return key;
	}

	gl_set_add (loop_check, loop_check_key);

	return copy_datum (key);
}

/* return the first key in the db */
datum btree_firstkey (DB *db)
{
	return btree_findkey (db, R_FIRST);
}

/* return the next key in the db. NB. This routine only works if the cursor
   has been previously set by btree_firstkey() since it was last opened. So
   if we close/reopen a db mid search, we have to manually set up the
   cursor again. */
datum btree_nextkey (DB *db)
{
	return btree_findkey (db, R_NEXT);
}

/* compound nextkey routine, initialising key and content */
int btree_nextkeydata (DB *db, datum *key, datum *cont)
{
	int status;

	if ((status = (db->seq) (db, (DBT *) key, (DBT *) cont, R_NEXT)) != 0)
		return status;

	*key = copy_datum (*key);
	*cont = copy_datum (*cont);

	return 0;
}

struct timespec btree_get_time (DB *db)
{
	struct stat st;

	if (fstat ((db->fd) (db), &st) < 0) {
		struct timespec t;
		t.tv_sec = -1;
		t.tv_nsec = -1;
		return t;
	}
	return get_stat_mtime (&st);
}

void btree_set_time (DB *db, const struct timespec time)
{
	struct timespec times[2];

	times[0] = time;
	times[1] = time;
	futimens ((db->fd) (db), times);
}

#endif /* BTREE */
