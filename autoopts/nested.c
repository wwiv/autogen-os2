
/*
 *  $Id: nested.c,v 4.4 2005/02/23 00:09:53 bkorb Exp $
 *  Time-stamp:      "2005-02-22 12:27:43 bkorb"
 *
 *   Automated Options Nested Values module.
 */

/*
 *  Automated Options copyright 1992-2005 Bruce Korb
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
/* = = = START-STATIC-FORWARD = = = */
/* static forward declarations maintained by :mkfwd */
static void
removeBackslashes( char* pzSrc );

static const char*
scanQuotedString( const char* pzTxt );

static tNameValue*
addStringValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen );

static tNameValue*
addBoolValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen );

static tNameValue*
addNumberValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen );

static tNameValue*
addNestedValue( void** pp, const char* pzName, size_t nameLen,
                char* pzValue, size_t dataLen, tOptionLoadMode mode );

static const char*
scanNameEntry( const char* pzName, tOptionValue* pRes, tOptionLoadMode mode );

static const char*
scanXmlEntry( const char* pzName, tOptionValue* pRes, tOptionLoadMode mode );
/* = = = END-STATIC-FORWARD = = = */

/*  removeBackslashes
 *
 *  This function assumes that all newline characters were preceeded by
 *  backslashes that need removal.
 */
static void
removeBackslashes( char* pzSrc )
{
    char* pzD = strchr(pzSrc, '\n');

    if (pzD == NULL)
        return;
    *--pzD = '\n';

    for (;;) {
        char ch = ((*pzD++) = *(pzSrc++));
        switch (ch) {
        case '\n': *--pzD = ch; break;
        case NUL:  return;
        default:
            ;
        }
    }
}


/*  scanQuotedString
 *
 *  Find the end of a quoted string, skipping escaped quote characters.
 */
static const char*
scanQuotedString( const char* pzTxt )
{
    char q = *(pzTxt++); /* remember the type of quote */

    for (;;) {
        char ch = *(pzTxt++);
        if (ch == NUL)
            return pzTxt-1;

        if (ch == q)
            return pzTxt;

        if (ch == '\\') {
            ch = *(pzTxt++);
            /*
             *  IF the next character is NUL, drop the backslash, too.
             */
            if (ch == NUL)
                return pzTxt - 2;

            /*
             *  IF the quote character or the escape character were escaped,
             *  then skip both, as long as the string does not end.
             */
            if ((ch == q) || (ch == '\\')) {
                if (*(pzTxt++) == NUL)
                    return pzTxt-1;
            }
        }
    }
}


/*  addStringValue
 *
 *  Associate a name with either a string or no value.
 */
static tNameValue*
addStringValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen )
{
    tNameValue* pNV;
    size_t sz = nameLen + dataLen + sizeof(*pNV);

    pNV = AGALOC( sz, "option name/str value pair" );
    if (pNV == NULL)
        return NULL;

    if (pzValue == NULL) {
        pNV->val.valType = OPARG_TYPE_NONE;
        pNV->pzName = pNV->val.v.strVal;

    } else {
        pNV->val.valType = OPARG_TYPE_STRING;
        if (dataLen > 0)
            memcpy( pNV->val.v.strVal, pzValue, dataLen );
        pNV->val.v.strVal[dataLen] = NUL;
        pNV->pzName = pNV->val.v.strVal + dataLen + 1;
    }

    memcpy( pNV->pzName, pzName, nameLen );
    pNV->pzName[ nameLen ] = NUL;
    addArgListEntry( pp, pNV );
    return pNV;
}


/*  addBoolValue
 *
 *  Associate a name with either a string or no value.
 */
static tNameValue*
addBoolValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen )
{
    tNameValue* pNV;
    size_t sz = nameLen + sizeof(*pNV) + 1;

    pNV = AGALOC( sz, "option name/bool value pair" );
    if (pNV == NULL)
        return NULL;
    while (isspace( *pzValue ) && (dataLen > 0)) {
        dataLen--; pzValue++;
    }
    if (dataLen == 0)
        pNV->val.v.boolVal = 0;
    else if (isdigit( *pzValue ))
        pNV->val.v.boolVal = atoi( pzValue );
    else switch (*pzValue) {
    case 'f':
    case 'F':
    case 'n':
    case 'N':
        pNV->val.v.boolVal = 0; break;
    default:
        pNV->val.v.boolVal = 1;
    }

    pNV->val.valType = OPARG_TYPE_BOOLEAN;
    pNV->pzName = (char*)(pNV + 1);
    memcpy( pNV->pzName, pzName, nameLen );
    pNV->pzName[ nameLen ] = NUL;
    addArgListEntry( pp, pNV );
    return pNV;
}


