[= AutoGen5 template -*-texinfo-*-

##  Documentation template
## 
##  AutoGen Copyright (C) 1992-1999 Bruce Korb
## 
## Author:            Bruce Korb <korbb@datadesign.com>
## Maintainer:        Bruce Korb <korbb@datadesign.com>
## Created:           Tue Sep 15 13:13:48 1998
## Last Modified:     Mon Aug 30 10:50:10 1999                                
##            by:     Bruce Korb <korb@datadesign.com>                        
## ---------------------------------------------------------------------
## $Id: auto_gen.tpl,v 2.30 1999/10/26 02:44:23 bruce Exp $
## ---------------------------------------------------------------------
##
texi=autogen.texi =]
\input texinfo
@c %**start of header
@setfilename autogen.info
@settitle AutoGen
@setchapternewpage off
@c %**end of header

@ignore
[=(dne "")=]

Plus bits and pieces gathered from all over the source/build
directories:
[=
FOR infile=]
	[=infile=][=
ENDFOR infile =]
[=`echo "\t${top_srcdir}/autoopts/autoopts.texi"
   for f in ${top_builddir}/*/*.menu
   do echo "\t$f"
      echo "\t\`echo $f|sed 's/\\.menu$/.texi/'\`"
   done` =]

@end ignore

@set EDITION [=`echo ${AG_REVISION}`=]
@set VERSION [=`echo ${AG_REVISION}`=]
@set UPDATED [=`date "+%B %Y"`=]

@dircategory GNU programming tools
@direntry
* AutoGen: (autogen).         [=prog_title=]
@end direntry

@ifinfo
This file documents [=package=] Version @value{VERSION}

AutoGen copyright @copyright{} [=copyright=] Bruce Korb
AutoOpts copyright @copyright{} [=copyright=] Bruce Korb
snprintfv copyright @copyright{} 1999 Gary V. Vaughan

[=(gpl "AutoGen" "")=]

@ignore
Permission is granted to process this file through TeX and print the
results, provided the printed document carries copying permission
notice identical to this one except for the removal of this paragraph
@end ignore
@end ifinfo


@titlepage
@title AutoGen - [=prog_title=]
@subtitle For version @value{VERSION}, @value{UPDATED}
@author Bruce Korb (AutoGen, AutoOpts)
@author @email{autogen@@linuxbox.com}

@author Gary V. Vaughan (snprintfv)
@author @email{gary@@oranda.demon.co.uk}

@page
@vskip 0pt plus 1filll
AutoGen copyright @copyright{} [=copyright=] Bruce Korb
@sp 2
This is the second edition of the GNU AutoGen documentation,
@sp 2
Published by Bruce Korb, 910 Redwood Dr., Santa Cruz, CA  95060

[=(gpl "AutoGen" "")=]
@end titlepage

@ifinfo
@node Top, Introduction, , (dir)
@top [=prog_title=]
@comment  node-name,  next,  previous,  up

This file documents AutoGen, a tool designed for generating program
files that contain repetitive text with varied substitutions.
This document is very long because it is intended as a reference
document.  For a quick start example, @xref{Example Usage}.
For a simple example of Automated Option processing, @xref{Quick Start}.

This edition documents version @value{VERSION}, @value{UPDATED}.

@menu
* Introduction::         AutoGen's Purpose
* Definitions File::     AutoGen Definitions File
* Template File::        AutoGen Template
* AutoGen Invocation::   Invoking AutoGen
* Installation::         What Gets Installed Where
* AutoOpts::             Automated Option Processing
* Add-Ons::              Add-on packages for AutoGen
* Future::               Some ideas for the future.
* Concept Index::        General index
* Function Index::       Function index
@end menu

@end ifinfo

@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
@end ignore
@page
@node Introduction
@chapter Introduction
@cindex Introduction

