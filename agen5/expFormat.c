
/*
 *  expFormat.c
 *  $Id: expFormat.c,v 1.20 2000/08/13 21:20:24 bkorb Exp $
 *  This module implements formatting expression functions.
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
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with AutoGen.  See the file "COPYING".  If not,
 *  write to:  The Free Software Foundation, Inc.,
 *             59 Temple Place - Suite 330,
 *             Boston,  MA  02111-1307, USA.
 */

static const char zGpl[] =
"%2$s%1$s is free software.\n%2$s\n"
"%2$sYou may redistribute it and/or modify it under the terms of the\n"
"%2$sGNU General Public License, as published by the Free Software\n"
"%2$sFoundation; either version 2, or (at your option) any later version.\n"
"%2$s\n"
"%2$s%1$s is distributed in the hope that it will be useful,\n"
"%2$sbut WITHOUT ANY WARRANTY; without even the implied warranty of\n"
"%2$sMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
"%2$sSee the GNU General Public License for more details.\n"
"%2$s\n"
"%2$sYou should have received a copy of the GNU General Public License\n"
"%2$salong with %1$s.  See the file \"COPYING\".  If not,\n"
"%2$swrite to:  The Free Software Foundation, Inc.,\n"
"%2$s           59 Temple Place - Suite 330,\n"
"%2$s           Boston,  MA  02111-1307, USA.";

static const char zLgpl[] =
"%2$s%1$s is free software.\n%2$s\n"
"%2$sYou may redistribute it and/or modify it under the terms of the\n"
"%2$sGNU General Public License, as published by the Free Software\n"
"%2$sFoundation; either version 2, or (at your option) any later version.\n"
"%2$s\n"
"%2$s%1$s is distributed in the hope that it will be useful,\n"
"%2$sbut WITHOUT ANY WARRANTY; without even the implied warranty of\n"
"%2$sMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
"%2$sSee the GNU General Public License for more details.\n"
"%2$s\n"
"%2$sYou should have received a copy of the GNU General Public License\n"
"%2$salong with %1$s.  See the file \"COPYING\".  If not,\n"
"%2$swrite to:  The Free Software Foundation, Inc.,\n"
"%2$s           59 Temple Place - Suite 330,\n"
"%2$s           Boston,  MA  02111-1307, USA.\n"
"%2$s\n"
"%2$sAs a special exception, %3$s gives permission for additional\n"
"%2$suses of the text contained in the release of %1$s.\n"
"%2$s\n"
"%2$sThe exception is that, if you link the %1$s library with other\n"
"%2$sfiles to produce an executable, this does not by itself cause the\n"
"%2$sresulting executable to be covered by the GNU General Public License.\n"
"%2$sYour use of that executable is in no way restricted on account of\n"
"%2$slinking the %1$s library code into it.\n"
"%2$s\n"
"%2$sThis exception does not however invalidate any other reasons why\n"
"%2$sthe executable file might be covered by the GNU General Public License.\n"
"%2$s\n"
"%2$sThis exception applies only to the code released by %3$s under\n"
"%2$sthe name %1$s.  If you copy code from other sources under the\n"
"%2$sGeneral Public License into a copy of %1$s, as the General Public\n"
"%2$sLicense permits, the exception does not apply to the code that you add\n"
"%2$sin this way.  To avoid misleading anyone as to the status of such\n"
"%2$smodified files, you must delete this exception notice from them.\n"
"%2$s\n"
"%2$sIf you write modifications of your own for %1$s, it is your choice\n"
"%2$swhether to permit this exception to apply to your modifications.\n"
"%2$sIf you do not wish that, delete this exception notice.";

static const char zBsd[] =
"%2$s%1$s is free software copyrighted by %3$s.\n%2$s\n"
"%2$sRedistribution and use in source and binary forms, with or without\n"
"%2$smodification, are permitted provided that the following conditions\n"
"%2$sare met:\n"
"%2$s1. Redistributions of source code must retain the above copyright\n"
"%2$s   notice, this list of conditions and the following disclaimer.\n"
"%2$s2. Redistributions in binary form must reproduce the above copyright\n"
"%2$s   notice, this list of conditions and the following disclaimer in the\n"
"%2$s   documentation and/or other materials provided with the distribution.\n"
"%2$s3. Neither the name ``%3$s'' nor the name of any other\n"
"%2$s   contributor may be used to endorse or promote products derived\n"
"%2$s   from this software without specific prior written permission.\n"
"%2$s\n"
"%2$sTHIS SOFTWARE IS PROVIDED BY %3$s ``AS IS'' AND \n"
"%2$sANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n"
"%2$sIMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR\n"
"%2$sPURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS\n"
"%2$sBE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR\n"
"%2$sCONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF\n"
"%2$sSUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR\n"
"%2$sBUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,\n"
"%2$sWHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR\n"
"%2$sOTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF\n"
"%2$sADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";

