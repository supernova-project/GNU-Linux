# man-linguas.m4 serial 2
dnl MAN_LINGUAS
dnl Compute the set of localised manual pages to install, taking the LINGUAS
dnl environment variable into account if set.

dnl Draws somewhat on po.m4:

dnl Copyright (C) 1995-2007 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.
dnl
dnl This file can can be used in projects which are not available under
dnl the GNU General Public License or the GNU Library General Public
dnl License but which still want to provide support for the GNU gettext
dnl functionality.
dnl Please note that the actual code of the GNU gettext library is covered
dnl by the GNU Library General Public License, and the rest of the GNU
dnl gettext package package is covered by the GNU General Public License.
dnl They are *not* in the public domain.

dnl Authors:
dnl   Ulrich Drepper <drepper@cygnus.com>, 1995-2000.
dnl   Bruno Haible <haible@clisp.cons.org>, 2000-2003.

AC_PREREQ([2.50])

AC_DEFUN([MAN_LINGUAS],
[
  AC_REQUIRE([AM_NLS])dnl
  if test "$USE_NLS" = yes; then
    # The LINGUAS file contains the set of available languages.
    man_all_linguas=
    if test -n "$srcdir/man/LINGUAS"; then
      man_all_linguas=`sed -e "/^#/d" -e "s/#.*//" "$srcdir/man/LINGUAS"`
    fi
    if test -n "$PO4A" && test -n "$srcdir/man/LINGUAS.po4a"; then
      man_all_linguas_po4a=`sed -e "/^#/d" -e "s/#.*//" "$srcdir/man/LINGUAS.po4a"`
      man_all_linguas="$man_all_linguas $man_all_linguas_po4a"
    fi
    man_inst_linguas=
    for presentlang in $man_all_linguas; do
      useit=no
      if test -n "$LINGUAS"; then
        desiredlanguages="$LINGUAS"
      else
        desiredlanguages="$man_all_linguas"
      fi
      for desiredlang in $desiredlanguages; do
        # Use the presentlang catalog if desiredlang is
        #   a. equal to presentlang, or
        #   b. a variant of presentlang (because in this case,
        #      presentlang can be used as a fallback for messages
        #      which are not translated in the desiredlang catalog).
        case "$desiredlang" in
          "$presentlang"*) useit=yes;;
        esac
      done
      if test $useit = yes; then
        man_inst_linguas="$man_inst_linguas $presentlang"
      fi
    done
    if test -n "$PO4A"; then
      MAN_SUBDIRS="po4a $man_inst_linguas"
    else
      MAN_SUBDIRS="$man_inst_linguas"
    fi
  else
    MAN_SUBDIRS=
  fi
  AC_SUBST([MAN_SUBDIRS])
]) # MAN_LINGUAS
