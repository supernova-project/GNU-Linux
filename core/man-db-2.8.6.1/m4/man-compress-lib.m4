# man-compress-lib.m4 serial 1
dnl MAN_COMPRESS_LIB(LIBRARY, FUNCTION)
dnl Look for FUNCTION in LIBRARY. If it is available, define HAVE_LIBLIBRARY
dnl and add -lLIBRARY to LIBCOMPRESS.
AC_DEFUN([MAN_COMPRESS_LIB],
[AC_CHECK_LIB(
  [$1], [$2],
  [AC_DEFINE_UNQUOTED(
    AS_TR_CPP([HAVE_LIB$1]), [1],
    [Define to 1 if you have the `$1' library (-l$1).])
   LIBCOMPRESS="-l$1 $LIBCOMPRESS"])
 AC_SUBST([LIBCOMPRESS])
]) # MAN_COMPRESS_LIB
