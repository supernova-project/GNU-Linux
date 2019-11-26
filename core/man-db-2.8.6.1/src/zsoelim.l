%top{
#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif /* HAVE_CONFIG_H */
}

%{

/*
 * zsoelim.l: eliminate .so includes within *roff source
 *  
 * Copyright (C) 1994, 1995 Graeme W. Wilford. (Wilf.)
 * Copyright (C) 1997 Fabrizio Polacco.
 * Copyright (C) 2001, 2002, 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011
 *               Colin Watson.
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
 * Added functionality over gsoelim to allow for compressed .so includes.
 * This is required as the first *roff preprocessor in order to deal with
 * 100% of compressed source files correctly. A replacement tmac.andoc was
 * considered, but would not have been portable to all systems.
 *
 * Wed Oct 12 18:46:11 BST 1994  Wilf. (G.Wilford@ee.surrey.ac.uk) 
 *
 * Tue, 14 Oct 1997 Fabrizio Polacco <fpolacco@debian.org>
 * - added changes that were done to .c instead of -l source
 * - added new start condition to avoid execution of .so requests
 *   inside a macro definition.
 */

#define MAX_SO_DEPTH 	10		/* max .so recursion depth */
#undef ACCEPT_QUOTES			/* accept quoted roff requests */

#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#define NAME	so_name[so_stack_ptr]
#define LINE	so_line[so_stack_ptr]
#define PIPE	so_pipe[so_stack_ptr]

#include "dirname.h"
#include "gl_linkedhash_list.h"
#include "gl_xlist.h"
#include "xgetcwd.h"
#include "xvasprintf.h"

#include "gettext.h"
#include <locale.h>
#define _(String) gettext (String)

#include "manconfig.h"

#include "error.h"
#include "glcontainers.h"
#include "pipeline.h"
#include "decompress.h"

#include "globbing.h"
#include "zsoelim.h"

#ifdef ACCEPT_QUOTES
#  define ZAP_QUOTES	zap_quotes ()
static void zap_quotes (void);
#else
#  define ZAP_QUOTES
#endif

static YY_BUFFER_STATE so_stack[MAX_SO_DEPTH];
static char *so_name[MAX_SO_DEPTH];
static int so_line[MAX_SO_DEPTH];
static pipeline *so_pipe[MAX_SO_DEPTH];
static int so_stack_ptr;
static int no_newline;
static gl_list_t so_manpathlist;
static const char *so_parent_path;

struct zsoelim_stdin_data {
	char *path;
	gl_list_t manpathlist;
};

/* The flex documentation says that yyin is only used by YY_INPUT, so we
 * should safely be able to abuse it as a handy way to keep track of the
 * current 'pipeline *' rather than the usual 'FILE *'.
 */
#define YY_INPUT(buf,result,max_size) { \
	size_t size = max_size; \
	const char *block = pipeline_read ((pipeline *) yyin, &size); \
	if (block && size != 0) { \
		memcpy (buf, block, size); \
		buf[size] = '\0'; \
		result = size; \
	} else \
		result = YY_NULL; \
}
#define YY_NO_INPUT
%}

%x so
%x de
%x end_request
%x lfnumber
%x lfname

W	[ \t]

%option full noread ecs
%option 8bit batch never-interactive
%option noyywrap nounput

%%

^\.de{W}*.+	{	
			no_newline = 1;
			ECHO;
			BEGIN (de);	/* Now we're inside of a macro definition: ends with a comment */
		}

^\.so{W}*	{	
			no_newline = 1;
			BEGIN (so);	/* Now we're in the .so environment */
		}

^\.lf{W}*	{
			no_newline = 1;
			ECHO;		/* Now we're in the .lf environment */
			BEGIN (lfnumber);
		}

^[^\.\n].*		|	/* fallback */
^\.[^sl].*		|
^\.l[^f].*		|
^\.s[^o].*		|
^\.s			|
^\.l			|
.			{
				no_newline = 1;
				ECHO;
			}

\n		{
			no_newline = 0;
			putchar ('\n');
			LINE++;
		}
		

<so>\"?[^ \t\n\"]+\"?	{ 	/* file names including whitespace ?  */
			if (so_stack_ptr == MAX_SO_DEPTH - 1) 
				error (FATAL, 0, 
				       _("%s:%d: .so requests nested too "
				         "deeply or are recursive"),
				       NAME, LINE);

			ZAP_QUOTES;
			so_stack[so_stack_ptr++] = YY_CURRENT_BUFFER;
			LINE = 1;

			no_newline = 0;

			if (zsoelim_open_file (yytext, so_manpathlist,
					       so_parent_path)) {
				--so_stack_ptr;
#ifndef __alpha
				error (OK, 0, 
				       _("%s:%d: warning: failed .so request"),
				       NAME, LINE);
				printf (".so %s\n", yytext);
#endif
				BEGIN (end_request);
			} else {
				printf (".lf 1 %s\n", yytext);
				yy_switch_to_buffer
					(yy_create_buffer (yyin, YY_BUF_SIZE));
				BEGIN (INITIAL);
			}

		}

