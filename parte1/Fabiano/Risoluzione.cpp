#include "Risoluzione.h"
#include <stdexcept>
#include <set>

/* Funzione trovaSezione: cerca linearmente la sezione con nome sectionName.
Restituisce nullptr se non esiste.
*/
const Sezione* trovaSezione(const Configurazione& config, const std::string& sectionName) {
    for (const Sezione& s : config.sections) {
        if (s.name == sectionName) {
            return &s;
        }
    }
    return nullptr;
}

/* Funzione trovaCampo: cerca linearmente, dentro una sezione già trovata,
il binding con nome varName. Restituisce nullptr se non esiste.
*/
const Campo* trovaCampo(const Sezione& sect, const std::string& varName) {
    for (const Campo& b : sect.fields) {
        if (b.name == varName) {
            return &b;
        }
    }
    return nullptr;
}

/* Funzione resolve: segue la catena di riferimenti (locali e qualificati) a partire
da (sectionName, varName) fino a un valore base (Int/Bool/Str). Ad ogni passo
la coppia corrente viene marcata come "visitata" in una chiave testuale "sezione.nome":
se si ripresenta la stessa chiave significa che c'è un ciclo, e si lancia un'eccezione.
Lancia eccezioni anche se la sezione o la variabile cercata non esistono.
*/
Valore resolve(const Configurazione& config, const std::string& sectionName, const std::string& varName) {
    std::set<std::string> visitati;   // per rilevare cicli

    std::string currentSection = sectionName;
    std::string currentName = varName;

    while (true) {
        std::string chiave = currentSection + "." + currentName;
        if (visitati.count(chiave)) {
            throw std::runtime_error("Ciclo di riferimenti rilevato su " + chiave);
        }
        visitati.insert(chiave);

        const Sezione* sect = trovaSezione(config, currentSection);
        if (!sect) {
            throw std::runtime_error("Sezione non trovata: " + currentSection);
        }

        const Campo* b = trovaCampo(*sect, currentName);
        if (!b) {
            throw std::runtime_error("Variabile non trovata: " + currentName + " in " + currentSection);
        }

        const Valore& v = b->value;

        if (v.kind == ValueKind::Int || v.kind == ValueKind::Bool || v.kind == ValueKind::Str) {
            return v;   // valore base, fine della catena
        }
        else if (v.kind == ValueKind::RiferimentoSemplice) {
            currentName = v.refName;
            // currentSection resta la stessa
        }
        else if (v.kind == ValueKind::RiferimentoConSezione) {
            currentSection = v.refSection;
            currentName = v.refName;
        }
    }
}