static const char zDne[] =
"%1$sDO NOT EDIT THIS FILE   (%2$s)\n"
"%1$s\n"
"%1$sIt has been AutoGen-ed  %3$s\n"
"%1$sFrom the definitions    %4$s\n"
"%1$sand the template file   %5$s";

#include <string.h>

#include "autogen.h"
#include <guile/gh.h>
#include "expGuile.h"
#include "expr.h"

#ifndef HAVE_STRFTIME
#  include "compat/strftime.c"
#endif

tSCC zFmtAlloc[] = "asprintf allocation";


/*=gfunc dne
 *
 * what:  '"Do Not Edit" warning'
 *
 * exparg: prefix, string for starting each output line
 * doc:  Generate a "Do Not Edit" warning string.
 *       The argument is a per-line string prefix.
=*/
    SCM
ag_scm_dne( SCM prefix )
{
    char*    pzPfx;
    char*    pzRes;
    SCM      res;
    char     zTimeBuf[ 128 ];

    if (! gh_string_p( prefix ))
        return SCM_UNDEFINED;
    pzPfx = SCM_CHARS( prefix );

    {
        time_t    curTime = time( (time_t*)NULL );
        struct tm*  pTime = localtime( &curTime );
        strftime( zTimeBuf, 128, "%A %B %e, %Y at %r %Z", pTime );
    }

    pzRes = asprintf( zDne, pzPfx, pCurFp->pzName,
                      zTimeBuf, OPT_ARG( DEFINITIONS ), pzTemplFileName );

    if (pzRes == (char*)NULL) {
        fprintf( stderr, zAllocErr, pzProg, -1, "Do-Not-Edit string" );
        LOAD_ABORT( pCurTemplate, pCurMacro, zFmtAlloc );
    }

    res = gh_str02scm( pzRes );
    AGFREE( (void*)pzRes );
    return res;
}


/*=gfunc error
 *
 * what:  display message and exit
 *
 * exparg: @message@message to display before exiting@@
 * doc:
 *
 *  The argument is a string that printed out as part of an error
 *  message.  The message is formed from the formatting string:
 *
 *  @example
 *  DEFINITIONS ERROR in %s line %d for %s:  %s\n
 *  @end example
 *
 *  The first three arguments to this format are provided by the
 *  routine and are: The name of the template file, the line within
 *  the template where the error was found, and the current output
 *  file name.
 *
 *  After displaying the message, the current output file is removed
 *  and autogen exits with the EXIT_FAILURE error code.  IF, however,
 *  the argument is the number 0 (zero), then processing continues
 *  with the next suffix.
=*/
    SCM
ag_scm_error( SCM res )
{
    tSCC      zFmt[]    = "DEFINITIONS %s in %s line %d for %s:\n\t%s\n";
    tSCC      zErr[]    = "ERROR";
    tSCC      zWarn[]   = "Warning";
    tSCC      zBadMsg[] = "??? indecipherable error message ???";
    tCC*      pzMsg;
    tSuccess  abort = FAILURE;
    char      zNum[16];

    switch (gh_type_e( res )) {
    case GH_TYPE_BOOLEAN:
        if (SCM_FALSEP( res ))
            abort = PROBLEM;
        pzMsg = "";
        break;

    case GH_TYPE_NUMBER:
    {
        long val = gh_scm2long( res );
        if (val == 0)
            abort = PROBLEM;
        snprintf( zNum, sizeof( zNum ), "%d", val );
        pzMsg = zNum;
        break;
    }

    case GH_TYPE_CHAR:
        zNum[0] = gh_scm2char( res );
        if ((zNum[0] == '\0') || (zNum[0] == '0'))
            abort = PROBLEM;
        zNum[1] = NUL;
        pzMsg = zNum;
        break;

    case GH_TYPE_STRING:
        pzMsg = SCM_CHARS( res );
        while (isspace( *pzMsg )) pzMsg++;
        /*
         *  IF the message starts with the number zero,
         *    OR the message is the empty string,
         *  THEN this is just a warning that is ignored
         */
        if (  (  isdigit( *pzMsg )
              && (strtol( pzMsg, (char**)NULL, 0 ) == 0))
           || (*pzMsg == '\0')  )
            abort = PROBLEM;
        break;

    default:
        pzMsg = zBadMsg;
    }

    /*
     *  IF there is a message,
     *  THEN print it.
     */
    if (*pzMsg != '\0')
        fprintf( stderr, zFmt, (abort != PROBLEM) ? zErr : zWarn,
                 pCurTemplate->pzFileName, pCurMacro->lineNo,
                 pCurFp->pzName, pzMsg );
    longjmp( fileAbort, abort );
    /* NOTREACHED */
    return SCM_UNDEFINED;
}


