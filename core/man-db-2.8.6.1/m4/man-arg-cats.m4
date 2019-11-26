# man-arg-cats.m4 serial 1
dnl MAN_ARG_CATS
dnl Add a --disable-cats option.

AC_DEFUN([MAN_ARG_CATS],
[
AC_ARG_ENABLE([cats],
[AS_HELP_STRING([--disable-cats], [don't allow man to create/update cat files])],
	[if test "$enableval" = "yes"
	 then
		AC_DEFINE([MAN_CATS], [1], [Allow man to create/update cat files.])
	 fi],
	[AC_DEFINE([MAN_CATS], [1], [Allow man to create/update cat files.])])
])
