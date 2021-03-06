
dnl do always before generated macros:
dnl
AC_DEFUN([INVOKE_LIBOPTS_MACROS_FIRST],[
  AC_REQUIRE([AC_HEADER_STDC])
  AC_HEADER_DIRENT

  # =================
  # AC_CHECK_HEADERS
  # =================
  AC_CHECK_HEADERS([ \
      sys/mman.h    sys/param.h   sys/poll.h    sys/procset.h \
      sys/select.h  sys/socket.h  sys/stropts.h sys/time.h \
      sys/un.h      sys/wait.h    dlfcn.h       errno.h \
      fcntl.h       libgen.h      libintl.h     memory.h \
      netinet/in.h  setjmp.h      stdbool.h     sysexits.h \
      unistd.h      utime.h])

  AC_CHECK_HEADERS([stdarg.h     varargs.h],
      [lo_have_arg_hdr=true;break],
      [lo_have_arg_hdr=false])

  AC_CHECK_HEADERS([string.h     strings.h],
      [lo_have_str_hdr=true;break],
      [lo_have_str_hdr=false])

  AC_CHECK_HEADERS([limits.h     sys/limits.h  values.h],
      [lo_have_lim_hdr=true;break],
      [lo_have_lim_hdr=false])

  AC_CHECK_HEADERS([inttypes.h   stdint.h],
      [lo_have_typ_hdr=true;break],
      [lo_have_typ_hdr=false])
  gl_HEADER_ERRNO_H
  gl_HEADER_TIME_H
  gl_CHECK_TYPE_STRUCT_TIMESPEC
  gl_FUNC_NANOSLEEP
  gl_STDDEF_H
  gl_STDNORETURN_H
  gl_TIMESPEC

  # ----------------------------------------------------------------------
  # check for various programs used during the build.
  # On OS/X, "wchar.h" needs "runetype.h" to work properly.
  # ----------------------------------------------------------------------
  AC_CHECK_HEADERS([runetype.h wchar.h], [], [],[
  AC_INCLUDES_DEFAULT
  #if HAVE_RUNETYPE_H
  # include <runetype.h>
  #endif
  ])

  AC_ARG_ENABLE([nls],
    AS_HELP_STRING([--disable-nls],[disable nls support in libopts]))
  AS_IF([test "x$enable_nls" != "xno" && \
    test "X${ac_cv_header_libintl_h}" = Xyes], [
    AC_DEFINE([ENABLE_NLS],[1],[nls support in libopts])])

  # --------------------------------------------
  # Verify certain entries from AC_CHECK_HEADERS
  # --------------------------------------------
  [${lo_have_arg_hdr} || \
    ]AC_MSG_ERROR([you must have stdarg.h or varargs.h on your system])[

  ${lo_have_str_hdr} || \
    ]AC_MSG_ERROR([you must have string.h or strings.h on your system])[

  ${lo_have_lim_hdr} || \
    ]AC_MSG_ERROR(
      [you must have one of limits.h, sys/limits.h or values.h])[

  ${lo_have_typ_hdr} || \
    ]AC_MSG_ERROR([you must have inttypes.h or stdint.h on your system])[

  for f in sys_types sys_param sys_stat string errno stdlib memory setjmp
  do eval as_ac_var=\${ac_cv_header_${f}_h}
     test "X${as_ac_var}" = Xyes || {
       ]AC_MSG_ERROR([you must have ${f}.h on your system])[
     }
  done
  test "X${ac_cv_header_inttypes_h-no}" = Xyes || \
    echo '#include <stdint.h>' > inttypes.h]

  # ----------------------------------------------------------------------
  # Checks for typedefs
  # ----------------------------------------------------------------------
  AC_CHECK_TYPES(wchar_t)
  AC_CHECK_TYPES(wint_t, [], [], [
    AC_INCLUDES_DEFAULT
    #if HAVE_RUNETYPE_H
    # include <runetype.h>
    #endif
    #if HAVE_WCHAR_H
    # include <wchar.h>
    #endif
  ])
  AC_CHECK_TYPES([int8_t, uint8_t, int16_t, uint16_t, int32_t, uint32_t,
  intptr_t, uintptr_t, uint_t, pid_t, size_t, ptrdiff_t])
  AC_CHECK_SIZEOF(char *, 8)
  AC_CHECK_SIZEOF(int,    4)
  AC_CHECK_SIZEOF(long,   8)
  AC_CHECK_SIZEOF(short,  2)

  # ------------
  # AC_CHECK_LIB
  # ------------
  AC_CHECK_LIB(gen, pathfind)
  AC_CHECK_LIB(intl,gettext)
  AC_FUNC_VPRINTF
  AC_FUNC_FORK
  AC_CHECK_FUNCS([mmap canonicalize_file_name snprintf strchr \
                 strrchr strsignal fchmod fstat chmod])
  AC_PROG_SED
  [while :
  do
      test -x "$POSIX_SHELL" && break
      POSIX_SHELL=`which bash`
      test -x "$POSIX_SHELL" && break
      POSIX_SHELL=`which dash`
      test -x "$POSIX_SHELL" && break
      POSIX_SHELL=/usr/xpg4/bin/sh
      test -x "$POSIX_SHELL" && break
      POSIX_SHELL=`/bin/sh -c '
          exec 2>/dev/null
          if ! true ; then exit 1 ; fi
          echo /bin/sh'`
      test -x "$POSIX_SHELL" && break
      ]AC_MSG_ERROR([cannot locate a working POSIX shell])[
  done]
  AC_DEFINE_UNQUOTED([POSIX_SHELL], ["${POSIX_SHELL}"],
           [define to a working POSIX compliant shell])
  AC_SUBST([POSIX_SHELL])
])

