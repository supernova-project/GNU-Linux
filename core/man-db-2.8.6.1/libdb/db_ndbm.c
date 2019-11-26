/*
 * db_ndbm.c: low level ndbm interface routines for man.
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
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifdef NDBM

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include <sys/file.h> /* for flock() */
#include <sys/types.h> /* for open() */
#include <sys/stat.h>

#include "stat-time.h"
#include "timespec.h"
#include "xvasprintf.h"

#include "manconfig.h"

#include "mydbm.h"
#include "db_storage.h"

/* release the lock and close the database */
int ndbm_flclose (DBM *db)
{
	flock (dbm_dirfno (db), LOCK_UN);
	dbm_close (db);
	return 0;
}

/* open a ndbm type database, with file locking. */
DBM* ndbm_flopen (char *filename, int flags, int mode)
{
	DBM *db;
	int lock_op;
	int lock_failed;

	if (flags & ~O_RDONLY) {
		/* flags includes O_RDWR or O_WRONLY, need an exclusive lock */
		lock_op = LOCK_EX | LOCK_NB;
	} else {
		lock_op = LOCK_SH | LOCK_NB;
	}

	if (flags & O_TRUNC) {
		/* opening the db is destructive, need to lock first */
		char *dir_fname;
		int dir_fd;

		db = NULL;
		lock_failed = 1;
		dir_fname = xasprintf ("%s.dir", filename);
		dir_fd = open (dir_fname, flags & ~O_TRUNC, mode);
		free (dir_fname);
		if (dir_fd != -1) {
			if (!(lock_failed = flock (dir_fd, lock_op)))
				db = dbm_open (filename, flags, mode);
			close (dir_fd);
		}
	} else {
		db = dbm_open (filename, flags, mode);
		if (db)
			lock_failed = flock (dbm_dirfno (db), lock_op);
	}

	if (!db)
		return NULL;

	if (lock_failed) {
		gripe_lock (filename);
		dbm_close (db);
		return NULL;
	}

	return db;
}

struct timespec ndbm_get_time (DBM *db)
{
	struct stat st;

	if (fstat (dbm_dirfno (db), &st) < 0) {
		struct timespec t;
		t.tv_sec = -1;
		t.tv_nsec = -1;
		return t;
	}
	return get_stat_mtime (&st);
}

void ndbm_set_time (DBM *db, const struct timespec time)
{
	struct timespec times[2];

	times[0] = time;
	times[1] = time;
	futimens (dbm_dirfno (db), times);
}

#endif /* NDBM */
