#include "Positions.h"

std::map<Sect*, int> rigaDiSezione;
std::map<Fld*, int> rigaDiField;

void registraRigaSezione(Sect* s, int riga) {
    rigaDiSezione[s] = riga;
}

void registraRigaField(Fld* f, int riga) {
    rigaDiField[f] = riga;
}