dnl
dnl @synopsis  INVOKE_LIBOPTS_MACROS
dnl
dnl  This macro will invoke the AutoConf macros specified in libopts.def
dnl  that have not been disabled with "omit-invocation".
dnl
AC_DEFUN([LIBOPTS_WITH_REGEX_HEADER],[
  AC_ARG_WITH([regex-header],
    AS_HELP_STRING([--with-regex-header], [a reg expr header is specified]),
    [libopts_cv_with_regex_header=${with_regex_header}],
    AC_CACHE_CHECK([whether a reg expr header is specified], libopts_cv_with_regex_header,
      libopts_cv_with_regex_header=no)
  ) # end of AC_ARG_WITH
  if test "X${libopts_cv_with_regex_header}" != Xno
  then
    AC_DEFINE_UNQUOTED([REGEX_HEADER],[<${libopts_cv_with_regex_header}>])
  else
    AC_DEFINE([REGEX_HEADER],[<regex.h>],[name of regex header file])
  fi

]) # end of AC_DEFUN of LIBOPTS_WITH_REGEX_HEADER


AC_DEFUN([LIBOPTS_WITHLIB_REGEX],[
  AC_ARG_WITH([libregex],
    AS_HELP_STRING([--with-libregex], [libregex installation prefix]),
    [libopts_cv_with_libregex_root=${with_libregex}],
    AC_CACHE_CHECK([whether with-libregex was specified], libopts_cv_with_libregex_root,
      libopts_cv_with_libregex_root=no)
  ) # end of AC_ARG_WITH libregex

  if test "${with_libregex+set}" = set && \
     test "X${withval}" = Xno
  then ## disabled by request
    libopts_cv_with_libregex_root=no
    libopts_cv_with_libregex_cflags=no
    libopts_cv_with_libregex_libs=no
  else

  AC_ARG_WITH([libregex-cflags],
    AS_HELP_STRING([--with-libregex-cflags], [libregex compile flags]),
    [libopts_cv_with_libregex_cflags=${with_libregex_cflags}],
    AC_CACHE_CHECK([whether with-libregex-cflags was specified], libopts_cv_with_libregex_cflags,
      libopts_cv_with_libregex_cflags=no)
  ) # end of AC_ARG_WITH libregex-cflags

  AC_ARG_WITH([libregex-libs],
    AS_HELP_STRING([--with-libregex-libs], [libregex link command arguments]),
    [libopts_cv_with_libregex_libs=${with_libregex_libs}],
    AC_CACHE_CHECK([whether with-libregex-libs was specified], libopts_cv_with_libregex_libs,
      libopts_cv_with_libregex_libs=no)
  ) # end of AC_ARG_WITH libregex-libs

  case "X${libopts_cv_with_libregex_cflags}" in
  Xyes|Xno|X )
    case "X${libopts_cv_with_libregex_root}" in
    Xyes|Xno|X ) libopts_cv_with_libregex_cflags=no ;;
    * ) libopts_cv_with_libregex_cflags=-I${libopts_cv_with_libregex_root}/include ;;
    esac
  esac
  case "X${libopts_cv_with_libregex_libs}" in
  Xyes|Xno|X )
    case "X${libopts_cv_with_libregex_root}" in
    Xyes|Xno|X ) libopts_cv_with_libregex_libs=no ;;
    * )        libopts_cv_with_libregex_libs="-L${libopts_cv_with_libregex_root}/lib -lregex" ;;
    esac
  esac
  libopts_save_CPPFLAGS="${CPPFLAGS}"
  libopts_save_LIBS="${LIBS}"
  case "X${libopts_cv_with_libregex_cflags}" in
  Xyes|Xno|X )
    libopts_cv_with_libregex_cflags="" ;;
  * ) CPPFLAGS="${CPPFLAGS} ${libopts_cv_with_libregex_cflags}" ;;
  esac
  case "X${libopts_cv_with_libregex_libs}" in
  Xyes|Xno|X )
    libopts_cv_with_libregex_libs="" ;;
  * )
    LIBS="${LIBS} ${libopts_cv_with_libregex_libs}" ;;
  esac
  LIBREGEX_CFLAGS=""
  LIBREGEX_LIBS=""
  AC_MSG_CHECKING([whether libregex functions properly])
  AC_CACHE_VAL([libopts_cv_with_libregex],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <stdio.h>
@%:@include <stdlib.h>
@%:@include <sys/types.h>
@%:@include REGEX_HEADER
static regex_t re;
void comp_re(char const * pzPat) {
  int res = regcomp( &re, pzPat, REG_EXTENDED|REG_ICASE|REG_NEWLINE );
  if (res == 0) return;
  exit( res ); }
int main() {
  regmatch_t m@<:@2@:>@;
  comp_re( "^.*\@S|@"   );
  comp_re( "()|no.*" );
  comp_re( "."       );
  if (regexec( &re, "X", 2, m, 0 ) != 0)  return 1;
  if ((m@<:@0@:>@.rm_so != 0) || (m@<:@0@:>@.rm_eo != 1)) {
    fputs( "error: regex -->.<-- did not match\n", stderr );
    return 1;
  }
  return 0; }] )],
    [libopts_cv_with_libregex=yes], [libopts_cv_with_libregex=no],
    [libopts_cv_with_libregex=no]) # end of AC_RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_with_libregex
  fi ## disabled by request
  AC_MSG_RESULT([${libopts_cv_with_libregex}])
  if test "X${libopts_cv_with_libregex}" != Xno
  then
    AC_DEFINE([WITH_LIBREGEX],[1],
        [Define this if a working libregex can be found])
  else
    CPPFLAGS="${libopts_save_CPPFLAGS}"
    LIBS="${libopts_save_LIBS}"
    libopts_cv_with_libregex_root=no
