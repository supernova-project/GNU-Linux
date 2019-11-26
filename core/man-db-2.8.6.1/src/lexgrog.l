%top{
#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif /* HAVE_CONFIG_H */
}

%{

/*
 * lexgrog.l: extract 'whatis' info from nroff man / formatted cat pages.
 *  
 * Copyright (C) 1994, 1995 Graeme W. Wilford. (Wilf.)
 * Copyright (C) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
 *               2011, 2012 Colin Watson.
 *
 * This file is part of man-db.
 *
 * man-db is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * man-db is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with man-db; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Wed Oct 12 18:46:11 BST 1994  Wilf. (G.Wilford@ee.surrey.ac.uk) 
 * 
 * CJW: Detect grap and vgrind. Understand fill requests. Other improvements
 * in the syntax accepted.
 */

#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "gettext.h"
#define _(String) gettext (String)

#include "manconfig.h"

#include "error.h"
#include "pipeline.h"
#include "decompress.h"
#include "security.h"
#include "encodings.h"
#include "sandbox.h"

#include "manconv_client.h"

#define YY_READ_BUF_SIZE	1024
#define MAX_NAME		8192

#define ARRAY_SIZE(array) (sizeof (array) / sizeof ((array)[0]))

extern man_sandbox *sandbox;

struct macro {
	const char *name;
	const char *value;
};

static const struct macro glyphs[] = {
	/* It is vital to keep these in strcmp order (sort -t\" -k2)!  They
	 * will be searched using bsearch.
	 * Data from groff_char(7), although I have omitted some that are
	 * particularly unlikely to be used in NAME sections.
	 */
	{ "'A", "Á" },
	{ "'C", "Ć" },
	{ "'E", "É" },
	{ "'I", "Í" },
	{ "'O", "Ó" },
	{ "'U", "Ú" },
	{ "'Y", "Ý" },
	{ "'a", "á" },
	{ "'c", "ć" },
	{ "'e", "é" },
	{ "'i", "í" },
	{ "'o", "ó" },
	{ "'u", "ú" },
	{ "'y", "ý" },
	{ ",C", "Ç" },
	{ ",c", "ç" },
	{ "-D", "Ð" },
	{ ".i", "ı" },
	{ "/L", "Ł" },
	{ "/O", "Ø" },
	{ "/l", "ł" },
	{ "/o", "ø" },
	{ ":A", "Ä" },
	{ ":E", "Ë" },
	{ ":I", "Ï" },
	{ ":O", "Ö" },
	{ ":U", "Ü" },
	{ ":Y", "Ÿ" },
	{ ":a", "ä" },
	{ ":e", "ë" },
	{ ":i", "ï" },
	{ ":o", "ö" },
	{ ":u", "ü" },
	{ ":y", "ÿ" },
	{ "AE", "Æ" },
	{ "Bq", "„" },
	{ "Fc", "»" },
	{ "Fi", "ffi" },
	{ "Fl", "ffl" },
	{ "Fo", "«" },
	{ "IJ", "Ĳ" },
	{ "OE", "Œ" },
	{ "Sd", "ð" },
	{ "TP", "Þ" },
	{ "Tp", "þ" },
	{ "^A", "Â" },
	{ "^E", "Ê" },
	{ "^I", "Î" },
	{ "^O", "Ô" },
	{ "^U", "Û" },
	{ "^a", "â" },
	{ "^e", "ê" },
	{ "^i", "î" },
	{ "^o", "ô" },
	{ "^u", "û" },
	{ "`A", "À" },
	{ "`E", "È" },
	{ "`I", "Ì" },
	{ "`O", "Ò" },
	{ "`U", "Ù" },
	{ "`a", "à" },
	{ "`e", "è" },
	{ "`i", "ì" },
	{ "`o", "ò" },
	{ "`u", "ù" },
	{ "a\"", "˝" },
	{ "a-", "¯" },
	{ "a.", "˙" },
	{ "a^", "^" },
	{ "aa", "´" },
	{ "ab", "˘" },
	{ "ac", "¸" },
	{ "ad", "¨" },
	{ "ae", "æ" },
	{ "ah", "ˇ" },
	{ "ao", "˚" },
	{ "aq", "'" },
	{ "a~", "~" },
	{ "bq", "‚" },
	{ "cq", "’" },
	{ "dq", "\"" },
	{ "em", "—" },
	{ "en", "–" },
	{ "fc", "›" },
	{ "ff", "ff" },
	{ "fi", "fi" },
	{ "fl", "fl" },
	{ "fo", "‹" },
	{ "ga", "`" },
	{ "ha", "^" },
	{ "ho", "˛" },
	{ "hy", "‐" },
	{ "ij", "ĳ" },
	{ "lq", "“" },
	{ "oA", "Å" },
	{ "oa", "å" },
	{ "oe", "œ" },
	{ "oq", "‘" },
	{ "r!", "¡" },
	{ "r?", "¿" },
	{ "rq", "”" },
	{ "ss", "ß" },
	{ "ti", "~" },
	{ "vS", "Š" },
	{ "vZ", "Ž" },
	{ "vs", "š" },
	{ "vz", "ž" },
	{ "~A", "Ã" },
	{ "~N", "Ñ" },
	{ "~O", "Õ" },
	{ "~a", "ã" },
	{ "~n", "ñ" },
	{ "~o", "õ" }
};

static const struct macro perldocs[] = {
	/* It is vital to keep these in strcmp order (sort -t\" -k2)!  They
	 * will be searched using bsearch.
	 * Data from Pod/Man.pm.
	 */
	{ "--", "-" },
	{ "Aq", "'" },
	{ "C'", "'" },
	{ "C+", "C++" },
	{ "C`", "`" },
	{ "L\"", "\"" },
	{ "PI", "π" },
	{ "R\"", "\"" }
};

static void add_str_to_whatis (const char *string, size_t length);
static void add_char_to_whatis (unsigned char c);
static void add_separator_to_whatis (void);
static void add_wordn_to_whatis (const char *string, size_t length);
static void add_word_to_whatis (const char *string);
static void add_glyph_to_whatis (const char *string, size_t length);
static void add_perldoc_to_whatis (const char *string, size_t length);
static void mdoc_text (const char *string);
static void newline_found (void);

static char newname[MAX_NAME];
static char *p_name;
static const char *fname;
static char filters[MAX_FILTERS];

static int fill_mode;
static int waiting_for_quote;

static pipeline *decomp;

#define YY_INPUT(buf,result,max_size) { \
	size_t size = max_size; \
	const char *block = pipeline_read (decomp, &size); \
	if (block && size != 0) { \
		memcpy (buf, block, size); \
		buf[size] = '\0'; \
		result = size; \
	} else \
		result = YY_NULL; \
}
#define YY_NO_INPUT
%}

