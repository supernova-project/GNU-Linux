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
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "xvasprintf.h"

#include "common.h"

const char *program_name = "exec";

START_TEST (test_exec_process)
{
	int i;

	for (i = 0; i < 3; ++i) {
		pipecmd *cmd;
		pid_t pid;
		int status;

		if (i < 2) {
			char *arg;

			cmd = pipecmd_new_args (SHELL, "-c", (void *) 0);
			arg = xasprintf ("exit %d", i);
			pipecmd_arg (cmd, arg);
			free (arg);
		} else {
			cmd = pipecmd_new ("nonexistent command");
			pipecmd_discard_err (cmd, 1);
		}

		pid = fork ();
		if (pid < 0) {
			fail ("fork failed: %s", strerror (errno));
			return;
		}
		if (pid == 0)
			pipecmd_exec (cmd);

		while (waitpid (pid, &status, 0) < 0) {
			if (errno == EINTR)
				continue;
			fail ("waitpid failed: %s", strerror (errno));
			return;
		}

		fail_unless (WIFEXITED (status));
		if (i < 2)
			fail_unless (WEXITSTATUS (status) == i);
		else
			fail_if (WEXITSTATUS (status) == 0);

		pipecmd_free (cmd);
	}
}
END_TEST

static void exit_helper (void *data)
{
	exit (*(int *) data);
}

START_TEST (test_exec_function)
{
	int i;

	for (i = 0; i < 2; ++i) {
		pipecmd *cmd;
		pid_t pid;
		int status;

		cmd = pipecmd_new_function ("exit_helper", exit_helper, NULL,
					    &i);

		pid = fork ();
		if (pid < 0) {
			fail ("fork failed: %s", strerror (errno));
			return;
		}
		if (pid == 0)
			pipecmd_exec (cmd);

		while (waitpid (pid, &status, 0) < 0) {
			if (errno == EINTR)
				continue;
			fail ("waitpid failed: %s", strerror (errno));
			return;
		}

		fail_unless (WIFEXITED (status));
		fail_unless (WEXITSTATUS (status) == i);

		pipecmd_free (cmd);
	}
}
END_TEST

Suite *exec_suite (void)
{
	Suite *s = suite_create ("Exec");

	TEST_CASE (s, exec, process);
	TEST_CASE (s, exec, function);

	return s;
}

MAIN (exec)
