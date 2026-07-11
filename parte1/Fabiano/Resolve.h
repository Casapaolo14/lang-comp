#ifndef RESOLVE_H
#define RESOLVE_H

#include "MyConfig.h"

// Cerca il valore risolto (senza riferimenti) di una variabile in una sezione.
// Lancia un'eccezione (std::runtime_error) se non trovata o se c'è un ciclo.
MyValue resolve(const MyConfig& config, const std::string& sectionName, const std::string& varName);
const MySection* trovaSezione(const MyConfig& config, const std::string& sectionName);
const Binding* trovaBinding(const MySection& sect, const std::string& varName);

#endif