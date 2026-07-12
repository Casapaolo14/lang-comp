#include "Comments.h"

std::vector<CommentoTrovato> commentiTrovati;

void salvaCommento(const std::string& testo, int riga) {
    commentiTrovati.push_back({riga, testo});
}