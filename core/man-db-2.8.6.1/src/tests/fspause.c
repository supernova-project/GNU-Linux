/*
 * fspause.c: pause until a file timestamp updates
 *
 * Copyright (C) 2014 Colin Watson.
 *
 * This file is part of man-db.
 *
 * man-db is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * man-db is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with man-db; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif /* HAVE_CONFIG_H */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "progname.h"
#include "stat-time.h"
#include "timespec.h"
#include "xalloc.h"

#include "manconfig.h"

static char *filename;
static int fd = -1;

#define MUST(name, cond) \
	do { \
		if (!(cond)) { \
			fprintf (stderr, "fspause: " name " failed\n"); \
			abort (); \
		} \
	} while (0)

static void unlink_tempfile (void)
{
	if (fd >= 0) {
		MUST ("close", close (fd) >= 0);
		MUST ("unlink", unlink (filename) >= 0);
	}
}

static void delay (int delay_ns)
{
	struct timespec delay_ts;

	delay_ts.tv_sec = delay_ns / 1000000000;
	delay_ts.tv_nsec = delay_ns % 1000000000;
	for (;;) {
		errno = 0;
		if (nanosleep (&delay_ts, NULL) == 0)
			break;
		MUST ("nanosleep", errno == 0 || errno == EINTR);
	}
}

static int try_delay (struct stat *st, int delay_ns)
{
	struct timespec start_ts, end_ts;

	start_ts = get_stat_mtime (st);
	delay (delay_ns);
	MUST ("write", write (fd, "\n", 1) == 1);
	MUST ("fstat", fstat (fd, st) >= 0);
	end_ts = get_stat_mtime (st);
	return timespec_cmp (start_ts, end_ts) != 0;
}

int main (int argc ATTRIBUTE_UNUSED, char **argv)
{
	struct stat st;
	int delay_ns;

	set_program_name (argv[0]);

	filename = xstrdup ("fspause.tmp.XXXXXX");
	MUST ("mkstemp", (fd = mkstemp (filename)) >= 0);
	atexit (unlink_tempfile);
	MUST ("fstat", fstat (fd, &st) >= 0);

	/* 0x40000000 nanoseconds is just over a second.  The effective
	 * maximum delay we will allow is thus about two seconds.  This
	 * saves us having to keep track of anything more complicated than a
	 * single signed 32-bit int.
	 */
	for (delay_ns = 1; delay_ns < 0x40000000; delay_ns *= 2) {
		if (try_delay (&st, delay_ns))
			return 0;
	}

	fprintf (stderr,
		 "fspause: temporary file timestamp refuses to change!\n");
	return 1;
}
