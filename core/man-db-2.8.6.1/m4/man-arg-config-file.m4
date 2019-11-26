# man-arg-config-file.m4 serial 1
dnl MAN_ARG_CONFIG_FILE
dnl Add a --with-config-file option.

AC_DEFUN([MAN_ARG_CONFIG_FILE],
[
AC_ARG_WITH([config-file],
[AS_HELP_STRING([--with-config-file=CF], [use config file CF [CF=SYSCONFDIR/man_db.conf]])],
	[if test "$withval" = "yes" || test "$withval" = "no"
	 then
		AC_MSG_ERROR([--with-config-file requires an argument])
	 else
		config_file=$withval
	 fi],
	[: ${config_file=\$\{sysconfdir\}/man_db.conf}])
config_file_basename=${config_file##*/}
config_file_dirname=`AS_DIRNAME(["$config_file"])`
AC_SUBST([config_file])
AC_SUBST([config_file_basename])
AC_SUBST([config_file_dirname])
])
