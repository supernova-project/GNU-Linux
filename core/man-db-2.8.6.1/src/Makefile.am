## Process this file with automake to produce Makefile.in
##
## Copyright (C) 1994, 1995 Graeme Wilford.
## Copyright (C) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
##               2011, 2012 Colin Watson.
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

pkglibexecdir = $(libexecdir)/@PACKAGE@

SUBDIRS = . tests

bin_PROGRAMS = \
	catman \
	lexgrog \
	man \
	mandb \
	manpath \
	whatis
sbin_PROGRAMS = accessdb
pkglibexec_PROGRAMS = globbing manconv zsoelim
noinst_DATA = man_db.conf

EXTRA_DIST = lexgrog.c zsoelim.c

AM_CPPFLAGS = \
	-I$(top_builddir)/include \
	-I$(top_builddir)/gl/lib \
	-I$(top_srcdir)/gl/lib \
	-I$(top_srcdir)/lib \
	-I$(top_srcdir)/libdb \
	-DCONFIG_FILE=\"$(config_file)\" \
	-DAPROPOS=\"$(bindir)/$(TRANS_APROPOS)\" \
	-DAPROPOS_NAME=\"$(TRANS_APROPOS)\" \
	-DMAN=\"$(bindir)/$(TRANS_MAN)\" \
	-DMANCONV=\"$(pkglibexecdir)/$(TRANS_MANCONV)\" \
	-DMANDB=\"$(bindir)/$(TRANS_MANDB)\" \
	-DWHATIS=\"$(bindir)/$(TRANS_WHATIS)\" \
	-DZSOELIM=\"$(pkglibexecdir)/$(TRANS_ZSOELIM)\"
AM_CFLAGS = \
	$(WARN_CFLAGS) \
	$(libpipeline_CFLAGS)

LIBMAN = $(top_builddir)/lib/libman.la $(top_builddir)/gl/lib/libgnu.la \
	 @LTLIBINTL@
LIBMANDB = $(top_builddir)/libdb/libmandb.la $(LIBMAN) $(DBLIBS)

accessdb_LDADD = $(LIBMANDB)
catman_LDADD = $(LIBMANDB) $(libpipeline_LIBS)
globbing_LDADD = $(LIBMAN)
lexgrog_LDADD = $(LIBMAN) $(libpipeline_LIBS) $(LTLIBICONV)
man_LDADD = $(LIBMANDB) $(libpipeline_LIBS) $(LTLIBICONV)
manconv_LDADD = $(LIBMAN) $(libpipeline_LIBS) $(LTLIBICONV)
mandb_LDADD = $(LIBMANDB) $(libpipeline_LIBS) $(LTLIBICONV)
manpath_LDADD = $(LIBMAN)
whatis_LDADD = $(LIBMANDB) $(libpipeline_LIBS) $(LTLIBICONV)
zsoelim_LDADD = $(LIBMAN) $(libpipeline_LIBS)

accessdb_SOURCES = \
	accessdb.c
catman_SOURCES = \
	catman.c \
	globbing.c \
	globbing.h \
	manp.c \
	manp.h
globbing_SOURCES = \
	globbing.c \
	globbing.h \
	globbing_test.c
lexgrog_SOURCES = \
	compression.c \
	descriptions.c \
	descriptions.h \
	filenames.c \
	filenames.h \
	globbing.c \
	globbing.h \
	lexgrog.l \
	lexgrog_test.c \
	manconv.c \
	manconv.h \
	manconv_client.c \
	manconv_client.h \
	ult_src.c \
	ult_src.h
man_SOURCES = \
	compression.c \
	filenames.c \
	filenames.h \
	globbing.c \
	globbing.h \
	man.c \
	manconv.c \
	manconv.h \
	manconv_client.c \
	manconv_client.h \
	manp.c \
	manp.h \
	ult_src.c \
	ult_src.h \
	zsoelim.h \
	zsoelim.l
manconv_SOURCES = \
	manconv.c \
	manconv.h \
	manconv_main.c
mandb_SOURCES = \
	check_mandirs.c \
	check_mandirs.h \
	compression.c \
	descriptions.c \
	descriptions.h \
	descriptions_store.c \
	filenames.c \
	filenames.h \
	globbing.c \
	globbing.h \
	lexgrog.l \
	manconv.c \
	manconv.h \
	manconv_client.c \
	manconv_client.h \
	mandb.c \
	manp.c \
	manp.h \
	straycats.c \
	ult_src.c \
	ult_src.h
manpath_SOURCES = \
	globbing.c \
	globbing.h \
	manp.c \
	manp.h \
	manpath.c
whatis_SOURCES = \
	globbing.c \
	globbing.h \
	manconv.c \
	manconv.h \
	manp.c \
	manp.h \
	whatis.c
zsoelim_SOURCES = \
	globbing.c \
	globbing.h \
	manp.c \
	manp.h \
	zsoelim.h \
	zsoelim.l \
	zsoelim_main.c

CLEANFILES = apropos man_db.conf

apropos$(EXEEXT): whatis$(EXEEXT)
	rm -f $@
	$(LN_S) whatis$(EXEEXT) $@

all-am: apropos$(EXEEXT)

install-exec-hook:
	if [ "$(man_owner)" ] && [ "$(man_mode)" = 6755 ]; then \
		chown $(man_owner):$(man_owner) \
			$(DESTDIR)$(bindir)/$(TRANS_MAN) \
			$(DESTDIR)$(bindir)/$(TRANS_MANDB); \
	fi
	chmod $(man_mode) \
		$(DESTDIR)$(bindir)/$(TRANS_MAN) \
		$(DESTDIR)$(bindir)/$(TRANS_MANDB)
	cd $(DESTDIR)$(bindir) && rm -f $(TRANS_APROPOS)$(EXEEXT) && \
		$(LN_S) $(TRANS_WHATIS)$(EXEEXT) $(TRANS_APROPOS)$(EXEEXT)

install-data-hook:
	@if test -f $(DESTDIR)$(config_file); then \
		echo "$(DESTDIR)$(config_file) already exists; overwrite manually if necessary"; \
	else \
		test -z "$(config_file_dirname)" || $(MKDIR_P) "$(DESTDIR)$(config_file_dirname)"; \
		echo " $(INSTALL_DATA) man_db.conf $(DESTDIR)$(config_file)"; \
		$(INSTALL_DATA) man_db.conf $(DESTDIR)$(config_file); \
	fi

uninstall-hook:
	rm -f $(DESTDIR)$(bindir)/$(TRANS_APROPOS)$(EXEEXT)
	@echo "Please remove $(DESTDIR)$(config_file) manually if necessary"
