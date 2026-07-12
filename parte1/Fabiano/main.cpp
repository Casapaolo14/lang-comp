#include <cstdio>
#include <iostream>
#include "Parser.H"
#include "Absyn.H"
#include "ParserError.H"
#include "Build.h"
#include "Comments.h"
#include "Resolve.h"
#include "Delete.h"

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
    abbinaCommenti(config);

    // stampa "a occhio" per verificare che la conversione sia corretta
    for (const MySection& sect : config.sections) {
        std::cout << "Sezione: " << sect.name << " (riga " << sect.riga << ")" << std::endl;
        for (const std::string& c : sect.commenti) {
            std::cout << "  [commento sezione]: " << c << std::endl;
        }
        for (const Binding& b : sect.fields) {
            for (const std::string& c : b.commenti) {
                std::cout << "  [commento field]: " << c << std::endl;
            }
            std::cout << "  " << b.name << " (riga " << b.riga << ") = ";
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
    for (const CommentoTrovato& c : commentiTrovati) {
        std::cout << "riga " << c.riga << ": " << c.testo << std::endl;
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

    std::cout << "\n--- Test cancellazione ---" << std::endl;

    // Tentativo 1: cancellare nomesez1.var1 -> DEVE FALLIRE (referenziato da var3 nella stessa sezione,
    // e da nomesez3.miao tramite la catena)
    bool ok1 = cancellaBinding(config, "nomesez1", "var1");
    std::cout << "Cancellazione nomesez1.var1: " << (ok1 ? "RIUSCITA" : "RIFIUTATA") << std::endl;

    // Tentativo 2: cancellare nomesez2.var1 -> DEVE RIUSCIRE (nessuno lo referenzia)
    bool ok2 = cancellaBinding(config, "nomesez2", "var1");
    std::cout << "Cancellazione nomesez2.var1: " << (ok2 ? "RIUSCITA" : "RIFIUTATA") << std::endl;

    // Tentativo 3: cancellare l'intera sezione nomesez1 -> DEVE FALLIRE (var3 referenziata da nomesez3.miao)
    bool ok3 = cancellaSezione(config, "nomesez1");
    std::cout << "Cancellazione sezione nomesez1: " << (ok3 ? "RIUSCITA" : "RIFIUTATA") << std::endl;

    // Stampa finale per vedere cosa è rimasto
    std::cout << "\n--- Config dopo le cancellazioni ---" << std::endl;
    for (const MySection& sect : config.sections) {
        std::cout << "Sezione: " << sect.name << std::endl;
        for (const Binding& b : sect.fields) {
            std::cout << "  " << b.name << std::endl;
        }
    }

    delete parse_tree;
    return 0;
}