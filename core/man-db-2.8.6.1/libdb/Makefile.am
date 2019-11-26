## Process this file with automake to produce Makefile.in
##
## Copyright (C) 1994, 1995 Graeme Wilford.
## Copyright (C) 2001, 2003, 2005, 2006, 2007 Colin Watson.
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

pkglib_LTLIBRARIES = libmandb.la
dist_noinst_DATA = README

AM_CFLAGS = $(WARN_CFLAGS)

libmandb_la_CPPFLAGS = \
	-I$(top_builddir)/include \
	-I$(top_srcdir)/gl/lib \
	-I$(top_builddir)/gl/lib \
	-I$(top_srcdir)/lib

libmandb_la_SOURCES = \
	db_btree.c \
	db_delete.c \
	db_gdbm.c \
	db_lookup.c \
	db_ndbm.c \
	db_storage.h \
	db_store.c \
	db_ver.c \
	mydbm.h

libmandb_la_LIBADD = ../lib/libman.la $(DBLIBS)

libmandb_la_LDFLAGS = \
	-avoid-version -release $(VERSION) -rpath $(pkglibdir) -no-undefined
