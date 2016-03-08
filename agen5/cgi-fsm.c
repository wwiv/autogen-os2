/*   -*- buffer-read-only: t -*- vi: set ro:
 *
 *  DO NOT EDIT THIS FILE   (cgi-fsm.c)
 *
 *  It has been AutoGen-ed
 *  From the definitions    cgi.def
 *  and the template file   fsm
 *
 *  Automated Finite State Machine
 *
 *  Copyright (C) 1992-2016 Bruce Korb - all rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name ``Bruce Korb'' nor the name of any other
 *    contributor may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * AutoFSM IS PROVIDED BY Bruce Korb ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL Bruce Korb OR ANY OTHER CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#define DEFINE_FSM
#include "cgi-fsm.h"
#include <stdio.h>

/*
 *  Do not make changes to this file, except between the START/END
 *  comments, or it will be removed the next time it is generated.
 */
/* START === USER HEADERS === DO NOT CHANGE THIS COMMENT */

/*  This file is part of AutoGen.
 *  Copyright (C) 1992-2016 Bruce Korb - all rights reserved
 */

#include "autogen.h"

static inline te_cgi_state
get_next_event(char ch, int inlen, char * out, int outlen)
{
    if (inlen <= 0)
        return CGI_EV_END;

    if (outlen < 4) {
        static char const exhaustion[] = "output space exhausted\n";
        memcpy(out, exhaustion, sizeof(exhaustion));

        return CGI_ST_INVALID;
    }

    if (IS_ALPHABETIC_CHAR( ch ))
        return CGI_EV_ALPHA;

    if (IS_DEC_DIGIT_CHAR( ch ))
        return CGI_EV_NAME_CHAR;

    switch (ch) {
    case '_': return CGI_EV_NAME_CHAR; break;
    case '=': return CGI_EV_EQUAL;     break;
    case '+': return CGI_EV_SPACE;     break;
    case '%': return CGI_EV_ESCAPE;    break;
    case '&': return CGI_EV_SEPARATOR; break;
    default:  return CGI_EV_OTHER;     break;
    }
}

/* END   === USER HEADERS === DO NOT CHANGE THIS COMMENT */

#ifndef NULL
#  define NULL 0
#endif

/**
 *  Enumeration of the valid transition types
 *  Some transition types may be common to several transitions.
 */
typedef enum {
    CGI_TR_INVALID,
    CGI_TR_NAME_EQUAL,
    CGI_TR_SEPARATE,
    CGI_TR_STASH,
    CGI_TR_VALUE_ESCAPE
} te_cgi_trans;
#define CGI_TRANSITION_CT  5

/**
 *  State transition handling map.  Map the state enumeration and the event
 *  enumeration to the new state and the transition enumeration code (in that
 *  order).  It is indexed by first the current state and then the event code.
 */
typedef struct cgi_transition t_cgi_transition;
struct cgi_transition {
    te_cgi_state  next_state;
    te_cgi_trans  transition;
};
static const t_cgi_transition
cgi_trans_table[ CGI_STATE_CT ][ CGI_EVENT_CT ] = {

  /* STATE 0:  CGI_ST_INIT */
  { { CGI_ST_NAME, CGI_TR_STASH },                  /* EVT:  ALPHA */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  NAME_CHAR */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  = */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  + */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  % */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  OTHER */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  & */
    { CGI_ST_INVALID, CGI_TR_INVALID }              /* EVT:  END */
  },


  /* STATE 1:  CGI_ST_NAME */
  { { CGI_ST_NAME, CGI_TR_STASH },                  /* EVT:  ALPHA */
    { CGI_ST_NAME, CGI_TR_STASH },                  /* EVT:  NAME_CHAR */
    { CGI_ST_VALUE, CGI_TR_NAME_EQUAL },            /* EVT:  = */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  + */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  % */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  OTHER */
    { CGI_ST_INVALID, CGI_TR_INVALID },             /* EVT:  & */
    { CGI_ST_INVALID, CGI_TR_INVALID }              /* EVT:  END */
  },


  /* STATE 2:  CGI_ST_VALUE */
  { { CGI_ST_VALUE, CGI_TR_STASH },                 /* EVT:  ALPHA */
    { CGI_ST_VALUE, CGI_TR_STASH },                 /* EVT:  NAME_CHAR */
    { CGI_ST_VALUE, CGI_TR_STASH },                 /* EVT:  = */
    { CGI_ST_VALUE, CGI_TR_STASH },                 /* EVT:  + */
    { CGI_ST_VALUE, CGI_TR_VALUE_ESCAPE },          /* EVT:  % */
    { CGI_ST_VALUE, CGI_TR_STASH },                 /* EVT:  OTHER */
    { CGI_ST_INIT, CGI_TR_SEPARATE },               /* EVT:  & */
    { CGI_ST_DONE, CGI_TR_SEPARATE }                /* EVT:  END */
  }
};


#define CgiFsmErr_off     19
#define CgiEvInvalid_off  75
#define CgiStInit_off     83


static char const zCgiStrings[133] =
/*     0 */ "** OUT-OF-RANGE **\0"
/*    19 */ "FSM Error:  in state %d (%s), event %d (%s) is invalid\n\0"
/*    75 */ "invalid\0"
/*    83 */ "init\0"
/*    88 */ "name\0"
/*    93 */ "value\0"
/*    99 */ "alpha\0"
/*   105 */ "name_char\0"
/*   115 */ "=\0"
/*   117 */ "+\0"
/*   119 */ "%\0"
/*   121 */ "other\0"
/*   127 */ "&\0"
/*   129 */ "end";

