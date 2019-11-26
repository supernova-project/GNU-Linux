# man-trans-subst.m4 serial 2
dnl MAN_TRANS_SUBST(PROGRAM-NAME)
dnl Define and substitute a shell variable TRANS_PROG to the transformed
dnl version of PROGRAM-NAME, where PROG is PROGRAM-NAME converted to upper
dnl case.
dnl Also define and substitute an upper-case variant TRANS_PROG_UPPER.
AC_DEFUN([MAN_TRANS_SUBST],
[man_transformed=`echo $1 | sed "$program_transform_name"`
 AC_SUBST(AS_TR_CPP([TRANS_$1]), [$man_transformed])
 AC_SUBST(AS_TR_CPP([TRANS_$1_UPPER]), [AS_TR_CPP([$man_transformed])])
]) # MAN_TRANS_SUBST
