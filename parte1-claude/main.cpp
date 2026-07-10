/* Executable required by the assignment: parses the given file and emits
 * the serialization of the resulting structure on stdout. */
#include "config.h"

#include <cstdio>
#include <iostream>

extern FILE *yyin;
extern int yyparse();
extern Config cfg;

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <config-file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror(argv[1]);
        return 1;
    }
    if (yyparse() != 0)
        return 1;
    prettyPrint(cfg, std::cout);
    return 0;
}
