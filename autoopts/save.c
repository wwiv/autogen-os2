
/*
 *  save.c  $Id: save.c,v 1.2 1998/06/17 20:21:09 bkorb Exp $
 *
 *  This module's routines will take the currently set options and
 *  store them into an ".rc" file for re-interpretation the next
 *  time the invoking program is run.
 */

/*
 *  Automated Options copyright 1992-1998 Bruce Korb
 *
 *  Automated Options is free software.
 *  You may redistribute it and/or modify it under the terms of the
 *  GNU General Public License, as published by the Free Software
 *  Foundation; either version 2, or (at your option) any later version.
 *
 *  Automated Options is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Automated Options.  See the file "COPYING".  If not,
 *  write to:  The Free Software Foundation, Inc.,
 *             59 Temple Place - Suite 330,
 *             Boston,  MA  02111-1307, USA.
 *
 * As a special exception, Bruce Korb gives permission for additional
 * uses of the text contained in his release of AutoOpts.
 *
 * The exception is that, if you link the AutoOpts library with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the AutoOpts library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by Bruce Korb under
 * the name AutoOpts.  If you copy code from other sources under the
 * General Public License into a copy of AutoOpts, as the General Public
 * License permits, the exception does not apply to the code that you add
 * in this way.  To avoid misleading anyone as to the status of such
 * modified files, you must delete this exception notice from them.
 *
 * If you write modifications of your own for AutoOpts, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 */

#include <compat/compat.h>

#include <time.h>

#include "autoopts.h"

tSCC  zWarn[] = "%s WARNING:  cannot save options - ";

    STATIC char*
findDirName( tOptions*  pOpts )
{
    char*  pzDir;

    if (pOpts->specOptIdx.save_opts == 0)
        return (char*)NULL;

    pzDir = pOpts->pOptDesc[ pOpts->specOptIdx.save_opts ].pzLastArg;
    if ((pzDir != (char*)NULL) && (*pzDir != '\0'))
        return pzDir;
    
    /*
     *  This function only works if there is a directory where
     *  we can stash the RC (INI) file.
     */
    {
        const char** papz = pOpts->papzHomeList;
        if (papz == (const char**)NULL)
            return (char*)NULL;

        while (papz[1] != (char*)NULL) papz++;
        pzDir = (char*)(*papz);
    }

    /*
     *  IF it does not require deciphering an env value, then just copy it
     */
    if (*pzDir != '$')
        return pzDir;

    {
        char* pzEndDir = strchr( ++pzDir, DIR_SEP_CHAR );
        char* pzFileName;
        char* pzEnv;

        if (pzEndDir != (char*)NULL)
            *(pzEndDir++) = '\0';

        /*
         *  Make sure we can get the env value (after stripping off
         *  any trailing directory or file names)
         */
        pzEnv = getenv( pzDir );
        if (pzEnv == (char*)NULL) {
            fprintf( stderr, zWarn, pOpts->pzProgName );
            fprintf( stderr, "'%s' not defined\n", pzDir );
            return (char*)NULL;
        }

        if (pzEndDir == (char*)NULL)
            return pzEnv;

        pzFileName = (char*)AGALOC(( strlen( pzEnv ) + 2 +
                     (pzEndDir != (char*)NULL) ? strlen( pzEndDir ) : 0 ));

        /*
         *  IF we stripped something off, now tack it back on.
         */
        if (pzFileName == (char*)NULL)
            return (char*)NULL;

        strcpy( pzFileName, pzEnv );
        pzDir = pzFileName + strlen( pzFileName );

        while ((pzDir > pzFileName) && (pzDir[-1] == DIR_SEP_CHAR)) pzDir--;
        *(pzDir++) = DIR_SEP_CHAR;
        strcpy( pzDir, pzEndDir );
        return pzFileName;
    }
}


    STATIC char*
findFileName( tOptions*  pOpts )
{
    char*  pzDir;
    tSCC   zNoStat[] = "error %d (%s) stat-ing %s\n";
    struct stat stBuf;

    pzDir = findDirName( pOpts );
    if (pzDir == (char*)NULL)
        return (char*)NULL;

    /*
     *  See if we can find the specified directory.
     *  We use a once-only loop structure so we can bail
     *  out if we can recover from the unusual condition.
     */
    if (stat( pzDir, &stBuf ) != 0) do {

        /*
         *  IF we could not, check to see if we got a full
         *  path to a file name that has not been created yet.
         */
        if (errno == ENOENT) {
            /*
             *  Strip off the last component,
             *  stat the remaining string
             *  and that string must name a directory
             */
            char*  pzDirCh = strrchr( pzDir, DIR_SEP_CHAR );
                        if (pzDirCh == (char*)NULL) {
                stBuf.st_mode = S_IFREG;
                break;
            }

            if (pzDirCh != (char*)NULL) {
                *pzDirCh = '\0';
                if (  (stat( pzDir, &stBuf ) == 0)
                   && S_ISDIR( stBuf.st_mode )) {

                    /*
                     *  We found the directory.
                     *  Restore the file name and mark the
                     *  full name as a regular file
                     */
                    *pzDirCh = DIR_SEP_CHAR;
                    stBuf.st_mode = S_IFREG;

                    break;  /* bail out of error condition */
                }
            }
        }

        /*
         *  We got a bogus name.
         */
        fprintf( stderr, zWarn, pOpts->pzProgName );
        fprintf( stderr, zNoStat, errno, strerror( errno ), pzDir );
        return (char*)NULL;
    } while (0);

    /*
     *  IF what we found was a directory,
     *  THEN tack on the RC file name
     */
    if (S_ISDIR( stBuf.st_mode )) {
            char*  pzPath = (char*)AGALOC(( strlen( pzDir )
                                          + strlen( pOpts->pzRcName )));
            sprintf( pzPath, "%s%c%s", pzDir, DIR_SEP_CHAR, pOpts->pzRcName );
            pzDir = pzPath;

        /*
         *  IF we cannot stat the object for any reason other than
         *     it does not exist, then we bail out
         */
        if (stat( pzDir, &stBuf ) != 0) {
            if (errno != ENOENT) {
                fprintf( stderr, zWarn, pOpts->pzProgName );
                fprintf( stderr, zNoStat, errno, strerror( errno ),
                         pzDir );
                return (char*)NULL;
            }

            /*
             *  It does not exist yet, but it will be a regular file
             */
            stBuf.st_mode = S_IFREG;
        }
    }

    /*
     *  Make sure that whatever we ultimately found, that it either is
     *  or will soon be a file.
     */
    if (! S_ISREG( stBuf.st_mode )) {
        fprintf( stderr, zWarn, pOpts->pzProgName );
        fprintf( stderr, "'%s' is not a regular file.\n", pzDir );
        return (char*)NULL;
    }

    /*
     *  Get rid of the old file
     */
    unlink( pzDir );
    return pzDir;
}
 
 
    STATIC void