libopts_cv_with_libregex_cflags=no
libopts_cv_with_libregex_libs=no
libopts_cv_with_libregex=no
  fi

]) # end of AC_DEFUN of LIBOPTS_WITHLIB_REGEX


AC_DEFUN([LIBOPTS_RUN_PATHFIND],[
  AC_MSG_CHECKING([whether pathfind(3) works])
  AC_CACHE_VAL([libopts_cv_run_pathfind],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <string.h>
@%:@include <stdlib.h>
int main (int argc, char ** argv) {
   char * pz = pathfind( getenv( "PATH" ), "sh", "x" );
   return (pz == 0) ? 1 : 0;
}] )],
    [libopts_cv_run_pathfind=yes],[libopts_cv_run_pathfind=no],[libopts_cv_run_pathfind=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_run_pathfind
  AC_MSG_RESULT([${libopts_cv_run_pathfind}])
  if test "X${libopts_cv_run_pathfind}" != Xno
  then
    AC_DEFINE([HAVE_PATHFIND],[1],
        [Define this if pathfind(3) works])
  fi

]) # end of AC_DEFUN of LIBOPTS_RUN_PATHFIND


AC_DEFUN([LIBOPTS_TEST_DEV_ZERO],[
  AC_MSG_CHECKING([whether /dev/zero is readable device])
  AC_CACHE_VAL([libopts_cv_test_dev_zero],[
    libopts_cv_test_dev_zero=`exec 2> /dev/null
dzero=\`ls -lL /dev/zero | egrep ^c......r\`
test -z "${dzero}" && exit 1
echo ${dzero}`
    if test $? -ne 0 || test -z "$libopts_cv_test_dev_zero"
    then libopts_cv_test_dev_zero=no
    fi
  ]) # end of CACHE_VAL of libopts_cv_test_dev_zero
  AC_MSG_RESULT([${libopts_cv_test_dev_zero}])
  if test "X${libopts_cv_test_dev_zero}" != Xno
  then
    AC_DEFINE([HAVE_DEV_ZERO],[1],
        [Define this if /dev/zero is readable device])
  fi

]) # end of AC_DEFUN of LIBOPTS_TEST_DEV_ZERO


