## Process this file with automake to produce Makefile.in
##
## Copyright (C) 2009, 2010, 2011 Colin Watson.
##
## This file is part of man-db.
##
## man-db is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## man-db is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with man-db; if not, write to the Free Software Foundation,
## Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

TESTS_ENVIRONMENT = PATH=$(abs_builddir)/..:$$PATH; export PATH; \
		    DBTYPE=$(DBTYPE); export DBTYPE; \
		    MANDIR_LAYOUT=$(MANDIR_LAYOUT); export MANDIR_LAYOUT; \
		    abs_top_builddir=$(abs_top_builddir); export abs_top_builddir; \
		    OVERRIDE_DIR="$(override_dir)"; export OVERRIDE_DIR;
# Each test must use the configure-detected shell, not necessarily /bin/sh.
AM_LOG_FLAGS = $(SHELL)
ALL_TESTS = \
	lexgrog-1 lexgrog-2 lexgrog-3 \
	man-1 man-2 man-3 man-4 man-5 man-6 man-7 man-8 man-9 man-10 man-11 \
	manconv-1 manconv-2 manconv-3 \
	mandb-1 mandb-2 mandb-3 mandb-4 mandb-5 mandb-6 mandb-7 \
	whatis-1 \
	zsoelim-1
if !CROSS_COMPILING
TESTS = $(ALL_TESTS)
endif

AM_CPPFLAGS = \
	-I$(top_builddir)/include \
	-I$(top_builddir)/gl/lib \
	-I$(top_srcdir)/gl/lib
AM_CFLAGS = $(WARN_CFLAGS)
check_PROGRAMS = fspause
fspause_SOURCES = fspause.c
fspause_LDADD = \
	$(top_builddir)/gl/lib/libgnu.la \
	$(LIB_NANOSLEEP)

dist_check_SCRIPTS = testlib.sh $(ALL_TESTS)