<end_request>{W}*\n	{
			no_newline = 0;
			BEGIN (INITIAL);
		}
		
<so>\n		{
			no_newline = 0;
			error (OK, 0,
			       _("%s:%d: warning: newline in .so request, "
			         "ignoring"),
			       NAME, LINE);
			putchar ('\n');
			LINE++;
			BEGIN (INITIAL);
		}

<de>^\.\..*	{
			no_newline = 1;
			ECHO;
			BEGIN (INITIAL);
		}

<de>.*		{
			no_newline = 1;
			ECHO;
		}

<de>\n		{
			no_newline = 0;
			putchar ('\n');
			LINE++;
		}


<lfnumber>\"?[0-9]+\"?	{
			no_newline = 1;
			ECHO;
			ZAP_QUOTES;
			LINE = atoi (yytext);
			BEGIN (lfname);
		}

<lfname>\"?[^ \t\n\"]+\"?	{	/* file names including whitespace ?? */
			no_newline = 1;
			ECHO;
			putchar ('\n');
			ZAP_QUOTES;
			if (NAME)
				free (NAME);
			NAME = xstrdup (yytext);
			BEGIN (end_request); 
		}

<lfname>{W}+	{
			no_newline = 1;
			ECHO;
		}

<lfname>\n	{
			no_newline = 0;
			putchar ('\n');
			LINE++;
			BEGIN (INITIAL);
		}

<lfnumber,lfname>.	{
			no_newline = 1;
			error (OK, 0,
			       _("%s:%d: warning: malformed .lf request, "
			         "ignoring"),
			       NAME, LINE);
			putchar (*yytext);
			BEGIN (INITIAL);
		}

<lfnumber>\n	{
			no_newline = 0;
			error (OK, 0,
			       _("%s:%d: warning: newline in .lf request, "
			         "ignoring"),
			       NAME, LINE);
			putchar ('\n');
			LINE++;
			BEGIN (INITIAL);
		}

<<EOF>>	{
		pipeline_wait (PIPE);
		pipeline_free (PIPE);
		PIPE = NULL;
		free (NAME);
		NAME = NULL;

		if (no_newline)
			putchar ('\n');

		if (--so_stack_ptr < 0) {
			yyterminate ();
		} else {
			yy_delete_buffer (YY_CURRENT_BUFFER);
			yy_switch_to_buffer (so_stack[so_stack_ptr]);
			printf (".lf %d %s\n", LINE += 1, NAME);
		}
		no_newline = 0;
		BEGIN (end_request);
	}
%%

#ifdef ACCEPT_QUOTES
/* remove leading and trailing quotes in requests */
static void zap_quotes (void)
{
	if (*yytext == '"') {
		if (yytext[yyleng - 1] == '"') {
			yytext[yyleng - 1] = '\0';
			yytext++;
		} else
			error (OK, 0,
			       _("%s:%d: unterminated quote in roff request"),
			       NAME, LINE);
	}
}
#endif

/* initialise the stack and call the parser */
void zsoelim_parse_file (gl_list_t manpathlist, const char *parent_path)
{
#ifdef PP_COOKIE
	const char *line;
#endif /* PP_COOKIE */
	int linenum = 1;

	so_stack_ptr = 0;
	so_manpathlist = manpathlist;
	so_parent_path = parent_path;

#ifdef PP_COOKIE
	/* Skip over the first line if it's something that manconv might
	 * need to know about.
	 */
	line = pipeline_peekline ((pipeline *) yyin);
	if (line &&
	    (STRNEQ (line, PP_COOKIE, 4) || STRNEQ (line, ".\\\" ", 4))) {
		fputs (line, stdout);
		pipeline_peek_skip ((pipeline *) yyin, strlen (line));
		++linenum;
	}
#endif /* PP_COOKIE */

	printf (".lf %d %s\n", linenum, NAME);
	LINE = 1;
	yylex ();
}

static pipeline *try_compressed (char **filename)
{
	struct compression *comp;
	size_t len = strlen (*filename);
	pipeline *decomp;

	/* Try the uncompressed name first. */
	(*filename)[len - 1] = '\0';
	debug ("trying %s\n", *filename);
	decomp = decompress_open (*filename);
	if (decomp)
		return decomp;
	(*filename)[len - 1] = '.';

	for (comp = comp_list; comp->ext; ++comp) {
		*filename = appendstr (*filename, comp->ext, NULL);
		debug ("trying %s\n", *filename);
		decomp = decompress_open (*filename);
		if (decomp)
			return decomp;
		(*filename)[len] = '\0';
	}

	return NULL;
}

