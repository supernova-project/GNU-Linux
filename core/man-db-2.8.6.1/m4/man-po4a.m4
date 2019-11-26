# man-po4a.m4 serial 2
dnl MAN_PO4A
dnl Detect the presence of po4a.

AC_DEFUN([MAN_PO4A],
[AC_CHECK_PROGS([PO4A], [po4a])
 AC_SUBST([PO4A])
 AM_CONDITIONAL([PO4A], [test -n "$PO4A"])
]) # MAN_PO4A
