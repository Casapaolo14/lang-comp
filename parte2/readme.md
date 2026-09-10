# Roadmap — Progetto LC 24-14 (fac simile)

Linguaggio imperativo, sintassi concreta Chapel-like, implementato in Haskell con Alex/Happy (+ BNFC come prototipo). Stima totale: **~31–50 ore**, variabile in base all'esperienza pregressa.

Modo di lavoro: per ogni step, leggo prima le pagine indicate, poi scrivo io il codice (pezzo alla volta) seguendo le istruzioni, verificando insieme prima di passare allo step successivo.

---

## Step 1 — Architettura generale + ripasso grammatiche libere dal contesto
**Stato: ✅ completato**
**Pagine:** 6–15, 16–28, 178–180
**Durata stimata:** 1–2 h

Cosa fare:
- Decidere la pipeline: Lexer (Alex) → Parser (Happy) → AST non attribuita → type checker (ambiente esplicito) → generatore TAC (state monad) → pretty-printer sorgente/TAC.
- Ripassare ambiguità classiche (dangling-else, precedenza operatori) e come risolverle.
- Leggere le raccomandazioni pratiche P1–P9 (conflitti da giustificare, roundtrip pretty-print, combinazioni array/puntatore, l-expr composte, niente error recovery in Happy).
- Elencare i costrutti del linguaggio da includere in grammatica (dichiarazioni, tipi, istruzioni, funzioni predefinite, espressioni).

---

## Step 2 — Sintassi concreta/astratta + prototipo BNFC
**Stato: ✅ completato e validato in locale dall'utente** (`bnfc`+`make`: 68 rules accepted, 0 conflitti shift/reduce; 4 test case eseguiti — precedenza, dangling-else, array-di-puntatori/l-expr composte P9, programma completo — tutti con AST corretto, output confermato via terminale dell'utente)
**Pagine:** 29–52
**Durata stimata:** 3–5 h

Cosa fare:
- Scrivere `Lang.cf` (formato LBNF) pezzo per pezzo: entrypoint, `TopDecl` (var/proc), `Param`/`Intent`, `Type` (base, array, puntatore), `Stmt`/`Block`, `Exp` con precedenza tramite categorie numerate + `coercions`.
- Decidere e annotare le scelte di sintassi concreta (assunzioni): `c_ptr(T)`/`c_ptrTo`/`*` per i puntatori, `[a..b] T` per gli array, `ref` per il passaggio per riferimento.
- Lanciare `bnfc --haskell Lang.cf`, poi `make` per generare/compilare lexer, parser, AST, pretty-printer di prototipo.
- Verificare assenza di conflitti shift/reduce (`ParLang.info`).
- Testare con programmi di prova (inclusi i casi limite P8/P9: array di puntatori, l-expr composte con `*` e `[ ]`).

---

## Step 3 — Lexer con Alex
**Stato: ✅ completato e validato in locale dall'utente** (P1/P2 corretti di default; P3 — notazione scientifica — richiedeva un fix manuale alla regex `Double` in `LexLinguaggio.x`, applicato e verificato con `e`/`E`/`+`/`-`; maximal munch keyword-vs-identificatori verificato; test finale integrato con commenti multi-riga, escape, notazione scientifica e identificatore con prefisso keyword insieme — tutti superati; toolchain fissata a GHC 9.2.8 + BNFC 2.9.1 esatti, come richiesto dal testo)
**Pagine:** 132–154
**Durata stimata:** 2–3 h

Cosa fare:
- Ripassare la teoria dell'analisi lessicale (automi, espressioni regolari) nella parte teorica.
- Raffinare a mano `LexLang.x` generato da BNFC (o scriverlo da zero): categorie di token, identificatori vs parole chiave, commenti, literal (interi, reali, caratteri, stringhe con escape).
- Gestire correttamente casi ambigui (es. notazione scientifica per i `real`, se prevista).

---

## Step 4 — Parser Happy monadico + AST definitiva
**Stato: ✅ completato (solo verifica, nessuna modifica al codice necessaria)** — `%monad`/`Err = Either String` già puro (niente `IORef`/`STRef`); `happyError` testato su 3 casi reali (token inatteso, punto e virgola mancante, EOF) e giudicato adeguato; scelta motivata di non implementare `catch`/error-recovery di Happy (coerente con le raccomandazioni del corso); `AbsLinguaggio.hs` verificato conforme al design (`Exp` unificata, livelli di precedenza scomparsi dopo `coercions`, come atteso)
**Pagine:** 155–177, 265–267, 268–297, 298–307, 381–390
**Durata stimata:** 4–6 h

Cosa fare:
- Passare da grammatica BNFC a `Parser.y` Happy scritto/raffinato a mano, con `%monad { Either String }` (o simile) per la gestione degli errori di parsing.
- Definire `happyError`.
- Verificare/giustificare eventuali conflitti shift/reduce residui.
- Consolidare la sintassi astratta definitiva in `AbsSyntax.hs`.

---

