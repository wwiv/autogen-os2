
dnl AC_SNPRINTFV_CONVENIENCE[(dir)] - sets LIBSNPRINTFV to the link flags for
dnl the snprintfv convenience library and INCSNPRINTFV to the include flags for
dnl the snprintfv header and adds --enable-snprintfv-convenience to the
dnl configure arguments.  Note that AC_CONFIG_SUBDIRS is not called.  If DIR
dnl is not provided, it is assumed to be `snprintfv'.  LIBSNPRINTFV will be
dnl prefixed with '${top_builddir}/' and INCSNPRINTFV will be prefixed with
dnl '${top_srcdir}/' (note the single quotes!).  If your package is not
dnl flat and you're not using automake, define top_builddir and
dnl top_srcdir appropriately in the Makefiles.
AC_DEFUN([AC_SNPRINTFV_CONVENIENCE],
[case $enable_snprintfv_convenience in
  no) AC_MSG_ERROR([this package needs a convenience snprintfv]) ;;
  "") enable_snprintfv_convenience=yes
      ac_configure_args="$ac_configure_args --enable-snprintfv-convenience" ;;
  esac
  LIBSNPRINTFV='${top_builddir}/'ifelse($#,1,[$1],['snprintfv'])/snprintfv/libsnprintfvc.la
  INCSNPRINTFV='-I${top_builddir}/'ifelse($#,1,[$1],['snprintfv'])' -I${top_srcdir}/'ifelse($#,1,[$1],['snprintfv'])
  AC_SUBST(LIBSNPRINTFV)
  AC_SUBST(INCSNPRINTFV)
])

AC_DEFUN([INVOKE_SNPRINTFV_MACROS],[
  AC_SNPRINTFV_CONVENIENCE
  # ----------------------------------------------------------------------
  # Set up and process configure options
  # ----------------------------------------------------------------------
  AC_ARG_ENABLE(snprintfv-install,
  [  --enable-snprintfv-install  install libsnprintfv [yes]])
  AM_CONDITIONAL(INSTALL_SNPRINTFV,
  test x"${enable_snprintfv_install-no}" != xno)
  AM_CONDITIONAL(CONVENIENCE_SNPRINTFV,
  test x"${enable_snprintfv_convenience-no}" != xno)
  AM_CONDITIONAL(SUBDIR_SNPRINTFV,
  test x"${enable_subdir-no}" != xno)

  AM_WITH_DMALLOC

  # ----------------------------------------------------------------------
  # check for various programs used during the build.
  # ----------------------------------------------------------------------
  AC_PROG_AWK
  AC_CHECK_HEADER(wchar.h)
  dnl am_cv_prog_cc_stdc is set by AC_PROG_CC_STDC
  case x$am_cv_prog_cc_stdc in
  xno)
    # Non ansi C => won't work with stdarg.h
    AC_CHECK_HEADER(varargs.h)
    ;;
  *)
    case x$ac_cv_header_varargs_h in
    xyes)
      # Parent package is using varargs.h which is incompatible with
      # stdarg.h, so we do the same.
      AC_CHECK_HEADER(varargs.h)
      ;;
    *)
      # If stdarg.h is present define HAVE_STDARG_H, otherwise if varargs.h
      # is present define HAVE_VARARGS_H.
      AC_CHECK_HEADERS(stdarg.h varargs.h, break)
      ;;
    esac
    ;;
  esac

  case x$ac_cv_header_stdarg_h$ac_cv_header_varargs_h in
  x*yes*) ;;
  *) AC_MSG_ERROR(Could not find either stdarg.h or varargs.h.) ;;
  esac

  # ----------------------------------------------------------------------
  # Checks for typedefs
  # ----------------------------------------------------------------------
  AC_CHECK_TYPE(wchar_t, unsigned int)
  AC_CHECK_TYPE(wint_t,  unsigned int)
  AC_CHECK_TYPE(long double)
  AC_CHECK_TYPE(intmax_t)
  AC_TYPE_SIZE_T

  # ----------------------------------------------------------------------
  # Checks for library calls
  # ----------------------------------------------------------------------
  AC_REPLACE_FUNCS(strtoul ldexpl frexpl)
  AC_CHECK_LIB(m, log)
  AC_CHECK_FUNCS(copysign copysignl)
])