/*  addNumberValue
 *
 *  Associate a name with either a string or no value.
 */
static tNameValue*
addNumberValue( void** pp, const char* pzName, size_t nameLen,
                const char* pzValue, size_t dataLen )
{
    tNameValue* pNV;
    size_t sz = nameLen + sizeof(*pNV) + 1;

    pNV = AGALOC( sz, "option name/bool value pair" );
    if (pNV == NULL)
        return NULL;
    while (isspace( *pzValue ) && (dataLen > 0)) {
        dataLen--; pzValue++;
    }
    if (dataLen == 0)
        pNV->val.v.boolVal = 0;
    else
        pNV->val.v.boolVal = atoi( pzValue );

    pNV->val.valType = OPARG_TYPE_NUMERIC;
    pNV->pzName = (char*)(pNV + 1);
    memcpy( pNV->pzName, pzName, nameLen );
    pNV->pzName[ nameLen ] = NUL;
    addArgListEntry( pp, pNV );
    return pNV;
}


/*  addNestedValue
 *
 *  Associate a name with either a string or no value.
 */
static tNameValue*
addNestedValue( void** pp, const char* pzName, size_t nameLen,
                char* pzValue, size_t dataLen, tOptionLoadMode mode )
{
    tNameValue* pNV;
    size_t sz = nameLen + sizeof(*pNV) + 1;

    pNV = AGALOC( sz, "option name/bool value pair" );
    if (pNV == NULL)
        return NULL;

    if (dataLen == 0)
        pNV->val.v.nestVal = NULL;
    else {
        tOptionValue* pOV;
        char ch = pzValue[ dataLen ];
        pzValue[ dataLen ] = NUL;
        pOV = optionLoadNested( pzValue, mode );
        pNV->val.v.nestVal = pOV->v.nestVal;
        free( pOV );
        pzValue[ dataLen ] = ch;
    }

    pNV->val.valType = OPARG_TYPE_HIERARCHY;
    pNV->pzName = (char*)(pNV + 1);
    memcpy( pNV->pzName, pzName, nameLen );
    pNV->pzName[ nameLen ] = NUL;
    addArgListEntry( pp, pNV );
    return pNV;
}


/*  scanNameEntry
 *
 *  We have an entry that starts with a name.  Find the end of it, cook it
 *  (if called for) and create the name/value association.
 */
static const char*
scanNameEntry( const char* pzName, tOptionValue* pRes, tOptionLoadMode mode )
{
    tNameValue* pNV;
    const char* pzScan = pzName+1;
    const char* pzVal;
    size_t nameLen = 1;
    size_t dataLen = 0;

    while (ISNAMECHAR( *pzScan ))  { pzScan++; nameLen++; }

    while (isspace( *pzScan )) {
        char ch = *(pzScan++);
        if ((ch == '\n') || (ch == ',')) {
            addStringValue( &(pRes->v.nestVal), pzName, nameLen, NULL, 0 );
            return pzScan - 1;
        }
    }

    switch (*pzScan) {
    case '=':
    case ':':
        while (isspace( *++pzScan ))  ;
        switch (*pzScan) {
        case ',':  goto comma_char;
        case '"':
        case '\'': goto quote_char;
        case NUL:  addStringValue( &(pRes->v.nestVal), pzName, nameLen, NULL, 0);
                   goto leave_scan_name;
        default:   goto default_char;
        }

    case ',':
    comma_char:
        pzScan++;
        /* FALLTHROUGH */

    case NUL:
    no_value:
        addStringValue( &(pRes->v.nestVal), pzName, nameLen, NULL, 0 );
        break;

    case '"':
    case '\'':
    quote_char:
        pzVal = pzScan;
        pzScan = scanQuotedString( pzScan );
        dataLen = pzScan - pzVal;
        pNV = addStringValue( &(pRes->v.nestVal), pzName, nameLen,
                              pzVal, dataLen );
        if ((pNV != NULL) && (mode == OPTION_LOAD_COOKED))
            ao_string_cook( pNV->val.v.strVal, NULL );
        break;

    default:
    default_char:
        /*
         *  We have found some strange text value.  It ends with a newline
         *  or a comma.
         */
        pzVal = pzScan;
        for (;;) {
            char ch = *(pzScan++);
            switch (ch) {
            case '\n':
                if ((pzScan > pzVal + 2) && (pzScan[-2] == '\\'))
                    continue;
                /* FALLTHROUGH */

            case ',':
                dataLen = (pzScan - pzVal) - 1;
                pNV = addStringValue( &(pRes->v.nestVal), pzName, nameLen,
                                      pzVal, dataLen );
                if (pNV != NULL)
                    removeBackslashes( pNV->val.v.strVal );
                goto leave_scan_name;
            }
        }
        break;
    } leave_scan_name:;

    return pzScan;
}


