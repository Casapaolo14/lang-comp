#include "Build.h"
#include <set>
#include <iostream>
#include <cstdlib>
#include "Posizioni.h"


/* Funzione convertiValue: converte i valori dell'AST di BNFC nella struttura Valore
Utilizza il dynamic_cast per determinare il tipo di valore 
tra intero, booleano, stringa e riferimento impostando il flag 'kind'.
Nel caso dei riferimenti ($), distingue se sono locali o qualificati
separando il nome della sezione dal nome del campo.
 */
Valore convertiValue(Value* v) {
    Valore result;

    if (VInt* vi = dynamic_cast<VInt*>(v)) {
        result.kind = ValueKind::Int;
        result.ival = vi->integer_;
    }
    else if (VBool* vb = dynamic_cast<VBool*>(v)) {
        result.kind = ValueKind::Bool;
        result.bval = (dynamic_cast<BTrue*>(vb->boolean_) != nullptr);
    }
    else if (VStr* vs = dynamic_cast<VStr*>(v)) {
        result.kind = ValueKind::Str;
        result.sval = vs->string_;
    }
    else if (VRef* vr = dynamic_cast<VRef*>(v)) {
        if (RiferimentoSemplice* rl = dynamic_cast<RiferimentoSemplice*>(vr->ref_)) {
            result.kind = ValueKind::RiferimentoSemplice;
            result.refName = rl->ident_;
        } else if (RiferimentoConSezione* rq = dynamic_cast<RiferimentoConSezione*>(vr->ref_)) {
            result.kind = ValueKind::RiferimentoConSezione;
            result.refSection = rq->ident_1;
            result.refName = rq->ident_2;
        }
    }
    return result;
}

/* Funzione build: converte l'AST personalizzato basato su Configurazione ed esegue l'analisi semantica.
Effettua due controlli sull'AST di BNFC:
1. Rilevazione delle sezioni duplicate: se una sezione si ripete, genera un errore ed esce;
2. Avviso sui campi duplicati: se un campo si ripete nella stessa sezione, genera un warning. L'ultimo valore inserito sovrascrive i precedenti;
Infine ritorna un oggetto Configurazione validato.
 */
Configurazione build(Conf* ast) {
    Configurazione result;

    std::set<std::string> nomiSezioniViste;

    //for per ogni sezione che compare nella configuazione
    for (Section* s : *(ast->listsection_)) {
        Sect* sect = dynamic_cast<Sect*>(s);
        
        //controlla che se il nome della sezione è già comparso precedentemente
        if (nomiSezioniViste.count(sect->ident_)) {
            std::cerr << "Errore: sezione ripetuta '" << sect->ident_ << "'" << std::endl;
            exit(1);
        }
        nomiSezioniViste.insert(sect->ident_);

        Sezione mySect;
        mySect.name = sect->ident_;
        mySect.riga = rigaDiSezione[sect];
        mySect.rigaChiusura = rigaChiusuraSezione[sect];

        std::set<std::string> nomiCampiVisti;
        for (Field* f : *(sect->listfield_)) {
            Fld* fld = dynamic_cast<Fld*>(f);

            //controlla se una sezione si ripete e nel caso succeda genera un warning
            if (nomiCampiVisti.count(fld->ident_)) {
                std::cerr << "Warning: ridefinizione di '" << fld->ident_
                          << "' nella sezione '" << sect->ident_ << "'" << std::endl;
            }
            nomiCampiVisti.insert(fld->ident_);

            Valore v = convertiValue(fld->value_);
            Campo nuovoCampo;
            nuovoCampo.name = fld->ident_;
            nuovoCampo.value = v;
            nuovoCampo.riga = rigaDiField[fld];
            mySect.fields.push_back(nuovoCampo);
        }
        result.sections.push_back(mySect);
    }
    return result;
}