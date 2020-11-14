#! /bin/echo thils-file-should-not-be-directly-executed
##  -*- Mode: shell-script -*-
##
## mklibsrc.sh --   make the libopts tear-off library source tarball
##
## This file is called via $(POSIX_SHELL) in autoopts/Makefile
##
##  This file is part of AutoGen.
##  AutoGen Copyright (C) 1992-2020 by Bruce Korb - all rights reserved
##
##  AutoGen is free software: you can redistribute it and/or modify it
##  under the terms of the GNU General Public License as published by the
##  Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  AutoGen is distributed in the hope that it will be useful, but
##  WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##  See the GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License along
##  with this program.  If not, see <http://www.gnu.org/licenses/>.

die() {
    echo "$prog fatal error:  $*"
    kill -TERM $progpid
    exit 1
} >&2

init() {
    test ${#CDPATH} -gt 0 && CDPATH=''
    test -d "${top_builddir}" && test -d "${top_srcdir}" || {
            echo top_builddir and top_srcdir must specify a directory >&2
            exit 1
        }
    top_builddir=`cd $top_builddir ; pwd`
    top_srcdir=`cd $top_srcdir ; pwd`

    test -x ${top_builddir}/agen5/autogen   || exit 0
    test -x ${top_builddir}/columns/columns || exit 0

    ao_rev=${AO_CURRENT}.${AO_REVISION}.${AO_AGE}
    tag=libopts-${ao_rev}

    cd ${top_builddir}/pkg
    [ ! -d ${tag} ] || rm -rf ${tag}
    mkdir ${tag} ${tag}/compat ${tag}/autoopts ${tag}/m4
    tagd=${top_builddir}/pkg/${tag}
    prog=${0##*/}
}

try_copy_file() {
    local file=$1

    for td in ${top_srcdir} ${top_builddir}
    do
        for d in . autoopts
        do
            test -f "$td/$d/$file" && {
                cp -f "$td/$d/$file" "${tagd}/$file"
                return 0
            }
        done
    done

    die "could not locate ${file} in ${top_srcdir} or" \
        "${top_builddir} to copy into tarball"
}

copy_sources() {
    cd ${top_builddir}/autoopts
    files='libopts.c gettext.h parse-duration.c parse-duration.h
	stdnoreturn.in.h _Noreturn.h '$(
        grep -F '#include' libopts.c | \
            sed -e 's,"$,,;s,#.*",,' )

    for f in ${files} intprops.h verify.h
    do
        try_copy_file $f
    done

    cp -f ${top_srcdir}/pkg/libopts/COPYING.* ${tagd}/.

    cd ${top_srcdir}/compat
    cp windows-config.h compat.h pathfind.c snprintf.c strchr.c \
       ${tagd}/compat/. || \
        die "compat sources could not be found"

    cd ${tagd}
    cp ${top_srcdir}/config/*.m4 m4/.
    rm -f m4/unlocked-io*
    chmod u+w m4/libopts.m4
    cat ${top_srcdir}/pkg/libopts/libopts-add.m4 >> m4/libopts.m4
    rm -f Makefile.am config.h
    sed s,'\${tag}',"${tag}",g ${top_srcdir}/pkg/libopts/README > README
}

create_makefile() {
    cd ${tagd}
    touch MakeDefs.inc

    vers=${AO_CURRENT}:${AO_REVISION}:${AO_AGE}
    {
        cat <<- EOMakefile
		## LIBOPTS Makefile
		MAINTAINERCLEANFILES    = Makefile.in
		if INSTALL_LIBOPTS
		lib_LTLIBRARIES         = libopts.la
		else
		noinst_LTLIBRARIES      = libopts.la
		endif
		libopts_la_SOURCES      = libopts.c
		libopts_la_CPPFLAGS     = -I\$(srcdir)
		libopts_la_LDFLAGS      = -version-info ${AM_LDFLAGS} ${vers}
		EXTRA_DIST		=
		BUILT_SOURCES		=
		MOSTLYCLEANFILES	=
                
		libopts.c:		\$(BUILT_SOURCES)
			@: do-nothing rule to avoid default SCCS get
                
		EOMakefile

        printf '\n# Makefile fragment from gnulib-s stdnoreturn module:\n#\n'
        sed '/^#/d;/^$/d;s/top_srcdir/srcdir/' \
            ${top_srcdir}/pkg/libopts/stdnoreturn.mk
        sed '1,/^Makefile.am:/d;/^[A-Z][a-z0-9-]*:/,$d' \
            ${top_srcdir}/pkg/libopts/_Noreturn

        printf '\nEXTRA_DIST += \\\n'
        find $(ls -A) -type f \
            | env LC_COLLATE=C sort \
            | egrep -v '^(libopts\.c|Makefile\.am)$' \
            | ${CLexe} -I4 --spread=1 --line-sep="  \\"
    } > Makefile.am
}

make_tarball() {
    cd ${top_builddir}/pkg

    # If we have a SOURCE_DATE_EPOCH *and* tar supports a sort option,
    # then add some fancy options to make tar output repeatable.
    #
    rbopts=""
    if test ${#SOURCE_DATE_EPOCH} -gt 1
    then
        if (exec 2>/dev/null ; tar --help|grep -q sort=)
        then
            rbopts="--sort=name --format=gnu --clamp-mtime"
            rbopts="$rbopts --mtime @$SOURCE_DATE_EPOCH"
        fi
    fi

    tar cvf - $rbopts ${tag} | \
        gzip --best -n > \
             ${top_builddir}/autoopts/${tag}.tar.gz
    rm -rf ${tag}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#  MAIN
#
init
copy_sources
create_makefile
make_tarball
exit 0

## Local Variables:
## mode: shell-script
## indent-tabs-mode: nil
## sh-indentation: 4
## sh-basic-offset: 4
## End:

## end of mklibsrc.sh
