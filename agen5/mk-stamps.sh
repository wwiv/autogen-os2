#! /bin/echo This_file_must_be_sourced,_not_executed
#
# agen5/mk-stamps.sh
#
##  This file is part of AutoGen.
##  AutoGen Copyright (C) 1992-2020 by Bruce Korb - all rights reserved
##
## AutoGen is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by the
## Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## AutoGen is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  If not, see <http://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------
#
#  This script rebuilds sources not kept in the GIT repository.
#  These files are distributed, so it is not necessary to invoke
#  AutoGen before building AutoGen.

#  "make" will invoke this file with the name of the desired output
#  as an argument.  We do this here rather than in the make file
#  because some of the rules are complex and we don't want to
#  deal with the dual update problem.

init_stamps() {
    test -z "$TEMP_DIR" && {
        TEMP_DIR=${TMPDIR:-/tmp}/mk-stamp-????????.tdir
        rm -rf ${TEMP_DIR}
        TEMP_DIR=$(mktemp -d ${TEMP_DIR//\?/X})
        export TEMP_DIR
    }
    exec 9>&2 2>> ${TEMP_DIR}/mk-stamps.log
    stop_tracing=:
    if (shopt -qo xtrace)
    then
        shopt -qo xtrace || stop_tracing="set +x"
    else
        shopt() {
            local on=$(set -o|sed -n "s/^$2 *//p")
            test $on = on
        }

        shopt -qo xtrace || stop_tracing="set +x"
    fi
    set -x

    if test -z "$mainpid"
    then
        test -z "${top_srcdir}" && top_srcdir=`
        \\cd \`dirname $0\`
        \\cd ..
        pwd`

        test -z "${top_builddir}" && top_builddir=`
        \\cd ..
        pwd`
        export top_srcdir top_builddir
        . ${top_srcdir}/config/bootstrap.shlib

        test -f ${top_builddir}/config/shdefs || {

            test -f ${top_builddir:-..}/config/mk-shdefs || {
                echo "mk-shdefs has not beein configured in ${top_builddir:-$PWD/..}"
                exit 1
            } 1>&2

            ( set -e
              cd ${top_builddir:-..}
              make shdefs
            ) || exit 1

            . ${top_builddir:-..}/config/shdefs
        }
    fi

    set_defaults
}

set_defaults()
{
    local AGnam=autogen
    local GDnam=getdefs
    local CLnam=columns
    local AGdir=agen5
    local GDdir=getdefs
    local CLdir=columns
    local f n b v

    for v in AG GD CL
    do
        eval f=\${${v}exe}
        eval n=\${${v}nam}
        eval b=${top_builddir}/\${${v}dir}/\${${v}nam}
        if test -x "$b"
        then
            f=$b

        elif ! test -x "$f"
        then
            f=`command -v $n`
            test -x "${f}" || die "$n is required"
        fi
        eval $v=$f
        export $v
    done

    if ! test -x ${AGexe}
    then
        run_ag() {
            touch stamp-${1}
            touch ${target}
        }
    fi

    #  Make sure we have a default for top build and source.
    #  Some of the templates need this information.
    #
    local verdata=`${EGREP} '^AG_' ${top_srcdir}/VERSION | \
       sed 's,^\(AG[^=]*\)\(.*\),\1\2 export \1,'`
    eval "${verdata}"

    #  disable any $HOME defaults
    #
    HOME=/dev/null
    SHELL=${POSIX_SHELL-/bin/sh}

    ${VERBOSE:-false} && set -x || :
    #  Ensure complete success or a noticable failure
    #
    set -e
}

# # # # # # # # # # # # # # # # # # #
#
# Make the definition parser
#
make_parse()
{
    local opts=''

    test ${#DEBUG_ENABLED} -gt 0 && \
        opts=-DDEBUG_ENABLED

    run_ag parse ${opts} defParse.def
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Make the pseudo-macro processing Finite State Machine
#
make_cgi()
{
    run_ag cgi cgi.def
    echo EXIT $? 1>&2
}

make_pseudo()
{
    run_ag pseudo pseudo.def
    rm -f .fsm.*
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Make the expression processing code
#
# NOTE: the expr.test test extracts this function!!
#
make_exprini()
{
    #  funcCase.c must be first file in list.
    #  It has the exparg attribute names.
    #
    exec 3> expr.cfg
    cat >&3 <<- _EOConfig_
	defs-to-get gfunc
	template    snarf.tpl
	srcfile
	assign      two-phase   = yes
	assign      group       = ag
	assign      addtogroup  = "autogen"
	output      expr.def
	subblock    exparg      = arg_name,arg_desc,arg_optional,arg_list
	_EOConfig_

    test ${#DEBUG_ENABLED} -gt 0 && \
        printf '%-15s %s\n' assign 'debug-enabled = true' >&3

    for f in func*.c exp*.c agShell.c
    do echo input ${f} ; done >&3
    exec 3>&-

    echo ${GDexe} load=expr.cfg
    set +e
    {
        SHELL=sh ${GDexe} load=expr.cfg 2>&1
    } | ${GREP} -v 'no copies of pattern' >&2
    set -e
    run_ag exprini expr.def
    echo EXIT $? 1>&2
    rm -f expr.cfg
}

# # # # # # # # # # # # # # # # # # #
#
#  Make the directive.h header
#
make_directive()
{
    : ${AG_TIMEOUT=10}
    to=--timeout=`expr $AG_TIMEOUT '*' 3`
    dlist=$(
        sed -n '/^doDir_invalid/d
		/^doDir_[a-z]*(/{;s@(.*@@;s@^doDir_@@;p;}' defDirect.c | \
            sort)
    test -f directive.def && rm -f directive.def
    {
      cat <<- _EOF_
	AutoGen Definitions str2enum;
	prefix = dir;
	type   = '';
	length = '';
	addtogroup = 'autogen';

	dispatch = {
	   d-nam = 'doDir_%s';
	   d-ret = 'char *';
	   d-arg = 'char * scan_next';
	};
	_EOF_
      echo cmd = $(echo $dlist | sed 's/ /, /g')\;
    } > directive.def

    run_ag dirtv directive.def
    echo EXIT $? 1>&2
    echo directive.cfg >&5
}

# # # # # # # # # # # # # # # # # # #
#
# Construct the texinfo doc
#
make_texi()
{
    : ${AG_TIMEOUT=10}
    eopt="-Tagtexi-cmd.tpl -DLEVEL=chapter -binvoke-autogen"
    eopt=${eopt}\ --timeout=`expr $AG_TIMEOUT '*' 3`
    run_ag texi ${eopt} ${srcdir}/opts.def
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Construct the ag-text strings
#
make_opts()
{
    run_ag opts ${srcdir}/opts.def
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Construct the ag-text strings
#
make_ag_text()
{
    run_ag ag_text ${srcdir}/ag-text.def
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Construct the man page
#
make_fmem()
{
    ${GDexe} templ=agman3.tpl linenum output=fmemopen.def ${srcdir}/fmemopen.c
    run_ag fmem fmemopen.def
    echo EXIT $? 1>&2
}

make_man()
{
    run_ag man -Tagman-cmd -DMAN_SECTION=1 ${srcdir}/opts.def
    echo EXIT $? 1>&2
}

# # # # # # # # # # # # # # # # # # #
#
# Construct the function tables
#
make_func()
{
    local files=`${GREP} -l '/\*=macfunc' *.c`
    local opts='srcfile linenum defs=macfunc listattr=alias'

    ${GDexe} output=functions.def template=functions.tpl ${opts} ${files}
    run_ag func functions.def
    echo EXIT $? 1>&2
}

# make_proto() -- comes from bootstrap.shlib

dispatch()
{
    test -z "$DEPDIR" && test -d .deps && DEPDIR=.deps
    if test -d "${DEPDIR}"
    then DEPFILE=./${DEPDIR}/stamp-${1}.d
    else DEPFILE=''
    fi
    eval make_${1} 2> ${TEMP_DIR}/make-$1.log '&'
    pid_list+=" $!"
    log_file_list+=" ${TEMP_DIR}/make-$1.log"
}

conf_time_make_dep_file() {
    local d=`dirname "$1"`
    test -d "$d" || mkdir -p "$d" || exit 1
    touch -t 197001020000 "$1"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#  M A I N
#
export PS4='+stmp=${FUNCNAME:-=}-$LINENO> '
init_stamps
rmlist=${TEMP_DIR}/rm-list.txt
exec 5> $rmlist
pid_list=''
log_file_list=''

#  FOR each output target,
#   DO the appropriate rule...
#
for t
do
    echo Re-building "$t"
    case "$t" in
    stamp-* )
        dispatch ${t#stamp-} ;;

    defParse-fsm.c | defParse-fsm.h )
        dispatch parse ;;

    opts.[ch] )
        dispatch opts ;;

    expr.h | expr.def | expr.ini )
        dispatch exprini ;;

    directive.h )
        dispatch directive ;;

    autogen.texi | autogen.menu )
        dispatch texi ;;

    autogen.1 )
        dispatch man ;;

    fmemopen.3 )
        dispatch fmem ;;

    proto.h )
        dispatch proto ;;

    functions.h )
        dispatch func ;;

    *dep-*.mk )
        conf_time_make_dep_file "$t"
        ;;

    *)  if test `type -t make_$t` = function 2>/dev/null 1>&2
        then dispatch $t
        else die "Don't know how to make $t"
        fi ;;
    esac
done

test ${#pid_list} -gt 1 && wait $pid_list
test -z "$log_file_list" || {
    echo =============================
    head -n 99999 $log_file_list
    echo =============================
} >&2
rm -rf ${TEMP_DIR}/.ag-?????? `cat $rmlist` $log_file_list
$stop_tracing
exec 2>&9 9>&-
trap '' 0

# Local Variables:
# mode:shell-script
# sh-indentation:4
# sh-basic-offset:4
# indent-tabs-mode: nil
# End:

# end of agen5/mk-stamps.sh
