/* Lexer for the XML-like configuration language. Comments are not turned
 * into tokens: they are saved (with their line) for the pretty-printer. */
%option noyywrap nounput noinput yylineno

%{
#include "config.h"
#include "parser.tab.hpp"

#include <cstdlib>
#include <cstring>

#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;
%}

%%

[ \t\r\n]+              ;
"#"[^\n]*               saveComment(yylineno, yytext);
section                 return SECTION;
field                   return FIELD;
name                    return NAME;
true                    { yylval.boolean = true;  return BOOL; }
false                   { yylval.boolean = false; return BOOL; }
-?[0-9]+                { yylval.num = atol(yytext); return INT; }
[a-zA-Z][a-zA-Z0-9]*    { yylval.str = strdup(yytext); return IDENT; }
\"[^\"\n]*\"            { yylval.str = strndup(yytext + 1, yyleng - 2); return STRING; }
[<>/=$.]                return yytext[0];
.                       { fprintf(stderr, "error: line %d: unexpected character '%s'\n",
                                  yylineno, yytext);
                          exit(1); }

%%
