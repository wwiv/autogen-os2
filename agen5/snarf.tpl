[= AutoGen5 template  -*- Mode: C -*-

# $Id: snarf.tpl,v 1.5 1999/11/24 23:30:12 bruce Exp $

ini =]
/*
[=(dne " *  ")=]
 *
 *  copyright 1992-1999 Bruce Korb
 *
[=(gpl "AutoGen" " *  ")=]
 *
 *  Guile Initializations - [=% group (string-capitalize! "%s ")
                            =]Global Variables
 */
typedef SCM (t_scm_callout_proc)();[=

DEFINE string_content =]
static const char s_[=% name (sprintf "%%-26s" "%s[]") =] = [=
    IF (exist? "string") =][=(c-string (get "string"))=][=
    ELSE =]"[= % name `echo %s |
       sed -e's/_p$/?/' -e's/_x$/!/' -e's/_/-/g' -e's/_to_/->/'` =]"[=
    ENDIF =];[=
ENDDEF =][=

  FOR gfunc =][=
    string_content =][=
  ENDFOR gfunc =]
[=
  FOR gfunc =]
extern t_scm_callout_proc [=% group "%s_" =]scm_[=name=];[=
  ENDFOR gfunc =][=

  FOR syntax =][=
    string_content =][=
  ENDFOR syntax =][=

  FOR symbol =]
[=  IF (exist? "global") =]      [=ELSE=]static[=ENDIF
    =] SCM sym_[=% name %-18s =] = SCM_BOOL_F;[=
  ENDFOR symbol =]
[=
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
=][=

DEFINE CALL_NEWPROC =]
    gh_new_procedure( (char*)s_[=name=],
                      [=
      % group "%s_"     =]scm_[= % name (sprintf "%%-28s" "%s,") =] [=

      IF (not (exist? "exparg"))
       =]0, 0, 0[=

      ELIF (not (exist? "exparg.arg_list")) =][=
       (- (count "exparg") (count "exparg.arg_optional")) =], [=
       (count "exparg.arg_optional" ) =], 0[=

      ELIF (not (exist? "exparg.arg_optional")) =][=
       (- (count "exparg") 1) =], 0, 1[=

      ELSE =][=
       (- (count "exparg") (count "exparg.arg_optional")) =], [=
       (- (count "exparg.arg_optional" ) 1) =], 1[=
      ENDIF =] );[=
ENDDEF =][=

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
=]
/*
 *  [=% group "%s " =]Two-Phase Initialization procedure
 *
 *  This routine assumes that certain routines are not to be exported
 *  until the second time it is called.
 */
void
[=% group "%s_" =]init( void )
{
  static int first_time = 0;
  if (first_time++ == 0) {
[=
  IF (exist? "init_code") =]
    [=init_code=][=
  ENDIF =][=

  FOR gfunc =][=
    IF (exist? "general_use") =][=
      CALL_NEWPROC =][=
    ENDIF =][=
  ENDFOR gfunc =][=

  FOR syntax =]
    scm_make_synt( s_[=% name (sprintf "%%-16s" "%s,")=] [=type=], [=cfn=] );[=
  ENDFOR syntax =][=

  FOR symbol =][=
    IF (not (exist? "vcell")) =]
    sym_[=name=] = scm_permanent_object (SCM_CAR (scm_intern0 ([=
                 scheme_name=])));[=
    ELSE =]
    sym_[=name=] = scm_permanent_object (scm_intern0 ([=scheme_name=]));
    SCM_SETCDR (sym_[=name=], [=
      IF    (exist? "init_val") =][=init_val=][=
      ELIF (exist? "const_val") =]scm_long2num([=const_val=])[=
      ELSE                      =]SCM_BOOL_F[=
      ENDIF=]);[=
    ENDIF =][=
  ENDFOR symbol =]
  } else {[=

  FOR gfunc =][=
    IF (not (exist? "general_use")) =][=
      CALL_NEWPROC =][=
    ENDIF =][=
  ENDFOR gfunc =][=

  IF (exist? "fini_code") =]
    [=fini_code=][=
  ENDIF =]
  }
}[= #

end of snarf.tpl =]
