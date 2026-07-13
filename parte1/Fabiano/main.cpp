#include <cstdio>
#include <iostream>
#include "Parser.H"
#include "Absyn.H"
#include "ParserError.H"
#include "Build.h"
#include "StampaFormattata.h"

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Uso: " << argv[0] << " <file.conf>" << std::endl;
        return 1;
    }

    FILE* input = fopen(argv[1], "r");
    if (!input) {
        std::cerr << "Impossibile aprire il file: " << argv[1] << std::endl;
        return 1;
    }

    Config* parse_tree = nullptr;
    try {
        parse_tree = pConfig(input);
    } catch (parse_error& e) {
        std::cerr << "Errore di parsing alla riga " << e.getLine() << std::endl;
        return 1;
    }

    if (!parse_tree) {
        std::cerr << "Parsing fallito." << std::endl;
        return 1;
    }

    Conf* conf = dynamic_cast<Conf*>(parse_tree);
    if (!conf) {
        std::cerr << "Errore interno: tipo AST inatteso." << std::endl;
        return 1;
    }

    Configurazione config = build(conf);

    std::cout << prettyPrint(config);

    delete parse_tree;
    return 0;
}