printEntry( FILE* fp, tOptDesc* p, char*  pzLA )
{
    /*
     *  There is an argument.  Pad the name so values line up
     */
    fprintf( fp, "%c%-18s  ", (DISABLED_OPT( p )) ? '+' : ' ', p->pz_Name );

    /*
     *  IF the option is numeric only,
     *  THEN the char pointer is really the number
     */
    if ((p->fOptState & OPTST_NUMERIC) != 0)
        fprintf( fp, "%ld\n", (t_word)pzLA );

    /*
     *  OTHERWISE, FOR each line of the value text, ...
     */
    else {
        for (;;) {
            char* pzNl = strchr( pzLA, '\n' );

            /*
             *  IF this is the last line
             *  THEN print it and bail
             */
            if (pzNl == (char*)NULL)
                break;

            /*
             *  Print the continuation and the text from the current line
             */
            fputs( "\\\n", fp );
            *pzNl = '\0';
            fputs( pzLA, fp );
            *pzNl = '\n';   /* Restore the newline */

            pzLA  = pzNl+1; /* advance the Last Arg pointer */
        }

        /*
         *  Terminate the entry
         */
        fputs( pzLA, fp );
        fputc( '\n', fp );
    }
}


    void
optionSave( tOptions* pOpts )
{
    char*  pzFName;

    pzFName = findFileName( pOpts );
    if (pzFName == (char*)NULL)
        return;

    {
        tOptDesc* pOD = pOpts->pOptDesc;
        int       ct  = pOpts->presetOptCt;
        FILE*     fp  = fopen( pzFName, "w" );

        if (fp == (FILE*)NULL) {
            fprintf( stderr, zWarn, pOpts->pzProgName );
            fprintf( stderr, "error %d (%s) creating %s\n", errno,
                     strerror( errno ), pzFName );
            return;
        }

        {
            const char*  pz = pOpts->pzUsageTitle;
            fputs( "#  ", fp );
            do { fputc( *pz, fp ); } while (*(pz++) != '\n');
        }

        {
            time_t  timeVal = time( (time_t*)NULL );
            char*   pzTime  = ctime( &timeVal );

            fprintf( fp, "#  preset/initialization file\n#  %s#\n",
                     pzTime );
#ifdef ALLOCATED_CTIME
            /*
             *  The return values for ctime(), localtime(), and
             *  gmtime() point to static data whose content is
             *  overwritten by each call.
             */
            free( (void*)pzTime );
#endif
        }

        /*
         *  FOR each of the defined options, ...
         */
        for (;--ct >= 0; pOD++) {
            tOptDesc*  p;

            /*
             *  IF    the option has not been defined
             *     OR it does not take an initialization value
             *     OR it is equivalenced to another option
             *  THEN continue (ignore it)
             */
            if (UNUSED_OPT( pOD ))
                continue;

            if ((pOD->fOptState & OPTST_NO_INIT) != 0)
                continue;

            if (  (pOD->optEquivIndex != NO_EQUIVALENT)
               && (pOD->optEquivIndex != pOD->optIndex))
                continue;

            /*
             *  Set a temporary pointer to the real option description
             *  (i.e. account for equivalencing)
             */
            p = ((pOD->fOptState & OPTST_EQUIVALENCE) != 0)
                ? (pOpts->pOptDesc + pOD->optActualIndex) : pOD;

            /*
             *  IF    no arguments are allowed
             *  THEN just print the name and continue
             */
            if (p->optArgType == ARG_NONE) {
                fprintf( fp, "%c%s\n", (DISABLED_OPT( p )) ? '+' : ' ',
                         p->pz_Name );
                continue;
            }

            /*
             *  IF the supplied argument is empty
             *  THEN we will not put the option in the RC file
             */
            if (  ((p->fOptState & OPTST_NUMERIC) == 0)
               && (  (p->pzLastArg  == (char*)NULL)
                  || (p->pzLastArg[0] == '\0')
               )  )
                continue;

            if ((p->fOptState & OPTST_STACKED) == 0)
                printEntry( fp, p, p->pzLastArg );
            else {
                tArgList*  pAL = (tArgList*)p->optCookie;
                int        ct  = pAL->useCt;
                char**     ppz = pAL->apzArgs;
                while (ct-- > 0)
                    printEntry( fp, p, *(ppz++) );
            }
        }

        fclose( fp );
    }
}
