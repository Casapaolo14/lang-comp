#include "Build.h"
#include <set>
#include <iostream>
#include <cstdlib>
#include "Positions.h"
#include "Comments.h"


/* Funzione convertiValue: converte i valori dell'AST di BNFC nella struttura MyValue
Utilizza il dynamic_cast per determinare il tipo di valore 
tra intero, booleano, stringa e riferimento impostando il flag 'kind'.
Nel caso dei riferimenti ($), distingue se sono locali o qualificati
separando il nome della sezione dal nome del campo.
 */
MyValue convertiValue(Value* v) {
    MyValue result;

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
        if (RefLocal* rl = dynamic_cast<RefLocal*>(vr->ref_)) {
            result.kind = ValueKind::RefLocal;
            result.refName = rl->ident_;
        } else if (RefQual* rq = dynamic_cast<RefQual*>(vr->ref_)) {
            result.kind = ValueKind::RefQual;
            result.refSection = rq->ident_1;
            result.refName = rq->ident_2;
        }
    }
    return result;
}

/* Funzione build: costruisce l'AST personalizzato basato su MyConfig ed esegue l'analisi semantica.
Effettua due controlli sull'AST di BNFC:
1. Rilevazione delle sezioni duplicate: se una sezione si ripete, genera un errore ed esce;
2. Avviso sui campi duplicati: se un campo si ripete nella stessa sezione, genera un warning. L'ultimo valore inserito sovrascrive i precedenti;
Infine ritorna un oggetto MyConfig validato.
 */
MyConfig build(Conf* ast) {
    MyConfig result;

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

        MySection mySect;
        mySect.name = sect->ident_;
        mySect.riga = rigaDiSezione[sect];

        std::set<std::string> nomiCampiVisti;
        for (Field* f : *(sect->listfield_)) {
            Fld* fld = dynamic_cast<Fld*>(f);

            //controlla se una sezione si ripete e nel caso succeda genera un warning
            if (nomiCampiVisti.count(fld->ident_)) {
                std::cerr << "Warning: ridefinizione di '" << fld->ident_
                          << "' nella sezione '" << sect->ident_ << "'" << std::endl;
            }
            nomiCampiVisti.insert(fld->ident_);

            MyValue v = convertiValue(fld->value_);
            Binding nuovoBinding;
            nuovoBinding.name = fld->ident_;
            nuovoBinding.value = v;
            nuovoBinding.riga = rigaDiField[fld];
            mySect.fields.push_back(nuovoBinding);
        }
        result.sections.push_back(mySect);
    }
    return result;
}


/** Funzione abbinaCommenti: associa i commenti incontrati dal Lexer agli elementi corretti dell'AST.
 * Per ogni commento cerca la sezione o il campo più vicino che lo precede,
 * confrontando i numeri di riga salvati. Il commento viene fissato 
 * alla struttura dati (MySection o Binding) per consentire al Pretty-Printer 
 * di riprodurlo nella sua posizione originale.
 */
void abbinaCommenti(MyConfig& config) {
    for (const CommentoTrovato& c : commentiTrovati) {
        MySection* miglioreS = nullptr;
        Binding* miglioreB = nullptr;
        int migliorRiga = -1;

        MySection* primoSuccessivoS = nullptr;
        Binding* primoSuccessivoB = nullptr;
        int primaRigaSuccessiva = -1;

        for (MySection& s : config.sections) {
            if (s.riga <= c.riga && s.riga > migliorRiga) {
                migliorRiga = s.riga;
                miglioreS = &s;
                miglioreB = nullptr;
            }
            if (s.riga > c.riga && (primaRigaSuccessiva == -1 || s.riga < primaRigaSuccessiva)) {
                primaRigaSuccessiva = s.riga;
                primoSuccessivoS = &s;
                primoSuccessivoB = nullptr;
            }

            for (Binding& b : s.fields) {
                if (b.riga <= c.riga && b.riga > migliorRiga) {
                    migliorRiga = b.riga;
                    miglioreS = &s;
                    miglioreB = &b;
                }
                if (b.riga > c.riga && (primaRigaSuccessiva == -1 || b.riga < primaRigaSuccessiva)) {
                    primaRigaSuccessiva = b.riga;
                    primoSuccessivoS = &s;
                    primoSuccessivoB = &b;
                }
            }
        }

        if (miglioreB) {
            miglioreB->commenti.push_back(c.testo);
        } else if (miglioreS) {
            miglioreS->commenti.push_back(c.testo);
        } else if (primoSuccessivoB) {
            primoSuccessivoB->commenti.push_back(c.testo);
        } else if (primoSuccessivoS) {
            primoSuccessivoS->commenti.push_back(c.testo);
        }
    }
}