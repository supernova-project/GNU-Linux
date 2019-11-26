## Process this file with automake to produce Makefile.in
##
## Copyright (C) 1994, 1995 Graeme Wilford.
## Copyright (C) 2001, 2002, 2003, 2005, 2006, 2007, 2009, 2010, 2011, 2012
##               Colin Watson.
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

if HAVE_GNULIB_PO
GNULIB_PO = gl/po
endif

SUBDIRS = docs gl/lib $(GNULIB_PO) init lib libdb src man manual po tools

dist_noinst_DATA = FAQ NEWS README include/README

EXTRA_DIST = \
	.gitignore \
	ChangeLog-2013 \
	bootstrap \
	bootstrap.conf \
	patches/argp-domain.patch \
	patches/fdutimens-hurd.patch \
	release.sh

# These macro files are imported by gnulib-tool, but at present not used. We
# include them in the distribution anyway for maximum consistency.
EXTRA_DIST += \
	gl/m4/glibc2.m4 \
	gl/m4/intdiv0.m4 \
	gl/m4/intl.m4 \
	gl/m4/intldir.m4 \
	gl/m4/intmax.m4 \
	gl/m4/inttypes-pri.m4 \
	gl/m4/lcmessage.m4 \
	gl/m4/math_h.m4 \
	gl/m4/printf-posix.m4 \
	gl/m4/sockpfaf.m4 \
	gl/m4/uintmax_t.m4 \
	gl/m4/visibility.m4

# Installing in --enable-setuid mode (the default) requires root; disable
# this so that distcheck can be run as non-root.
# The defaults for systemdsystemunitdir and systemdtmpfilesdir are
# intentionally not prefix-sensitive, but we need to adjust them in order
# for distcheck to pass.
AM_DISTCHECK_CONFIGURE_FLAGS = \
	--disable-setuid \
	--with-systemdsystemunitdir=\$${prefix}/lib/systemd/system \
	--with-systemdtmpfilesdir=\$${prefix}/lib/tmpfiles.d

# We deliberately leave the configuration file in place on uninstall, since
# it may contain local customisations.
distuninstallcheck_listfiles = \
	find . -type f -print | grep -v 'etc/man_db\.conf'

# Note that autopoint installs into the first directory here. Yes, this
# means that it installs into gl/m4, so we always run gnulib-tool after
# autopoint, at least for now. See
# https://lists.gnu.org/archive/html/bug-gnulib/2009-03/msg00154.html and
# thread.
ACLOCAL_AMFLAGS = -I gl/m4 -I m4

dist-hook: gen-ChangeLog

gen_start_date = '2013-12-09 00:52'
.PHONY: gen-ChangeLog
gen-ChangeLog:
	$(AM_V_GEN)if test -d .git; then \
		$(top_srcdir)/build-aux/gitlog-to-changelog \
			--format='%s%n%n%b%n' \
			--since="$(gen_start_date)" > $(distdir)/cl-t; \
		rm -f $(distdir)/ChangeLog; \
		mv $(distdir)/cl-t $(distdir)/ChangeLog; \
	fi
