
/*
 *  autogen.h
 *  $Id: autogen.h,v 3.1 2001/12/24 14:13:32 bkorb Exp $
 *  Global header file for AutoGen
 */

/*
 *  AutoGen copyright 1992-2001 Bruce Korb
 *
 *  AutoGen is free software.
 *  You may redistribute it and/or modify it under the terms of the
 *  GNU General Public License, as published by the Free Software
 *  Foundation; either version 2, or (at your option) any later version.
 *
 *  AutoGen is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with AutoGen.  See the file "COPYING".  If not,
 *  write to:  The Free Software Foundation, Inc.,
 *             59 Temple Place - Suite 330,
 *             Boston,  MA  02111-1307, USA.
 */
#ifndef AUTOGEN_HDR_H
#define AUTOGEN_HDR_H

#include "compat/compat.h"
#include "agUtils.h"
#include "streqv.h"

typedef enum {
    PROC_STATE_INIT,       /* set up `atexit' and load Guile   */
    PROC_STATE_OPTIONS,    /* processing command line options  */
    PROC_STATE_GUILE_PRELOAD,
    PROC_STATE_LOAD_DEFS,  /* Loading value definitions        */
    PROC_STATE_LIB_LOAD,   /* Loading library template         */
    PROC_STATE_LOAD_TPL,   /* Loading primary template         */
    PROC_STATE_EMITTING,   /* processing templates             */
    PROC_STATE_INCLUDING,  /* loading an included template     */
    PROC_STATE_CLEANUP,
    PROC_STATE_ABORTING,   /* Clean up code in error response  */
    PROC_STATE_DONE        /* `exit' has been called           */
} teProcState;

#ifdef DEBUG
#  define GIVE_UP(f,l) \
    fprintf( stderr, zGiveUp, f, l )
#else
#  define GIVE_UP(f,l)
#endif

#define EXPORT

#define AG_ABEND STMTS( \
    GIVE_UP( __FILE__, __LINE__ ); \
    if (procState < PROC_STATE_EMITTING) \
        exit(EXIT_FAILURE); \
    procState = PROC_STATE_ABORTING; \
    longjmp( fileAbort, FAILURE ) )

#define AG_ABEND_START(s) \
    fprintf( stderr, zErrorPfx, pzOopsPrefix, (s) )

#define AG_ABEND_STR(s)  STMTS( \
    AG_ABEND_START( s ); AG_ABEND; )

#define LOAD_ABORT( pT, pM, m ) STMTS( AG_ABEND_START( m ); \
    if (procState >= PROC_STATE_LIB_LOAD) \
        fprintf( stderr, zTplErr, (pT)->pzFileName, (pM)->lineNo, m ); \
    AG_ABEND )

typedef struct fpStack       tFpStack;
typedef struct outSpec       tOutSpec;
typedef struct scanContext   tScanCtx;
typedef struct defEntry      tDefEntry;
typedef struct macro_desc    tMacro;
typedef struct template_desc tTemplate;
typedef struct for_info      tForInfo;
typedef struct for_state     tForState;
typedef struct template_lib_marker tTlibMark;

#define MAX_SUFFIX_LEN  8  /* maximum length of a file name suffix */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Template Library Layout
 *
 *  Procedure for loading a template function
 */
typedef tMacro* (tLoadProc)( tTemplate*, tMacro*, const char** ppzScan );
typedef tLoadProc* tpLoadProc;

/*
 *  Procedure for handling a template function
 *  during the text emission phase.
 */
typedef tMacro* (tHdlrProc)( tTemplate*, tMacro* );
typedef tHdlrProc* tpHdlrProc;

/*
 *  This must be included after the function prototypes
 *  (the prototypes are used in the generated tables),
 *  but before the macro descriptor structure (the function
 *  enumeration is generated here).
 */
#include "functions.h"

#define TEMPLATE_REVISION     1
#define TEMPLATE_MAGIC_MARKER {{'A', 'G', 'L', 'B'}, \
                               TEMPLATE_REVISION, FUNCTION_CKSUM }

