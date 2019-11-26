# man-libseccomp.m4 serial 2
dnl MAN_LIBSECCOMP
dnl Add a --without-libseccomp option; check for the libseccomp library.
AC_DEFUN([MAN_LIBSECCOMP],
	[AC_ARG_WITH([libseccomp],
		[AS_HELP_STRING([--without-libseccomp],
				[do not confine subprocesses using seccomp])],
		[],
		[with_libseccomp=check])
	if test "x$with_libseccomp" != "xno"; then
		PKG_CHECK_MODULES([libseccomp], [libseccomp],
			[AC_DEFINE([HAVE_LIBSECCOMP], [1],
				[Define to 1 if you have the `libseccomp' library.])],
			[if test "x$with_libseccomp" = "xyes"; then
				AC_MSG_ERROR([--with-libseccomp given but cannot find libseccomp])
			 fi])
	fi
]) # MAN_LIBSECCOMP
