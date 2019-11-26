# man-arg-manual.m4 serial 1
dnl MAN_ARG_MANUAL
dnl Add a --disable-manual option.
dnl This may be useful when cross-compiling, or to reduce the installation
dnl size.

AC_DEFUN([MAN_ARG_MANUAL],
[
AC_ARG_ENABLE([manual],
[AS_HELP_STRING([--disable-manual], [don't build or install the man-db manual])],
	[enable_manual="$enableval"], [enable_manual=yes])
AM_CONDITIONAL([BUILD_MANUAL], [test "$enable_manual" = yes])
])