struct template_lib_marker {
    union {
        char        str[4];  /* {'A', 'G', 'L', 'B'} */
        long        i[1];
    }           magic;
    short       revision;    /* TEMPLATE_REVISION    */
    short       funcSum;     /* FUNCTION_CKSUM       */
};

/*
 *  Defines for conditional expressions.
 *  The first four are an enumeration that appear in the
 *  low four bits and the next-to-lowest four bits.
 *  "PRIMARY_TYPE" and "SECONDARY_TYPE" are masks for
 *  extracting this enumeration.  The rest are flags.
 */
#define EMIT_VALUE          0x0000  /* emit value of variable  */
#define EMIT_EXPRESSION     0x0001  /* Emit Scheme result      */
#define EMIT_SHELL          0x0002  /* emit shell output       */
#define EMIT_STRING         0x0003  /* emit content of expr    */
#define EMIT_PRIMARY_TYPE   0x0007
#define EMIT_SECONDARY_TYPE 0x0070
#define EMIT_SECONDARY_SHIFT     4
#define EMIT_IF_ABSENT      0x0100
#define EMIT_ALWAYS         0x0200  /* emit one of two exprs   */
#define EMIT_FORMATTED      0x0400  /* format, if val present  */
#define EMIT_NO_DEFINE      0x0800  /* don't get defined value */

struct macro_desc {
    teFuncType  funcCode;  /* Macro function         */
    int         lineNo;    /* of macro def           */
    int         endIndex;  /* End of block macro     */
    int         sibIndex;  /* Sibling macro (ELIF or SELECT) */

    off_t       ozName;    /* macro name (sometimes) */
    off_t       ozText;    /* associated text        */
    long        res;       /* some sort of result    */
    void*       funcPrivate;
};

