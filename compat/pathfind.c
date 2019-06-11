/*  -*- Mode: C -*-  */

/* pathfind.c --- find a FILE  MODE along PATH */

/* Author: Gary V Vaughan <gvaughan@oranda.demon.co.uk> */

/* Code: */

static char *
pathfind( char const * path,
          char const * fname,
          char const * mode );

#include "compat.h"
#ifndef HAVE_PATHFIND
#if defined(__windows__) && !defined(__CYGWIN__)
static char *
pathfind( char const * path,
          char const * fname,
          char const * mode )
{
    return strdup(fname);
}
#else

static char * make_absolute(char const * string, char const * dot_path);
static char * canonicalize_pathname(char * path);
static char * extract_colon_unit(char * dir, char const * string, int * p_index);

/**
 * local implementation of pathfind.
 * @param[in] path  colon separated list of directories
 * @param[in] fname the name we are hunting for
 * @param[in] mode  the required file mode
 * @returns an allocated string with the full path, or NULL
 */
static char *
pathfind( char const * path,
          char const * fname,
          char const * mode )
{
    int    p_index   = 0;
    int    mode_bits = 0;
    char * res_path  = NULL;
    char   zPath[ AG_PATH_MAX + 1 ];

    if (strchr( mode, 'r' )) mode_bits |= R_OK;
    if (strchr( mode, 'w' )) mode_bits |= W_OK;
    if (strchr( mode, 'x' )) mode_bits |= X_OK;

    /*
     *  FOR each non-null entry in the colon-separated path, DO ...
     */
    for (;;) {
        DIR  * dirP;
        char * colon_unit = extract_colon_unit( zPath, path, &p_index );

        if (colon_unit == NULL)
            break;

        dirP = opendir( colon_unit );

        /*
         *  IF the directory is inaccessable, THEN next directory
         */
        if (dirP == NULL)
            continue;

        for (;;) {
            struct dirent *entP = readdir( dirP );

            if (entP == (struct dirent *)NULL)
                break;

            /*
             *  IF the file name matches the one we are looking for, ...
             */
            if (strcmp(entP->d_name, fname) == 0) {
                char * abs_name = make_absolute(fname, colon_unit);

                /*
                 *  Make sure we can access it in the way we want
                 */
                if (access(abs_name, mode_bits) >= 0) {
                    /*
                     *  We can, so normalize the name and return it below
                     */
                    res_path = canonicalize_pathname(abs_name);
                }

                free(abs_name);
                break;
            }
        }

        closedir( dirP );

        if (res_path != NULL)
            break;
    }

    return res_path;
}

/*
 * Turn STRING  (a pathname) into an  absolute  pathname, assuming  that
 * DOT_PATH contains the symbolic location of  `.'.  This always returns
 * a new string, even if STRING was an absolute pathname to begin with.
 */
static char *
make_absolute( char const * string, char const * dot_path )
{
    char * result;
    int result_len;

    if (!dot_path || *string == '/') {
        result = strdup( string );
    } else {
        if (dot_path && dot_path[0]) {
            result = malloc( 2 + strlen( dot_path ) + strlen( string ) );
            strcpy( result, dot_path );
            result_len = (int)strlen(result);
            if (result[result_len - 1] != '/') {
                result[result_len++] = '/';
                result[result_len] = '\0';
            }
        } else {
            result = malloc( 3 + strlen( string ) );
            result[0] = '.'; result[1] = '/'; result[2] = '\0';
            result_len = 2;
        }

        strcpy( result + result_len, string );
    }

    return result;
}

/*
 *    Multiple `/'s     are collapsed to a single `/'.
 *    Leading `./'s     are removed.
 */
static char *
trim_path_leader( char * path )
{
    for (;;) {
        switch (*path) {
        case NUL:
            return NULL;

        case '.':
            if (path[1] != '/')
                return path;
            path += 2;
            continue;

        case '/':
            while (path[1] == '/')
                path++;
            return path;
        }
    }
}

/*
 *    Trailing `/.'s    are removed.
 *    Trailing `xxx/..'s   are removed.
 *    Trailing `/'s     are removed.
 */
