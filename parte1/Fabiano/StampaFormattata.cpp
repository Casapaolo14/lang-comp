#include "StampaFormattata.h"
#include "Commenti.h"
#include <sstream>

std::string prettyPrintValue(const Valore& v) {
    switch (v.kind) {
        case ValueKind::Int:
            return std::to_string(v.ival);
        case ValueKind::Bool:
            return v.bval ? "true" : "false";
        case ValueKind::Str:
            return "\"" + v.sval + "\"";
        case ValueKind::RiferimentoSemplice:
            return "$" + v.refName;
        case ValueKind::RiferimentoConSezione:
            return "$" + v.refSection + "." + v.refName;
    }
    return "";
}

/* Funzione prettyPrint: invece di associare prima ogni commento a un elemento
e poi ristamparlo come se lo precedesse sempre (cosa che sposta i commenti "in
coda" e rende il round-trip instabile), qui i commenti vengono "scaricati" via
via che si stampa, nell'ordine in cui sono stati letti dal Lexer: prima di
ogni sezione/campo viene stampato ogni commento la cui riga originale non
supera quella dell'elemento; quelli rimasti dopo l'ultimo campo vengono
scaricati prima della chiusura della sezione, così un commento resta "dentro"
la sezione anche se segue l'ultimo campo. Eventuali commenti avanzati alla
fine (nessun elemento successivo li reclama) vengono stampati in coda.
*/
std::string prettyPrint(const Configurazione& config) {
    std::ostringstream out;

    size_t prossimo = 0;
    auto scaricaCommenti = [&](int finoARiga) {
        while (prossimo < commentiTrovati.size() && commentiTrovati[prossimo].riga <= finoARiga) {
            out << commentiTrovati[prossimo].testo << "\n";
            prossimo++;
        }
    };

    for (const Sezione& sect : config.sections) {
        scaricaCommenti(sect.riga);
        out << "<section name=" << sect.name << ">\n";

        for (const Campo& b : sect.fields) {
            scaricaCommenti(b.riga);
            out << "<field name=" << b.name << ">"
                << prettyPrintValue(b.value)
                << "</field>\n";
        }

        scaricaCommenti(sect.rigaChiusura);
        out << "</section>\n";
    }

    while (prossimo < commentiTrovati.size()) {
        out << commentiTrovati[prossimo].testo << "\n";
        prossimo++;
    }

    return out.str();
}