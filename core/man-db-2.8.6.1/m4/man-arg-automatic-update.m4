# man-arg-automatic-update.m4 serial 1
dnl MAN_ARG_AUTOMATIC_UPDATE
dnl Add a --disable-automatic-update option.

AC_DEFUN([MAN_ARG_AUTOMATIC_UPDATE],
[
AC_ARG_ENABLE([automatic-update],
[AS_HELP_STRING([--disable-automatic-update], [don't allow man to update databases on the fly])],
	[if test "$enableval" = "yes"
	 then
		AC_DEFINE([MAN_DB_UPDATES], [1], [Allow man to update databases on the fly.])
	 fi],
	[AC_DEFINE([MAN_DB_UPDATES], [1], [Allow man to update databases on the fly.])])
])