/*=gfunc gpl
 *
 * what:  GNU public license
 *
 * exparg: prog-name, name of the program under the GPL
 * exparg: prefix, String for starting each output line
 *
 * doc:
 *  Emit a string that contains the GNU Public License.  It
 *  takes two arguments: @code{prefix} contains the string to start
 *  each output line, and
 *  @code{prog_name} contains the name of the program the copyright is
 *  about.
 *
=*/
    SCM
ag_scm_gpl( SCM prog_name, SCM prefix )
{
    char*     pzName;
    char*     pzPfx;
    char*     pzRes;
    SCM       res;

    if (! (   gh_string_p( prog_name )
           && gh_string_p( prefix )))
        return SCM_UNDEFINED;

    pzName  = SCM_CHARS( prog_name );
    pzPfx   = SCM_CHARS( prefix );

    pzRes = asprintf( zGpl, pzName, pzPfx );

    if (pzRes == (char*)NULL) {
        fprintf( stderr, zAllocErr, pzProg, -1, "GPL string" );
        LOAD_ABORT( pCurTemplate, pCurMacro, zFmtAlloc );
    }

    res = gh_str02scm( pzRes );
    AGFREE( (void*)pzRes );
    return res;
}


/*=gfunc lgpl
 *
 * what:  GNU lib public license
 *
 * exparg: prog_name, name of the program under the LGPL
 * exparg: owner, Grantor of the LGPL
 * exparg: prefix, String for starting each output line
 *
 * doc:
 *  Emit a string that contains the GNU Library Public License.  It
 *  takes three arguments: @code{prefix} contains the string to start
 *  each output line.  @code{owner} contains the copyright owner.
 *  @code{prog_name} contains the name of the program the copyright is
 *  about.
 *
=*/
    SCM
ag_scm_lgpl( SCM prog_name, SCM owner, SCM prefix )
{
    char*     pzName;
    char*     pzPfx;
    char*     pzOwner;
    char*     pzRes;
    SCM       res;

    if (! (   gh_string_p( prog_name )
           && gh_string_p( owner )
           && gh_string_p( prefix )))
        return SCM_UNDEFINED;

    pzName  = SCM_CHARS( prog_name );
    pzPfx   = SCM_CHARS( prefix );
    pzOwner = SCM_CHARS( owner );

    pzRes = asprintf( zLgpl, pzName, pzPfx, pzOwner );

    if (pzRes == (char*)NULL) {
        fprintf( stderr, zAllocErr, pzProg, -1, "LGPL string" );
        LOAD_ABORT( pCurTemplate, pCurMacro, zFmtAlloc );
    }

    res = gh_str02scm( pzRes );
    AGFREE( (void*)pzRes );
    return res;
}


/*=gfunc bsd
 *
 * what:  Free BSD public license
 *
 * exparg: prog_name, name of the program under the BSD
 * exparg: owner, Grantor of the BSD License
 * exparg: prefix, String for starting each output line
 *
 * doc:
 *  Emit a string that contains the Free BSD Public License.  It
 *  takes three arguments: @code{prefix} contains the string to start
 *  each output line.  @code{owner} contains the copyright owner.
 *  @code{prog_name} contains the name of the program the copyright is
 *  about.
 *
=*/
    SCM
