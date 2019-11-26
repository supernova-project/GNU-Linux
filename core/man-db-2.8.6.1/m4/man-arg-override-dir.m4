# man-arg-override-dir.m4 serial 1
dnl MAN_ARG_OVERRIDE_DIR
dnl Add an --enable-override-dir option.

AC_DEFUN([MAN_ARG_OVERRIDE_DIR],
[
AC_ARG_WITH([override-dir],
[AS_HELP_STRING([--with-override-dir=OVERRIDE], [use OVERRIDE as relative override dir inside the man path - the first directory to be searched when looking for man pages])],
	[if test "$withval" = "yes" || test "$withval" = "no"
	 then
		AC_MSG_ERROR([--with-override-dir requires an argument])
	 else
		override_dir=$withval
	 fi],
	[: ${override_dir=""}])
AC_SUBST([override_dir])
])
