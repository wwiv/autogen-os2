#!/bin/bash
# 
# This script derives the list of stdio_unlocked functions defined
# in your current operating system. It derives them by scanning
# /usr/include/stdio.h. If those functions migrate to another file,
# this script will need to be adjusted. It also assumes that both
# the "extern" keyword and the "_unlocked" name appear on the same
# line. It furthermore assumes that the closing parenthesis for the
# declaration appears either on the same line or the one following.

die() {
    echo "FATAL $prog ERROR: $*"
    exit 1
} >&2

init_vars() {
    PS4='+MK-${FUNCNAME:-=}-$LINENO> '
    cd "${progdir}"
    unlocked_list=''
    extern_line='^extern .*_unlocked'
    close_decl='\) *[;_]'
    exec 4< /usr/include/stdio.h

    decl_fmt='
#if HAVE_DECL_%s
#  undef  %s
#  define %s(%s) %s_unlocked (%s)
#else
#  define %s_unlocked(%s) %s (%s)
#endif
'

    m4_file=unlocked-io.m4
    hdr_file=unlocked-io.h
    hdr_guard='UNLOCKED_IO_HEADER_GUARD'
    rm -f ../autoopts/${hdr_file} ${m4_file}
    exec 5> ../autoopts/${hdr_file} 6> ${m4_file}
    sed '1,/### *M4-LEADER/d;/### *END-M4-LEADER/Q' "$program" >&6
    exec 6>&-
    sed '1s@^...@/* @;s/^dnl/ */;s/ *$//;/^$/Q' ${m4_file} >&5
    exec 6>>${m4_file}
    printf " */\n#ifndef $hdr_guard\n#define $hdr_guard 1\n" >&5
}

do_func() {
    local txt="$1"
    local fn=$(sed 's/ *(.*//;s/ *extern  *[^ ]*  *//;s/\*//' <<<"$txt")
    local FN=${fn^^} args=$2
    fn=${fn%_unlocked}

    printf '  AC_CHECK_DECLS_ONCE([%s_unlocked])\n' $fn >&6
    printf "$decl_fmt" "$FN" "$fn" \
           "$fn" "$args" "$fn" "$args" \
           "$fn" "$args" "$fn" "$args" >&5
}

do_stdio() {
    while read -u4 line
    do
        [[ "$line" =~ $extern_line ]] || continue
        [[ "$line" =~ $close_decl  ]] || {
            read -u4 args || die "no close for $line"
            line+="$args"
        }

        ct=$(sed 's/.*( *//;s/ *).*//' <<<"$line")
        if (( ${#ct} > 0 )) && [[ "$ct" != "void" ]]
        then
            ct=$(sed 's/[^,]//g' <<<"$ct")
            ct=$(( (${#ct} * 3) + 2 ))
            args='_w,_x,_y,_z'
            args=${args:$(( ${#args} - ct )):$ct}
        else
            args='' ct=0
        fi
        do_func "$line" "$args"
    done
}

wrapup() {
    echo '])' >&6
    echo "#endif // ${hdr_guard}" >&5
    exec 5>&- 6>&- 4<&-
    cd ..
    git add autoopts/${hdr_file} config/${m4_file}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# MAIN:
#
prog=${0##*/}
progdir=$(dirname $0)
if test -x "$progdir/$prog"
then progdir=$(\cd $progdir && pwd)
else
    progdir=$(command -v $prog)
    progdir=${progdir%/*}
fi
program=${progdir}/${prog}
test -x "$program" || die "cannot locate myself: $prog"

init_vars
do_stdio
wrapup

exit 0

### M4-LEADER
dnl -*- buffer-read-only: t -*- vi: set ro:
dnl
dnl DO NOT EDIT THIS FILE   (unlocked-io.m4)
dnl
dnl It has been derived from /usr/include/stdio.h
dnl using the script config/mk-unlocked-io.sh
dnl
dnl This file is part of AutoOpts, a companion to AutoGen.
dnl AutoOpts is free software.
dnl AutoOpts is Copyright (C) 1992-2020 by Bruce Korb - all rights reserved
dnl
dnl Automated Options (AutoOpts) Copyright (C) 1992-2020 by Bruce Korb
dnl
dnl AutoOpts is available under any one of two licenses.  The license
dnl in use must be one of these two and the choice is under the control
dnl of the user of the license.
dnl
dnl  The GNU Lesser General Public License, version 3 or later
dnl     See the files "COPYING.lgplv3" and "COPYING.gplv3"
dnl
dnl  The Modified Berkeley Software Distribution License
dnl     See the file "COPYING.mbsd"
dnl
dnl These files have the following sha256 sums:
dnl
dnl 8584710e9b04216a394078dc156b781d0b47e1729104d666658aecef8ee32e95  COPYING.gplv3
dnl 4379e7444a0e2ce2b12dd6f5a52a27a4d02d39d247901d3285c88cf0d37f477b  COPYING.lgplv3
dnl 13aa749a5b0a454917a944ed8fffc530b784f5ead522b1aacaf4ec8aa55a6239  COPYING.mbsd

AC_DEFUN([ag_UNLOCKED_IO_CHECK],
[
  AC_DEFINE([USE_UNLOCKED_IO], [1],
    [Define to 1 if you want to use unlocked I/O if available.])
  AC_REQUIRE([gl_USE_SYSTEM_EXTENSIONS])
  ### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  ### EXTRACTED UNLOCKED FUNCTIONS
  ### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### END-M4-LEADER

# Local Variables:
# mode:shell-script
# sh-indentation:4
# sh-basic-offset:4
# indent-tabs-mode: nil
# End:

# mk-unlocked-io.sh ends here
