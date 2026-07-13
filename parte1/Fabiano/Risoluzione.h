#ifndef RISOLUZIONE_H
#define RISOLUZIONE_H

#include "Configurazione.h"

// Cerca il valore risolto (senza riferimenti) di una variabile in una sezione.
// Lancia un'eccezione (std::runtime_error) se non trovata o se c'è un ciclo.
Valore resolve(const Configurazione& config, const std::string& sectionName, const std::string& varName);
const Sezione* trovaSezione(const Configurazione& config, const std::string& sectionName);
const Campo* trovaCampo(const Sezione& sect, const std::string& varName);

#endif