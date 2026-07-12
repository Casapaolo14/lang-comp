#include "Positions.h"

std::map<Sect*, int> rigaDiSezione;
std::map<Fld*, int> rigaDiField;

/* Funzione registraRigaSezione: registra la riga di inizio di una sezione,
usando il puntatore al nodo Sect* come chiave della mappa.
*/
void registraRigaSezione(Sect* s, int riga) {
    rigaDiSezione[s] = riga;
}

/* Funzione registraRigaField: registra la riga di inizio di un field,
usando il puntatore al nodo Fld* come chiave della mappa.
*/
void registraRigaField(Fld* f, int riga) {
    rigaDiField[f] = riga;
}