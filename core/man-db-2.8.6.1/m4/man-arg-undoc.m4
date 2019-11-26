# man-arg-undoc.m4 serial 1
dnl MAN_ARG_UNDOC
dnl Add an --enable-undoc option.

AC_DEFUN([MAN_ARG_UNDOC],
[
AC_ARG_ENABLE([undoc],
[AS_HELP_STRING([--enable-undoc=COMMAND], [suggest COMMAND for missing manual pages])],
	[if test "$enableval" = "yes" || test "$enableval" = "no"
	 then
		AC_MSG_ERROR([--enable-undoc requires an argument])
	 else
		AC_MSG_NOTICE([Suggesting '$enableval' for missing manual pages])
		AC_DEFINE_UNQUOTED([UNDOC_COMMAND], ["$enableval"],
				   [Define as the name of a command you want to suggest when a non-existent page is requested.])
	 fi])
])
