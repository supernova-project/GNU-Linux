# man-arg-automatic-create.m4 serial 1
dnl MAN_ARG_AUTOMATIC_CREATE
dnl Add an --enable-automatic-create option.

AC_DEFUN([MAN_ARG_AUTOMATIC_CREATE],
[
AC_ARG_ENABLE([automatic-create],
[AS_HELP_STRING([--enable-automatic-create], [allow man to create user databases on the fly])],
	[if test "$enableval" = "yes"
	 then
		AC_DEFINE([MAN_DB_CREATES], [1], [Allow man to create user databases on the fly.])
	 fi])
])