AutoGen is a tool designed for generating program files that contain
repetitive text with varied substitutions.  Its goal is to simplify the
maintenance of programs that contain large amounts of repetitious text.
This is especially valuable if there are several blocks of such text
that must be kept synchronized.

One common example is the problem of maintaining the code required for
processing program options.  Processing options requires a minimum of
four different constructs be kept in proper order in different places in
your program.  You need at least:

@enumerate
@item
The flag character in the flag string,
@item
code to process the flag when it is encountered,
@item
a global state variable or two, and
@item
a line in the usage text.
@end enumerate

@noindent
You will need more things besides this if you choose to implement long
option names, rc/ini file processing, environment variables and so on.
For a simple example of Automated Option processing, @xref{Quick Start}.

All of this can be done mechanically; with the proper templates and this
program.  In fact, it has already been done and AutoGen itself uses it:
@xref{AutoOpts}.

@menu
* Generalities::         General Ideas
* Example Usage::        A Simple Example
* Testimonial::          A User's Perspective
@end menu

@node Generalities
@section General Ideas
@cindex m4

The idea of this program is to have a text file, a template if
you will, that contains the general text of the desired output file.
That file includes substitution expressions and sections of text that are
replicated under the control of separate definition files.

@cindex design goals

AutoGen was designed with the following features:

@enumerate
@item
The definitions are completely separate from the template.  By
completely isolating the definitions from the template it greatly
increases the flexibility of the template implementation.  A secondary
goal is that a template user only needs to specify those data
that are necessary to describe his application of a template.

@item
Each datum in the definitions is named.  Thus, the definitions can be
rearranged, augmented and become obsolete without it being necessary to
go back and clean up older definition files.  Reduce incompatibilities!

@item
Multiple values for a given name create an array of values.
This array of values is used to control the repetition of
sections of the template.

@item
There are named collections of definitions.  They form a nested hierarchy.
Associated values are collected and associated with a group name.
These associated data are used collectively in sets of substitutions.

@item
The template has special markers to indicate where substitutions are
required, much like the @code{$@{VAR@}} construct in a shell @code{here
doc}.  These markers are not fixed strings.  They are specified at the
start of each template.  Template designers know best what fits into their
syntax and can avoid marker conflicts.

We did this because it is burdensome and difficult to avoid conflicts
using the pure C preprocessor substitution rules.  It also makes it
easier to specify expressions that transform the value.  Of course, our
expressions are less cryptic than the shell methods.

@item
These same markers are used, in conjunction with enclosed keywords, to
indicate sections of text that are to be skipped and for sections of
text that were to be repeated.  This is a major improvement over using C
preprocessing macros.  With the C preprocessor, you have no way of
selecting output text because it is an @i{un}varying, mechanical
substitution process.

@item
Finally, we supply methods for carefully controlling the output.
Sometimes, it is just simply easier and clearer to compute some text or
a value in one context when its application needs to be later.  So,
functions are available for saving text or values for later use.
@end enumerate

@node Example Usage
@section A Simple Example
@cindex example, simple
@cindex simple example

Assume you have an enumeration of names and you wish to associate some
string with each name.  Assume also, for the sake of this example,
that it is either too complex or too large to maintain easily by hand.
We will start by writing an abbreviated version of what the result
is supposed to be.  We will use that to construct our output templates.

@noindent
In a header file, @file{list.h}, you define the enumeration
and the global array containing the associated strings:

@example
typedef enum @{
        IDX_ALPHA,
        IDX_BETA,
        IDX_OMEGA @}  list_enum;

extern const char* az_name_list[ 3 ];
@end example

@noindent
Then you also have @file{list.c} that defines the actual
strings:

@example
#include "list.h"
const char* az_name_list[] = @{
        "some alpha stuff",
        "more beta stuff",
        "final omega stuff" @};
@end example

@noindent
First, we will define the information that is unique for
each enumeration name/string pair.

