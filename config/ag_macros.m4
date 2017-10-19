
dnl do always before generated macros:
dnl
AC_DEFUN([INVOKE_AG_MACROS_FIRST],[
  AC_CHECK_HEADERS([libio.h ctype.h assert.h sys/resource.h])
  AC_CHECK_DECLS([sigsetjmp],,, [#include <setjmp.h>])
  AC_DECL_SYS_SIGLIST
  AC_CHECK_FUNCS([putenv getdate_r utimes futimes])

  AC_C_INLINE
  AC_TYPE_LONG_LONG_INT

  AC_PROG_GREP
  AC_PROG_EGREP
  AC_PROG_FGREP
])



dnl
dnl do always after generated macros:
dnl
AC_DEFUN([INVOKE_AG_MACROS_LAST],[
[if test X${INVOKE_AG_MACROS_LAST_done} != Xyes ; then]
  GUILE_FLAGS
  [test -x "${PKG_CONFIG}" || {
    test -z "${PKG_CONFIG}" && PKG_CONFIG=pkg-config
    f=`command -v ${PKG_CONFIG}`
    test -x "${f}" && PKG_CONFIG="$f"
  }
  # Grab the first "-I" option that works
  #
  ag_gv=`gdir=\`${PKG_CONFIG} --cflags-only-I \
      guile-${GUILE_EFFECTIVE_VERSION} | \
    sed 's/ *-I/ /g'\`
  test ${#gdir} -gt 1 || gdir=/usr/include
  for d in $gdir
  do  test -f "$d/libguile/version.h" && gdir=$d && break
  done
  gdir=\`awk '/SCM_MICRO_VERSION/{ print @S|@3 }' \
  "${gdir}/libguile/version.h"\`
  test -n "$gdir" || exit 1
  IFS=' .'
  set -- ${GUILE_EFFECTIVE_VERSION}
  printf '%u%02u%03u' ${1} ${2} ${gdir}
  `

  test -n "$ag_gv" || ]AC_MSG_FAILURE([cannot determine Guile version], 1)
  AC_DEFINE_UNQUOTED(GUILE_VERSION, ${ag_gv},
             [define to a single number for Guile version])
  INVOKE_LIBOPTS_MACROS

  [test "X${ac_cv_header_sys_wait_h}" = Xyes || \
      ]AC_MSG_ERROR([you must have sys/wait.h on your system])

  AC_CHECK_FUNCS([fopencookie funopen], [break])
  case "${ac_cv_func_fopencookie}${ac_cv_func_funopen}" in
  *yes* )
     AC_DEFINE([ENABLE_FMEMOPEN], 1, "Define if we can use it")
     ;;
  esac

  # Note that BSD does not typedef these in its headers, but instead
  # calls for them to be identical in signature to read(2), write(2),
  # lseek(2), and close(2).  Newlib however does include typedefs
  # in its stdio.h for these, and they do not match the signatures
  # of the BSD implementation.  So this test relies on the fact
  # that any typedef will succeed for BSD, while only one that
  # matches the existing definitions in stdio.h will succeed for
  # a newlib system.

  if test "X${ac_cv_func_funopen}" = Xyes; then
    AC_CACHE_CHECK([for cookie_function_t type],
      [ag_cv_cookie_function_t],
      [AC_TRY_COMPILE([#include <stdio.h>
        typedef int cookie_read_function_t (void *, char *, int);
        ], [], ag_cv_cookie_function_t="bsd",
        AC_TRY_COMPILE([#include <stdio.h>
          typedef ssize_t cookie_read_function_t (void *, char *, size_t);
          ], [], ag_cv_cookie_function_t="newlib",
          AC_MSG_ERROR([Unknown flavor of cookie_XXX_t types])))])
  fi
  if test "X${ag_cv_cookie_function_t}" = Xbsd; then
    AC_DEFINE([NEED_COOKIE_FUNCTION_TYPEDEFS], [1],
      [Define if typedefs for the funopen function pointers are required.])
  fi

  AC_CACHE_CHECK([for static inline], [snv_cv_static_inline], [
  AC_TRY_COMPILE([static inline foo(bar) int bar; { return bar; }],
    [return foo(0);],
    [snv_cv_static_inline='static inline'],
    [snv_cv_static_inline='static'])
  ])
  AC_DEFINE_UNQUOTED(SNV_INLINE, ${snv_cv_static_inline},
           [define to static or static inline])
  [if test "X${libopts_cv_with_libregex}" = Xno
  then
    echo "A POSIX compliant regcomp/regexec routine is required.
  These are required for AutoGen to work correctly.  If you have
  such a library present on your system, you must specify it by
  setting the LIBS environment variable, e.g., \"LIBS='-lregex'\".
  If you do not have such a library on your system, then you should
  download and install, for example, the one from:
      ftp://ftp.gnu.org/gnu/rx/" >&2]
    AC_MSG_ERROR([Cannot find working POSIX regex library])
  [fi]
[  INVOKE_AG_MACROS_LAST_done=yes
fi]])

dnl
dnl @synopsis  INVOKE_AG_MACROS
dnl
dnl  This macro will invoke the AutoConf macros specified in misc.def
dnl  that have not been disabled with "omit-invocation".
dnl
AC_DEFUN([AG_DISABLE_SHELL],[
  AC_ARG_ENABLE([shell],
    AS_HELP_STRING([--disable-shell], [shell scripts are desired]),
    [ag_cv_enable_shell=${enable_shell}],
    AC_CACHE_CHECK([whether shell scripts are desired], ag_cv_enable_shell,
      ag_cv_enable_shell=yes)
  ) # end of AC_ARG_ENABLE
  if test "X${ag_cv_enable_shell}" != Xno
  then
    AC_FUNC_FORK
  fi

]) # end of AC_DEFUN of AG_DISABLE_SHELL


AC_DEFUN([AG_TEST_DO_SHELL],[
  AC_MSG_CHECKING([whether using shell scripts])
  AC_CACHE_VAL([ag_cv_test_do_shell],[
    ag_cv_test_do_shell=`exec 2> /dev/null
test "x$ac_cv_func_fork_works" != xyes && \\
    test "x$ac_cv_func_vfork_works" != xyes && exit 1
test "x$ag_cv_enable_shell" = xyes || exit 1
echo yes`
    if test $? -ne 0 || test -z "$ag_cv_test_do_shell"
    then ag_cv_test_do_shell=no
    fi
  ]) # end of CACHE_VAL of ag_cv_test_do_shell
  AC_MSG_RESULT([${ag_cv_test_do_shell}])
  if test "X${ag_cv_test_do_shell}" != Xno
  then
    AC_SUBST(OPTS_TESTDIR)
AC_SUBST(AGEN5_TESTS)
AC_DEFINE([SHELL_ENABLED], [1], [Define if shell scripts are enabled])
OPTS_TESTDIR=test
AGEN5_TESTS='$(SHELL_TESTS) $(NOSHELL_TESTS)'
  else
    OPTS_TESTDIR=
AGEN5_TESTS='$(NOSHELL_TESTS)'
  fi
  AM_CONDITIONAL([DO_SHELL_CMDS],[test "X${ag_cv_test_do_shell}" != Xno])

]) # end of AC_DEFUN of AG_TEST_DO_SHELL


AC_DEFUN([AG_ENABLE_STATIC_AUTOGEN],[
  AC_ARG_ENABLE([static-autogen],
    AS_HELP_STRING([--enable-static-autogen], [statically link autogen to libopts]),
    [ag_cv_enable_static_autogen=${enable_static_autogen}],
    AC_CACHE_CHECK([whether statically link autogen to libopts], ag_cv_enable_static_autogen,
      ag_cv_enable_static_autogen=no)
  ) # end of AC_ARG_ENABLE
  if test "X${ag_cv_enable_static_autogen}" != Xno
  then
    AC_DEFINE([STATIC_AUTOGEN_ENABLED],[1],
        [Define this if statically link autogen to libopts])
    AG_STATIC_AUTOGEN="-static"
  else
    AG_STATIC_AUTOGEN=''
  fi
  AC_SUBST([AG_STATIC_AUTOGEN])

]) # end of AC_DEFUN of AG_ENABLE_STATIC_AUTOGEN


AC_DEFUN([AG_LINK_SETJMP],[
  AC_MSG_CHECKING([whether setjmp() links okay])
  AC_CACHE_VAL([ag_cv_link_setjmp],[
  AC_LINK_IFELSE(
    AC_LANG_PROGRAM([@%:@include <setjmp.h>],
      [jmp_buf bf;
if (setjmp(bf))
  return 0;
return 0;]),
    [ag_cv_link_setjmp=yes],
    [ag_cv_link_setjmp=no]
  ) # end of AC_LINK_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_link_setjmp
  AC_MSG_RESULT([${ag_cv_link_setjmp}])
  if test "X${ag_cv_link_setjmp}" != Xno
  then
    AC_DEFINE(HAVE_WORKING_SETJMP, 1, @<:@setjmp links okay@:>@)
  fi

]) # end of AC_DEFUN of AG_LINK_SETJMP


AC_DEFUN([AG_COMPILE_FORMAT_ARG],[
  AC_MSG_CHECKING([whether __attribute__((format_arg(n))) works])
  AC_CACHE_VAL([ag_cv_compile_format_arg],[
  AC_COMPILE_IFELSE(
    AC_LANG_PROGRAM([@%:@include <stdio.h>
char const * foo(char const * fmt, int v) __attribute__((format_arg(1)));],
      [  int i = 0;
  printf(foo("argc is %d\n", i), i);]),
    [ag_cv_compile_format_arg=yes],
    [ag_cv_compile_format_arg=no]
  ) # end of AC_COMPILE_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_compile_format_arg
  AC_MSG_RESULT([${ag_cv_compile_format_arg}])
  if test "X${ag_cv_compile_format_arg}" != Xno
  then
    format_arg_expansion="__attribute__((format_arg(_a)))"
  else
    format_arg_expansion=""
  fi
    AC_DEFINE_UNQUOTED([ATTRIBUTE_FORMAT_ARG(_a)],
	[${format_arg_expansion}],
	[format_arg attribute wrapper])

]) # end of AC_DEFUN of AG_COMPILE_FORMAT_ARG


AC_DEFUN([AG_LINK_SIGSETJMP],[
  AC_MSG_CHECKING([whether sigsetjmp() links okay])
  AC_CACHE_VAL([ag_cv_link_sigsetjmp],[
  AC_LINK_IFELSE(
    AC_LANG_PROGRAM([@%:@include <setjmp.h>],
      [sigjmp_buf bf;
if (sigsetjmp(bf,0))
  return 0;
return 0;]),
    [ag_cv_link_sigsetjmp=yes],
    [ag_cv_link_sigsetjmp=no]
  ) # end of AC_LINK_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_link_sigsetjmp
  AC_MSG_RESULT([${ag_cv_link_sigsetjmp}])
  if test "X${ag_cv_link_sigsetjmp}" != Xno
  then
    AC_DEFINE(HAVE_WORKING_SIGSETJMP, 1, @<:@sigsetjmp links okay@:>@)
  fi

]) # end of AC_DEFUN of AG_LINK_SIGSETJMP


AC_DEFUN([AG_WITHLIB_XML2],[
  AC_ARG_WITH([libxml2],
    AS_HELP_STRING([--with-libxml2], [libxml2 installation prefix]),
    [ag_cv_with_libxml2_root=${with_libxml2}],
    AC_CACHE_CHECK([whether with-libxml2 was specified], ag_cv_with_libxml2_root,
      ag_cv_with_libxml2_root=no)
  ) # end of AC_ARG_WITH libxml2

  if test "${with_libxml2+set}" = set && \
     test "X${withval}" = Xno
  then ## disabled by request
    ag_cv_with_libxml2_root=no
    ag_cv_with_libxml2_cflags=no
    ag_cv_with_libxml2_libs=no
  else

  AC_ARG_WITH([libxml2-cflags],
    AS_HELP_STRING([--with-libxml2-cflags], [libxml2 compile flags]),
    [ag_cv_with_libxml2_cflags=${with_libxml2_cflags}],
    AC_CACHE_CHECK([whether with-libxml2-cflags was specified], ag_cv_with_libxml2_cflags,
      ag_cv_with_libxml2_cflags=no)
  ) # end of AC_ARG_WITH libxml2-cflags

  AC_ARG_WITH([libxml2-libs],
    AS_HELP_STRING([--with-libxml2-libs], [libxml2 link command arguments]),
    [ag_cv_with_libxml2_libs=${with_libxml2_libs}],
    AC_CACHE_CHECK([whether with-libxml2-libs was specified], ag_cv_with_libxml2_libs,
      ag_cv_with_libxml2_libs=no)
  ) # end of AC_ARG_WITH libxml2-libs

  case "X${ag_cv_with_libxml2_cflags}" in
  Xyes|Xno|X )
    case "X${ag_cv_with_libxml2_root}" in
    Xyes|Xno|X ) ag_cv_with_libxml2_cflags=no ;;
    * ) ag_cv_with_libxml2_cflags=-I${ag_cv_with_libxml2_root}/include ;;
    esac
  esac
  case "X${ag_cv_with_libxml2_libs}" in
  Xyes|Xno|X )
    case "X${ag_cv_with_libxml2_root}" in
    Xyes|Xno|X ) ag_cv_with_libxml2_libs=no ;;
    * )        ag_cv_with_libxml2_libs="-L${ag_cv_with_libxml2_root}/lib -lxml2" ;;
    esac
  esac
  ag_save_CPPFLAGS="${CPPFLAGS}"
  ag_save_LIBS="${LIBS}"
  case "X${ag_cv_with_libxml2_cflags}" in
  Xyes|Xno|X )
    f=`xml2-config --cflags 2>/dev/null` || f=''
    test -n "${f}" && ag_cv_with_libxml2_cflags="${f}" && \
      AC_MSG_NOTICE([xml2-config used for CFLAGS: $f]) ;;
  esac
  case "X${ag_cv_with_libxml2_libs}" in
  Xyes|Xno|X )
    f=`xml2-config --libs 2>/dev/null` || f=''
    test -n "${f}" && ag_cv_with_libxml2_libs="${f}" && \
      AC_MSG_NOTICE([xml2-config used for LIBS: $f]) ;;
  esac
  case "X${ag_cv_with_libxml2_cflags}" in
  Xyes|Xno|X )
    ag_cv_with_libxml2_cflags="" ;;
  * ) CPPFLAGS="${CPPFLAGS} ${ag_cv_with_libxml2_cflags}" ;;
  esac
  case "X${ag_cv_with_libxml2_libs}" in
  Xyes|Xno|X )
    LIBS="${LIBS} -lxml2"
    ag_cv_with_libxml2_libs="-lxml2" ;;
  * )
    LIBS="${LIBS} ${ag_cv_with_libxml2_libs}" ;;
  esac
  LIBXML2_CFLAGS=""
  LIBXML2_LIBS=""
  AC_MSG_CHECKING([whether libxml2 can be linked with])
  AC_CACHE_VAL([ag_cv_with_libxml2],[
  AC_LINK_IFELSE(
    [AC_LANG_SOURCE([[@%:@include <libxml/parser.h>
@%:@include <libxml/tree.h>

int main () {
xmlDocPtr p = xmlParseFile( "mumble.xml" ); }]])],
    [ag_cv_with_libxml2=yes],
    [ag_cv_with_libxml2=no]) # end of AC_LINK_IFELSE 
  ]) # end of AC_CACHE_VAL for ag_cv_with_libxml2
  fi ## disabled by request
  AC_MSG_RESULT([${ag_cv_with_libxml2}])
    AC_SUBST([LIBXML2_CFLAGS])
    AC_SUBST([LIBXML2_LIBS])
  if test "X${ag_cv_with_libxml2}" != Xno
  then[
      LIBXML2_CFLAGS="${ag_cv_with_libxml2_cflags}"
      LIBXML2_LIBS="${ag_cv_with_libxml2_libs}"]
    CPPFLAGS="@S|@{ag_save_CPPFLAGS}"
    LIBS="@S|@{ag_save_LIBS}"
    
  else
    CPPFLAGS="${ag_save_CPPFLAGS}"
    LIBS="${ag_save_LIBS}"
      LIBXML2_CFLAGS=''
      LIBXML2_LIBS=''
  fi
  AC_SUBST([AG_XML2])
  AM_CONDITIONAL([HAVE_XML_LIB],[test "X${ag_cv_with_libxml2}" != Xno])

]) # end of AC_DEFUN of AG_WITHLIB_XML2


