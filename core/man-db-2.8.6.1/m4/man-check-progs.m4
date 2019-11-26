# man-check-progs.m4 serial 3
dnl MAN_CHECK_PROGS(VARIABLE, WITH-ARG, HELP-STRING, PROGS-TO-CHECK-FOR)
dnl Look for a program to use as VARIABLE. If --with-VARIABLE is given, then
dnl set VARIABLE to the path provided there (WITH-ARG and HELP-STRING are
dnl used for --help output). Otherwise, set VARIABLE to the first of
dnl PROGS-TO-CHECK-FOR on the path; if none of those is found, leave
dnl VARIABLE unchanged.
dnl If the program was found, define HAVE_WITH-ARG.
AC_DEFUN([MAN_CHECK_PROGS],
[AC_ARG_WITH([$1], [AS_HELP_STRING([--with-$1=$2], [$3])],
             [AS_IF([test "$withval" = yes || test "$withval" = no],
                    [AC_MSG_ERROR([--with-$1 requires an argument])],
                    [AC_MSG_CHECKING([for $1])
                     AC_MSG_RESULT([$withval])
                     $1="$withval"])],
             [AC_CHECK_PROGS([$1], [$4])])
if test -n "$$1"; then
	AC_DEFINE([HAVE_$2], [1], [Define if you have $1.])
fi]) # MAN_CHECK_PROGS