ag_scm_bsd( SCM prog_name, SCM owner, SCM prefix )
{
    char*     pzName;
    char*     pzPfx;
    char*     pzOwner;
    char*     pzRes;
    SCM       res;

    if (! (   gh_string_p( prog_name )
           && gh_string_p( owner )
           && gh_string_p( prefix )))
        return SCM_UNDEFINED;

    pzName  = SCM_CHARS( prog_name );
    pzPfx   = SCM_CHARS( prefix );
    pzOwner = SCM_CHARS( owner );

    pzRes = asprintf( zBsd, pzName, pzPfx, pzOwner );

    if (pzRes == (char*)NULL) {
        fprintf( stderr, zAllocErr, pzProg, -1, "BSD string" );
        LOAD_ABORT( pCurTemplate, pCurMacro, zFmtAlloc );
    }

    res = gh_str02scm( pzRes );
    AGFREE( (void*)pzRes );
    return res;
}


/*=gfunc license
 *
 * what:  an arbitrary license
 *
 * exparg: lic_name, file name of the license
 * exparg: prog_name, name of the licensed program or library
 * exparg: owner, Grantor of the License
 * exparg: prefix, String for starting each output line
 *
 * doc:
 *  Emit a string that contains the named license.  The license text
 *  is read from a file named, @code{lic_name}.lic, searching the standard
 *  directories.  The file contents are used as a format argument
 *  to @code{printf}(3), with @code{prog_name} and @code{owner} as
 *  the two string formatting arguments.  Each output line is automatically
 *  prefixed with the string @code{prefix}.
=*/
    SCM
ag_scm_license( SCM license, SCM prog_name, SCM owner, SCM prefix )
{
    static tMapInfo mi = { NULL, 0, 0, NULL };

    char*     pzRes;
    SCM       res;

    if (! (   gh_string_p( license )
           && gh_string_p( prog_name )
           && gh_string_p( owner )
           && gh_string_p( prefix )))
        return SCM_UNDEFINED;

    {
        char* pzLicense = SCM_CHARS( license );

        /*
         *  Set the current file name.
         *  If it changes, then unmap the old data
         */
        if (mi.pzFileName == NULL)
            AGDUPSTR( mi.pzFileName, pzLicense );

        else if (strcmp( mi.pzFileName, pzLicense ) != 0) {
            munmap( mi.pData, mi.size );
            close( mi.fd );
            mi.pData = NULL;
            AGFREE( (void*)mi.pzFileName );
            AGDUPSTR( mi.pzFileName, pzLicense );
        }
    }

    /*
     *  Make sure the data are loaded and trim any white space
     */
    if (mi.pData == (char*)NULL) {
	char* pz;
        tSCC*  apzSfx[] = { "lic", NULL };

        mapDataFile( mi.pzFileName, &mi, apzSfx );

	pz = (char*)mi.pData + mi.size - 1;
	while (isspace( pz[-1] )) pz--;
	*pz = NUL;
    }

    /*
     *  Reformat the string with the given arguments
     */
    {
        char*  pzName   = SCM_CHARS( prog_name );
        char*  pzOwner  = SCM_CHARS( owner );

        pzRes = asprintf( (char*)mi.pData, pzName, pzOwner );

        if (pzRes == (char*)NULL) {
            fprintf( stderr, zAllocErr, pzProg, -1, "license string" );
            LOAD_ABORT( pCurTemplate, pCurMacro, zFmtAlloc );
        }
    }

    {
        char*   pzPfx    = SCM_CHARS( prefix );
        char*   pzScan   = pzRes;
        char*   pzOut;
        size_t  pfx_size = strlen( pzPfx );
        size_t  out_size = pfx_size + 1;

        /*
         *  Figure out how much space we need (text size plus
         *  a prefix size for each newline)
         */
        for (;;) {
            switch (*(pzScan++)) {
            case NUL:
                goto exit_count;
            case '\n':
                out_size += pfx_size;
                /* FALLTHROUGH */
            default:
                out_size++;
            }
        } exit_count:;

        /*
         *  Create our output buffer and insert the first prefix
         */
        res    = scm_makstr( out_size, 0 );
        pzOut  = SCM_CHARS( res );
        strcpy( pzOut, pzPfx );
        pzOut += pfx_size;
        pzScan = pzRes;

        for (;;) {
            switch (*(pzOut++) = *(pzScan++)) {
            case NUL:
                goto exit_copy;

            case '\n':
                strcpy( pzOut, pzPfx );
                pzOut += pfx_size;
                break;

            default:
                break;
            }
        }
    } exit_copy:;

    /*
     *  We allocated a temporary buffer that has all the formatting done,
     *  but need the prefixes on each line.
     */
    AGFREE( (void*)pzRes );

    return res;
}
/* end of expFormat.c */
