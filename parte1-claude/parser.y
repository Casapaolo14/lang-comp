/* Parser for the XML-like configuration language (alternative 1: references
 * are resolved here, the structure holds base values only). */
%{
#include "config.h"

#include <cstdio>
#include <cstdlib>

extern int yylex();
void yyerror(const char *msg);

Config cfg; /* parse result, read by main */
%}

%locations

%union {
    long num;
    bool boolean;
    char *str;
    Value *val;
}

%token SECTION FIELD NAME
%token <num> INT
%token <boolean> BOOL
%token <str> STRING IDENT
%type <val> value

%%

config : /* empty */
       | config section
       ;

section : sectionhead fields '<' '/' SECTION '>'
              { cfg.sections.back().endLine = @6.first_line; }
        ;

/* Separate head so the section is registered before its fields: duplicate
 * sections are detected immediately and local references can be resolved
 * against the section under construction. */
sectionhead : '<' SECTION NAME '=' IDENT '>'
                  { addSection(cfg, $5, @5.first_line); free($5); }
            ;

fields : /* empty */
       | fields field
       ;

field : '<' FIELD NAME '=' IDENT '>' value '<' '/' FIELD '>'
            { addBinding(cfg, $5, $7, @5.first_line); free($5); }
      ;

value : INT                 { $$ = mkInt($1); }
      | BOOL                { $$ = mkBool($1); }
      | STRING              { $$ = mkStr($1); free($1); }
      | '$' IDENT           { $$ = resolveRef(cfg, nullptr, $2, @2.first_line); free($2); }
      | '$' IDENT '.' IDENT { $$ = resolveRef(cfg, $2, $4, @2.first_line);
                              free($2); free($4); }
      ;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "error: line %d: %s\n", yylloc.first_line, msg);
}