struct template_desc {
    tTlibMark   magic;       /* TEMPLATE_MAGIC_MARKER    */
    int         fd;          /* mmap file descriptor     */
    size_t      descSize;    /* Structure Size           */
    char*       pNext;       /* Next Pointer             */
    int         macroCt;     /* Count of Macros          */
    char*       pzFileName;  /* Name of Macro File       */
    char*       pzTplName;   /* Template Name Pointer    */
    char*       pzTemplText; /* offset of the text       */
    char        zStartMac[8];
    char        zEndMac[8];
    tMacro      aMacros[1];  /* Array of Macros          */
/*  char        text[...];    * strings at end of macros */
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Name/Value Definitions Layout
 */
typedef enum {
    VALTYP_UNKNOWN = 0,
    VALTYP_TEXT,
    VALTYP_BLOCK
} teValType;


#define NO_INDEX ((short)0x80DEAD)

typedef struct def_stack tDefStack;
struct def_stack {
	tDefEntry* pDefs;        /* ptr to current def set     */
    tDefStack* pPrev;        /* ptr to previous def set    */
};

struct defEntry {
    tDefEntry* pNext;        /* next member of same level  */
    tDefEntry* pTwin;        /* next member with same name */
    tDefEntry* pPrevTwin;    /* previous memb. of level    */
    tDefEntry* pEndTwin;     /* head of chain to end ptr   */
    char*      pzDefName;    /* name of this member        */
    teValType  valType;      /* text/block/not defined yet */
    long       index;        /* index among twins          */
    char*      pzValue;      /* string or list of children */
};

struct scanContext {
    tScanCtx*   pCtx;
    char*       pzScan;
    char*       pzFileName;
    char*       pzData;
    int         lineNo;
};

struct outSpec {
    tOutSpec*   pNext;
    const char* pzFileFmt;
    char        zSuffix[ 1 ];
};

#define FPF_FREE       0x0001  /* free the fp structure   */
#define FPF_UNLINK     0x0002  /* unlink file (temp file) */
#define FPF_NOUNLINK   0x0004  /* do not unlink file      */
#define FPF_STATIC_NM  0x0008  /* name statically alloced */

struct fpStack {
	int         flags;
    tFpStack*   pPrev;
    FILE*       pFile;
    char*       pzOutName;
};

typedef struct {
    tCC*        pzFileName;
    int         fd;
    size_t      size;
    void*       pData;
} tMapInfo;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  FOR loop processing state
 */
struct for_info {
    int          fi_depth;
    int          fi_alloc;
    tForState*   fi_data;
};

struct for_state {
    ag_bool      for_loading;
    int          for_from;
    int          for_to;
    int          for_by;
    int          for_index;
    char*        for_pzSep;
    char*        for_pzName;
    ag_bool      for_lastFor;
    ag_bool      for_firstFor;
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  GLOBAL VARIABLES
 *
 *  General Processing Globals
 */
#define pzProg   autogenOptions.pzProgName
MODE teProcState procState        VALUE( PROC_STATE_INIT );
MODE char*       pzTemplFileName  VALUE( (char*)NULL );
MODE tTemplate*  pNamedTplList    VALUE( (tTemplate*)NULL );
MODE tCC*        pzOopsPrefix     VALUE( "" );

/*
 *  Template Processing Globals
 */
MODE tCC*        pzCurSfx         VALUE( (char*)NULL );
MODE time_t      outTime          VALUE( 0 );
MODE tFpStack*   pCurFp           VALUE( (tFpStack*)NULL );
MODE tOutSpec*   pOutSpecList     VALUE( (tOutSpec*)NULL );
MODE jmp_buf     fileAbort        VALUE( { 0 } );
MODE char*       pzCurStart       VALUE( (char*)NULL );
MODE off_t       curStartOff      VALUE( 0 );
MODE tForInfo    forInfo          VALUE( { 0 } );
MODE FILE*       pfTrace          VALUE( (FILE*)NULL );

MODE tCC*        serverArgs[2]    VALUE( { (char*)NULL } );

/*
 *  AutoGen definiton and template context
 *
 *  currDefCtx is the current, active list of name/value pairs.
 *  Points to its parent list for full search resolution.
 *
 *  pCurTemplate the template (and DEFINE macro) from which
 *  the current set of macros is being extracted.
 *
 *  These are set in exactly ONE place:
 *  On entry to the dispatch routine (generateBlock)
 *  Two routines, however, must restore the values:  mFunc_Define
 *  and mFunc_For.  They are the only routines that dynamically
 *  push name/value pairs on the definition stack.
 */
MODE tDefStack   currDefCtx       VALUE( { NULL } );
MODE tDefStack   rootDefCtx       VALUE( { NULL } );
MODE tTemplate*  pCurTemplate     VALUE( (tTemplate*)NULL );

/*
 *  Current Macro
 *
 *  This may be set in exactly three places:
 *  1.  The dispatch routine (generateBlock) that steps through
 *      a list of macros
 *  2.  mFunc_If may transfer to one of its 'ELIF' or 'ELSE'
 *      alternation macros
 *  3.  mFunc_Case may transfer to one of its selection clauses.
 */
MODE tMacro*     pCurMacro        VALUE( (tMacro*)NULL );

/*
 *  Template Parsing Globals
 */
MODE int         templLineNo      VALUE( 1 );
MODE tScanCtx*   pBaseCtx         VALUE( (tScanCtx*)NULL );
MODE tScanCtx*   pCurCtx          VALUE( (tScanCtx*)NULL );
MODE tScanCtx*   pDoneCtx         VALUE( (tScanCtx*)NULL );
MODE int         endMacLen        VALUE( 0  );
MODE char        zEndMac[   8 ]   VALUE( "" );
MODE int         startMacLen      VALUE( 0  );
MODE char        zStartMac[  8 ]  VALUE( "" );

/*
 *  Definition Parsing Globals
 */
MODE char*       pzDefineData     VALUE( (char*)NULL );
MODE size_t      defineDataSize   VALUE( 0 );

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  GLOBAL STRINGS
 */
#define MKSTRING( name, val ) \
        MODE const char z ## name[ sizeof( val )] VALUE( val )

MKSTRING( ErrorPfx,  "%sautogen ERROR:  %s\n" );
MKSTRING( AllocWhat, "\ta %d byte %s\n" );
MKSTRING( AllocErr,  "Allocation Failure" );
MKSTRING( Cannot,    "\t%d: cannot %s %s:  %s\n" );
MKSTRING( TplErr,    "Error in template %s, line %d\n\t%s\n" );
MKSTRING( TplWarn,   "Warning in template %s, line %d\n\t%s\n" );
MKSTRING( FileLine,  "\tfrom %s line %d\n" );
MKSTRING( ShDone,    "ShElL-OuTpUt-HaS-bEeN-cOmPlEtEd" );
#ifdef DEBUG
MKSTRING( GiveUp,    "Giving up in %s line %d\n" );
#endif

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  MEMORY DEBUGGING
 */
#ifdef MEMDEBUG

typedef struct mem_mgmt      tMemMgmt;
struct mem_mgmt {
    tMemMgmt*   pNext;
    tMemMgmt*   pPrev;
    char*       pEnd;
    const char* pzWhence;
};

#  ifdef strdup
#    undef strdup
#  endif
#  define strdup(s) dupString((s), __FILE__ " at " STR( __LINE__ ))

