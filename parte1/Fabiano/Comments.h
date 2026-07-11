#ifndef COMMENTS_H
#define COMMENTS_H

#include <string>
#include <vector>

// lista globale dei commenti trovati nel file, nell'ordine in cui compaiono
extern std::vector<std::string> commentiTrovati;

// funzione per aggiungere un commento alla lista
void salvaCommento(const std::string& testo);

#endif