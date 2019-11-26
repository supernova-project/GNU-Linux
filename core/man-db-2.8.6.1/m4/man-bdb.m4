# man-bdb.m4 serial 4
dnl MAN_CHECK_BDB(WITH-DB, HEADERS, LIBS, [ACTION-IF-FOUND])
dnl Helper to check Berkeley DB linkage when particular header files and
dnl libraries are included. ACTION-IF-FOUND may contain $head and $lib.
dnl Contributed by Duncan Simpson <dps@io.stargate.co.uk> and hacked into a
dnl macro by Colin Watson.

AC_DEFUN([MAN_CHECK_BDB], [dnl
man_bdb_requested=no
for trydb in $1
do
  if test "$db" = "$trydb"
  then
    man_bdb_requested=yes
  fi
done
if test "$db" = no || test "$man_bdb_requested" = yes
then
  for head in $2
  do
    AC_CHECK_HEADERS([$head], [got=yes], [got=no])
    if test "$got" = "yes"
    then
      for lib in $3
      do
        AS_VAR_PUSHDEF([man_tr_bdb], [man_cv_bdb_header_${head}_lib_${lib}])dnl
        man_saved_LIBS="$LIBS"
        LIBS="$LIBS -l$lib"
        AC_CACHE_CHECK([for dbopen from <${head}> in -l${lib}], man_tr_bdb,
           [AC_TRY_LINK([#include <$head>], [dbopen("foo", 0, 0, 0, (void *) 0)],
                        [AS_VAR_SET([man_tr_bdb], [yes])],
                        [AS_VAR_SET([man_tr_bdb], [no])])
           ])
        AS_VAR_IF([man_tr_bdb], [yes],
                  [$4
                   AC_DEFINE_UNQUOTED([BDB_H], [<$head>],
                                      [Define if you have, and want to use, Berkeley database header files.])
                   AC_DEFINE_UNQUOTED([BTREE], [1],
                                      [Define if you have, and want to use, the Berkeley database library.])
                   AC_SUBST([DBTYPE], [btree])
                   DBLIBS="-l$lib"
                   db=yes],
                  [db=no])
        LIBS="$man_saved_LIBS"
        AS_VAR_POPDEF([man_tr_bdb])dnl
        test "$db" = "yes" && break
      done
    fi
    test "$db" = "yes" && break
  done
fi[]dnl
])# MAN_CHECK_BDB
