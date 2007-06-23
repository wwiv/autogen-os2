[= AutoGen5 Template -*- Mode: C -*-

h
c

 (define base-name "")
 (define BASE-NAME "")
 (define element-type "")
 (define init-done #f)
 (define is-64-bit #f)
 (define is-array  #f)
 (define name-width 0)
 (define desc-width 0)

 (define id-name (lambda (sfx)
    (string-append
        prefix "_" (string-upcase! (string->c-name! (get "b-name"))) sfx
 )  ))

 (define mask-name (lambda (sfx)
    (string-append
        prefix "_" (string-upcase! (string->c-name! (get "m-name"))) sfx
 )  ))
=]
[= INVOKE preamble  =][=

CASE (suffix)       =][=

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

== h

=]
[= (make-header-guard "bit_mask") =]
#include <stdint.h>

typedef [=

 (define type-name (string-append base-name "_bits_t"))
 (define tmp
    (if (< (high-lim "bit") 32) (begin
        (set! element-type "uint32_t")
        "uint32_t %s_bits_t")
    (if (< (high-lim "bit") 64) (begin
        (set! element-type "uint64_t")
        "uint64_t %s_bits_t" )
      (begin
        (set! element-type "uint32_t")
        (sprintf "uint32_t %%s_bits_t[%s]"
                 (shellf "mask_ct=`calc '( %d + 32 ) / 32'` ; echo $mask_ct"
                         (high-lim "bit"))  ) ))  ))

 (sprintf tmp base-name)

=];
typedef enum {[=

FOR bit     =][=

  (shellf "mask_val=`calc \"${mask_val} + ( 2 ^ %d )\"`" (for-index))
  (set! tmp (string-length (get "b-name")))
  (if (> tmp name-width)
      (set! name-width tmp))
  (set! tmp (string-length (get "b-what")))
  (if (> tmp desc-width)
      (set! desc-width tmp)) =][=
ENDFOR bit  =][=

  (define define-width (+ name-width 6 (string-length prefix)))
  (define enum-fmt (sprintf "\n    %%-%ds =%%4d%%s /* %%-%ds */"
                            define-width desc-width))

=][=

FOR bit     =][=

  (sprintf enum-fmt (id-name "_ID") (for-index)
           (if (last-for?) " " ",") (get "b-what")) =][=
ENDFOR bit

= = = = = = = = = = = = = = = = =][=

IF (ag-fprintf 0 "\n} %s_enum_t;\n" base-name)
   (define def-fmt (sprintf "\n#define %%-%ds " define-width))

   (< (high-lim "bit") 32)      =][=

  INVOKE emit-word-macro  one = 'U'  mask-fmt = "%08XU" =][=

ELIF (< (high-lim "bit") 64)    =][=

  INVOKE emit-word-macro  one = 'ULL'  mask-fmt = "%016XULL" =][=

ELSE more than 64 bits          =][=

  INVOKE emit-multi-macros      =][=

ENDIF  how many bits

=][= IF (not (exist? "no-code")) =]
/*
 *  Return a string containing the names of the bits set.
 */
extern char *
[= (. base-name) =]_names([= (. type-name) =] bits);

#define INV_[= (. BASE-NAME) =] -1
#define DUP_[= (. BASE-NAME) =] -2

/*
 *  Set the bits in "bits" as specified by the input string "str".
 *  If any names are untranslatable (not in the name list or are
 *  ambiguous in that they match the initial portion of more than
 *  one entry), it will return -1 or -2, respectively.
 *  Otherwise, it returns the number of bits set in "bits".
 */
extern int
[= (. base-name) =]_bits(
    [= (. type-name) =] * const bits,
    char const * str);
[= ENDIF =]
#endif /* [= (. header-guard)   =] */[=

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

== c


=]
#include <ctype.h>
#include <string.h>
#include <stdio.h>
[=

 (if (exist? "no-code") (out-delete))
 (ag-fprintf 0 "#include \"%s\"\n" header-file)
 (string-table-new "nm")
 (string-table-add "nm" "* INVALID *")
 (define ix 0)
 (define offset-list "")
 (define sorted-off  "")        =][=

FOR bit (for-from 0) (for-by 1) =][=

    (if (exist? "b-name")
        (begin
           (set! tmp         (get "b-name"))
           (set! ix          (string-table-add "nm" tmp))
           (set! offset-list (string-append offset-list (sprintf "%d\n" ix)))
           (set! sorted-off  (string-append sorted-off
                             (sprintf "%-40s { %3d, %3d }\n" tmp ix (for-index))))
        )

        (set! offset-list (string-append offset-list "0\n" ))
    )       =][=

ENDFOR bit  =][=

 (emit-string-table "nm")
 (sprintf "\nchar *\n%1$s_names( %1$s_bits_t bits )\n{" base-name)
=]
    static int const nm_ixa[ [= (+ 1 (high-lim "bit")) =] ] = {
[=

 (define string-table-size (lambda (st-name)
    (hash-ref (hash-ref stt-table st-name) "current-index") ))

 (emit (shellf "columns -I8 -S, --spread=1 <<_EOF_\n%s_EOF_" offset-list))
=] };

    static char buf[ [= (+ (string-table-size "nm") (count "bit")) =] ];
    char * buf_p = buf;
    int ix = 0;
[=

IF (< (high-lim "bit") 64)

=]
    while (bits != 0) {
        if ((bits & 1) != 0) {
            char const * p = nm + nm_ixa[ix];

            if (buf_p > buf) {
                *(buf_p++) = ',';
                *(buf_p++) = ' ';
            }

            if (p == nm) {
            Oops:
                strncpy(buf_p, nm, sizeof (buf) - (buf_p - buf));
                break;
            }

            while ((*(buf_p++) = *(p++)) != '\0')   ;
            buf_p--;
        }
        bits >>= 1;
        if (++ix > [= (high-lim "bit") =]) {
            if (bits != 0)
                goto Oops;
            break;
        }
    }[=

ELSE  more than 64:

=]
    int bix     = 0;
    int bit_lim = 32;
    do  {
        uint32_t bit_word = bits[bix];
        int ix = bix * 32;

        while (bit_word != 0) {
            if ((bit_word & 1) != 0) {
                char const * p = nm + nm_ixa[ix];

                if (buf_p > buf) {
                    *(buf_p++) = ',';
                    *(buf_p++) = ' ';
                }

                if (p == nm) {
                Oops:
                    strncpy(buf_p, nm, sizeof (buf) - (buf_p - buf));
                    break;
                }

                while ((*(buf_p++) = *(p++)) != '\0')   ;
                buf_p--;
            }
            bit_word >>= 1;
            if (++ix > [= (high-lim "bit") =]) {
                if (bit_word != 0)
                    goto Oops;
                return buf;
            }
        }
    } while (++bix < [= `echo $mask_ct` =]);[=

ENDIF

=]

    return buf;
}

static int
str_to_id( char const * str, char const ** p_str )
{
    static char nm_buf[ [= (+ 1 name-width) =] ];
    int    res  = -1;
    int    part = 1;
    size_t len  = 0;

    /*
     *  Extract the lower cased name with '-' replaced with '_'
     */
    {
        char * p   = nm_buf;

        for (;;) {
            char ch = *(str++);
            switch (ch) {
            case '-':
                ch = '_';
                /* FALLTHROUGH */

            case '_':
                break;

            default:
                if (isupper(ch))
                    ch = _tolower(ch);
                else if (! isalnum(ch)) {
                    str--;
                    goto have_name;
                }
            }

            if (++len > [= (. name-width) =])
                return -1;

            *(p++) = ch;
        } have_name :;

        *p = '\0';
        len = p - nm_buf;
        if (len == 0)
            return INV_[= (. BASE-NAME) =];
    }

    /*
     * Search the alphabetized table
     */
    do  {
        static struct {
            unsigned short const nm_off, val;
        } nm_ixa[ [= (count "bit") =] ] = {
[=
 (shellf (string-append
          "(sort | sed 's/.*{/{/' | columns -I8 -S, --spread=1)<<_EOF_\n"
          sorted-off "_EOF_"
 ))
=] };

        int av;
        int lo = 0;
        int hi = [= (- (count "bit") 1) =];

        /*
         *  Binary search for first match
         */
        do  {
            char const * p;
            int df;

            av = (lo + hi) / 2;
            p  = nm + nm_ixa[av].nm_off;
            df = strncmp(p, nm_buf, len);

            if (df == 0) {
                res = nm_ixa[av].val;
                if (p[len] == '\0')
                    part = 0;

                break;
            }

            if (df > 0)
                 hi = av - 1;
            else lo = av + 1;

        } while (lo <= hi);

        if (res < 0)
            return INV_[= (. BASE-NAME) =];

        if (part == 0)
            break;

        /*
         * Partial match.  Look for preceeding matches.  One may be a full match.
         */
        lo = av;
        while (lo > 0) {
            char const * p = nm + nm_ixa[--lo].nm_off;
            int df = strncmp(p, nm_buf, len);
            if (df != 0)
                break;
            if (p[len] == '\0') {
                part = 0;
                res = nm_ixa[lo].val;
                break;
            }
            part++;
        }

        if (part > 1) {
            *p_str = nm_buf;
            return DUP_[= (. BASE-NAME) =];
        }

        if ((part == 0) || (av == [= (- (count "bit") 1) =]))
            break;

        /*
         * Look for a successor match.  No full match possible.
         */
        {
            char const * p = nm + nm_ixa[av+1].nm_off;
            int df = strncmp(p, nm_buf, len);
            if (df == 0) {
                *p_str = nm_buf;
                return DUP_[= (. BASE-NAME) =];
            }
        }
    } while (0);

    while (isspace(*str))  str++;
    *p_str = str;
    return res;
}

int
[=

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

(. base-name) =]_bits(
    [= (. type-name) =] * const bits[= (if is-array "_p")=],
    char const * str)
{[=
  IF (. is-array) =]
    [= (. element-type) =] * const bits = (void*)bits_p;[=
  ENDIF =]
    size_t len = 0;
    int    ct  = 0;
    int    res = 0;

    memset(bits, '\0', sizeof([= (. type-name) =]));

    another_bit:

    while (isspace(*str) || (*str == ','))  str++;

    for (;;) {
        if (isdigit(*str))
            *bits |= ([=(. element-type) =])strtoull(str, &str, 0);

        else if (isalpha(*str)) {
            res = str_to_id(str, &str);
            if (res < 0) {
                if (res == DUP_[= (. BASE-NAME) =])
                    fprintf(stderr, "duplicate matches for '%s'\n", str);
                goto fail_exit;
            }
            ct++;
[=

 IF (. is-array)    =]
            bits[res/32] |= 1 << (res & 0x1F);[=
 ELIF (. is-64-bit) =]
            *bits |= 1ULL << res;[=
 ELSE =]
            *bits |= 1 << res;[=
 ENDIF

=]
        } else switch (*str) {
        case ',':
            goto another_bit;

        case '\0':
            return ct;

        default:
            res = INV_[= (. BASE-NAME) =];
            goto fail_exit;
        }
    }

    fail_exit:
    memset(bits, '\0', sizeof(*bits));
    return res;
}

#ifdef TEST_BITS

static char const bit_names[] =
[=
(kr-string (string-append "The known " base-name " bit names are:\n"
  (shellf (string-append
    "(sort | columns -I2 --spread=1\n) <<_EOF_\n"
    (string-downcase! (join "\n" (stack "bit.b-name")))
    "\n_EOF_"))
  "\n" ))
 =];

int
main( int argc, char** argv )
{
    static char const fmt_z[] = "'%s' yields: %s\n";
    [= (. type-name) =] bts;
    if (argc != 2) {
        fputs(bit_names, stderr);
        return 1;
    }
    {
        int ct = [= (. base-name) =]_bits(&bts, argv[1]);
        if (ct <= 0) {
            char const * pz;
            switch (ct) {
            case 0: pz = "no results"; break;
            case INV_[= (. BASE-NAME) =]: pz = "invalid name"; break;
            case DUP_[= (. BASE-NAME) =]: pz = "multiple match"; break;
            }
            fprintf(stderr, fmt_z, argv[1], pz);
            fputs(bit_names, stderr);
            return 1;
        }
    }
    {
        char * pz = [= (. base-name) =]_names( bts );
        printf(fmt_z, argv[1], pz);
    }
    return 0;
}
#endif
[=

ESAC                =]
/* end of [= (out-name) =] */
[=#

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

DEFINE  preamble    =]
[=

 (if (not init-done) (begin

     (shell "calc() { bc <<_EOF_
$*
_EOF_
}
         mask_val=0")
     (if (not (exist? "mask-name"))
         (error "no defined bit mask name"))
     (set! init-done #t)
     (set! base-name (string-downcase! (string->c-name! (get "mask-name"))))
     (set! BASE-NAME (string-upcase base-name))
     (set! prefix    (string-upcase (string->c-name!
                     (if (exist? "prefix") (get "prefix") base-name) )))
 )   )

 (dne " * " "/* ")  =]
 */
[=

ENDDEF  preamble

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

DEFINE  emit-word-macro     =][=

  (sprintf def-fmt (string-append prefix "_NO_BITS")) =]0[= one =][=

  FOR bit   =][=

    (sprintf def-fmt (id-name "_BIT"))  =](1[= one =] << [= (id-name "_ID") =])[=

  ENDFOR    =][=

  (ag-fprintf 0 def-fmt (string-append BASE-NAME "_MASK"))
  (shellf "printf 0x%s ${mask_val}" (get "mask-fmt"))

=][=

  FOR mask

    =]
[= (sprintf def-fmt (mask-name "_MASK")) =]( [=
    FOR b-name " |"
       =][=
       (string-append " \\\n        " (id-name "_BIT"))
       =][=
    ENDFOR b-name
    =] )[=

  ENDFOR mask  =][=

(if (exist? "defined") (string-append "\n\n" (get "defined")))

=]

#define   SET_[= (. BASE-NAME) =](_m, _b) \
              do { (_m) |= 1[= one =] << _b; } while (0)
#define CLEAR_[= (. BASE-NAME) =](_m, _b) \
              do { (_m) &= ~(1[= one =] << _b); } while (0)
#define  TEST_[= (. BASE-NAME) =](_m, _b) (((_m) & (1[= one =] << _b)) != 0)
#define   AND_[= (. BASE-NAME) =](_d, _s1, _s2) \
              do { (_d) = (_s1) & (_s2); } while (0)
#define    OR_[= (. BASE-NAME) =](_d, _s1, _s2) \
              do { (_d) = (_s1) | (_s2); } while (0)
#define   XOR_[= (. BASE-NAME) =](_d, _s1, _s2) \
              do { (_d) = (_s1) ^ (_s2); } while (0)
#define   NOT_[= (. BASE-NAME) =](_d, _s) \
              do { (_d) = ~(_s); } while (0)
[=
ENDDEF  emit-word-macro

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =][=

DEFINE  emit-loop-macro

=][=

  (sprintf "#define %5s_%s" (get "mac-name") BASE-NAME) =][=

  CASE op-code  =][=
  == "~"        =](_d, _s)[=       (set! tmp one-arg-op)=][=
  *             =](_d, _s1, _s2)[= (set! tmp two-arg-op)=][=
  ESAC op-code  =] \
              [= (. iterate) =] \
              [= (sprintf tmp (get "op-code"))          =][=

ENDDEF  emit-loop-macro  =][=

DEFINE  emit-multi-macros

=][=

defined

=]

#define   SET_[=
(define is-array #t)
(define iterate (sprintf "do { int _ix_ = 0; for (;_ix_ < %s; _ix_++) {"
                         (shell "echo $mask_ct")  ))
(define two-arg-op "(_d)[_ix_] = (_s1)[_ix_] %s (_s2)[_ix_]; } } while (0)")
(define one-arg-op "(_d)[_ix_] = %s(_s)[_ix_]; } } while (0)")

                     BASE-NAME =](_m, _b) \
              do { (_m)[(_b)/32] |= 1U << ((_b) % 32); } while (0)
#define CLEAR_[= (. BASE-NAME) =](_m, _b) \
              do { (_m)[(_b)/32] &= ~(1U << ((_b) % 32)); } while (0)
#define  TEST_[= (. BASE-NAME)   =]( _m, _b) \
              (((_m)[(_b)/32] & (1U << ((_b) % 32))) != 0)
[= INVOKE emit-loop-macro op-code = "&"  mac-name = AND \=]
[= INVOKE emit-loop-macro op-code = "|"  mac-name =  OR \=]
[= INVOKE emit-loop-macro op-code = "^"  mac-name = XOR \=]
[= INVOKE emit-loop-macro op-code = "~"  mac-name = NOT  =]
[=

ENDDEF  emit-multi-macros   =][=

# End of bits.tpl  \=]
