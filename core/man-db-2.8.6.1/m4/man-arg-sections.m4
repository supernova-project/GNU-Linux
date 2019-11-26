# man-arg-sections.m4 serial 2
dnl MAN_ARG_SECTIONS
dnl Add a --with-sections option.

AC_DEFUN([MAN_ARG_SECTIONS],
[
AC_ARG_WITH([sections],
[AS_HELP_STRING([--with-sections=SECTIONS], [use manual page sections SECTIONS @<:@1 n l 8 3 0 2 5 4 9 6 7@:>@])],
	[if test "$withval" = "yes" || test "$withval" = "no"
	 then
		AC_MSG_ERROR([--with-sections requires an argument])
	 else
		sections="$withval"
	 fi],
	[: ${sections=1 n l 8 3 0 2 5 4 9 6 7}])
AC_SUBST([sections])dnl
])
