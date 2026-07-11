#include <cstdio>
#include <iostream>
#include "Parser.H"
#include "Absyn.H"
#include "ParserError.H"
#include "Build.h"
#include "Comments.h"
#include "Resolve.h"

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

    MyConfig config = build(conf);

    // stampa "a occhio" per verificare che la conversione sia corretta
    for (const MySection& sect : config.sections) {
        std::cout << "Sezione: " << sect.name << std::endl;
        for (const Binding& b : sect.fields) {
            std::cout << "  " << b.name << " = ";
            switch (b.value.kind) {
                case ValueKind::Int:  std::cout << b.value.ival; break;
                case ValueKind::Bool: std::cout << (b.value.bval ? "true" : "false"); break;
                case ValueKind::Str:  std::cout << "\"" << b.value.sval << "\""; break;
                case ValueKind::RefLocal: std::cout << "$" << b.value.refName; break;
                case ValueKind::RefQual:  std::cout << "$" << b.value.refSection << "." << b.value.refName; break;
            }
            std::cout << std::endl;
        }
    }

    std::cout << "\n--- Commenti trovati (" << commentiTrovati.size() << ") ---" << std::endl;
    for (const std::string& c : commentiTrovati) {
        std::cout << c << std::endl;
    }

    std::cout << "\n--- Test resolve() ---" << std::endl;
    try {
        MyValue risolto = resolve(config, "nomesez3", "miao");
        std::cout << "nomesez3.miao risolve a: ";
        switch (risolto.kind) {
            case ValueKind::Int:  std::cout << risolto.ival; break;
            case ValueKind::Bool: std::cout << (risolto.bval ? "true" : "false"); break;
            case ValueKind::Str:  std::cout << "\"" << risolto.sval << "\""; break;
            default: std::cout << "(non dovrebbe succedere)"; break;
        }
        std::cout << std::endl;
    } catch (std::runtime_error& e) {
        std::cerr << "Errore in resolve: " << e.what() << std::endl;
    }

    delete parse_tree;
    return 0;
}