static size_t
real_path_length( char * path )
{
    size_t res = strlen(path);

    for (;;) {
        char * end = path + res;
        switch (res) {
        default: // res >= 3
            if ((end[-1] == '.') &&
                (end[-2] == '.') &&
                (end[-3] == '/')) {
                res -= 3;
                while ((res > 0) && (path[res - 1] == '/'))
                    res--;
                continue;
            }
            /* FALLTHROUGH: */

        case 2:
            if ((res > 1) &&
                (end[-1] == '.') &&
                (end[-2] == '/')) {
                res -= 2;
                while ((res > 0) && (path[res - 1] == '/'))
                    res--;
                continue;
            }
            /* FALLTHROUGH: */

        case 1:
            if ((end[-1] == '/')) {
                res--;
                while ((res > 0) && (path[res - 1] == '/'))
                    res--;
                continue;
            }
            /* FALLTHROUGH: */

        case 0:
            return res;
        }
    }
}

static void
strip_up_dirs(char * path)
{
    static char const up_dir[] = "/../";
    static size_t const skip_up_dir_sz = sizeof(up_dir) - 1;

    char * scn;
 restart:
    scn = path;

    for (;;) {
        char * upone = scn = strstr(scn, up_dir);

        if (scn == NULL)
            return;

        upone += skip_up_dir_sz;

        /*
         * scan backward for DIR character or start of path.
         * IF start of path, then everything after "/../" is
         * the canonical path. Otherwise, remove the directory
         * name, "/" and the two dots.
         */
        for (;;) {
            if (scn <= path) {
                memmove(path, upone, strlen(upone) + 1);
                goto restart;
            }
            if (*(--scn) == '/')
                break;
        }
        /*
         * We found a "/", so remove the directory name
         */
        memmove(++scn, upone, strlen(upone) + 1);
    }
}

/*
 * Canonicalize PATH, and return a  new path.  The new path differs from
 * PATH in that:
 *
 *    Multiple `/'s     are collapsed to a single `/'.
 *    Leading `./'s     are removed.
 *    Trailing `/.'s    are removed.
 *    Trailing `/..'s   are removed.
 *    Trailing `/'s     are removed.
 *    Non-leading `../'s and trailing `..'s are handled by removing
 *                    portions of the path.
 */
static char *
canonicalize_pathname(char const * path)
{
    size_t psz;
    char * scn;
    char * res;

    path = trim_path_leader(path);
    if (path == NULL)
        goto leave_empty_handed;

    psz = real_path_length(path);
    if (psz == 0)
        goto leave_empty_handed;

    res = scn = malloc(psz + 1);
    memcpy(res, path, psz);
    res[psz] = '\0';

    /*
     * Strip no-op dirs
     */
    for (;;) {
        char * noop = strstr(scn, "/./");
        if (noop == NULL)
            break;
        memmove(noop, noop + 2, strlen(noop + 1));
        scn = noop;
    }

    strip_up_dirs(res);
    return res;

 leave_empty_handed:
    res  = malloc(2);
    res[0] = (*path == '/') ? '/' : '.';
    res[1] = NUL;
    return res;
}

/*
 * Given a  string containing units of information separated  by colons,
 * return the next one  pointed to by (P_INDEX), or NULL if there are no
 * more.  Advance (P_INDEX) to the character after the colon.
 */
static char *
extract_colon_unit(char * pzDir, char const * string, int * p_index)
{
    char * pzDest = pzDir;
    int    ix     = *p_index;

    if (string == NULL)
        return NULL;

    if ((unsigned)ix >= strlen( string ))
        return NULL;

    {
        char const * pzSrc = string + ix;

        while (*pzSrc == ':')  pzSrc++;

        for (;;) {
            char ch = (*(pzDest++) = *(pzSrc++));
            switch (ch) {
            case ':':
                pzDest[-1] = NUL;
                /* FALLTHROUGH */
            case NUL:
                goto copy_done;
            }

            if ((unsigned long)(pzDest - pzDir) >= AG_PATH_MAX)
                break;
        } copy_done:;

        ix = (int)(pzSrc - string);
    }

    if (*pzDir == NUL)
        return NULL;

    *p_index = ix;
    return pzDir;
}
#endif /* __windows__ / __CYGWIN__ */
#endif /* HAVE_PATHFIND */

/*
 * Local Variables:
 * mode: C
 * c-file-style: "stroustrup"
 * indent-tabs-mode: nil
 * End:
 * end of compat/pathfind.c */