@example
autogen definitions list;
list = @{ list_element = alpha;
         list_info    = "some alpha stuff"; @};
list = @{ list_info    = "more beta stuff";
         list_element = beta; @};
list = @{ list_element = omega;
         list_info    = "final omega stuff"; @};
@end example

The @code{autogen definitions list;} entry defines the file as an
AutoGen definition file that uses a template named @code{list}.  That is
followed by three @code{list} entries that define the associations
between the enumeration names and the strings.  The order of the
differently named elements inside of list is unimportant.  They are
reversed inside of the @code{beta} entry and the output is unaffected.

Now, to actually create the output, we need a template or two that can
be expanded into the files you want.  In this program, we use a single
template that is capable of multiple output files.

It looks something like this.
(For a full description, @xref{Template File}.)

@example
[+ AutoGen5 template h c +]
[+ CASE (suffix) +][+
   ==  h  +]
typedef enum @{[+
   FOR list "," +]
        IDX_[+ (string-upcase! (get "list_element")) +][+
   ENDFOR list +] @}  list_enum;

extern const char* az_name_list[ [+ (count "list") +] ];
[+

   ==  c  +]
#include "list.h"
const char* az_name_list[] = @{[+
  FOR list "," +]
        "[+list_info+]"[+
  ENDFOR list +] @};[+

ESAC +]
@end example

