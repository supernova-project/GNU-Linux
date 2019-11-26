/*
 * Copyright (C) 2010, 2012 Colin Watson.
 *
 * This file is part of libpipeline.
 *
 * libpipeline is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * libpipeline is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with libpipeline; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
 * USA.
 */

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "xalloc.h"
#include "xvasprintf.h"

#include "common.h"

const char *program_name = "redirect";

START_TEST (test_redirect_files)
{
	char *template = xstrdup ("testtmp.XXXXXX");
	int fd;
	FILE *fh;
	pipeline *p;
	const char *line;

	fd = mkstemp (template);
	if (fd < 0) {
		fail ("mkstemp failed: %s", strerror (errno));
		return;
	}
	fh = fdopen (fd, "w");
	fprintf (fh, "test data\n");
	fflush (fh);

	p = pipeline_new_command_args ("sed", "-e", "s/$/ out/", (void *) 0);
	pipeline_want_infile (p, template);
	pipeline_want_out (p, -1);
	pipeline_start (p);
	line = pipeline_readline (p);
	fail_unless (line != NULL);
	fail_unless (!strcmp (line, "test data out\n"));

	fclose (fh);
	unlink (template);

	pipeline_free (p);
	free (template);
}
END_TEST

START_TEST (test_redirect_outfile)
{
	pipeline *p;
	char *outfile;
	FILE *fh;
	char line[5];

	p = pipeline_new_command_args ("echo", "test", (void *) 0);
	outfile = xasprintf ("%s/test", temp_dir);
	pipeline_want_outfile (p, outfile);
	fail_unless (pipeline_run (p) == 0);
	fh = fopen (outfile, "r");
	fail_unless (fh != NULL);
	fail_unless (fgets (line, 5, fh) != NULL);
	fail_unless (!strcmp (line, "test"));

	fclose (fh);
	free (outfile);
}
END_TEST

Suite *redirect_suite (void)
{
	Suite *s = suite_create ("Redirect");

	TEST_CASE (s, redirect, files);
	TEST_CASE_WITH_FIXTURE (s, redirect, outfile,
				temp_dir_setup, temp_dir_teardown);

	return s;
}

MAIN (redirect)
