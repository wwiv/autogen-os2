
/*
 *  $Id: tpLoad.c,v 1.1 1999/10/14 00:33:53 bruce Exp $
 *
 *  This module will load a template and return a template structure.
 */

/*
 *  AutoGen copyright 1992-1999 Bruce Korb
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

#include <sys/mman.h> 
#include <sys/param.h>
#include <fcntl.h>

#include "autogen.h"


static tTlibMark magicMark = TEMPLATE_MAGIC_MARKER;

tTemplate* findTemplate( const char* pzTemplName )
{
    tTemplate* pT = pNamedTplList;
    while (pT != (tTemplate*)NULL) {
        if (streqvcmp( pzTemplName, pT->pzTplName ) == 0)
            break;
        pT = (tTemplate*)(pT->pNext);
    }
    return pT;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Starting with the current directory, search the directory
 *  list trying to find the base template file name.
 */
    tSuccess
findTemplateFile( const char* pzTempl, char* pzFullName )
{
    char*   pzRoot;
    char*   pzSfx;

    /*
     *  Expand leading environment variables.
     *  We will not mess with embedded ones.
     */
    if (*pzTempl == '$') {
        char* pzDef = (char*)(pzTempl+1);
        char* pzEnd = strchr( pzDef, '/' );

        /*
         *  IF the string contains a directory separator,
         *  THEN everything up to that is the define name.
         */
        if (pzEnd != (char*)NULL)
            *(pzEnd++) = NUL;

        pzDef = (char*)getDefine( pzDef );

        /*
         *  IF we cannot find a define name,
         *  THEN print a warning and continue as normal.
         */
        if (pzDef == (char*)NULL) {
            if (pzEnd != (char*)NULL)
                pzEnd[-1] = '/';

            fprintf( stderr, "NOTE: cannot expand %s\n", pzTempl );
            return FAILURE;
        }

        /*
         *  Add stuff after the expanded name IFF there is stuff
         */
        if (pzEnd != (char*)NULL) {
            sprintf( pzFullName, "%s/%s", pzDef, pzEnd );
            /*
             *  FIXME:  this is a memory leak
             */
            AGDUPSTR( pzTempl, pzFullName );
            pzEnd[-1] = '/';
        } else {
            pzTempl = pzDef;
        }
        /*
         *  pzTempl now points to the name the file system can use.
         *  It must _not_ point to pzFullName because we will likely
         *  rewrite that value using this pointer!
         */
    }

    /*
     *  Check for an immediately accessible file
     */
    if (access( pzTempl, R_OK ) == 0) {
        strcpy( pzFullName, pzTempl );
        return SUCCESS;
    }

    /*
     *  Not a complete file name.  If there is not already
     *  a suffix for the file name, then append ".tpl".
     *  Check for immediate access once again.
     */
    pzRoot = strrchr( pzTempl, '/' );
    pzSfx  = (pzRoot != (char*)NULL)
             ? strchr( ++pzRoot, '.' )
             : strchr( pzTempl, '.' );

    /*
     *  Check for an immediately accessible suffixed file
     */
    if (pzSfx == (char*)NULL) {
        sprintf( pzFullName, "%s.agl", pzTempl );
        if (access( pzFullName, R_OK ) == 0)
            return SUCCESS;

        sprintf( pzFullName, "%s.tpl", pzTempl );
        if (access( pzFullName, R_OK ) == 0)
            return SUCCESS;
    }

    if (*pzTempl == '/')
        return FAILURE;

    /*
     *  Search each directory in our directory search list
     *  for the file.
     */
    if (HAVE_OPT( TEMPL_DIRS )) {
        int     ct     = STACKCT_OPT(  TEMPL_DIRS );
        char**  ppzDir = STACKLST_OPT( TEMPL_DIRS ) + ct - 1;

        do  {
            tSCC zDirFmt[] = "%s/%s";
            char*   pzDir  = *(ppzDir--);
            char*   pzEnd  = pzFullName;

            pzEnd += sprintf( pzFullName, zDirFmt, pzDir, pzTempl );

            if (access( pzFullName, R_OK ) == 0)
                return SUCCESS;
            if (pzSfx == (char*)NULL) {
                strcpy( pzEnd, ".agl" );
                if (access( pzFullName, R_OK ) == 0)
                    return SUCCESS;

                strcpy( pzEnd, ".tpl" );
                if (access( pzFullName, R_OK ) == 0)
                    return SUCCESS;
            }
        } while (--ct > 0);
    }

    /*
     *  IF there is a directory component to the template name,
     *  THEN we will not search for templates in the executable's
     *       directory.
     */
    if (pzRoot != (char*)NULL)
        return FAILURE;

    /*
     *  Now we try to find this file using our PATH environment variable.
     */
    {
        tSCC   zPath[] = "PATH";
        char*  pzPath  = getenv( zPath );
        char*  pzFound;

        /*
         *  IF we cannot find a PATH variable, bail
         */
        if (pzPath == (char*)NULL)
            return FAILURE;

        pzFound = pathfind( pzPath, pzTempl, "rs" );
        if ((pzFound == (char*)NULL) && (pzSfx == (char*)NULL)) do {
            sprintf( pzFullName, "%s.agl", pzTempl );
            pzFound = pathfind( pzPath, pzFullName, "rs" );
            if (pzFound != (char*)NULL)
                break;
            sprintf( pzFullName, "%s.tpl", pzTempl );
            pzFound = pathfind( pzPath, pzFullName, "rs" );
        } while (AG_FALSE);

        if (pzFound == (char*)NULL)
            return FAILURE;

        strcpy( pzFullName, pzFound );
        return SUCCESS;
    }
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  skipSuffixSpec
 *
 *  Process a suffix specification
 */
    STATIC const char*
skipSuffixSpec( const char* pzData, const char* pzFileName, int lineNo )
{
    /*
     *  The following is the complete list of POSIX
     *  required-to-be-legal file name characters.
     *  These are the only characters we allow to
     *  appear in a suffix.  We do, however, add
     *  '=' and '%' because we also allow a format
     *  specification to follow the suffix, separated
     *  by an '=' character.
     */
    tSCC       zFilChars[] = "abcdefghijklmnopqrstuvwxyz"
                             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                             "0123456789" "-_./" "=%";
    tOutSpec*  pOS;
    char*      pz;
    static tOutSpec**  ppOSList = &pOutSpecList;

    /*
     *  Skip over the suffix construct
     */
    size_t spn = strspn( pzData, zFilChars );

    /*
     *  The suffix construct is saved only for the main template!
     */
    if (procState != PROC_STATE_LOAD_TPL)
        return pzData + spn;

    /*
     *  Allocate the suffix structure
     */
    pOS = (tOutSpec*)AGALOC( sizeof( *pOS ) + (size_t)spn + 1);
    if (pOS == (tOutSpec*)NULL) {
        tSCC zOutSpec[] = "Output Specification";

        fprintf( stderr, zAllocErr, pzProg,
                 sizeof( *pOS ) + spn + 1, zOutSpec );
        AG_ABEND;
    }

    /*
     *  Link it into the global list
     */
    *ppOSList  = pOS;
    ppOSList   = &pOS->pNext;
    pOS->pNext = (tOutSpec*)NULL;

    /*
     *  Copy the data into the suffix field from our input buffer.
     *  IF the suffix contains its own formatting construct,
     *  THEN split it off from the suffix and set the formatting ptr.
     *  ELSE supply a default.
     */
    strncpy( pOS->zSuffix, pzData, spn );
    pOS->zSuffix[ spn ] = NUL;

    pz = strchr( pOS->zSuffix, '=' );

    if (pz != (char*)NULL) {
        tSCC zFileFmt3[] = "%s";
        *pz++ = NUL;
        if (*pz == NUL)
             pOS->pzFileFmt = zFileFmt3;
        else pOS->pzFileFmt = pz;

    } else {
        tSCC zFileFmt1[] = "%s.%s";
        tSCC zFileFmt2[] = "%s%s";

        /*
         *  IF the suffix does not start with punctuation,
         *  THEN we will insert a '.' of our own.
         */
        if (isalnum( pOS->zSuffix[0] ))
             pOS->pzFileFmt = zFileFmt1;
        else pOS->pzFileFmt = zFileFmt2;
    }

    return pzData + spn;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  loadPseudoMacro
 *
 *  Find the start and end macro markers.  In btween we must find the
 *  "autogen" and "template" keywords, followed by any suffix specs.
 */
    STATIC const char*
loadPseudoMacro( const char* pzData, const char* pzFileName )
{
    tSCC zNotAg[]  = "not an AutoGen file";
    tSCC    zAG[]  = "AutoGen";
    tSCC   zTPL[]  = "template";
    typedef enum { LOAD_NEED_START, LOAD_NEED_AUTOGEN,
                   LOAD_NEED_TEMPLATE, LOAD_NEED_END, LOAD_DONE
    } te_load_state;

    te_load_state state = LOAD_NEED_START;

    ag_bool haveEditMode = AG_FALSE;

    zStartMac[0] = NUL;
    startMacLen  = 0;
    endMacLen    = 0;
    zEndMac[0]   = NUL;
    templLineNo  = 1;

    for (;;) {
        /*
         *  Skip white space
         */
        while (isspace( *pzData )) {
            if (*(pzData++) == '\n') {
                templLineNo++;

                /*
                 *  IF we are done with the macro markers,
                 *  THEN we skip white space only thru the first new line.
                 */
                if (state == LOAD_DONE)
                    goto end_loadTemplText;
            }
        }

        /*
         *  Skip comments
         */
        if ((pzData[0] == '/') && (pzData[1] == '*')) {
            const char* pz = strstr( (char*)pzData + 2, "*/" );
            if (pz == (const char*)NULL) {
                tSCC zEr[] = "unended comment";
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                AG_ABEND;
            }
            for (;;) {
                pzData = (const char*)strchr( (char*)pzData+1, '\n' );
                if ((pzData == (const char*)NULL) || (pzData > pz))
                    break;
                templLineNo++;
            }
            pzData = pz+2;
            continue;
        }

        if (*pzData == '#') {
            char* pz = strchr( pzData, '\n' );
            if (pz == (const char*)NULL) {
                tSCC zEr[] = "unended pseudo macro";
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                AG_ABEND;
            }
            pzData = pz;
            continue;
        }

        /*
         *  Skip one edit mode
         */
        if (  (! haveEditMode)
           && (pzData[0] == '-')
           && (pzData[1] == '*')
           && (pzData[2] == '-')  )  {
            char* pz = strstr( pzData+3, "-*-" );
            haveEditMode = AG_TRUE;
            pzData = strchr( pzData+3, '\n' );

            /*
             *  IF mode end not found OR newline embedded in mode
             *  THEN oops.
             */
            if ((pz == (const char*)NULL) || (pzData < pz)) {
                tSCC zEr[] = "unended mode";
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                AG_ABEND;
            }
            pzData = pz + 3;
            continue;
        }


        switch (state) {
        case LOAD_NEED_START:
            if (! ispunct( *pzData )) {
                tSCC zEr[] = "No start macro mark";
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                AG_ABEND;
            }
            do  {
                zStartMac[ startMacLen++ ] = *(pzData++);
                if (startMacLen >= sizeof( zStartMac )) {
                    tSCC zEr[] = "start marker too long";
                    fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                    AG_ABEND;
                }
            } while (ispunct( *pzData ));
            zStartMac[ startMacLen ] = NUL;
            state = LOAD_NEED_AUTOGEN;
            break;

        case LOAD_NEED_AUTOGEN:
            if (strneqvcmp( pzData, zAG, STRSIZE( zAG )) != 0) {
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zNotAg );
                AG_ABEND;
            }
            if (pzData[ sizeof( zAG )-1 ] != '5') {
                tSCC zOutDate[] = "Out of date AutoGen template";
                const char* pzWhich = (isspace( pzData[ sizeof( zAG )-1 ] ))
                    ? zOutDate : zNotAg;
                fprintf( stderr, zTplErr, pzFileName, templLineNo, pzWhich );
                AG_ABEND;
            }

            pzData += sizeof( zAG );
            state  = LOAD_NEED_TEMPLATE;
            break;

        case LOAD_NEED_TEMPLATE:
            if (  (strneqvcmp( pzData, zTPL, STRSIZE( zTPL )) != 0)
               || (! isspace( pzData[ STRSIZE( zTPL ) ]))  ) {
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zNotAg );
                AG_ABEND;
            }
            pzData += sizeof( zTPL );
            state  = LOAD_NEED_END;
            break;

        case LOAD_NEED_END:
            /*
             *  IF the next character is alphanumeric, a period,
             *      a hyphen or an underscore,
             *  THEN process the new suffix...
             */
            if (ISSUFFIXCHAR( *pzData )) {
                pzData = skipSuffixSpec( pzData, pzFileName, templLineNo );
                break;
            }
            if (! ispunct( *pzData )) {
                tSCC zEr[] = "No end macro mark";
                fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                AG_ABEND;
            }
            do  {
                zEndMac[ endMacLen++ ] = *(pzData++);
                if (endMacLen >= sizeof( zEndMac )) {
                    tSCC zEr[] = "end marker too long";
                    fprintf( stderr, zTplErr, pzFileName, templLineNo, zEr );
                    AG_ABEND;
                }
            } while (ispunct( *pzData ));
            zEndMac[ endMacLen ] = NUL;
            state = LOAD_DONE;
            break;

        case LOAD_DONE:
            goto end_loadTemplText;
        } /* switch (state) */
    }     /* for (;;) */

 end_loadTemplText:;
    templLineNo = templLineNo;
    return pzData;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  countMacros
 *
 *  Figure out how many macros there are in the template
 *  so that we can allocate the right number of pointers.
 */
    STATIC size_t
countMacros( const char* pz )
{
    size_t  ct = 2;
    for (;;) {
        pz = strstr( pz, zStartMac );
        if (pz == (char*)NULL)
            break;
        ct += 2;
        if (strncmp( pz - endMacLen, zEndMac, endMacLen ) == 0)
            ct--;
        pz += startMacLen;
    }
    return ct;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  fillTemplate
 *
 *  Load the macro array and file name.
 */
    void
loadMacros( tTemplate*     pT,
            const char*    pzF,
            const char*    pzN,
            const char*    pzData )
{
    tMacro* pMac   = pT->aMacros;

    {
        char*   pzText = (char*)(pMac + pT->macroCt);
        size_t  len;

        pT->pzFileName = pzText;
        len = strlen( pzF ) + 1;
        memcpy( (void*)pzText, (void*)pzF, len );
        pzText += len;
        if (pzN != (char*)NULL) {
            len = strlen( pzN ) + 1;
            memcpy( (void*)pzText, (void*)pzN, len );
            pzText += len;
        }

        pT->pzTemplText = pzText;
        pT->pNext = pzText + 1;
    }

    {
        tMacro* pMacEnd = parseTemplate( pT, pMac, &pzData );

        /*
         *  Make sure all of the input string was scanned.
         */
        if (pzData != (char*)NULL)  {
            fprintf( stderr, zTplErr, pzF, -1,
                     "parse ended unexpectedly" );
            AG_ABEND;
        }

        pT->macroCt = pMacEnd - pMac;

        /*
         *  IF there are empty macro slots,
         *  THEN pack the text
         */
        if ((void*)pMacEnd < (void*)(pT->pzFileName)) {
            int  delta = pT->pzFileName - (char*)pMacEnd;
            int  size  = (pT->pNext - pT->pzFileName);
            memcpy( (void*)pMacEnd, (void*)(pT->pzFileName),
                    size );
            pT->pzFileName  -= delta;
            pT->pzTemplText -= delta;
            pT->pNext       -= delta;
            if (pT->pzTplName != 0)
                pT->pzTplName -= delta;
        }
    }

    pT->descSize     = pT->pNext - (char*)pT;
    pT->descSize    += 0x40;
    pT->descSize    &= ~0x3F;
    pT->pzFileName  -= (long)pT;
    pT->pzTplName    = 0;
    pT->pzTemplText -= (long)pT;
    pT->pNext        = NULL;

    /*
     *  We cannot reallocate a smaller array because
     *  the entries are all linked together and
     *  realloc-ing it may cause it to move.
     */
#if defined( DEBUG ) && defined( VALUE_OPT_SHOW_DEFS )
    if (HAVE_OPT( SHOW_DEFS )) {
        tSCC zSum[] = "loaded %d macros from %s\n"
            "\tBinary template size:  0x%X\n\n";
        printf( zSum, pT->macroCt, pzF, pT->descSize );
    }
#endif
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Convert a template from data file format to internal format.
 */
    tTemplate*
templateFixup( tTemplate* pTList, size_t ttlSize )
{
    tTemplate* pT = pTList;

    for (;;) {
        size_t  tplSize = pT->descSize;

        pT->pzFileName  += (long)pT;
        if (pT->pzTplName != (char*)0)
            pT->pzTplName = 0;
        pT->pzTemplText += (long)pT;

        ttlSize -= tplSize;
        if (ttlSize <= sizeof( tTemplate))
            break;

        pT->fd    = 0;
        pT->pNext = (char*)pT + tplSize;
        pT = (tTemplate*)(pT->pNext);
        if (memcmp( (void*)pT, (void*)pTList, sizeof( tTlibMark )) != 0) {
            tSCC z[] = "The %s binary template library is inconsistent\n";
            fprintf( stderr, z, pTList->pzFileName );
            AG_ABEND;
        }
    }

    pT->pNext = (char*)NULL;
    return pTList;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Starting with the current directory, search the directory
 *  list trying to find the base template file name.
 */
    tTemplate*
loadTemplate( const char* pzFileName )
{
    size_t       dataSize;
    void*        pDataMap;
    int          fd;

    static char  zRealFile[ MAXPATHLEN ];

    /*
     *  Find the template file somewhere
     */
    if (! SUCCESSFUL( findTemplateFile( pzFileName, zRealFile ))) {
        tSCC zFindTemplFile[] = "find template file";
        fprintf( stderr, zCannot, pzProg, ENOENT,
                 zFindTemplFile, pzFileName, strerror( ENOENT ));
        AG_ABEND;
    }

    /*
     *  The template file must really be a file.
     */
    {
        struct stat stbf;
        if (stat( zRealFile, &stbf ) != 0) {
            tSCC zStat[] = "stat";
            fprintf( stderr, zCannot, pzProg, errno,
                     zStat, zRealFile, strerror( errno ));
            AG_ABEND;
        }

        if (! S_ISREG( stbf.st_mode )) {
            fprintf( stderr, "ERROR:  `%s' is not a regular file\n",
                     zRealFile );
            AG_ABEND;
        }

        if (outTime <= stbf.st_mtime)
            outTime = stbf.st_mtime + 1;
        dataSize = stbf.st_size;
    }

    /*
     *  Now open it and map it into memory
     */
    fd = open( zRealFile, O_EXCL | O_RDONLY, 0 );
    if (fd == -1) {
        tSCC zOpen[] = "open";
        fprintf( stderr, zCannot, pzProg, errno,
                 zOpen, zRealFile, strerror( errno ));
        AG_ABEND;
    }

    pDataMap = mmap( (void*)NULL, dataSize + 1, PROT_READ | PROT_WRITE,
                     MAP_PRIVATE, fd, (off_t)0 );
    if (pDataMap == (void*)(-1)) {
        tSCC zMmap[] = "mmap";
        fprintf( stderr, zCannot, pzProg, errno,
                 zMmap, zRealFile, strerror( errno ));
        AG_ABEND;
    }

    /*
     *  Check for a binary template.  If it is, it must
     *  be the current revision, or we choke.
     */
    {
        tTemplate*  p = (tTemplate*)pDataMap;

        if (p->magic.magic.i[0] == magicMark.magic.i[0]) {
            tSCC zOutOfDate[] = "out-of-date binary template";
            tSCC zTooNew[]    = "unknown binary template version";
            tSCC zChange[]    = "Functions changed - rebuild lib";
            tCC* pz;

            if (p->magic.magic.i[1] == magicMark.magic.i[1]) {
                p->fd = fd;
                return templateFixup( p, dataSize );
            }

            if (p->magic.revision < TEMPLATE_REVISION)
                pz = zOutOfDate;
            if (p->magic.revision > TEMPLATE_REVISION)
                pz = zTooNew;
            else
                pz = zChange;

            fprintf( stderr, zTplErr, zRealFile, 0, pz );
            AG_ABEND;
        }
    }

    {
        size_t       macroCt;
        tTemplate*   pRes;
        size_t       alocSize;
        const char*  pzData;

        /*
         *  Process the leading pseudo-macro.  The template proper
         *  starts immediately after it.
         */
        pzData = loadPseudoMacro( (const char*)pDataMap, zRealFile );

        /*
         *  Count the number of macros in the template.  Compute
         *  the output data size as a function of the number of macros
         *  and the size of the template data.  These may get reduced
         *  by comments.
         */
        macroCt = countMacros( pzData );
        alocSize = sizeof( *pRes ) + (macroCt * sizeof( tMacro ))
                   + dataSize - (pzData - (const char*)pDataMap)
                   + strlen( zRealFile ) + 0x10;
        alocSize &= ~0x0F;
        pRes = AGALOC( alocSize );
        memset( (void*)pRes, 0, alocSize );

        /*
         *  Initialize the values:
         */
        memcpy( (void*)pRes, (void*)&magicMark, sizeof( magicMark ));
        pRes->descSize  = alocSize;
        pRes->macroCt   = macroCt;
        pRes->fd        = -1;

        loadMacros( pRes, zRealFile, (char*)NULL, pzData );
        pRes = (tTemplate*)AGREALOC( (void*)pRes, pRes->descSize );

        munmap( pDataMap, dataSize+1 );
        close( fd );
        return templateFixup( pRes, pRes->descSize );
    }
}

#ifdef MEMDEBUG

    void
unloadTemplate( tTemplate* pT )
{
    if (pT->fd < 0)
        AGFREE( (void*)pT );
    else {
        int     fd = pT->fd;
        void*   addr = (void*)pT;
        size_t  size = pT->descSize;
        close( fd );
        munmap( addr, size );
    }
}
#endif
/* end of tpLoad.c */