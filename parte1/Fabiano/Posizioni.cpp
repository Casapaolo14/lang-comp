#include "Posizioni.h"

std::map<Sect*, int> rigaDiSezione;
std::map<Sect*, int> rigaChiusuraSezione;
std::map<Fld*, int> rigaDiField;

/*registra la riga di inizio di una sezione,
usando il puntatore al nodo Sect* come chiave della mappa.
*/
void registraRigaSezione(Sect* s, int riga) {
    rigaDiSezione[s] = riga;
}

/*registra la riga del tag "</section>"
che chiude la sezione, usando il puntatore al nodo Sect* come chiave.
Serve per poter ristampare nel punto giusto un commento che nel file
originale si trova dopo l'ultimo campo, prima della chiusura della sezione.
*/
void registraChiusuraSezione(Sect* s, int riga) {
    rigaChiusuraSezione[s] = riga;
}

/*registra la riga di inizio di un field,
usando il puntatore al nodo Fld* come chiave della mappa.
*/
void registraRigaField(Fld* f, int riga) {
    rigaDiField[f] = riga;
}