## Process this file with automake to produce Makefile.in
##
## Copyright (C) 2008 Colin Watson.
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

DOMAIN = man-db-manpages
POFILES = \
	po/da.po \
	po/de.po \
	po/es.po \
	po/fr.po \
	po/id.po \
	po/ja.po \
	po/nl.po \
	po/pl.po \
	po/pt.po \
	po/pt_BR.po \
	po/ru.po \
	po/sr.po \
	po/sv.po \
	po/tr.po \
	po/zh_CN.po

EXTRA_DIST = po4a.cfg Locale/Po4a/Manext.pm po/$(DOMAIN).pot $(POFILES)

if PO4A
PO4A_ENVIRONMENT = PERL5LIB=$(srcdir)
STAGING = $(builddir)/tmp-po

# Always generate output files even if poorly translated, since Automake's
# generated rules will get upset otherwise.
PO4A_ARGS = --variable srcdir=$(top_srcdir)/man \
	    --variable builddir=$(top_builddir)/man \
	    --variable podir=$(STAGING) \
	    --keep 0

RUN_PO4A = $(PO4A_ENVIRONMENT) $(PO4A) $(PO4A_ARGS)

all-local:
	rm -rf $(STAGING)
	$(MKDIR_P) $(STAGING)
	set -e; for f in po/$(DOMAIN).pot $(POFILES); do \
		base=`basename $$f`; \
		cp -p $(srcdir)/$$f $(STAGING)/; \
		chmod u+w $(STAGING)/$$base; \
	done
	$(RUN_PO4A) $(srcdir)/po4a.cfg
	rm -rf $(STAGING)

update-po-real:
	@$(MAKE) -C $(top_builddir)/po remove-potcdate.sed
	rm -rf $(STAGING)
	$(MKDIR_P) $(STAGING)
	set -e; for f in po/$(DOMAIN).pot $(POFILES); do \
		base=`basename $$f`; \
		cp -p $(srcdir)/$$f $(STAGING)/; \
		chmod u+w $(STAGING)/$$base; \
	done
	$(RUN_PO4A) --force --no-translations $(srcdir)/po4a.cfg
	sed -f $(top_builddir)/po/remove-potcdate.sed \
		< $(srcdir)/po/$(DOMAIN).pot > $(STAGING)/$(DOMAIN).1po
	sed -f $(top_builddir)/po/remove-potcdate.sed \
		< $(STAGING)/$(DOMAIN).pot > $(STAGING)/$(DOMAIN).2po
	set -e; if ! cmp $(STAGING)/$(DOMAIN).1po $(STAGING)/$(DOMAIN).2po \
			>/dev/null 2>&1; then \
		for f in po/$(DOMAIN).pot $(POFILES); do \
			base=`basename $$f`; \
			mv -f $(STAGING)/$$base $(srcdir)/$$f; \
		done; \
	fi
	rm -rf $(STAGING)

update-po:
	@set -e; if test $(srcdir) = $(builddir); then \
		$(MAKE) update-po-real; \
	else \
		echo "update-po does not yet work with out-of-tree builds."; \
	fi

po/man-db-manpages.pot:
	$(MAKE) update-po

clean-local:
	rm -rf $(STAGING)
endif
