dnl Process this file with autoconf to produce a configure script.

# Copyright (C) 2010-2019 Colin Watson.
#
# This file is part of libpipeline.
#
# libpipeline is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# libpipeline is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with libpipeline; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
# USA.

m4_pattern_forbid([^PIPELINE_])

# Initialise and check we're in the correct directory.
AC_INIT([libpipeline], [1.5.1], [cjwatson@debian.org])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([1.11 -Wall -Werror foreign])
AM_MAINTAINER_MODE
AM_SILENT_RULES([yes])
AC_PREREQ([2.63])
AC_CONFIG_SRCDIR([lib/pipeline.c])
AC_GNU_SOURCE
PIPELINE_TAR_SORT_NAME

AC_CONFIG_HEADER([config.h])
AC_CANONICAL_HOST

# Check $PATH for the following programs and append suitable options.
AC_PROG_CC
gl_EARLY
AC_PROG_CPP
CFLAGS="$CFLAGS -Wall"
if test "$GCC" = yes
then
	gl_WARN_ADD([-W])
	gl_WARN_ADD([-Wpointer-arith])
	gl_WARN_ADD([-Wwrite-strings])
	gl_WARN_ADD([-Wstrict-prototypes])
	gl_WARN_ADD([-Wshadow])
	gl_WARN_ADD([-Wformat-security])
	gl_WARN_ADD([-Wredundant-decls])
	gl_WARN_ADD([-Wno-missing-field-initializers])
fi
AC_PROG_LN_S
AM_PROG_AR
LT_INIT([disable-static])
AC_DEFINE_UNQUOTED([SHELL], ["$SHELL"], [A POSIX shell interpreter.])
PKG_CHECK_MODULES([CHECK], [check >= 0.9.4], [run_tests=yes], [run_tests=no])
AM_CONDITIONAL([RUN_TESTS], [test "x$run_tests" = xyes])

# Check for various header files and associated libraries.
AC_ISC_POSIX
gl_INIT
AC_CHECK_HEADERS([fcntl.h])
AC_CHECK_FUNCS([clearenv])

# Checks for structures and compiler characteristics.
AC_C_CONST
AC_TYPE_PID_T
AC_TYPE_SIZE_T

# We must have fork(2) support.
AC_FUNC_FORK
if test "x$ac_cv_func_fork_works" != xyes; then
  AC_MSG_FAILURE([cannot use libpipeline on systems without fork])
fi

# Check for socketpair(2) as fast replacement for pipe(2).
AC_ARG_ENABLE([socketpair-pipe],
[AS_HELP_STRING([--enable-socketpair-pipe], [Use socketpair(2) as fast replacement for pipe(2)])],
  [ if test "$enableval" = "yes"
    then
      PIPELINE_SOCKETPAIR_PIPE
      if test "$pipeline_cv_socketpair_pipe" = yes; then
	PIPELINE_SOCKETPAIR_MODE
      fi
    fi
  ])

dnl PIPELINE_ECHO_VAR(ENV-VARIABLE)
define(PIPELINE_ECHO_VAR, [AC_MSG_NOTICE([default $1 = "$$1"])])dnl
dnl
PIPELINE_ECHO_VAR(CC)
PIPELINE_ECHO_VAR(CPP)
PIPELINE_ECHO_VAR(CPPFLAGS)
PIPELINE_ECHO_VAR(CFLAGS)
PIPELINE_ECHO_VAR(LDFLAGS)
PIPELINE_ECHO_VAR(LIBS)

AC_CONFIG_FILES([Makefile
	gl/lib/Makefile
	lib/Makefile
	lib/libpipeline.pc
	man/Makefile
	tests/Makefile])
AC_OUTPUT
