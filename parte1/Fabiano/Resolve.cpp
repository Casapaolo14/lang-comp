#include "Resolve.h"
#include <stdexcept>
#include <set>

const MySection* trovaSezione(const MyConfig& config, const std::string& sectionName) {
    for (const MySection& s : config.sections) {
        if (s.name == sectionName) {
            return &s;
        }
    }
    return nullptr;
}

const Binding* trovaBinding(const MySection& sect, const std::string& varName) {
    for (const Binding& b : sect.fields) {
        if (b.name == varName) {
            return &b;
        }
    }
    return nullptr;
}

MyValue resolve(const MyConfig& config, const std::string& sectionName, const std::string& varName) {
    std::set<std::string> visitati;   // per rilevare cicli

    std::string currentSection = sectionName;
    std::string currentName = varName;

    while (true) {
        std::string chiave = currentSection + "." + currentName;
        if (visitati.count(chiave)) {
            throw std::runtime_error("Ciclo di riferimenti rilevato su " + chiave);
        }
        visitati.insert(chiave);

        const MySection* sect = trovaSezione(config, currentSection);
        if (!sect) {
            throw std::runtime_error("Sezione non trovata: " + currentSection);
        }

        const Binding* b = trovaBinding(*sect, currentName);
        if (!b) {
            throw std::runtime_error("Variabile non trovata: " + currentName + " in " + currentSection);
        }

        const MyValue& v = b->value;

        if (v.kind == ValueKind::Int || v.kind == ValueKind::Bool || v.kind == ValueKind::Str) {
            return v;   // valore base, fine della catena
        }
        else if (v.kind == ValueKind::RefLocal) {
            currentName = v.refName;
            // currentSection resta la stessa
        }
        else if (v.kind == ValueKind::RefQual) {
            currentSection = v.refSection;
            currentName = v.refName;
        }
    }
}