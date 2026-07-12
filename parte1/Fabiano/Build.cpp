#include "Build.h"
#include <set>
#include <iostream>
#include <cstdlib>
#include "Positions.h"
#include "Comments.h"

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

MyConfig build(Conf* ast) {
    MyConfig result;

    //definito un set così da poter controllare se una sezione si ripeterà, nel caso succeda allora: warning! (1)
    std::set<std::string> nomiSezioniViste;

    //Dato l'AST generato da BNFC, facciamo un for per ogni sezione che compare nella nostra configuazione
    for (Section* s : *(ast->listsection_)) {
        Sect* sect = dynamic_cast<Sect*>(s); //Ricordiamo che il cast ha sempre successo perchè Sect nel file BNFC ha solo Section
        
        //ecco il codice (1) che controlla che se il nome della sezione è già comparso precedentemente
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