/*  scanXmlEntry
 *
 *  We've found a '<' character.  We ignore this if it is a comment or a
 *  directive.  If it is something else, then whatever it is we are looking
 *  at is bogus.  Returning NULL stops processing.
 */
static const char*
scanXmlEntry( const char* pzName, tOptionValue* pRes, tOptionLoadMode mode )
{
    size_t nameLen = 1, valLen = 0;
    const char* pzScan = ++pzName;
    const char* pzVal;
    tOptionValue    valu;

    if (! isalpha(*pzName)) {
        switch (*pzName) {
        default:
            pzName = NULL;
            break;

        case '!':
            pzName = strstr( pzName, "-->" );
            if (pzName != NULL)
                pzName += 3;
            break;

        case '?':
            pzName = strchr( pzName, '>' );
            if (pzName != NULL)
                pzName++;
            break;
        }
        return pzName;
    }

    while (isalpha( *++pzScan ))  nameLen++;
    if (nameLen > 64)
        return NULL;

    switch (*pzScan) {
    case ' ':
    case '\t':
        pzScan = parseAttributes( NULL, (char*)pzScan, &mode, &valu );
        if (*pzScan == '>') {
            pzScan++;
            break;
        }

        if (*pzScan != '/')
            return NULL;
        /* FALLTHROUGH */

    case '/':
        if (*++pzScan != '>')
            return NULL;
        addStringValue( &(pRes->v.nestVal), pzName, nameLen, NULL, 0 );
        return pzScan+2;

    default:  return NULL;
    case '>': break;
    }

    pzVal = pzScan;

    {
        char z[68];
        char* pzD = z;
        int  ct = nameLen;
        const char* pzS = pzName;

        *(pzD++) = '<';
        *(pzD++) = '/';

        do  {
            *(pzD++) = *(pzS++);
        } while (--ct > 0);
        *(pzD++) = '>';
        *pzD = NUL;

        pzScan = strstr( pzScan, z );
        if (pzScan == NULL)
            return NULL;
        valLen = (pzScan - pzVal);
        pzScan += nameLen + 3;
    }

    switch (valu.valType) {
    case OPARG_TYPE_NONE:
        addStringValue( &(pRes->v.nestVal), pzName, nameLen, NULL, 0 );
        break;

    case OPARG_TYPE_STRING:
        addStringValue( &(pRes->v.nestVal), pzName, nameLen, pzVal, valLen );
        break;

    case OPARG_TYPE_BOOLEAN:
        addBoolValue(   &(pRes->v.nestVal), pzName, nameLen, pzVal, valLen );
        break;

    case OPARG_TYPE_NUMERIC:
        addNumberValue( &(pRes->v.nestVal), pzName, nameLen, pzVal, valLen );
        break;

    case OPARG_TYPE_HIERARCHY:
    {
        char* pz = AGALOC( valLen+1, "hierarchical scan" );
        if (pz == NULL)
            break;
        memcpy( pz, pzVal, valLen );
        pz[valLen] = NUL;
        addNestedValue( &(pRes->v.nestVal), pzName, nameLen, pz, valLen, mode );
        free(pz);
        break;
    }

    case OPARG_TYPE_ENUMERATION:
    case OPARG_TYPE_MEMBERSHIP:
    default:
        break;
    }

    return pzScan;
}


