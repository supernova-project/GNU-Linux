# man-arg-setuid.m4 serial 3
dnl MAN_ARG_SETUID
dnl Add an --enable-setuid option.

AC_DEFUN([MAN_ARG_SETUID],
[
AC_ARG_ENABLE([setuid],
[AS_HELP_STRING([--enable-setuid], [install man setuid])
AS_HELP_STRING([--disable-setuid], [don't install man setuid])],
	  [if test "$enableval" = "yes" 
	   then
		if test -z "$man_owner"
		then
			AC_MSG_ERROR([--enable-setuid is incompatible with --disable-cache-owner])
		fi
		man_mode="6755"
		AC_MSG_NOTICE([Man will be installed setuid $man_owner])
	   elif test "$enableval" = "no" 
	   then
		man_mode="755"
		AC_MSG_NOTICE([Man will not be installed setuid])
	   else
		AC_MSG_ERROR([--enable-setuid=$enableval is no longer valid; consider --enable-cache-owner=$enableval --enable-setuid instead])
	   fi],
	  [if test -z "$man_owner"
	   then
		man_mode="755"
	   else
		man_mode="6755"
	   fi])
AC_SUBST([man_mode])
])
