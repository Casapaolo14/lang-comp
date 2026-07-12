#include "Delete.h"
#include "Resolve.h"

bool esisteRiferimentoA(const MyConfig& config, const std::string& sectionName, const std::string& varName) {
    for (const MySection& s : config.sections) {
        for (const Binding& b : s.fields) {
            if (b.value.kind == ValueKind::RefLocal) {
                // riferimento locale: la sezione "implicita" è quella in cui si trova il binding stesso
                if (s.name == sectionName && b.value.refName == varName) {
                    return true;
                }
            }
            else if (b.value.kind == ValueKind::RefQual) {
                if (b.value.refSection == sectionName && b.value.refName == varName) {
                    return true;
                }
            }
        }
    }
    return false;
}

bool cancellaBinding(MyConfig& config, const std::string& sectionName, const std::string& varName) {
    if (esisteRiferimentoA(config, sectionName, varName)) {
        return false;   // qualcuno lo referenzia, rifiutiamo
    }

    for (MySection& s : config.sections) {
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

bool cancellaSezione(MyConfig& config, const std::string& sectionName) {
    const MySection* sect = trovaSezione(config, sectionName);
    if (!sect) {
        return false;   // sezione non trovata
    }

    // controlliamo che nessun binding di QUESTA sezione sia referenziato altrove
    for (const Binding& b : sect->fields) {
        if (esisteRiferimentoA(config, sectionName, b.name)) {
            return false;   // qualcosa referenzia una variabile di questa sezione, rifiutiamo
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