## Step 5 — Visibilità e progettazione del sistema di tipi
**Stato: ✅ completato (design)** — visibilità dal punto di dichiarazione a fine blocco + doppio passaggio per mutua ricorsione, scoping statico; compatibilità tipi semplici (solo INT→REAL, ERROR assorbente, grafo disegnato); compatibilità array/puntatori (invarianza totale, nessun widening); regole parametri T6 (valore, compatibile)/T7 (riferimento, identico + l-expr); principi T1/T2/T4/S1/S2/S3 applicati (AST aumentata con tipi, nodi di cast espliciti, ambiente esplicito senza stack, array a inizializzazione obbligatoria — nota: solo per copia/chiamata funzione, niente letterali array in grammatica)
**Pagine:** 305–307, 308–334, 358–363
**Durata stimata:** 2–3 h

Cosa fare:
- Definire la regola di visibilità (dal punto di dichiarazione alla fine del blocco, con pre-scan delle intestazioni delle funzioni per la mutua ricorsione).
- Disegnare il grafo/tabella di compatibilità tra tipi semplici (incluso tipo `ERROR` assorbente).
- Specificare formalmente la compatibilità tra tipi composti (array: solo stesso tipo; puntatori: da definire con attenzione ai riferimenti "morti").

---

## Step 6 — Type checker (implementazione)
**Stato: ✅ completato e validato in locale dall'utente** — 5 file (`SemTypes.hs`, `Environment.hs`, `TypedAst.hs`, `TypeErrors.hs`, `TypeCheck.hs`); ambiente esplicito senza stato mutabile (S2); `sup`/`mathtype`/`rel`/`assignableTo` per la compatibilità (Step 5); AST aumentata con tipo+posizione su ogni nodo e cast espliciti (T1/T2); `checkExp` su tutti i 24 costruttori, `checkStmt` su tutti i 9, `checkTopDecl` con inizializzazione array obbligatoria (S3); doppio passaggio per mutua ricorsione (T4) verificato con funzioni annidate mutuamente ricorsive; parametri per valore/riferimento (T6/T7) e invarianza puntatori verificati con test mirati; 5 errori distinti su un unico programma riportati tutti insieme (S1), nessun falso positivo su un caso di widening valido
**Pagine:** 348–363
**Durata stimata:** 6–10 h

Cosa fare:
- Implementare l'ambiente come mappe passate esplicitamente (niente `IORef`/`STRef`, niente stack mutabile).
- Implementare la funzione di type-checking per espressioni e istruzioni (schema SDD con attributo sintetizzato `errs`).
- Gestire le funzioni predefinite (`writeInt`, `readInt`, ecc.) come ambiente iniziale, non come regole di grammatica.
- Messaggi d'errore precisi (entità coinvolta, posizione nel sorgente).
- Validare le regole sul passaggio parametri per valore/riferimento (T6/T7).

---

## Step 7 — TAC: datatype e schema per espressioni/controllo di flusso
**Stato: 🔄 prossimo**
**Pagine:** 402–492
**Durata stimata:** 4–6 h

Cosa fare:
- Definire il datatype Haskell per `Address` (ProgVar/TacLit/Temporary) e per le istruzioni TAC (no stringhe di caratteri).
- Schema di generazione per espressioni aritmetiche (l-value prima di r-value negli assegnamenti).
- Schema "jumping code" per espressioni booleane short-circuit (etichette true/false).
- Schema per `if`/`if-else`/`while`.

---

## Step 8 — TAC in front-end modulare: state monad, funzioni, parametri
**Pagine:** 493–550
**Durata stimata:** 6–10 h

Cosa fare:
- Implementare `newtemp`/`newlabel` con la libreria `Control.Monad.Trans.State` (niente riferimenti mutabili).
- Generare TAC per array multidimensionali e accesso puntatori.
- Generare TAC per chiamate a funzione/procedura secondo le modalità di parametro scelte (per valore, per riferimento), rispettando il vincolo esplicito della spec (il parametro attuale passato per valore non deve essere alterato).

---

## Step 9 — Pretty-printer, Main, test case, Makefile + demo
**Pagine:** nessuna specifica (tecniche standard)
**Durata stimata:** 3–5 h

Cosa fare:
- Pretty-printer TAC con annotazione del punto di dichiarazione (es. `t37 = x_12 + 5`).
- Funzione `Main` che, dato un file: fa parsing → type-check → pretty-print del sorgente → genera e stampa il TAC.
- Test case significativi (uno per costrutto/caso limite rilevante).
- `Makefile` conforme GNU make con target di default e `make demo`.

---

## Promemoria trasversali
- GHC → 9.2.8, BNFC → 2.9.1 richiesti per la consegna reale (il sandbox usa versioni leggermente diverse, solo per validare la logica).
- Vietati `Data.IORef` e `Data.STRef` ovunque nel progetto.
- Nella relazione: solo tecniche non standard, assunzioni fatte, versioni strumenti — niente riassunto del testo dell'esercizio.