/* This routine is used to open the specified file or uncompress a compressed
   version and open that instead */
int zsoelim_open_file (const char *filename, gl_list_t manpathlist,
		       const char *parent_path)
{
	pipeline *decomp;

	if (parent_path)
		debug ("opening %s (parent path: %s)\n",
		       filename, parent_path);
	else
		debug ("opening %s\n", filename);

	if (strcmp (filename, "-") == 0) {
		decomp = decompress_fdopen (dup (STDIN_FILENO));
		NAME = xstrdup (filename);
	} else {
		char *compfile;
		const char *mp;

		/* If there is no parent path, try opening directly first. */
		if (!parent_path) {
			compfile = xasprintf ("%s.", filename);

			decomp = try_compressed (&compfile);
			if (decomp) {
				NAME = compfile;
				goto out;
			} else
				free (compfile);
		}

		if (strchr (filename, '/')) {
			/* File name with a directory part.  Try looking it
			 * up within each manpath entry.
			 */
			if (parent_path) {
				compfile = xasprintf ("%s/%s.", parent_path,
						      filename);

				decomp = try_compressed (&compfile);
				if (decomp) {
					NAME = compfile;
					goto out;
				}

				free (compfile);
			}

			GL_LIST_FOREACH_START (manpathlist, mp) {
				if (parent_path && STREQ (mp, parent_path))
					continue;

				compfile = xasprintf ("%s/%s.", mp, filename);

				decomp = try_compressed (&compfile);
				if (decomp) {
					NAME = compfile;
					goto out;
				}

				free (compfile);
			} GL_LIST_FOREACH_END (manpathlist);
		} else {
			/* File name with no directory part.  Try searching
			 * the manpath.
			 */
			char *name, *sec, *dot;
			gl_list_t names;
			const char *found_name;

			name = xstrdup (filename);
			dot = strchr (name, '.');
			if (!dot) {
				free (name);
				goto out;
			}
			*dot++ = '\0';
			sec = dot;
			dot = strchr (dot, '.');
			if (dot)
				*dot = '\0';

			if (parent_path) {
				names = look_for_file (parent_path, sec, name,
						       0, LFF_MATCHCASE);
				GL_LIST_FOREACH_START (names, found_name) {
					decomp = decompress_open (found_name);
					if (decomp) {
						NAME = xstrdup (found_name);
						gl_list_free (names);
						goto out;
					}
				} GL_LIST_FOREACH_END (names);
				gl_list_free (names);
			}

			GL_LIST_FOREACH_START (manpathlist, mp) {
				if (parent_path && STREQ (mp, parent_path))
					continue;

				names = look_for_file (mp, sec, name,
						       0, LFF_MATCHCASE);
				GL_LIST_FOREACH_START (names, found_name) {
					decomp = decompress_open (found_name);
					if (decomp) {
						NAME = xstrdup (found_name);
						gl_list_free (names);
						free (name);
						goto out;
					}
				} GL_LIST_FOREACH_END (names);
				gl_list_free (names);
			} GL_LIST_FOREACH_END (manpathlist);

			free (name);
		}

		/* If there is a parent path, try opening directly last. */
		if (parent_path) {
			compfile = xasprintf ("%s.", filename);

			decomp = try_compressed (&compfile);
			if (decomp) {
				NAME = compfile;
				goto out;
			} else
				free (compfile);
		}

out:
		if (!decomp) {
			error (0, errno, _("can't open %s"), filename);
			return 1;
		}
	}

	debug ("opened %s\n", NAME);

	pipeline_start (decomp);
	PIPE = decomp;
	/* only used by YY_INPUT, which casts it back to 'pipeline *' */
	yyin = (FILE *) decomp;

	return 0;
}

void zsoelim_stdin (void *data)
{
	struct zsoelim_stdin_data *zsoelim_data = data;
	gl_list_t empty;

	empty = gl_list_create_empty (GL_LINKEDHASH_LIST, NULL, NULL, NULL,
				      true);
	zsoelim_open_file ("-", empty, zsoelim_data->path);
	gl_list_free (empty);
	zsoelim_parse_file (zsoelim_data->manpathlist, zsoelim_data->path);
}

struct zsoelim_stdin_data *zsoelim_stdin_data_new (const char *path,
						   gl_list_t manpathlist)
{
	struct zsoelim_stdin_data *data = XMALLOC (struct zsoelim_stdin_data);

	data->path = path ? xstrdup (path) : NULL;
	data->manpathlist = manpathlist;

	return data;
}

void zsoelim_stdin_data_free (void *data)
{
	struct zsoelim_stdin_data *zsoelim_data = data;

	free (zsoelim_data->path);
	free (zsoelim_data);
}
