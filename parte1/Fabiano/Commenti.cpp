#include "Commenti.h"

std::vector<CommentoTrovato> commentiTrovati;

/*chiamata dal lexer quando riconosce un commento,
al posto di scartarlo (comportamento di default generato da BNFC) ne salva
testo e riga per poterlo poi reinserire nel pretty-printer.
*/
void salvaCommento(const std::string& testo, int riga) {
    commentiTrovati.push_back({riga, testo});
}