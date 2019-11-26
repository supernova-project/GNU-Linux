# man-arg-device.m4 serial 1
dnl MAN_ARG_DEVICE
dnl Add a --with-device option.

AC_DEFUN([MAN_ARG_DEVICE],
[
AC_ARG_WITH([device],
[AS_HELP_STRING([--with-device=DEVICE], [use nroff with the output device DEVICE])],
	[if test "$withval" = "yes" || test "$withval" = "no" 
	 then
	 	AC_MSG_ERROR([--with-device requires an argument])
	 else
	 	nroff_device=" -T$withval"
	 fi])
])