%option ecs meta-ecs
%option 8bit batch caseful never-interactive 
%option nostdinit
%option warn
%option noyywrap nounput

%x MAN_PRENAME
%x MAN_NAME
%x MAN_DESC
%x MAN_DESC_AT
%x MAN_DESC_BSX
%x MAN_DESC_BX
%x MAN_DESC_BX_RELEASE
%x MAN_DESC_DQ
%x MAN_DESC_FX
%x MAN_DESC_NX
%x MAN_DESC_OX
%x CAT_NAME
%x CAT_FILE
%x MAN_FILE
%x CAT_REST
%x MAN_REST
%x FORCE_EXIT

digit		[[:digit:]]
upper		[[:upper:]]
alpha		[[:alpha:]]
blank		[[:blank:]]
blank_eol	[[:blank:]\r\n]
word		[[:alnum:]][^[:blank:]\r\n]*
eol		\r?\n
bol		{eol}+
next		{eol}*
empty		{eol}{blank}*
indent		{eol}{blank}+
dbl_quote	\"
font_change	\\f([[:upper:]1-4]|\({upper}{2})
size_change	\\s[+-]?{digit}
style_change	({font_change}{size_change}?|{size_change}{font_change}?)
typeface	\.(B[IR]?|I[BR]?|R[BI]|S[BM])
sec_request	\.[Ss][HhYySs]
comment		['.]\\{dbl_quote}

 /* Please add to this list if you know how. */
 /* Note that, since flex only supports UTF-8 by accident, character classes
  * including non-ASCII characters must be written out as (a|b|c|d) rather
  * than [abcd].
  */
bg_name		ИМЕ
cs_name		(J[Mm](É|é|\\\('[Ee]|E|e)[Nn][Oo]|N(Á|á)[Zz][Ee][Vv])
da_name		N[Aa][Vv][Nn]
de_name		B[Ee][Zz][Ee][Ii][Cc][Hh][Nn][Uu][Nn][Gg]
en_name		N[Aa][Mm][Ee]
es_name		N[Oo][Mm][Bb][Rr][Ee]
fi_name		N[Ii][Mm][Ii]
fr_name		N[Oo][Mm]
hu_name		N(É|é|E|e)[Vv]
id_name		N[Aa][Mm][Aa]
 /* NOME also works for gl, pt */
it_name		N[Oo][Mm][Ee]
ja_name		(名|̾)(前|称)
ko_name		(이름|명칭)
latin_name	N[Oo][Mm][Ee][Nn]
lt_name		PAVADINIMAS
nl_name		N[Aa][Aa][Mm]
pl_name		N[Aa][Zz][Ww][Aa]
ru_name         (ИМЯ|НАЗВАНИЕ|НАИМЕНОВАНИЕ)
sk_name		M[Ee][Nn][Oo]
sr_name		(ИМЕ|НАЗИВ)
srlatin_name	(IME|NAZIV)
sv_name		N[Aa][Mm][Nn]
tr_name		(İ|i)S(İ|i)M  
vi_name		TÊN
zh_CN_name	名{blank}?(称|字){blank}?.*
zh_TW_name	(名{blank}?(稱|字)|命令名){blank}?.*
name		({bg_name}|{cs_name}|{da_name}|{de_name}|{en_name}|{es_name}|{fi_name}|{fr_name}|{hu_name}|{id_name}|{it_name}|{ja_name}|{ko_name}|{latin_name}|{lt_name}|{nl_name}|{pl_name}|{ru_name}|{sk_name}|{sr_name}|{srlatin_name}|{sv_name}|{tr_name}|{vi_name}|{zh_CN_name}|{zh_TW_name})
name_sec	{dbl_quote}?{style_change}?{name}{style_change}?({blank}*{dbl_quote})?

 /* eptgrv : eqn, pic, tbl, grap, refer, vgrind */
tbl_request	\.TS
eqn_request	\.EQ
pic_request	\.PS
grap_request	\.G1
ref1_request	\.R1
ref2_request	\.\[
vgrind_request	\.vS

%%

 /* begin NAME section processing */
<MAN_FILE>{sec_request}{blank_eol}+{name_sec}{blank}*	BEGIN (MAN_PRENAME);
<CAT_FILE>{empty}{2,}{name}{blank}*{indent}		BEGIN (CAT_NAME);

 /* general text matching */
<MAN_FILE>{
	\.[^Ss\r\n].*				|
	\..{0,3}{dbl_quote}?.{0,4}{dbl_quote}? 	|
	{comment}.*				|
	.|{eol}
}

<CAT_FILE>{
	.{1,9}		|
	[ ]*		|
	{eol}{2,}	|
	.|{eol}
}

<MAN_REST>{
	{bol}{tbl_request}		filters[TBL_FILTER] = 't';
	{bol}{eqn_request}		filters[EQN_FILTER] = 'e';
	{bol}{pic_request}		filters[PIC_FILTER] = 'p';
	{bol}{grap_request}		filters[GRAP_FILTER] = 'g';
	{bol}{ref1_request}		|
	{bol}{ref2_request}		filters[REF_FILTER] = 'r';
	{bol}{vgrind_request}		filters[VGRIND_FILTER] = 'v';
}
<MAN_REST><<EOF>>	{	/* exit */
	*p_name = '\0'; /* terminate the string */
	yyterminate ();
}
<MAN_REST>.+|{eol}

 /* rules to end NAME section processing */
<FORCE_EXIT>.|{eol}	{	/* forced exit */
	*p_name = '\0'; /* terminate the string */
	yyterminate ();
}

<MAN_PRENAME>{bol}{sec_request}{blank}*	|
<MAN_PRENAME><<EOF>>	{	/* no NAME at all */
	*p_name = '\0';
	BEGIN (MAN_REST);
}

 /* need to match whole string so that we beat the following roff catch-all,
    so use yyless to push back the name */
<MAN_PRENAME>{
	{bol}{typeface}{blank}.*	|
	{bol}\.Tn{blank}.*		|
	{bol}\.ft{blank}.*		|
	{bol}\.V[be]{blank}.*		|
	{bol}\.IX{blank}.*		|
	{bol}\.Nm{blank}.*		{
		yyless (0);
		BEGIN (MAN_NAME);
	}
}

 /* Skip over initial roff requests in NAME section. The use of yyless here
    is evil. */
<MAN_PRENAME>{bol}['.].*

<MAN_PRENAME>{empty}{eol}		yyless (1);

<MAN_PRENAME>.|{eol}	{
	yyless (0);
	BEGIN (MAN_NAME);
}

<MAN_NAME,MAN_DESC>{
	{bol}{sec_request}{blank}*	| 	/* Another section */
	{bol}\.X{upper}{blank}+		|	/* special - hpux */
	{bol}\.sp{blank}*		|	/* vertical spacing */
	{bol}\.ig{blank}*		|	/* block comment */
	{bol}\.de[1i]?{blank}*		|	/* macro definition */
	{bol}\.i[ef]{blank}*		|	/* conditional */
	{empty}{bol}.+			|
	<<EOF>>				{	/* terminate the string */
		*p_name = '\0';
		BEGIN (MAN_REST);
	}
}

<CAT_NAME>{
	{bol}S[yYeE]	|
	{eol}{2,}.+	|
	{next}__	{	/* terminate the string */
		*p_name = '\0';
		BEGIN (CAT_REST);
		yyterminate ();
	}
}

 /* ROFF request removal */
<MAN_NAME,MAN_DESC>{
 /* some include quoting; dealing with this is unpleasant */
	{bol}{typeface}{blank}+\"	{
		newline_found ();
		waiting_for_quote = 1;
	}

	{bol}{typeface}{blank}+		|	/* type face commands */
	{bol}\.Tn{blank}+		|	/* mdoc trade name */
	{bol}\.ft{blank}.*		|	/* font change */
	{bol}\.V[be]{blank}.*		|	/* pod2man, verbatim mode */
	{bol}\.IX{blank}.*		|	/* .IX line */
	{bol}\.Nm{blank}+		|	/* mdoc name */
	{bol}\.PD{blank}*		|	/* paragraph spacing */
	{bol}\\&			|	/* non-breaking space */
	{next}{comment}.*		{	/* per line comments */
		newline_found ();
	}
}

 /* No-op requests */
<MAN_NAME,MAN_DESC>{
	{bol}\.{blank}*$		newline_found ();
	{bol}\.\.$			newline_found ();
}

 /* Toggle fill mode */
<MAN_NAME,MAN_DESC>{
	{bol}\.nf.*			fill_mode = 0;
	{bol}\.fi.*			fill_mode = 1;
}

<CAT_NAME>-{eol}{blank_eol}*		/* strip continuations */

 /* convert to DASH */
<MAN_NAME>{
	{next}{blank}*\\\((mi|hy|em|en){blank}*	|
	{next}{blank_eol}+[-\\]-{blank}*	|
	{next}{blank_eol}*[-\\]-{blank}+	|
	{bol}\.Nd{blank}*			{
		add_separator_to_whatis ();
		BEGIN (MAN_DESC);
	}
}
<CAT_NAME>{next}{blank}+-{1,2}{blank_eol}+	add_separator_to_whatis ();

 /* escape sequences and special characters */
<MAN_NAME,MAN_DESC>{
 	{next}\\[\\e]			add_char_to_whatis ('\\');
 	{next}\\('|\(aa)		add_char_to_whatis ('\'');
 	{next}\\(`|\(ga)		add_char_to_whatis ('`');
	{next}\\(-|\((mi|hy|em|en))	add_char_to_whatis ('-');
	{next}\\\.			add_char_to_whatis ('.');
	{next}((\\[ 0t~])|[ ]|\t)*	add_char_to_whatis (' ');
	{next}\\\((ru|ul)		add_char_to_whatis ('_');
	{next}\\\\t			add_char_to_whatis ('\t');

	{next}\\[|^&!%acdpruz{}\r\n]	/* various useless control chars */
	{next}\\[bhlLvx]{blank}*'[^']+'	/* various inline functions */

	{next}\\\$[1-9]			/* interpolate arg */

	/* roff named glyphs */
	{next}\\\(..|\\\[..\]		add_glyph_to_whatis (yytext + 2, 2);
	/* perldoc strings */
	{next}\\\*\(..|\\\*\[..\]	add_perldoc_to_whatis (yytext + 3, 2);
	{next}\\\*.			add_perldoc_to_whatis (yytext + 2, 1);

	{next}\\["#].* 			/* comment */

	{next}{font_change}		/* font changes */
	{next}\\k{alpha}		/* mark input place in register */

	{next}\\n(\({alpha})?{alpha}	/* interpolate number register */
	{next}\\o\"[^"]+\"		/* overstrike chars */

	{next}{size_change}		/* size changes */
	{next}\\w{blank}*'[^']+'[^ \t]*	/* width of string */

	{next}\\			/* catch all */

	{next}\(\\\|\){blank}*		/* function() in hpux */
}

 /* some people rather ambitiously use non-trivial mdoc macros in NAME
    sections; cope with those that have been seen in the wild, and a few
    more */
<MAN_DESC>{
	{bol}\.At{blank}*		BEGIN (MAN_DESC_AT);
	{bol}\.Bsx{blank}*		BEGIN (MAN_DESC_BSX);
	{bol}\.Bx{blank}*		BEGIN (MAN_DESC_BX);
	{bol}\.Fx{blank}*		BEGIN (MAN_DESC_FX);
	{bol}\.Nx{blank}*		BEGIN (MAN_DESC_NX);
	{bol}\.Ox{blank}*		BEGIN (MAN_DESC_OX);
	{bol}\.Ux{blank}*		add_word_to_whatis ("UNIX");

	{bol}\.Dq{blank}*	{
		add_word_to_whatis ("\"");
		BEGIN (MAN_DESC_DQ);
	}
}

<MAN_DESC_AT>{
	32v{blank}*		mdoc_text ("Version 32V AT&T UNIX");
	v1{blank}*		mdoc_text ("Version 1 AT&T UNIX");
	v2{blank}*		mdoc_text ("Version 2 AT&T UNIX");
	v3{blank}*		mdoc_text ("Version 3 AT&T UNIX");
	v4{blank}*		mdoc_text ("Version 4 AT&T UNIX");
	v5{blank}*		mdoc_text ("Version 5 AT&T UNIX");
	v6{blank}*		mdoc_text ("Version 6 AT&T UNIX");
	v7{blank}*		mdoc_text ("Version 7 AT&T UNIX");
	V{blank}*		mdoc_text ("AT&T System V UNIX");
	V.1{blank}*		mdoc_text ("AT&T System V.1 UNIX");
	V.2{blank}*		mdoc_text ("AT&T System V.2 UNIX");
	V.3{blank}*		mdoc_text ("AT&T System V.3 UNIX");
	V.4{blank}*		mdoc_text ("AT&T System V.4 UNIX");
	.|{eol}		{
		yyless (0);
		mdoc_text ("AT&T UNIX");
	}
}

<MAN_DESC_BSX>{
	{word}		{
		add_word_to_whatis ("BSD/OS");
		add_wordn_to_whatis (yytext, yyleng);
		BEGIN (MAN_DESC);
	}
	.|{eol}		{
		yyless (0);
		mdoc_text ("BSD/OS");
	}
}

<MAN_DESC_BX>{
	-alpha{blank}*		mdoc_text ("BSD (currently in alpha test)");
	-beta{blank}*		mdoc_text ("BSD (currently in beta test)");
	-devel{blank}*		mdoc_text ("BSD (currently under development");
	{word}{blank}*	{
		add_wordn_to_whatis (yytext, yyleng);
		add_str_to_whatis ("BSD", 3);
		BEGIN (MAN_DESC_BX_RELEASE);
	}
	.|{eol}		{
		yyless (0);
		mdoc_text ("BSD");
	}
}

<MAN_DESC_BX_RELEASE>{
	[Rr]eno{blank}*		{
		add_str_to_whatis ("-Reno", 5);
		BEGIN (MAN_DESC);
	}
	[Tt]ahoe{blank}*	{
		add_str_to_whatis ("-Tahoe", 6);
		BEGIN (MAN_DESC);
	}
	[Ll]ite{blank}*		{
		add_str_to_whatis ("-Lite", 5);
		BEGIN (MAN_DESC);
	}
	[Ll]ite2{blank}*	{
		add_str_to_whatis ("-Lite2", 6);
		BEGIN (MAN_DESC);
	}
	.|{eol}			{
		yyless (0);
		BEGIN (MAN_DESC);
	}
}

<MAN_DESC_DQ>.*		{
	add_str_to_whatis (yytext, yyleng);
	add_char_to_whatis ('"');
	BEGIN (MAN_DESC);
}

<MAN_DESC_FX>{
	{word}		{
		add_word_to_whatis ("FreeBSD");
		add_wordn_to_whatis (yytext, yyleng);
		BEGIN (MAN_DESC);
	}
	.|{eol}		{
		yyless (0);
		mdoc_text ("FreeBSD");
	}
}

<MAN_DESC_NX>{
	{word}		{
		add_word_to_whatis ("NetBSD");
		add_wordn_to_whatis (yytext, yyleng);
		BEGIN (MAN_DESC);
	}
	.|{eol}		{
		yyless (0);
		mdoc_text ("NetBSD");
	}
}

<MAN_DESC_OX>{
	{word}		{
		add_word_to_whatis ("OpenBSD");
		add_wordn_to_whatis (yytext, yyleng);
		BEGIN (MAN_DESC);
	}
	.|{eol}		{
		yyless (0);
		mdoc_text ("OpenBSD");
	}
}

 /* collapse spaces, escaped spaces, tabs, newlines to a single space */
<CAT_NAME>{next}((\\[ ])|{blank})*	add_char_to_whatis (' ');

 /* a ROFF break request, a paragraph request, or an indentation change
    usually means we have multiple whatis definitions, provide a separator
    for later processing */
<MAN_NAME,MAN_DESC>{
	{bol}\.br{blank}*		|
	{bol}\.LP{blank}*		|
	{bol}\.PP{blank}*		|
	{bol}\.P{blank}*		|
	{bol}\.IP{blank}.*		|
	{bol}\.HP{blank}.*		|
	{bol}\.RS{blank}.*		|
	{bol}\.RE{blank}.*		{
		add_char_to_whatis ((char) 0x11);
		BEGIN (MAN_NAME);
	}
}

 /* any other roff request we don't recognise terminates definitions */
<MAN_NAME,MAN_DESC>{bol}['.]	{
	*p_name = '\0';
	BEGIN (MAN_REST);
}

 /* pass words as a chunk. speed optimization */
<MAN_NAME,MAN_DESC>[[:alnum:]]*		add_str_to_whatis (yytext, yyleng);

 /* normalise the comma (,) separators */
<CAT_NAME>{blank}*,[ \t\r\n]*		|
<MAN_NAME,MAN_DESC>{blank}*,{blank}*	add_str_to_whatis (", ", 2);

<CAT_NAME,MAN_NAME,MAN_DESC>{bol}.	{
	newline_found ();
	add_char_to_whatis (yytext[yyleng - 1]);
}

<CAT_NAME,MAN_NAME,MAN_DESC>.		add_char_to_whatis (*yytext);

 /* default EOF rule */
<<EOF>>	return 1;

%%

/* print warning and force scanner to terminate */
static void too_big (void)
{
	/* Even though MAX_NAME is a macro expanding to a constant, we
	 * translate it using ngettext anyway because that will make it
	 * easier to change the macro later.
	 */
	error (0, 0,
	       ngettext ("warning: whatis for %s exceeds %d byte, "
			 "truncating.",
			 "warning: whatis for %s exceeds %d bytes, "
			 "truncating.", MAX_NAME),
	       fname, MAX_NAME);

	BEGIN (FORCE_EXIT);
}

/* append a string to newname if enough room */
static void add_str_to_whatis (const char *string, size_t length)
{
	if (p_name - newname + length >= MAX_NAME)
		too_big ();
	else {
		(void) strncpy (p_name, string, length);
		p_name += length;
	}
} 

/* append a char to newname if enough room */
static void add_char_to_whatis (unsigned char c)
{
	if (p_name - newname + 1 >= MAX_NAME)
		too_big ();
	else if (waiting_for_quote && c == '"')
		waiting_for_quote = 0;
	else
		*p_name++ = c;
}

/* append the " - " separator to newname, trimming the first space if one's
 * already there
 */
static void add_separator_to_whatis (void)
{
	if (p_name != newname && *(p_name - 1) != ' ')
		add_char_to_whatis (' ');
	add_str_to_whatis ("- ", 2);
}

/* append a word to newname if enough room, ensuring only necessary
   surrounding space */
static void add_wordn_to_whatis (const char *string, size_t length)
{
	if (p_name != newname && *(p_name - 1) != ' ')
		add_char_to_whatis (' ');
	while (length && string[length - 1] == ' ')
		--length;
	if (length)
		add_str_to_whatis (string, length);
}

static void add_word_to_whatis (const char *string)
{
	add_wordn_to_whatis (string, strlen (string));
}

struct compare_macro_key {
	const char *string;
	size_t length;
};

static int compare_macro (const void *left, const void *right)
{
	const struct compare_macro_key *key = left;
	const struct macro *value = right;
	int cmp;

	cmp = strncmp (key->string, value->name, key->length);
	if (cmp)
		return cmp;
	/* equal up to key->length, so value->name must be at least size
	 * key->length + 1
	 */
	else if (value->name[key->length])
		return -1;
	else
		return 0;
}

static void add_macro_to_whatis (const struct macro *macros, size_t n_macros,
				 const char *string, size_t length)
{
	struct compare_macro_key key;
	const struct macro *macro;

	key.string = string;
	key.length = length;
	macro = bsearch (&key, macros, n_macros, sizeof (struct macro),
			 compare_macro);
	if (macro)
		add_str_to_whatis (macro->value, strlen (macro->value));
}

static void add_glyph_to_whatis (const char *string, size_t length)
{
	add_macro_to_whatis (glyphs, ARRAY_SIZE (glyphs), string, length);
}

static void add_perldoc_to_whatis (const char *string, size_t length)
{
	add_macro_to_whatis (perldocs, ARRAY_SIZE (perldocs), string, length);
}

static void mdoc_text (const char *string)
{
	add_word_to_whatis (string);
	BEGIN (MAN_DESC);
}

static void newline_found (void)
{
	/* If we are mid p_name and the last added char was not a space,
	 * best add one.
	 */
	if (p_name != newname && *(p_name - 1) != ' ') {
		if (fill_mode)
			add_char_to_whatis (' ');
		else {
			add_char_to_whatis ((char) 0x11);
			BEGIN (MAN_NAME);
		}
	}
	waiting_for_quote = 0;
}

int find_name (const char *file, const char *filename, lexgrog *p_lg,
	       const char *encoding)
{
	int ret;
	pipeline *p;
	char *page_encoding = NULL;

	if (strcmp (file, "-") == 0) {
		p = decompress_fdopen (dup (STDIN_FILENO));
	} else {
		struct stat st;
		char *lang;

		if (stat (file, &st)) {
			error (0, errno, "%s", file);
			return 0;
		}

		if (S_ISDIR (st.st_mode)) {
			error (0, EISDIR, "%s", file);
			return 0;
		}

		drop_effective_privs ();
		p = decompress_open (file);
		if (!p) {
			error (0, errno, _("can't open %s"), file);
			regain_effective_privs ();
			return 0;
		}
		regain_effective_privs ();

		if (!encoding) {
			lang = lang_dir (file);
			page_encoding = get_page_encoding (lang);
			free (lang);
		}
	}
	if (!page_encoding && encoding)
		page_encoding = xstrdup (encoding);
	if (page_encoding)
		add_manconv (p, page_encoding, "UTF-8");
	free (page_encoding);
	if (p_lg->type && *COL) {
		pipecmd *col_cmd;
		col_cmd = pipecmd_new_args (COL, "-b", "-p", "-x", (void *) 0);
		pipecmd_pre_exec (col_cmd, sandbox_load, sandbox_free,
				  sandbox);
		pipeline_command (p, col_cmd);
	}
	pipeline_start (p);

	ret = find_name_decompressed (p, filename, p_lg);
	pipeline_free (p);
	return ret;
}

int find_name_decompressed (pipeline *p, const char *filename, lexgrog *p_lg)
{
	int ret;

	decomp = p;

	fname = filename;
	*(p_name = newname) = '\0';
	memset (filters, '_', sizeof (filters));

	fill_mode = 1;
	waiting_for_quote = 0;

	if (p_lg->type)
		BEGIN (CAT_FILE);
	else
		BEGIN (MAN_FILE);

	drop_effective_privs ();

	yyrestart (NULL);
	ret = yylex ();

	regain_effective_privs ();

	pipeline_wait (decomp);

	if (ret)
		return 0;
	else {
		char f_tmp[MAX_FILTERS];
		int j, k;

		/* wipe out any leading or trailing spaces */
		if (*newname) {
			for (p_name = strchr (newname, '\0');
			     *(p_name - 1) == ' ';
			     p_name--);
			if (*p_name == ' ')
				*p_name = '\0';
		}
		for (p_name = newname; *p_name == ' '; p_name++);
		p_lg->whatis = xstrdup (p_name);
		memset (f_tmp, '\0', MAX_FILTERS);
		f_tmp[0] = '-';
		for (j = k = 0; j < MAX_FILTERS; j++)
			if (filters[j] != '_')
				f_tmp[k++] = filters[j];
		p_lg->filters = xstrdup (f_tmp);
		return p_name[0];
	}
}