static const size_t aszCgiStates[3] = {
    83, 88, 93 };

static const size_t aszCgiEvents[9] = {
    99,  105, 115, 117, 119, 121, 127, 129, 75 };


#define CGI_EVT_NAME(t)   ( (((unsigned)(t)) >= 9) \
    ? zCgiStrings : zCgiStrings + aszCgiEvents[t])

#define CGI_STATE_NAME(s) ( (((unsigned)(s)) >= 3) \
    ? zCgiStrings : zCgiStrings + aszCgiStates[s])

#ifndef EXIT_FAILURE
# define EXIT_FAILURE 1
#endif

static int cgi_invalid_transition( te_cgi_state st, te_cgi_event evt );

/* * * * * * * * * THE CODE STARTS HERE * * * * * * * */
/**
 *  Print out an invalid transition message and return EXIT_FAILURE
 */
static int
cgi_invalid_transition( te_cgi_state st, te_cgi_event evt )
{
    /* START == INVALID TRANS MSG == DO NOT CHANGE THIS COMMENT */
    char * pz = aprf( zCgiStrings + CgiFsmErr_off, st, CGI_STATE_NAME( st ),
                     evt, CGI_EVT_NAME( evt ));

    AG_ABEND( aprf(CGI_PARSE_ERR_FMT, pz ));
    /* END   == INVALID TRANS MSG == DO NOT CHANGE THIS COMMENT */

    return EXIT_FAILURE;
}

/**
 *  Run the FSM.  Will return CGI_ST_DONE or CGI_ST_INVALID
 */
te_cgi_state
cgi_run_fsm(
    char const * pzSrc,
    int inlen,
    char * pzOut,
    int outlen )
{
    te_cgi_state cgi_state = CGI_ST_INIT;
    te_cgi_event trans_evt;
    te_cgi_state nxtSt;
    te_cgi_trans trans;
    char const * saved_pzSrc = pzSrc;
    int saved_inlen = inlen;
    char * saved_pzOut = pzOut;
    int saved_outlen = outlen;
    (void)saved_pzSrc;
    (void)saved_inlen;
    (void)saved_pzOut;
    (void)saved_outlen;

    while (cgi_state < CGI_ST_INVALID) {

        /* START == FIND TRANSITION == DO NOT CHANGE THIS COMMENT */
        char curCh = *(pzSrc++);
        trans_evt = get_next_event(curCh, inlen--, saved_pzOut, saved_outlen);
        /* END   == FIND TRANSITION == DO NOT CHANGE THIS COMMENT */

#ifndef __COVERITY__
        if (trans_evt >= CGI_EV_INVALID) {
            nxtSt = CGI_ST_INVALID;
            trans = CGI_TR_INVALID;
        } else
#endif /* __COVERITY__ */
        {
            const t_cgi_transition * ttbl =
            cgi_trans_table[ cgi_state ] + trans_evt;
            nxtSt = ttbl->next_state;
            trans = ttbl->transition;
        }


        switch (trans) {
        case CGI_TR_INVALID:
            /* START == INVALID == DO NOT CHANGE THIS COMMENT */
            exit( cgi_invalid_transition( cgi_state, trans_evt ));
            /* END   == INVALID == DO NOT CHANGE THIS COMMENT */
            break;


        case CGI_TR_NAME_EQUAL:
            /* START == NAME_EQUAL == DO NOT CHANGE THIS COMMENT */
            strcpy( pzOut, "='" );
            outlen -= 2;
            pzOut  += 2;
            /* END   == NAME_EQUAL == DO NOT CHANGE THIS COMMENT */
            break;


        case CGI_TR_SEPARATE:
            /* START == SEPARATE == DO NOT CHANGE THIS COMMENT */
            strcpy( pzOut, "';\n" );
            outlen -= 3;
            pzOut  += 3;
            /* END   == SEPARATE == DO NOT CHANGE THIS COMMENT */
            break;


        case CGI_TR_STASH:
            /* START == STASH == DO NOT CHANGE THIS COMMENT */
            *(pzOut++) = curCh;
            outlen--;
            /* END   == STASH == DO NOT CHANGE THIS COMMENT */
            break;


        case CGI_TR_VALUE_ESCAPE:
            /* START == VALUE_ESCAPE == DO NOT CHANGE THIS COMMENT */
            {
            char z[4];
            if (inlen < 2)
                exit( cgi_invalid_transition( cgi_state, trans_evt ));

            z[0] = *(pzSrc++);
            z[1] = *(pzSrc++);
            z[2] = NUL;
            inlen -= 2;

            /*
             *  We must backslash quote certain characters that are %-quoted
             *  in the input string:
             */
            switch (*(pzOut++) = (char)strtol( z, NULL, 16 )) {
            case '\'':
            case '\\':
            case '#':
                pzOut[0]  = pzOut[-1];
                pzOut[-1] = '\\';
                pzOut++;
            }
            }
            /* END   == VALUE_ESCAPE == DO NOT CHANGE THIS COMMENT */
            break;


        default:
            /* START == BROKEN MACHINE == DO NOT CHANGE THIS COMMENT */
            exit( cgi_invalid_transition( cgi_state, trans_evt ));
            /* END   == BROKEN MACHINE == DO NOT CHANGE THIS COMMENT */
        }

        cgi_state = nxtSt;
    }
    return cgi_state;
}
/*
 * Local Variables:
 * mode: C
 * c-file-style: "stroustrup"
 * indent-tabs-mode: nil
 * End:
 * end of cgi-fsm.c */