AC_DEFUN([LIBOPTS_RUN_REALPATH],[
  AC_MSG_CHECKING([whether we have a functional realpath(3C)])
  AC_CACHE_VAL([libopts_cv_run_realpath],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <limits.h>
@%:@include <stdlib.h>
int main (int argc, char ** argv) {
@%:@ifndef PATH_MAX
choke me!!
@%:@else
   char zPath@<:@PATH_MAX+1@:>@;
@%:@endif
   char *pz = realpath(argv@<:@0@:>@, zPath);
   return (pz == zPath) ? 0 : 1;
}] )],
    [libopts_cv_run_realpath=yes],[libopts_cv_run_realpath=no],[libopts_cv_run_realpath=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_run_realpath
  AC_MSG_RESULT([${libopts_cv_run_realpath}])
  if test "X${libopts_cv_run_realpath}" != Xno
  then
    AC_DEFINE([HAVE_REALPATH],[1],
        [Define this if we have a functional realpath(3C)])
  fi

]) # end of AC_DEFUN of LIBOPTS_RUN_REALPATH


AC_DEFUN([LIBOPTS_RUN_STRFTIME],[
  AC_MSG_CHECKING([whether strftime() works])
  AC_CACHE_VAL([libopts_cv_run_strftime],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <time.h>
@%:@include <string.h>
char t_buf@<:@ 64 @:>@;
int main() {
  static char const z@<:@@:>@ = "Thursday Aug 28 240";
  struct tm tm;
  tm.tm_sec   = 36;  /* seconds after the minute @<:@0, 61@:>@  */
  tm.tm_min   = 44;  /* minutes after the hour @<:@0, 59@:>@ */
  tm.tm_hour  = 12;  /* hour since midnight @<:@0, 23@:>@ */
  tm.tm_mday  = 28;  /* day of the month @<:@1, 31@:>@ */
  tm.tm_mon   =  7;  /* months since January @<:@0, 11@:>@ */
  tm.tm_year  = 86;  /* years since 1900 */
  tm.tm_wday  =  4;  /* days since Sunday @<:@0, 6@:>@ */
  tm.tm_yday  = 239; /* days since January 1 @<:@0, 365@:>@ */
  tm.tm_isdst =  1;  /* flag for daylight savings time */
  strftime( t_buf, sizeof( t_buf ), "%A %b %d %j", &tm );
  return (strcmp( t_buf, z ) != 0); }] )],
    [libopts_cv_run_strftime=yes],[libopts_cv_run_strftime=no],[libopts_cv_run_strftime=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_run_strftime
  AC_MSG_RESULT([${libopts_cv_run_strftime}])
  if test "X${libopts_cv_run_strftime}" != Xno
  then
    AC_DEFINE([HAVE_STRFTIME],[1],
        [Define this if strftime() works])
  fi

]) # end of AC_DEFUN of LIBOPTS_RUN_STRFTIME