static void
unloadNestedArglist( tArgList* pAL )
{
    int ct = pAL->useCt;
    tNameValue** ppNV = (tNameValue**)(pAL->apzArgs);

    while (ct-- > 0) {
        tNameValue* pNV = *(ppNV++);
        if (pNV->val.valType == OPARG_TYPE_HIERARCHY)
            unloadNestedArglist( pNV->val.v.nestVal );
        free( pNV );
    }

    free( (void*)pAL );
}


/*=export_func  optionUnloadNested
 *
 * what:  Deallocate the memory for a nested value
 * arg:   + const tOptionValue* + pOptVal + the hierarchical value +
 *
 * doc:
 *  A nested value needs to be deallocated.
=*/
void
optionUnloadNested( const tOptionValue* pOV )
{
    if (pOV == NULL) return;
    if (pOV->valType != OPARG_TYPE_HIERARCHY) {
        errno = EINVAL;
        return;
    }

    unloadNestedArglist( pOV->v.nestVal );

    free( (void*)pOV );
}


/*=export_func  optionLoadNested
 * private:
 *
 * what:  parse a hierarchical option argument
 * arg:   + const char*     + pzTxt + the text to scan +
 * arg:   + tOptionLoadMode + mode  + the value formation mode    +
 *
 * ret_type:  tOptionValue*
 * ret_desc:  An allocated, compound value structure
 *
 * doc:
 *  A nested value needs to be parsed
=*/
tOptionValue*
optionLoadNested( const char* pzTxt, tOptionLoadMode mode )
{
    int  startOfLine = 1;
    tOptionValue* pRes;
    tArgList* pAL;

    /*
     *  Make sure we have some data and we have space to put what we find.
     */
    if (pzTxt == NULL)
        return NULL;
    while (isspace( *pzTxt ))  pzTxt++;
    if (*pzTxt == NUL)
        return NULL;
    pRes = AGALOC( sizeof(*pRes), "nested args" );
    if (pRes == NULL)
        return NULL;
    pRes->valType   = OPARG_TYPE_HIERARCHY;
    pAL = AGALOC( sizeof(*pAL), "nested arg list" );
    if (pAL == NULL) {
        free( pRes );
        return NULL;
    }
    pRes->v.nestVal = pAL;
    pAL->useCt   = 0;
    pAL->allocCt = MIN_ARG_ALLOC_CT;

    /*
     *  Scan until we hit a NUL.
     */
    do  {
        while (isspace( *pzTxt ))  pzTxt++;
        if (isalpha( *pzTxt )) {
            pzTxt = scanNameEntry( pzTxt, pRes, mode );
        }
        else switch (*pzTxt) {
        case NUL: goto scan_done;
        case '<': pzTxt = scanXmlEntry( pzTxt, pRes, mode ); break;
        case '#': pzTxt = strchr( pzTxt, '\n' );             break;
        default:  goto woops;
        }
    } while (pzTxt != NULL); scan_done:;

    pAL = pRes->v.nestVal;
    if (pAL->useCt != 0)
        return pRes;

 woops:
    free( pRes->v.nestVal );
    free( pRes );
    return NULL;
}


/*=export_func  optionNestedVal
 * private:
 *
 * what:  parse a hierarchical option argument
 * arg:   + tOptions* + pOpts    + program options descriptor +
 * arg:   + tOptDesc* + pOptDesc + the descriptor for this arg +
 *
 * doc:
 *  Nested value was found on the command line
=*/
void
optionNestedVal( tOptions* pOpts, tOptDesc* pOD )
{
    tOptionValue* pOV = optionLoadNested(pOD->pzLastArg, OPTION_LOAD_UNCOOKED);

    if (pOV != NULL)
        addArgListEntry( &(pOD->optCookie), (void*)pOV );
}
/*
 * Local Variables:
 * mode: C
 * c-file-style: "stroustrup"
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 * end of autoopts/nested.c */