   extern void* ag_alloc( size_t, const char*, const char* );
   extern void* ag_realloc( void*, size_t, const char*, const char* );
   extern char* ag_strdup( const char* pz, const char*, const char* );

   extern void  ag_free( void* );
   extern void  unloadTemplate( tTemplate* pT );
   extern void  unloadDefs( void );

#  define AGALOC( c, w )       ag_alloc( c, w, __FILE__ " at " STR( __LINE__ ))
#  define AGREALOC( p, c, w )  ag_realloc( p, c, w, \
                                           __FILE__ " at " STR( __LINE__ ))
#  define AGDUPSTR( p, s, w )  STMTS( \
                               tSCC z[] = "strdup in " __FILE__ " at " \
                                          STR( __LINE__ );\
                               p = ag_strdup( s, z, w ))

#  define AGFREE( p )          ag_free( p )
#  define TAGMEM( m, t )   STMTS( tMemMgmt* p  = ((tMemMgmt*)m)-1; \
                           tSCC z[] = t " in " __FILE__ " at " \
                                  STR( __LINE__ ); \
                           p->pzWhence = z )

#else
   extern void* ag_alloc( size_t, const char* );
   extern void* ag_realloc( void*, size_t, const char* );
   extern char* ag_strdup( const char*, const char* );

#  define AGALOC( c, w )       ag_alloc( c, w )
#  define AGREALOC( p, c, w )  ag_realloc( p, c, w )
#  define AGDUPSTR( p, s, w )  p = ag_strdup( s, w )

#  define AGFREE( p )          free( p )
#  define TAGMEM( m, t )
#  define unloadTemplate(pt)
#  define unloadDefs()
#endif

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  GLOBAL PROCEDURES
 */
#ifndef HAVE_STRLCPY
size_t strlcpy( char* dest, const char* src, size_t n );
#endif

static inline char* ag_scm2zchars( SCM s, tCC* type )
{
    if (! gh_string_p( s )) {
        tSCC zNotStr[] = "ERROR: %s is not a string\n";
        fprintf( stderr, zNotStr, type );
        LOAD_ABORT( pCurTemplate, pCurMacro, zNotStr+14 );
    }

    if (SCM_SUBSTRP(s))
        s = scm_makfromstr( SCM_ROCHARS(s), SCM_ROLENGTH(s), 0 );
    return SCM_CHARS(s);
}

#include "proto.h"
#endif /* AUTOGEN_HDR */
/*
 * Local Variables:
 * c-file-style: "Stroustrup"
 * indent-tabs-mode: nil
 * End:
 * end of autogen.h */
