# man-arg-mandirs.m4 serial 1
dnl MAN_ARG_MANDIRS
dnl Add an --enable-mandirs option.

AC_DEFUN([MAN_ARG_MANDIRS],
[
# Work out which manual page hierarchy scheme might be in use.
AC_ARG_ENABLE([mandirs],
[AS_HELP_STRING([--enable-mandirs=OS], [select manual page hierarchy organization (GNU, HPUX, IRIX, Solaris, BSD)])],
	[AC_MSG_NOTICE([Using $enableval hierarchy organization(s)])
	 AC_DEFINE_UNQUOTED([MANDIR_LAYOUT], ["$enableval"],
			    [Define to the manual page hierarchy organization(s) in use.])
	 MANDIR_LAYOUT="$enableval"],
	[case $host in
		*-gnu)          mandirs=GNU;;
		*-hpux*)        mandirs=HPUX;;
		*-irix*)        mandirs=IRIX;;
		*-solaris*)     mandirs=Solaris;;
		*-*bsd*)        mandirs=BSD;;
		*)              mandirs=;;
	 esac
	 if test -n "$mandirs"; then
		AC_MSG_NOTICE([Using $mandirs hierarchy organization])
		AC_DEFINE_UNQUOTED([MANDIR_LAYOUT], ["$mandirs"])
		MANDIR_LAYOUT="$mandirs"
	 else
		AC_MSG_NOTICE([Allowing any hierarchy organization])
		AC_DEFINE([MANDIR_LAYOUT], [""])
		MANDIR_LAYOUT=
	 fi])
AC_SUBST([MANDIR_LAYOUT])
])
