# man-arg-systemdsystemunitdir.m4 serial 3
dnl MAN_ARG_SYSTEMDSYSTEMUNITDIR
dnl Add a --with-systemdsystemunitdir option.

AC_DEFUN([MAN_ARG_SYSTEMDSYSTEMUNITDIR],
[
AC_REQUIRE([AC_CANONICAL_HOST])
AC_ARG_WITH([systemdsystemunitdir],
[AS_HELP_STRING([--with-systemdsystemunitdir=DIR], [Directory for systemd service files (disable with "no")])],
	[], [dnl
	# The default is not prefix-sensitive, since systemd's prefix is not
	# necessarily the same as man-db's.
	case $host_os in
	linux*)
		m4_pushdef([AC_ARG_VAR])dnl No need for precious variable handling.
		PKG_CHECK_VAR([with_systemdsystemunitdir], [systemd], [systemdsystemunitdir],
			      [], [with_systemdsystemunitdir=/lib/systemd/system])
		m4_popdef([AC_ARG_VAR])
		;;
	*)	with_systemdsystemunitdir=no ;;
	esac])
AC_SUBST([systemdsystemunitdir], [$with_systemdsystemunitdir])
AM_CONDITIONAL([INSTALL_SYSTEMD_TIMER], [test "$with_systemdsystemunitdir" != "no"])
])
