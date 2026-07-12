#ifndef DELETE_H
#define DELETE_H

#include "MyConfig.h"

// Restituisce true se esiste, in qualunque sezione, un binding che referenzia (sectionName, varName)
bool esisteRiferimentoA(const MyConfig& config, const std::string& sectionName, const std::string& varName);

// Cancella un singolo binding. Restituisce true se cancellato, false se rifiutato (referenziato altrove)
bool cancellaBinding(MyConfig& config, const std::string& sectionName, const std::string& varName);

// Cancella un'intera sezione. Restituisce true se cancellata, false se rifiutata (qualcosa la referenzia)
bool cancellaSezione(MyConfig& config, const std::string& sectionName);

#endif