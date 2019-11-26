## Process this file with automake to produce Makefile.in
##
## Copyright (C) 2014, 2016 Colin Watson.
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

EXTRA_DIST = \
	man-db.conf.in \
	man-db.service.in

CLEANFILES = \
	man-db.conf \
	man-db.service

if INSTALL_SYSTEMD_TMPFILES
systemdtmpfiles_DATA = man-db.conf

man-db.conf: man-db.conf.in
	sed -e "s,[@]cache_top_owner[@],$(cache_top_owner),g" $< > $@
endif

if INSTALL_SYSTEMD_TIMER
dist_systemdsystemunit_DATA = man-db.timer
systemdsystemunit_DATA = man-db.service

man-db.service: man-db.service.in
	sed -e "s,[@]bindir[@],$(bindir),g" \
	    -e "s,[@]cache_top_owner[@],$(cache_top_owner),g" \
	    $< > $@
else
EXTRA_DIST += man-db.timer
endif
