#! /bin/bash
## run-ag.sh -- shell script for running autogen within autogen build
##
## Author:	    Bruce Korb <bkorb@gnu.org>
##
## This file is part of AutoGen.
## AutoGen Copyright (C) 2018-2020 by Bruce Korb - all rights reserved
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
## ---------------------------------------------------------------------
#
# If the first argument ends with *-dep.mk, then it is expected that this
# script has been called in the Makefile building phase and the target and
# any containing directory must be created. The target is created with a
# very old time stamp.
#
die() {
  echo "FATAL run-ag error: $*"
  exit 1
} 1>&2

find_exe() {
  eval local exe=\${$1}
  test -x "$exe" && return 0
  case "$2" in
    autogen ) exe=`cd ../agen5   > /dev/null ; pwd`/$2 ;;
    columns ) exe=`cd ../columns > /dev/null ; pwd`/$2 ;;

    * ) echo "wrong executable: '$2'" >&2
        exit 1 ;;
  esac
  test -x "$exe" || exe=`command -v $2`
  test -x "$exe" || die "cannot locate $2"
  eval $1=$exe
  return 0
}

open_log_file() {
    case "$-" in
        *x* )  VERBOSE=true ;;
        * )    case "X$VERBOSE" in
                   Xt* | X1* ) VERBOSE=true ;;
                   * ) VERBOSE=false ;;
               esac
               ;;
    esac

  test "X$VERBOSE" = X1 && {
    PS4='+run-ag-$LINENO> '
    set -x
    : in $PWD
  }

  if test -z "${TEMP_DIR}"
  then
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/run-ag-XXXXXXXX")
  fi

  local tag=${1#-MF} ; tag=${tag%-dep.mk}
  STAMP_TEMP_DIR=${TEMP_DIR}/ag-stamp-${tag##*/}
  mkdir -p "${STAMP_TEMP_DIR}" || die "cannot mkdir ${STAMP_TEMP_DIR}"
  exec 9>&2 2>> ${STAMP_TEMP_DIR}/mk-stamps.log
}

set_exe_vars() {
  test -x "$AGexe" || find_exe AGexe autogen
  test -x "CLexe"  || find_exe CLexe columns
  PATH=`dirname "$CLexe"`:"$PATH"
  L_opt="-L'${top_srcdir}/autoopts/tpl'"
  test "X${top_srcdir}" = "X${top_builddir}" || \
    L_opt="$L_opt -L'${top_builddir}/autoopts/tpl'"
  $VERBOSE && \
    L_opt="${L_opt} --trace=every --trace-out='${STAMP_TEMP_DIR}/ag-trace.txt'"
}

open_log_file "$1"
set_exe_vars

case "$1" in
  -MF*-dep.mk ) : ;;

  *-dep.mk )
    dir=`dirname "$1"`
    test -d "$dir" || \
      mkdir -p "$dir" || \
      die "cannot mkdir '$dir'"
    touch -t 197001020000 "$1"
    exit $?
    ;;

  * ) die "not a dependency file name: '$1'" ;;
esac

eval "${AGexe}" $L_opt '"$@"'
exit $?

## Local Variables:
## mode: shell-script
## indent-tabs-mode: nil
## sh-indentation: 4
## sh-basic-offset: 4
## End:

# END OF add-on/build-aux/mk-ag-dep.sh
