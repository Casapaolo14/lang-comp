#include "Cancellazione.h"
#include "Risoluzione.h"

/*scandisce tutti i binding di tutte le sezioni cercando un riferimento (semplice o sezione) 
che punti a (sectionName, varName).
Usata come controllo preventivo prima di ogni cancellazione, per evitare di lasciare
riferimenti pendenti.
*/
bool esisteRiferimentoA(const Configurazione& config, const std::string& sectionName, const std::string& varName) {
    for (const Sezione& s : config.sections) {
        for (const Campo& b : s.fields) {
            if (b.value.kind == ValueKind::RiferimentoSemplice) {
                // riferimento locale: la sezione è quella in cui si trova attualmente il binding
                if (s.name == sectionName && b.value.refName == varName) {
                    return true;
                }
            }
            else if (b.value.kind == ValueKind::RiferimentoConSezione) {
                if (b.value.refSection == sectionName && b.value.refName == varName) {
                    return true;
                }
            }
        }
    }
    return false;
}

/*cancella un singolo binding (sectionName, varName)
se esiste e se non è referenziato da nessun altro punto della configurazione;
altrimenti rifiuta la cancellazione restituendo false.
*/
bool cancellaCampo(Configurazione& config, const std::string& sectionName, const std::string& varName) {
    if (esisteRiferimentoA(config, sectionName, varName)) {
        return false;   // qualcuno lo referenzia, non lo cancelliamo
    }

    for (Sezione& s : config.sections) {
        if (s.name == sectionName) {
            for (size_t i = 0; i < s.fields.size(); i++) {
                if (s.fields[i].name == varName) {
                    s.fields.erase(s.fields.begin() + i);
                    return true;
                }
            }
            return false;   // sezione trovata, ma binding non trovato
        }
    }
    return false;   // sezione non trovata
}

/*cancella un'intera sezione solo se nessuno dei suoi
binding è referenziato da altre sezioni; altrimenti rifiuta la cancellazione
restituendo false, per non lasciare riferimenti pendenti.
*/
bool cancellaSezione(Configurazione& config, const std::string& sectionName) {
    const Sezione* sect = trovaSezione(config, sectionName);
    if (!sect) {
        return false;   // sezione non trovata
    }

    // controlliamo che nessun binding di QUESTA sezione sia referenziato da alre parti
    for (const Campo& b : sect->fields) {
        if (esisteRiferimentoA(config, sectionName, b.name)) {
            return false;   // la variabile in questa sezione è referenziata da un'altra sezione, non la cancelliamo
        }
    }

    for (size_t i = 0; i < config.sections.size(); i++) {
        if (config.sections[i].name == sectionName) {
            config.sections.erase(config.sections.begin() + i);
            return true;
        }
    }
    return false;
}