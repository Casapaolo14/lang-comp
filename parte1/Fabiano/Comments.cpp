#include "Comments.h"

std::vector<std::string> commentiTrovati;

void salvaCommento(const std::string& testo) {
    commentiTrovati.push_back(testo);
}