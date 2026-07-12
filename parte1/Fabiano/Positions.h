#ifndef POSITIONS_H
#define POSITIONS_H

#include <map>
#include "Absyn.H"

// Associa ogni puntatore Sect* alla riga in cui inizia
extern std::map<Sect*, int> rigaDiSezione;

// Associa ogni puntatore Fld* alla riga in cui inizia
extern std::map<Fld*, int> rigaDiField;

void registraRigaSezione(Sect* s, int riga);
void registraRigaField(Fld* f, int riga);

#endif