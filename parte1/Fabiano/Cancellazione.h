#define CANCELLAZIONE_H

#include "Configurazione.h"

// Restituisce true se esiste, in qualunque sezione, un binding che referenzia (sectionName, varName)
bool esisteRiferimentoA(const Configurazione& config, const std::string& sectionName, const std::string& varName);

// Cancella un singolo binding. Restituisce true se cancellato, false se rifiutato (referenziato altrove)
bool cancellaCampo(Configurazione& config, const std::string& sectionName, const std::string& varName);

// Cancella un'intera sezione. Restituisce true se cancellata, false se rifiutata (qualcosa la referenzia)
bool cancellaSezione(Configurazione& config, const std::string& sectionName);