/*  -*- Mode: C -*-
 *
 *  $Id: getdefs.h,v 3.10 2003/04/22 01:40:20 bkorb Exp $
 *
 *    getdefs copyright 1999 Bruce Korb
 *
 *  Time-stamp:        "2003-04-21 17:55:45 bkorb"
 *  Author:            Bruce Korb <bkorb@gnu.org>
 *  Maintainer:        Bruce Korb <bkorb@gnu.org>
 *  Created:           Mon Jun 30 15:35:12 1997
 */

#ifndef GETDEFS_HEADER
#define GETDEFS_HEADER

#include "config.h"
#include "compat/compat.h"
#include <sys/wait.h>
#include <utime.h>
#include "streqv.h"

#include REGEX_HEADER

#define EXPORT

#include "opts.h"

#ifdef DEFINE
#  define MODE
#  define VALUE(v) = v
#  define DEF_STRING(n,s) tCC n[] = s
#else
#  define MODE extern
#  define VALUE(v)
#  define DEF_STRING(n,s) extern tCC n[sizeof(s)]
#endif

#define MAXNAMELEN 256

#define MAX_SUBMATCH   1
#define COUNT(a)       (sizeof(a)/sizeof(a[0]))

#define MARK_CHAR ':'

#ifndef STR
#  define __STR(s)  #s
#  define STR(s)    __STR(s)
#endif

#define AG_NAME_CHAR(c) (zUserNameCh[(unsigned)(c)] & 2)
#define USER_NAME_CH(c) (zUserNameCh[(unsigned)(c)] & 1)
MODE char zUserNameCh[ 256 ] VALUE( { '\0' } );

/*
 *  Index database string pointers.
 */
MODE char*    pzIndexText VALUE( (char*)NULL ); /* all the text    */
MODE char*    pzEndIndex  VALUE( (char*)NULL ); /* end of current  */
MODE char*    pzIndexEOF  VALUE( (char*)NULL ); /* end of file     */
MODE size_t   indexAlloc  VALUE( 0 );           /* allocation size */

/*
 *  Name of program to process output (normally ``autogen'')
 */
MODE tCC*     pzAutogen   VALUE( "autogen" );

/*
 *  const global strings
 */
DEF_STRING( zGlobal,     "\n/* GLOBALDEFS */\n" );
DEF_STRING( zLineId,     "\n#line %d \"%s\"\n" );
DEF_STRING( zMallocErr,  "Error:  could not allocate %d bytes for %s\n" );
DEF_STRING( zAttribRe,   "\n[^*\n]*\\*[ \t]*([a-z][a-z0-9_-]*):");
DEF_STRING( zNameTag,    " = {\n    name    = '" );
DEF_STRING( zMemberLine, "    member  = " );
DEF_STRING( zNoData,     "error no data for definition in file %s line %d\n" );
DEF_STRING( zAgDef,      "autogen definitions %s;\n");
DEF_STRING( zDne,
            "/*  -*- buffer-read-only: t -*- vi: set ro:\n *\n"
            " *\n *  DO NOT EDIT THIS FILE   (%s)\n *\n"
            " *  It has been extracted by getdefs from the following files:\n"
            " *\n" );

/*
 *  ptr to zero (NUL) terminated definition pattern string.
 *
 *  The pattern we look for starts with the three characters
 *  '/', '*' and '=' and is followed by two names:
 *  the name of a group and the name of the entry within the group.
 *
 *  The patterns we accept for output may specify a particular group,
 *  certain members within certain groups or all members of all groups
 */
MODE char*   pzDefPat   VALUE( (char*)NULL );
MODE regex_t define_re;
MODE regex_t attrib_re;

/*
 *  The output file pointer.  It may be "stdout".
 *  It gets closed when we are done.
 */
MODE FILE*  evtFp       VALUE( (FILE*)NULL );

/*
 *  The output file modification time.  Only used if we
 *  have specified a real file for output (not stdout).
 */
MODE time_t modtime     VALUE( 0 );

/*
 *  The array of pointers to the output blocks.
 *  We build them first, then sort them, then print them out.
 */
MODE char**  papzBlocks VALUE( (char**)NULL );
MODE size_t  blkUseCt   VALUE(  0 );
MODE size_t  blkAllocCt VALUE(  0 );

MODE pid_t   agPid      VALUE( -1 );

#include "proto.h"

#endif /* GETDEFS_HEADER */

/* emacs
 * Local Variables:
 * mode: C
 * c-file-style: "stroustrup"
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 * end of getdefs/getdefs.h */
