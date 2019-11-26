## Process this file with automake to produce Makefile.in
##
## Copyright (C) 1995 Graeme Wilford.
## Copyright (C) 2001, 2007 Colin Watson.
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

ME_FILES = \
	comp.me \
	db.me \
	files.me \
	format.me \
	glossary.me \
	intro.me \
	leader.me \
	man_db.me \
	misc.me \
	sec.me

MANUAL = man_db
MANUAL_INSTALL = man-db-manual

dist_noinst_DATA = \
	README \
	$(ME_FILES) \
	options-only.me \
	print-options

if BUILD_MANUAL
noinst_DATA = \
	$(MANUAL).cat \
	$(MANUAL).ps

CLEANFILES = \
	$(noinst_DATA) \
	$(MANUAL).dvi \
	$(MANUAL).html \
	$(MANUAL).pp \
	$(MANUAL).tdvi \
	$(MANUAL).tps \
	version

SOELIM = soelim

version: $(top_srcdir)/configure.ac
	echo '.ds V $(roff_version)' > $@

$(MANUAL).pp: $(ME_FILES) version
	$(SOELIM) -I$(srcdir) man_db.me | tbl > $@.new && mv -f $@.new $@

.pp.dvi:
	$(TROFF) -me -Tdvi $< > $@.new && mv -f $@.new $@

.pp.ps:
	$(TROFF) -me -Tps $< > $@.new && mv -f $@.new $@

.pp.tdvi:
	$(TROFF) -me -Tdvi $< | grodvi -d > $@.new && mv -f $@.new $@

.tdvi.tps:
	dvips -f -t a4 $< > $@.new && mv -f $@.new $@

.pp.cat:
	LC_ALL=C nroff -me $< > $@.new && mv -f $@.new $@

.pp.html:
	$(TROFF) -me -Thtml -P-I$* $< > $@.new && mv -f $@.new $@

# Automake defines these targets already, so we need to use -local.
dvi-local: $(MANUAL).dvi
ps-local: $(MANUAL).ps
html-local: $(MANUAL).html

# These are all ours.
cat: $(MANUAL).cat
tps: $(MANUAL).tps

clean-local:
	-rm -f $(MANUAL)-*.png

install-data-hook:
	test -z "$(docdir)" || $(MKDIR_P) "$(DESTDIR)$(docdir)"
	@if test -f $(MANUAL).cat; then \
		echo " $(INSTALL_DATA) $(MANUAL).cat '$(DESTDIR)$(docdir)/$(MANUAL_INSTALL).txt'"; \
		$(INSTALL_DATA) $(MANUAL).cat "$(DESTDIR)$(docdir)/$(MANUAL_INSTALL).txt" || exit $$?; \
	fi
	@if test -f $(MANUAL).ps; then \
		echo " $(INSTALL_DATA) $(MANUAL).ps '$(DESTDIR)$(docdir)/$(MANUAL_INSTALL).ps'"; \
		$(INSTALL_DATA) $(MANUAL).ps "$(DESTDIR)$(docdir)/$(MANUAL_INSTALL).ps" || exit $$?; \
	fi

uninstall-hook:
	rm -rf "$(DESTDIR)$(docdir)"
endif
