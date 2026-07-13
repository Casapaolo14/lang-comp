#include <iostream>
#include "Parser.H"
#include "Absyn.H"
#include "ParserError.H"
#include "Build.h"
#include "Risoluzione.h"
#include "Cancellazione.h"

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Uso: " << argv[0] << " <file.conf>" << std::endl;
        return 1;
    }

    FILE* input = fopen(argv[1], "r");
    if (!input) {
        std::cerr << "Impossibile aprire il file." << std::endl;
        return 1;
    }

    Config* parse_tree = nullptr;
    try {
        parse_tree = pConfig(input);
    } catch (parse_error& e) {
        std::cerr << "Errore di parsing alla riga " << e.getLine() << std::endl;
        return 1;
    }

    Conf* conf = dynamic_cast<Conf*>(parse_tree);
    Configurazione config = build(conf);

    std::cout << "Test resolve() su tutte le variabili:" << std::endl;
    for (const Sezione& s : config.sections) {
        for (const Campo& b : s.fields) {
            try {
                Valore v = resolve(config, s.name, b.name);
                std::cout << "  " << s.name << "." << b.name << " risolve correttamente" << std::endl;
            } catch (std::runtime_error& e) {
                std::cout << "  " << s.name << "." << b.name << " -> ERRORE: " << e.what() << std::endl;
            }
        }
    }

    delete parse_tree;
    return 0;
}