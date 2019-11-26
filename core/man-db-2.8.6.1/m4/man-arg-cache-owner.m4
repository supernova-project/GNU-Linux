# man-arg-cache-owner.m4 serial 2
dnl MAN_ARG_CACHE_OWNER
dnl Add an --enable-cache-owner option.

AC_DEFUN([MAN_ARG_CACHE_OWNER],
[
AC_ARG_ENABLE([cache-owner],
[AS_HELP_STRING([--enable-cache-owner[=ARG]], [make system-wide cache files be owned by user ARG [arg=man]])
AS_HELP_STRING([--disable-cache-owner], [don't constrain ownership of system-wide cache files])],
	  [if test "$enableval" = "yes" 
	   then
		enableval=man
	   fi
	   if test "$enableval" = "no" 
	   then
		man_owner=
		cache_top_owner=root
		AC_MSG_NOTICE([System-wide cache files will have unconstrained ownership])
	   else
		man_owner=$enableval
		cache_top_owner=$enableval
		AC_MSG_NOTICE([System-wide cache files will be owned by $enableval])
	   	AC_DEFINE_UNQUOTED([MAN_OWNER], ["$man_owner"],
				   [Define as the owner of system-wide cache files.])
	   fi],
	  [man_owner=man
	   cache_top_owner=man
	   AC_DEFINE_UNQUOTED([MAN_OWNER], ["$man_owner"])])
AC_SUBST([man_owner])
AC_SUBST([cache_top_owner])
])
