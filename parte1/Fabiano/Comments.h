#ifndef COMMENTS_H
#define COMMENTS_H

#include <string>
#include <vector>

struct CommentoTrovato {
    int riga;
    std::string testo;
};

extern std::vector<CommentoTrovato> commentiTrovati;

void salvaCommento(const std::string& testo, int riga);

#endif