AC_DEFUN([LIBOPTS_RUN_FOPEN_BINARY],[
  AC_MSG_CHECKING([whether fopen accepts "b" mode])
  AC_CACHE_VAL([libopts_cv_run_fopen_binary],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <stdio.h>
int main (int argc, char ** argv) {
FILE * fp = fopen("conftest.@S|@ac_ext", "rb");
return (fp == NULL) ? 1 : fclose(fp); }] )],
    [libopts_cv_run_fopen_binary=yes],[libopts_cv_run_fopen_binary=no],[libopts_cv_run_fopen_binary=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_run_fopen_binary
  AC_MSG_RESULT([${libopts_cv_run_fopen_binary}])
  if test "X${libopts_cv_run_fopen_binary}" != Xno
  then
    AC_DEFINE([FOPEN_BINARY_FLAG],"b",
        [fopen(3) accepts a 'b' in the mode flag])
  else
    AC_DEFINE([FOPEN_BINARY_FLAG],"",
        [fopen(3) accepts a 'b' in the mode flag])
  fi

]) # end of AC_DEFUN of LIBOPTS_RUN_FOPEN_BINARY


AC_DEFUN([LIBOPTS_RUN_FOPEN_TEXT],[
  AC_MSG_CHECKING([whether fopen accepts "t" mode])
  AC_CACHE_VAL([libopts_cv_run_fopen_text],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([@%:@include <stdio.h>
int main (int argc, char ** argv) {
FILE * fp = fopen("conftest.@S|@ac_ext", "rt");
return (fp == NULL) ? 1 : fclose(fp); }] )],
    [libopts_cv_run_fopen_text=yes],[libopts_cv_run_fopen_text=no],[libopts_cv_run_fopen_text=no]
  ) # end of RUN_IFELSE
  ]) # end of AC_CACHE_VAL for libopts_cv_run_fopen_text
  AC_MSG_RESULT([${libopts_cv_run_fopen_text}])
  if test "X${libopts_cv_run_fopen_text}" != Xno
  then
    AC_DEFINE([FOPEN_TEXT_FLAG],"t",
        [fopen(3) accepts a 't' in the mode flag])
  else
    AC_DEFINE([FOPEN_TEXT_FLAG],"",
        [fopen(3) accepts a 't' in the mode flag])
  fi

]) # end of AC_DEFUN of LIBOPTS_RUN_FOPEN_TEXT


AC_DEFUN([LIBOPTS_DISABLE_OPTIONAL_ARGS],[
  AC_ARG_ENABLE([optional-args],
    AS_HELP_STRING([--disable-optional-args], [not wanting optional option args]),
    [libopts_cv_enable_optional_args=${enable_optional_args}],
    AC_CACHE_CHECK([whether not wanting optional option args], libopts_cv_enable_optional_args,
      libopts_cv_enable_optional_args=yes)
  ) # end of AC_ARG_ENABLE
  if test "X${libopts_cv_enable_optional_args}" = Xno
  then
    AC_DEFINE([NO_OPTIONAL_OPT_ARGS], [1],
          [Define this if optional arguments are disallowed])
  fi

]) # end of AC_DEFUN of LIBOPTS_DISABLE_OPTIONAL_ARGS


AC_DEFUN([INVOKE_LIBOPTS_MACROS],[
  AC_REQUIRE([INVOKE_LIBOPTS_MACROS_FIRST])
  # Check to see if a reg expr header is specified.
  LIBOPTS_WITH_REGEX_HEADER

  # Check to see if a working libregex can be found.
  LIBOPTS_WITHLIB_REGEX

  # Check to see if pathfind(3) works.
  LIBOPTS_RUN_PATHFIND

  # Check to see if /dev/zero is readable device.
  LIBOPTS_TEST_DEV_ZERO

  # Check to see if we have a functional realpath(3C).
  LIBOPTS_RUN_REALPATH

  # Check to see if strftime() works.
  LIBOPTS_RUN_STRFTIME

  # Check to see if fopen accepts "b" mode.
  LIBOPTS_RUN_FOPEN_BINARY

  # Check to see if fopen accepts "t" mode.
  LIBOPTS_RUN_FOPEN_TEXT

  # Check to see if not wanting optional option args.
  LIBOPTS_DISABLE_OPTIONAL_ARGS

]) # end AC_DEFUN of INVOKE_LIBOPTS_MACROS
