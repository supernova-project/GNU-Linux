# man-heirloom-nroff.m4 serial 1
dnl MAN_PROG_HEIRLOOM_NROFF(PROGRAM-NAME)
dnl Check whether the given nroff program is from the Heirloom Documentation
dnl Tools.  We do this by testing the .X number register; it should be
dnl non-zero, and should change to a different value if the -mg option is
dnl used to enable groff compatibility.
AC_DEFUN([MAN_PROG_HEIRLOOM_NROFF],
[AC_MSG_CHECKING([whether nroff is Heirloom nroff])

AC_CACHE_VAL([man_cv_prog_heirloom_nroff],
  [man_heirloom_ext_plain=`$1 2>/dev/null <<EOF | tr -d '\n'
\\n(.X
EOF
`
   man_heirloom_ext_mg=`$1 -mg 2>/dev/null <<EOF | tr -d '\n'
\\n(.X
EOF
`
   if test "x$man_heirloom_ext_plain" != 0 && \
      test "x$man_heirloom_ext_mg" != 0 && \
      test "x$man_heirloom_ext_plain" != "x$man_heirloom_extflag_mg"
   then
     man_cv_prog_heirloom_nroff=yes
   else
     man_cv_prog_heirloom_nroff=no
   fi])

if test "$man_cv_prog_heirloom_nroff" = "yes"
then
  AC_DEFINE([HEIRLOOM_NROFF], [1], [Define if nroff is Heirloom nroff.])
fi
AC_MSG_RESULT([$man_cv_prog_heirloom_nroff])
])
