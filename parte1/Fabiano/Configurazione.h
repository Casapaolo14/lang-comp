#ifndef CONFIGURAZIONE_H
#define CONFIGURAZIONE_H

#include <string>
#include <vector>

enum class ValueKind { Int, Bool, Str, RiferimentoSemplice, RiferimentoConSezione };

struct Valore {
    ValueKind kind;
    int ival = 0;
    bool bval = false;
    std::string sval;
    std::string refSection;
    std::string refName;
};

struct Campo {
    std::string name;
    Valore value;
    int riga = 0;
};

struct Sezione {
    std::string name;
    int riga = 0;
    int rigaChiusura = 0;
    std::vector<Campo> fields;
};

struct Configurazione {
    std::vector<Sezione> sections;
};

#endif