AC_DEFUN([AG_RUN_SOLARIS_SYSINFO],[
  AC_MSG_CHECKING([whether sysinfo(2) is Solaris])
  AC_CACHE_VAL([ag_cv_run_solaris_sysinfo],[
  AC_RUN_IFELSE([@%:@include <sys/systeminfo.h>
int main() { char z@<:@ 256 @:>@;
long sz = sysinfo(SI_SYSNAME, z, sizeof(z));
return (sz > 0) ? 0 : 1; }],
    [ag_cv_run_solaris_sysinfo=yes],[ag_cv_run_solaris_sysinfo=no],[ag_cv_run_solaris_sysinfo=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_run_solaris_sysinfo
  AC_MSG_RESULT([${ag_cv_run_solaris_sysinfo}])
  if test "X${ag_cv_run_solaris_sysinfo}" != Xno
  then
    AC_DEFINE([HAVE_SOLARIS_SYSINFO],[1],
        [Define this if sysinfo(2) is Solaris])
  fi

]) # end of AC_DEFUN of AG_RUN_SOLARIS_SYSINFO


AC_DEFUN([AG_ENABLE_TIMEOUT],[
  AC_ARG_ENABLE([timeout],
    AS_HELP_STRING([--enable-timeout], [specify an autogen timeout]),
    [ag_cv_enable_timeout=${enable_timeout}],
    AC_CACHE_CHECK([whether specify an autogen timeout], ag_cv_enable_timeout,
      ag_cv_enable_timeout=no)
  ) # end of AC_ARG_ENABLE
  if test "X${ag_cv_enable_timeout}" != Xno
  then
    AC_DEFINE([TIMEOUT_ENABLED],[1],
        [Define this if specify an autogen timeout])
    AG_TIMEOUT="@S|@{ag_cv_enable_timeout}"
  else
    AG_TIMEOUT=''
  fi
  AC_SUBST([AG_TIMEOUT])

]) # end of AC_DEFUN of AG_ENABLE_TIMEOUT


AC_DEFUN([AG_RUN_STRCSPN],[
  AC_MSG_CHECKING([whether strcspn matches prototype and works])
  AC_CACHE_VAL([ag_cv_run_strcspn],[
  AC_RUN_IFELSE([@%:@include <string.h>
int main (int argc, char ** argv) {
   char zRej@<:@@:>@ = reject;
   char zAcc@<:@@:>@ = "a-ok-eject";
   return strcspn( zAcc, zRej ) - 5;
}],
    [ag_cv_run_strcspn=yes],[ag_cv_run_strcspn=no],[ag_cv_run_strcspn=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_run_strcspn
  AC_MSG_RESULT([${ag_cv_run_strcspn}])
  if test "X${ag_cv_run_strcspn}" != Xno
  then
    AC_DEFINE([HAVE_STRCSPN],[1],
        [Define this if strcspn matches prototype and works])
  else
    COMPATOBJ="@S|@COMPATOBJ strcspn.lo"
  fi

]) # end of AC_DEFUN of AG_RUN_STRCSPN


AC_DEFUN([AG_RUN_UNAME_SYSCALL],[
  AC_MSG_CHECKING([whether uname(2) is POSIX])
  AC_CACHE_VAL([ag_cv_run_uname_syscall],[
  AC_RUN_IFELSE([@%:@include <sys/utsname.h>
int main() { struct utsname unm;
return uname( &unm ); }],
    [ag_cv_run_uname_syscall=yes],[ag_cv_run_uname_syscall=no],[ag_cv_run_uname_syscall=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for ag_cv_run_uname_syscall
  AC_MSG_RESULT([${ag_cv_run_uname_syscall}])
  if test "X${ag_cv_run_uname_syscall}" != Xno
  then
    AC_DEFINE([HAVE_UNAME_SYSCALL],[1],
        [Define this if uname(2) is POSIX])
  fi

]) # end of AC_DEFUN of AG_RUN_UNAME_SYSCALL


AC_DEFUN([AG_TEST_LDFLAGS],[
  AC_MSG_CHECKING([whether runtime library dirs can be specified])
  AC_CACHE_VAL([ag_cv_test_ldflags],[
    ag_cv_test_ldflags=`exec 2> /dev/null
echo 'int main() { return 0; }' > conftest.$ac_ext
libs="${LIBS}"
LIBS="${LIBS} -Wl,-R/tmp"
if (eval $ac_link) > /dev/null 2>&1
then echo '-Wl,-R${libdir}' ; rm -f conftest* ; exit 0 ; fi
LIBS="${libs} -R/tmp"
if (eval $ac_link) > /dev/null 2>&1
then echo '-R${libdir}' ; rm -f conftest* ; exit 0 ; fi
rm -f conftest* ; exit 1`
    if test $? -ne 0 || test -z "$ag_cv_test_ldflags"
    then ag_cv_test_ldflags=no
    fi
  ]) # end of CACHE_VAL of ag_cv_test_ldflags
  AC_MSG_RESULT([${ag_cv_test_ldflags}])
  if test "X${ag_cv_test_ldflags}" != Xno
  then
    AG_LDFLAGS="@S|@{ag_cv_test_ldflags}"
  else
    AG_LDFLAGS=''
  fi
  AC_SUBST([AG_LDFLAGS])

]) # end of AC_DEFUN of AG_TEST_LDFLAGS


AC_DEFUN([AG_ENABLE_DEBUG],[
  AC_ARG_ENABLE([debug],
    AS_HELP_STRING([--enable-debug], [wanting autogen debugging]),
    [ag_cv_enable_debug=${enable_debug}],
    AC_CACHE_CHECK([whether wanting autogen debugging], ag_cv_enable_debug,
      ag_cv_enable_debug=no)
  ) # end of AC_ARG_ENABLE
  if test "X${ag_cv_enable_debug}" != Xno
  then
    AC_DEFINE([DEBUG_ENABLED],[1],
        [Define this if wanting autogen debugging])
    AC_DEFINE([DEBUG_ENABLED], [1],
          [Define this if debugging is enabled])
    [f=`which dmalloc 2>/dev/null`
    test -n "$f" && LIBS="${LIBS} -ldmalloc"]
  fi

]) # end of AC_DEFUN of AG_ENABLE_DEBUG


AC_DEFUN([AG_WITH_GROUP_PACKAGER],[
  AC_ARG_WITH([packager],
    AS_HELP_STRING([--with-packager], [name of the packager of this software is supplied]),
    [ag_cv_with_group_packager=${with_packager}],
    AC_CACHE_CHECK([whether name of the packager of this software is supplied], ag_cv_with_group_packager,
      ag_cv_with_group_packager=no)
  ) # end of AC_ARG_WITH
  if test "X${ag_cv_with_group_packager}" != Xno
  then
    AC_DEFINE_UNQUOTED([WITH_PACKAGER],["${withval}"],
        [Define this if name of the packager of this software is supplied])
  fi
  AC_ARG_WITH([packager-version],
    AS_HELP_STRING([--with-packager-version], [packager-specific version information is supplied]),
    [ag_cv_with_group_packager_version=${with_packager_version}],
    AC_CACHE_CHECK([whether packager-specific version information is supplied], ag_cv_with_group_packager_version,
      ag_cv_with_group_packager_version=no)
  ) # end of AC_ARG_WITH
  if test "X${ag_cv_with_group_packager_version}" != Xno
  then
    AC_DEFINE_UNQUOTED([WITH_PACKAGER_VERSION],["${withval}"],
        [Define this if packager-specific version information is supplied])
  fi
  AC_ARG_WITH([packager-bug-reports],
    AS_HELP_STRING([--with-packager-bug-reports], [bug reporting URI/e-mail/etc. is supplied]),
    [ag_cv_with_group_packager_bug_reports=${with_packager_bug_reports}],
    AC_CACHE_CHECK([whether bug reporting URI/e-mail/etc. is supplied], ag_cv_with_group_packager_bug_reports,
      ag_cv_with_group_packager_bug_reports=no)
  ) # end of AC_ARG_WITH
  if test "X${ag_cv_with_group_packager_bug_reports}" != Xno
  then
    AC_DEFINE_UNQUOTED([WITH_PACKAGER_BUG_REPORTS],["${withval}"],
        [Define this if bug reporting URI/e-mail/etc. is supplied])
  fi
  if test "X$with_packager" != "X" || \
    test "X$with_packager_version$with_packager_bug_reports" = "X"
  then :
  else

    AC_MSG_ERROR([--with-packager-{bug-reports,version} require --with-packager])
  fi

]) # end of AC_DEFUN of AG_WITH_GROUP_PACKAGER


AC_DEFUN([INVOKE_AG_MACROS],[
  AC_REQUIRE([INVOKE_AG_MACROS_FIRST])
  # Check to see if shell scripts are desired.
  AG_DISABLE_SHELL

  # Check to see if using shell scripts.
  AG_TEST_DO_SHELL

  # Check to see if statically link autogen to libopts.
  AG_ENABLE_STATIC_AUTOGEN

  # Check to see if setjmp() links okay.
  AG_LINK_SETJMP

  # Check to see if __attribute__((format_arg(n))) works.
  AG_COMPILE_FORMAT_ARG

  # Check to see if sigsetjmp() links okay.
  AG_LINK_SIGSETJMP

  # Check to see if a working libxml2 can be found.
  AG_WITHLIB_XML2

  # Check to see if sysinfo(2) is Solaris.
  AG_RUN_SOLARIS_SYSINFO

  # Check to see if specify an autogen timeout.
  AG_ENABLE_TIMEOUT

  # Check to see if strcspn matches prototype and works.
  AG_RUN_STRCSPN

  # Check to see if uname(2) is POSIX.
  AG_RUN_UNAME_SYSCALL

  # Check to see if runtime library dirs can be specified.
  AG_TEST_LDFLAGS

  # Check to see if wanting autogen debugging.
  AG_ENABLE_DEBUG

  # Check to see if name of the packager of this software is supplied.
  AG_WITH_GROUP_PACKAGER

  INVOKE_AG_MACROS_LAST
]) # end AC_DEFUN of INVOKE_AG_MACROS
