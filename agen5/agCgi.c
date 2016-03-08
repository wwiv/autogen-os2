
/**
 * @file agCgi.c
 *
 *  This is a CGI wrapper for AutoGen.  It will take POST-method
 *  name-value pairs and emit AutoGen definitions to a spawned
 *  AutoGen process.
 *
 *  This file is part of AutoGen.
 *  AutoGen Copyright (C) 1992-2016 by Bruce Korb - all rights reserved
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * AutoGen is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

typedef struct {
    char const * pzName;
    char *       pzValue;
} name_map_t;

#define ENV_TABLE \
    _ET_(SERVER_SOFTWARE) \
    _ET_(SERVER_NAME) \
    _ET_(GATEWAY_INTERFACE) \
    _ET_(SERVER_PROTOCOL) \
    _ET_(SERVER_PORT) \
    _ET_(REQUEST_METHOD) \
    _ET_(PATH_INFO) \
    _ET_(PATH_TRANSLATED) \
    _ET_(SCRIPT_NAME) \
    _ET_(QUERY_STRING) \
    _ET_(REMOTE_HOST) \
    _ET_(REMOTE_ADDR) \
    _ET_(AUTH_TYPE) \
    _ET_(REMOTE_USER) \
    _ET_(REMOTE_IDENT) \
    _ET_(CONTENT_TYPE) \
    _ET_(CONTENT_LENGTH) \
    _ET_(HTTP_ACCEPT) \
    _ET_(HTTP_USER_AGENT) \
    _ET_(HTTP_REFERER)

static name_map_t name_val_map[] = {
#define _ET_(n) { #n, NULL },
    ENV_TABLE
#undef _ET_
    { NULL, NULL }
};

typedef enum {
#define _ET_(n) n ## _IDX,
    ENV_TABLE
#undef _ET_
    NAME_CT
} name_idx_t;

#define pzCgiMethod name_val_map[ REQUEST_METHOD_IDX ].pzValue
#define pzCgiQuery  name_val_map[ QUERY_STRING_IDX   ].pzValue
#define pzCgiLength name_val_map[ CONTENT_LENGTH_IDX ].pzValue

/* = = = START-STATIC-FORWARD = = = */
static char *
parse_input(char * src, int len);
/* = = = END-STATIC-FORWARD = = = */

LOCAL void
load_cgi(void)
{
    /*
     *  Redirect stderr to a file.  If it gets used, we must trap it
     *  and emit the content-type: preamble before actually emitting it.
     *  First, tho, do a simple stderr->stdout redirection just in case
     *  we stumble before we're done with this.
     */
    dup2(STDOUT_FILENO, STDERR_FILENO);
    {
        FILE * fp = fdopen(STDERR_FILENO, "w" FOPEN_BINARY_FLAG);
        (void)fp;
    }
    {
        int tmpfd;
        oops_pfx = CGI_ERR_MSG_FMT;
        AGDUPSTR(cgi_stderr, CGI_TEMP_ERR_FILE_STR, "stderr file");
        tmpfd = mkstemp(cgi_stderr);
        if (tmpfd < 0)
            AG_ABEND(aprf(MKSTEMP_FAIL_FMT, cgi_stderr));
        dup2(tmpfd, STDERR_FILENO);
        close(tmpfd);
    }

    /*
     *  Pull the CGI-relevant environment variables.  Anything we don't find
     *  gets an empty string default.
     */
    {
        name_map_t * nm_map = name_val_map;
        name_idx_t   ix     = (name_idx_t)0;

        do  {
            nm_map->pzValue = getenv(nm_map->pzName);
            if (nm_map->pzValue == NULL)
                nm_map->pzValue = (char *)zNil;
        } while (nm_map++, ++ix < NAME_CT);
    }

    base_ctx = (scan_ctx_t *)AGALOC(sizeof(scan_ctx_t), "CGI ctx");
    memset(VOIDP(base_ctx), 0, sizeof(scan_ctx_t));

    {
        size_t len = strtoul(pzCgiLength, NULL, 0);
        char * text;

        if (strcasecmp(pzCgiMethod, "POST") == 0) {
            if (len == 0)
                AG_ABEND(LOAD_CGI_NO_DATA_MSG);

            text  = AGALOC(len + 1, "CGI POST");
            if (fread(text, (size_t)1, len, stdin) != len)
                AG_CANT(LOAD_CGI_READ_NAME, LOAD_CGI_READ_WHAT);

            text[ len ] = NUL;

            base_ctx->scx_data = parse_input(text, (int)len);
            AGFREE(text);

        } else if (strcasecmp(pzCgiMethod, LOAD_CGI_GET_NAME) == 0) {
            if (len == 0)
                len = strlen(pzCgiQuery);
            base_ctx->scx_data = parse_input(pzCgiQuery, (int)len);

        } else {
            AG_ABEND(aprf(LOAD_CGI_INVAL_REQ_FMT, pzCgiMethod));
            /* NOTREACHED */
#ifdef  WARNING_WATCH
            text = NULL;
#endif
        }
    }

    base_ctx->scx_line  = 1;
    base_ctx->scx_fname = LOAD_CGI_DEFS_MARKER;
    base_ctx->scx_scan  = base_ctx->scx_data;
}


static char *
parse_input(char * src, int len)
{
    static char const preamble[] = "Autogen Definitions cgi;\n";
#   define def_len (sizeof(preamble) - 1)
    char * res = AGALOC((len * 2) + def_len + 1, "CGI Defs");

    memcpy(res, PARSE_INPUT_AG_DEF_STR, def_len);
    (void)cgi_run_fsm(src, len, res + def_len, len * 2);
    return AGREALOC(res, strlen(res)+1, "CGI input");
}

/*
 * Local Variables:
 * mode: C
 * c-file-style: "stroustrup"
 * indent-tabs-mode: nil
 * End:
 * end of agen5/agCgi.c */