The @code{[# AutoGen5 template h c #]} text tells AutoGen that this is
an AutoGen version 5 template file; that it is to be processed twice;
that the start macro marker is @code{[#}; and the end marker is
@code{#]}.  The template will be processed first with a suffix value of
@code{h} and then with @code{c}.  Normally, the suffix values are
appended to the @file{base-name} to create the output file name.

The @code{[# == h #]} and @code{[# == c #]} @code{CASE} selection clauses
select different text for the two different passes.  In this example,
the output is nearly disjoint and could have been put in two separate
templates.  However, sometimes there are common sections and this is
just an example.

The @code{[#FOR list "," #]} and @code{[# ENDFOR list #]} clauses delimit
blocks of text that will be repeated for every definition of @code{list}.
Inside of that block, the definition name-value pairs that
are members of each @code{list} are available for substitutions.

The remainder of the macros are expressions.  Some of these contain
special expression functions that are dependent on AutoGen named values;
others are simply Scheme expressions, the result of which will be
inserted into the output text.  Other expressions are names of AutoGen
values.  These values will be inserted into the output text.  For example,
@example
"[#list_info#]"
@end example
will result in the value associated with the name @code{list_info} being
inserted between the double quotes.

If you have compiled AutoGen, you can copy out the template and
definitions, run @file{autogen} and produce exactly the hypothesized
desired output.
@node Testimonial
@section A User's Perspective

@format
        Subject: Re: Sysadmin Package
           Date: Thu, 24 Sep 1998
           From: "Gary V. Vaughan"
             To: Alexandre
             CC: autoconf <autoconf@@gnu.org>

> Bruce Korb writes:
> 
> > I would like to recommend my tool.  It exactly and precisely
> > addresses these very problems in a manner far simpler than M4.

Alexandre wrote:
> 
> I'd appreciate opinions from others about advantages/disadvantages of
> each of these macro packages.
@end format

I am using AutoGen in my pet project, and find one of its best points to
be that it separates the operational data from the implementation.

Indulge me for a few paragraphs, and all will be revealed:
In the manual, Bruce cites the example of maintaining command line flags
inside the source code; traditionally spreading usage information, flag
names, letters and processing across several functions (if not files). 
Investing the time in writing a sort of boiler plate (a template in
AutoGen terminology) pays by moving all of the option details (usage,
flags names etc.) into a well structured table (a definition file if you
will),  so that adding a new command line option becomes a simple matter
of adding a set of details to the table.

So far so good!  Of course, now that there is a template, writing all of
that tedious optargs processing and usage functions is no longer an
issue.  Creating a table of the options needed for the new project and
running AutoGen generates all of the option processing code in C
automatically from just the tabular data.  AutoGen in fact already ships
with such a template... AutoOpts.

One final consequence of the good separation in the design of AutoGen is
that it is retargetable to a greater extent.  The
egcs/gcc/fixinc/inclhack.def can equally be used (with different
templates) to create a shell script (inclhack.sh) or a c program
(fixincl.c).

This is just the tip of the iceberg.  AutoGen is far more powerful than
these examples might indicate, and has many other varied uses.  I am
certain Bruce or I could supply you with many and varied examples, and I
would heartily recommend that you try it for your project and see for
yourself how it compares to m4.

As an aside, I would be interested to see whether someone might be
persuaded to rationalise autoconf with AutoGen in place of m4...  Ben,
are you listening?  autoconf-3.0! `kay?  =)O|

@format
Sincerely,
        Gary V. Vaughan
@end format

@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
@end ignore
@page
@node Definitions File
@chapter AutoGen Definitions File
@cindex definitions file
@cindex .def file

This chapter describes the syntax and semantics of the AutoGen
definition file.  Knowledge of identification, simple and compound
definition syntax is required to instantiate a template.  Consequently,
we keep it very simple.  For "advanced" users, there are preprocessing
directives and comments that may be used as well.

The definitions file is used to associate values with names.  When
multiple values are associated with a single name, an implicit array of
values is formed.  Values may be either simple strings or compound
collections of value-name pairs.  An array may not contain both simple
and compound members.  Fundamentally, it is as simple as:

@example
prog_name = "autogen";
flag = @{
    name      = templ_dirs;
    value     = L;
    descrip   = "Template search directory list";
@};
@end example

For purposes of commenting and controlling the processing of the
definitions, C-style comments and most C preprocessing directives are
honored.  The major exception is that the @code{#if} directive is
ignored, along with all following text through the matching
@code{#endif} directive.  The C preprocessor is not actually invoked, so
C macro substitution is @strong{not} performed.

@menu
* Identification::  The First Definition
* Definitions::     Simple and Compound Definitions
* Directives::      Controlling What Gets Processed
* Comments::        Commenting Your Definitions
* Example::         What it all looks like.
* Full Syntax::     YACC Language Grammar
@end menu

@node Identification
@section The First Definition
@cindex identification

The first definition in this file is used to identify it as a
AutoGen file.  It consists of the two keywords,
@samp{autogen} and @samp{definitions} followed by the default
template name and a terminating semi-colon (@code{;}).  That is:

@example
        AutoGen Definitions @var{template-name};
@end example

@noindent
Note that, other than the name @var{template-name}, the words
@samp{AutoGen} and @samp{Definitions} are searched for without case
sensitivity.  Most lookups in this program are case insensitive.

@cindex template, file name
@cindex .tpl, file name
@cindex tpl, file name

@noindent
AutoGen uses the name of the template to find the corresponding template
file.  It searches for the file in the following way, stopping when
it finds the file:

@enumerate
@item
It tries to open @file{./@var{template-name}}.  If it fails,
@item
it tries @file{./@var{template-name}.tpl}.
@item
It searches for either of these files in the directories listed in the
templ-dirs command line option.
@end enumerate

If AutoGen fails to find the template file in one of these places,
it prints an error message and exits.

@node Definitions
@section Simple and Compound Definitions
@cindex definitions
@cindex simple definitions
@cindex compound definitions

Any name may have multiple values associated with it in the definition
file.  If there is more than one instance, the @strong{only} way to
expand all of the copies of it is by using the FOR (@xref{FOR}.) text
function on it, as described in the next chapter.

There are two kinds of definitions, @samp{simple} and @samp{compound}.
They are defined thus:

@example
compound_name '=' '@{' definition-list '@}' ';'

text_name '=' string ';'

no_text_name ';'
@end example

@noindent
The names may be a simple name taking the next available index,
or may specify an index by name or number.  For example:

@example
txt_name
txt_name[2]
txt_name[ DEF_NAME ]
@end example
@noindent
@code{DEF_NAME} must be defined to have a numeric value.
If you do specify an index, you must take care not to cause conflicts.

@noindent
@code{No_text_name} is a text definition with a shorthand empty string
value.

@noindent
@code{definition-list} is a list of definitions that may or may not
contain nested compound definitions.  Any such definitions may
@strong{only} be expanded within a @code{FOR} block iterating over the
containing compound definition.  @xref{FOR}.

Here is, again, the example definitions from the previous chapter,
with three additional name value pairs.  Two with an empty value
assigned (@var{first} and @var{last}), and a "global" @var{group_name}.

@example
autogen definitions list;
group_name = example;
list = @{ list_element = alpha;  first;
         list_info    = "some alpha stuff"; @};
list = @{ list_info    = "more beta stuff";
         list_element = beta; @};
list = @{ list_element = omega;  last;
         list_info    = "final omega stuff"; @};
@end example

@cindex simple definitions, format
The string values for definitions may be specified in one of five
formation rules:

@table @samp
@item with a double quote @code{"}
@cindex string, double quote
The string follows the C-style escaping (@code{\}, @code{\n}, @code{\f},
@code{\v}, etc.), plus octal character numbers specified as @code{\ooo}.
The difference from "C" is that the string may span multiple lines.

@item with a single quote @code{'}
@cindex string, single quote
This is similar to the shell single-quote string.  However, escapes
@code{\} are honored before another escape, single quotes @code{'}
and hash characters @code{#}.  This latter is done specifically
to disambiguate lines starting with a hash character inside
of a quoted string.  In other words,

@example
foo = '
#endif
';
@end example

could be misinterpreted by the definitions scanner, whereas
this would not:

@example
foo = '
\#endif
';
@end example

@item with a back quote @code{`}
@cindex string, shell output
This is treated identically with the double quote, except that the
resulting string is written to a shell server process and the definition
takes on the value of the output string.

NB:  The text is interpreted by a server shell.  There may be
left over state from previous @code{`} processing and it may
leave state for subsequent processing.  However, a @code{cd}
to the original directory is always issued before the new
command is issued.

A definition utilizing a backquote may not be joined with any other text.

@item without surrounding quotes
The string must not contain any of the characters special to the
definition text.  E.g. @code{;}, @code{"}, @code{'}, @code{`}, @code{=},
@code{@{}, @code{@}}, @code{[}, @code{]}, @code{#} or any
white space character.  Basically, if the string looks like it is a
normal file name or variable name, and it is not one of two keywords
(@samp{autogen} or @samp{definitions}) then it is OK to not quote it.

@item a Scheme expression starting with an open parenthesis @code{(}
The scheme expression will be evaluated by Guile and the
value will be the result.  The AutoGen expression functions
are @strong{dis}abled at this stage, so do not use them.
@end table

If single or double quote characters are used, then you
also have the option, a la ANSI-C syntax, of implicitly
concatenating a series of them together, with intervening
white space ignored.

NOTE: You @strong{cannot} use directives to alter the string
content.  That is,

@example
str = "foo"
#ifdef LATER
      "bar"
#endif
      ;
@end example

@noindent
will result in a syntax error.  The preprocessing directives are not
carried out by the C preprocessor.  However,

@example
str = '"foo\n"
#ifdef LATER
"     bar\n"
#endif
';
@end example

@noindent
@strong{Will} work.  It will enclose the @samp{#ifdef LATER}
and @samp{#endif} in the string.  But it may also wreak
havoc with the definition processing directives.  The hash
characters in the first column should be disambiguated with
an escape @code{\} or join them with previous lines:
@code{"foo\n#ifdef LATER...}.

@node Directives
@section Controlling What Gets Processed
@cindex directives

Definition processing directives can @strong{only} be processed
if the '#' character is the first character on a line.  Also, if you
want a '#' as the first character of a line in one of your string
assignments, you should either escape it by preceding it with a
backslash @samp{\}, or by embedding it in the string as in @code{"\n#"}.

All of the normal C preprocessing directives are recognized, though
several are ignored.  There is also an additional @code{#shell} -
@code{#endshell} pair.  Another minor difference is that AutoGen
directives must have the hash character (@code{#}) in column 1.

The ignored directives are:
[=
FOR directive =][=
  % dummy (string-downcase! "@samp{#%s}, ") =][=
ENDFOR directive=] and @samp{#if}.
Note that when ignoring the @code{#if} directive, all intervening
text through its matching @code{#endif} is also ignored,
including the @code{#else} clause.

The AutoGen directives that affect the processing of
definitions are:

@table @code[=
FOR directive "\n" =][=
  IF (exist? "text") =]
@item #[=% name (string-downcase! "%s") =][= % arg " %s" =]
@cindex #[=% name (string-downcase! "%s") =]
@cindex [=% name (string-downcase! "%s") =] directive
[=text=][=
  ENDIF=][=
ENDFOR directive=]
@end table

@node Comments
@section Commenting Your Definitions
@cindex comments

The definitions file may contain C-style comments.

@example
/*
 *  This is a comment.
 *  It continues for several lines and suppresses all processing
 *  until the closing characters '*' and '/' appear together.
#include is ignored.
 */
@end example

@node Example
@section What it all looks like.

@noindent
This is an extended example:

@example
autogen definitions @samp{template-name};
/*
 *  This is a comment that describes what these
 *  definitions are all about.
 */
global = "value for a global text definition.";

/*
 *  Include a standard set of definitions
 */
#include standards.def

a_block = @{
    a_field;
    /*
     *  You might want to document sub-block definitions, too
     */
    a_subblock = @{
        sub_name  = first;
        sub_field = "sub value.";
    @};

#ifdef FEATURE
    /*
     *  This definition is applicable only if FEATURE
     *  has been defined during the processing of the definitions.
     */
    a_subblock = @{
        sub_name  = second;
    @};
#endif

@};

a_block = @{
    a_field = here;
@};
@end example

@node    Full Syntax
@section YACC Language Grammar

The processing directives and comments are not
part of the grammar.  They are handled by the scanner/lexer.
The following was extracted directly from the agParse.y source file:

@ignore
Extracted from $top_srcdir/agen5/defParse.y
@end ignore
@example
[=`sed -n -e '/^definitions/,$p' $top_srcdir/agen5/defParse.y |
  sed -e 's/{/@{/g' -e 's/}/@}/g' `=]
@end example

@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
@end ignore
@page
@node Template File
@chapter AutoGen Template
@cindex template file
@cindex .tpl file

The template is really composed of two parts.
The first part consists of a pseudo macro invocation and commentary.
It is followed by the template proper.

@cindex pseudo macro
@cindex macro, pseudo
This pseudo macro is special.  It is used to identify the file as a
AutoGen template file, fixing the starting and ending marks for
the macro invocations in the rest of the file, and specifying the list
of suffixes to be generated by the template.

@menu
* template id::      Format of the Pseudo Macro
@end menu

AutoGen-ing a file consists of copying text from the template to
the output file until a start macro marker is found.  The text from the
start marker to the end marker constitutes the macro text.  If it starts
with a hash mark (@code{#}), then the macro is a comment.  If it starts
with an underscore (@code{_}), then it is an explicit function invocation.
These functions are listed below.  If it starts with an alphabetic
character, then @code{eval} will be invoked implicitly.  See the
discussion below.  If it begins with any other character (white space
being ignored), then it is in error and processing will stop.

@menu[=
FOR macfunc =][=
  IF (exist? "desc") =]
* [=(sprintf "%-16s" (string-append (get "name") "::"))
  =] [=(string-upcase (get "name"))=] - [=what=][=
  ENDIF =][=
ENDFOR macfunc=]
@end menu

@node template id
@section Format of the Pseudo Macro
@cindex template id

The template file must begin with a pseudo-macro.  The pseudo-macro
is used to identify the file as an AutoGen template file,
define the starting and ending macro markers and specify the
list of output files the template is to create.

Assuming we want to use @code{[+} and @code{+]} as the start and
end macro markers, and we wish to produce a @file{.c} and a @file{.h}
file, then the first macro invocation will look something like this:

@example
[+ autogen template -*- Mode: emacs-mode-of-choice -*-

h=chk-%s.h

c +]
@end example

@noindent
Note:  It is generally a good idea to use some sort of opening
bracket in the starting macro and closing bracket in the ending
macro  (e.g. @code{@{}, @code{(}, @code{[}, or even @code{<}
in the starting macro).  It helps both visually and with editors
capable of finding a balancing parenthesis.

@noindent
Detailed description:

The starting macro marker must be the first non-white space characters
encountered in the file.  The marker consists of all the contiguous
ASCII punctuation characters found there.  With optional intervening
white space, this marker must be immediately followed by the keywords,
"autogen" and "template".  Capitalization of these words is not
important.  This is followed by zero, one or more suffix specifications.

Suffix specifications consist of a sequence of POSIX compliant file name
characters and, optionally, an equal sign and a file name "printf"-style
formatting string.  Two string arguments are allowed for that string:
the base name of the definition file and the current suffix (that being
the text to the left of the equal sign).  (Note: "POSIX compliant file
name characters" consist of alphanumerics plus the period (@code{.}),
hyphen (@code{-}) and underscore (@code{_}) characters.)  If there are
no suffix specifications, then the generated file will be written to the
stdout file descriptor.

The pseudo macro ends with an end macro marker.  Like the starting macro
marker, it consists of a contiguous sequence of arbitrary punctuation
characters.  However, additionally, it may not begin with any of the
POSIX file name characters and it may not contain the start macro
marker.

This pseudo macro may appear on one or several lines of text.
Intermixed may be comment lines (completely blank or starting with the
hash character @code{#} in column 1), and file content markers (text
between @code{-*-} pairs on a single line).  This may be used to
establish editing "modes" for the file.  These are ignored by
AutoGen.

The template proper starts after the pseudo-macro.  The starting
character is either the first non-whitespace character or the first
character after the new-line that follows the end macro marker.

[=

#  FOR each defined function,
      this code will insert the extracted documentation =][=

FOR macfunc =][=
  IF (exist? "desc") =]

@node [=name=]
@section [=% name (string-upcase! "%s") =] - [=what=]
@findex [=% name (string-upcase! "%s") =][=
    FOR cindex =]
@cindex [=cindex=][=
    ENDFOR cindex=]

[=desc=][=
  ENDIF desc exists =][=
ENDFOR macfunc=]
@ignore

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

@end ignore
@page

@table @samp[=
FOR gfunc =]
@findex [=% name (string-upcase! "%s") =]
@item [=% name (string-upcase! "%s") =]
[=descrip=]
[=
ENDFOR evalexpr
=]
@end table[=

@ignore

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

@end ignore
@page

[=`
if [ -s ${top_builddir}/src/autogen.texi ]
then cat ${top_builddir}/src/autogen.texi
else cat ${top_srcdir}/src/autogen.texi
fi`=]
@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
@end ignore
@page
@node Installation
@chapter What Gets Installed Where
@cindex Installation

There are several files that get installed.  The number depend
whether or not both shared and archive libraries are to be
installed.  The following assumes that everything is installed
relative to @code{$prefix}.  You can, of course, use
@code{configure} to place these files where you wish.

@strong{NB}:  AutoGen does not contain any compiled-in path names.
All support directories are located via option processing
and the environment variable @code{HOME}.

The installed files are:

@enumerate
@item
The executables in @file{bin} (autogen, getdefs and columns).

@item
The link library(ies) as @file{lib/libopts.*}.

@item
An include file in @file{include/options.h}, needed for
Automated Option Processing (see next chapter).

@item
Six template files in @file{share/autogen}, needed for
Automated Option Processing (@xref{AutoOpts}.) and for documenting
your program.  (@xref{documentation attributes}.)

@item
Info-style help files as @file{info/autogen.info*}.
These files document AutoGen, the option processing
library AutoOpts, and several add-on components.
@end enumerate

This program, library and supporting files can be installed
with two commands:

@itemize @bullet
@item
<src-dir>/configure [ <configure-options> ]
@item
make install
@end itemize

However, you may wish to insert @code{make}
and @code{make check} before the second command.

If you do perform a @code{make check} and there are any failures, you
will find the results in @code{tests/FAILURES}.  Needless to say, I
would be interested in seeing the contents of those files and any
associated messages.  If you choose to go on and analyze one of these
failures, you will need to invoke the test scripts individually.  You
may do so by specifying the test (or list of test) in the TESTS make
variable, thus:

@example
make TESTS=test-name.test check
@end example

All of the AutoGen tests are written to honor the contents of the
@t{VERBOSE} environment variable.  Normally, any commentary generated
during a test run is discarded unless the @t{VERBOSE} environment
variable is set.  So, to see what is happening during the test, you
might invoke the following with @i{bash} or @i{ksh}:

@example
VERBOSE=1 make TESTS="for.test forcomma.test" check
@end example

Or equivalently with @i{csh}:

@example
env VERBOSE=1 make TESTS="for.test forcomma.test" check
@end example

@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
autoopts.texi input
@end ignore
@page
@node AutoOpts
@chapter Automated Option Processing
@cindex autoopts
[=# INCLUDE autoopts/autoopts.texi =]
@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
Absorbed documents from the add-ons

@end ignore
@page
@node Add-Ons
@chapter Add-on packages for AutoGen

This chapter includes several programs that either work closely
with AutoGen (extracting definitions or providing special formatting
functions), or else it is @code{mkmerge}.  I want to promote the
latter as an alternative to the builddir/srcdir schizophrenia.
I hate it. :(

AutoOpts ought to appear in this list also, but since it is
the primary reason why many people would even look into AutoGen
at all, I decided to leave it in the list of chapters.

@menu
[=`

for f in ${top_builddir}/*/*.menu
do
  case $f in
    *src/autogen.menu ) : ;;
    * ) cat $f ;;
  esac
done

echo '
@end menu

'

TOPSRC=\`cd ${top_srcdir} ; pwd\`
TOPBUILD=\`cd ${top_builddir} ; pwd\`
for f in ${top_srcdir}/*/*.menu
do 
   if [ "$f" = ${top_srcdir}/src/autogen.menu ] ; then : ; else
   echo '@page'
   echo '@ignore'
   echo 'Copy of $f and associated .texi'
   echo '@end ignore'
   cat \`echo $f | sed 's/\\.menu$/.texi/'\`
   fi
done

` =]

@ignore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
Resume text from auto_gen.tpl
@end ignore
@page
@node Future
@chapter Some ideas for the future.
@cindex futures

Here are some things that might happen in the distant future.

@itemize @bullet
@item
Rewrite in Guile.

@item
Write code for "AutoGetopts" (GNU getopt), or
possibly the new glibc argp parser.

@item
Fix up current tools that contain
miserably complex perl, shell, sed, awk and m4 scripts
to instead use this tool.
@end itemize
@page
@node Concept Index
@unnumbered Concept Index

@printindex cp
@page
@node Function Index
@unnumbered Function Index

@printindex fn
@page
@contents
@bye
