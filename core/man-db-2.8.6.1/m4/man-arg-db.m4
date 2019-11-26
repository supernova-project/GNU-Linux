# man-arg-db.m4 serial 1
dnl MAN_ARG_DB
dnl Add a --with-db option.

AC_DEFUN([MAN_ARG_DB],
[
AC_ARG_WITH([db],
[AS_HELP_STRING([--with-db=LIBRARY], [use database library LIBRARY (db5, db4, db3, db2, db1, db, gdbm, ndbm)])],
	[if test "$withval" = "yes" || test "$withval" = "no" 
	 then
	 	AC_MSG_ERROR([--with-db requires an argument])
	 else
	 	db=$withval
	 fi],
	[: ${db=no}])
])
