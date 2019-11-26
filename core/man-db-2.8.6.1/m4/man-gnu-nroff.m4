# man-gnu-nroff.m4 serial 3
dnl
dnl Check to see if nroff is GNU nroff, take nroff path as arg.
dnl
AC_DEFUN([MAN_PROG_GNU_NROFF],
[AC_MSG_CHECKING([whether nroff is GNU nroff])

AC_CACHE_VAL([man_cv_prog_gnu_nroff],
  [if test `$1 <<EOF | tr -d '\n'
\\n(.g
EOF
` = 1
   then
	man_cv_prog_gnu_nroff=yes
   else
	man_cv_prog_gnu_nroff=no
   fi])

if test "$man_cv_prog_gnu_nroff" = "yes" 
then
	AC_DEFINE([GNU_NROFF], [1], [Define if nroff is GNU nroff.])
fi
AC_MSG_RESULT([$man_cv_prog_gnu_nroff])
])
