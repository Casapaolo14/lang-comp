# Roadmap di lavoro — Progetto LC Parte 2, Gruppo 24-14

> ⚠️ **File di lavoro interno: NON va incluso nello ZIP di consegna.**
> Contiene una rielaborazione dei requisiti della traccia, che la traccia vieta di includere sia nella relazione sia nello ZIP.
> Tenerlo fuori dalla cartella del progetto, oppure cancellarlo prima di creare lo ZIP.

## Strumenti

| Strumento | Versione |
|---|---|
| GHC | 9.2.8 |
| BNFC | 2.9.1 |
| Alex | 3.5.4.2 |
| Happy | 2.2 |

Suggerimento per lo sviluppo (il Makefile consegnato non cambia): compilare con
`make GHC_OPTS=-Wincomplete-patterns`, così GHC segnala ogni caso dimenticato nei `case` dopo l'aggiunta di nuovi costruttori.

## Metodo di lavoro

Si modifica solo ciò che serve a soddisfare un requisito della traccia. Per ogni voce:

1. si individua il requisito (codice R) e la modifica minima necessaria;
2. si scrive il codice;
3. si scrive un test `.lang` che dimostra il requisito;
4. si verifica l'output insieme;
5. si aggiorna lo stato qui sotto e si scrive la nota per la relazione nella sezione dello step.

## Requisiti di riferimento

| Codice | Requisito | Stato |
|---|---|---|
| R1 | `==`/`!=` solo su bool, char, int, real; `<` `<=` `>` `>=` solo su int, real | 🔧 |
| R2 | Operazioni aritmetiche solo su tipi numerici | 🔧 |
| R3 | Semantica canonica del passaggio per riferimento | 🔧 |
| R4 | Array passato per valore non modificato nel chiamante | ⬜ |
| R5 | Puntatori a tipi qualsiasi con selezione, incluso `(*p)[i]` | 🔧 |
| R6 | if-then-else come espressione | ⬜ |
| R7 | `+=`, `-=`, `*=` con semantica canonica | ⬜ |
| R8 | do-while e iterazione determinata (`for`) | ⬜ |
| R9 | `break`/`continue` ammessi solo nei cicli | ⬜ |
| R10 | Visibilità definita e coerente per ogni dichiarazione (ridichiarazione, shadowing) | 🔧 |
| R11 | Messaggi d'errore con entità coinvolte e posizione | 🔧 |
| R12 | Identificatori del programma annotati con la riga nel TAC | 🔧 |
| R13 | TAC corretto per le procedure (`return` finale) | 🔧 |
| R14 | Grafico dei tipi semplici, regole formali dei tipi composti, variabile del for | ⬜ |
| R15 | Scelte motivate su short-cut e ordine di valutazione | ✅ (solo relazione) |
| R16 | `make demo` con test significativi | 🔧 |
| R17 | Relazione autocontenuta | ⬜ |

## Legenda

Stati: ✅ fatto · 🔧 da correggere · ⬜ da fare.

Colonna "In relazione":
- **cita**: una frase sulla scelta fatta (usata anche per le tecniche standard del corso, che non vanno spiegate);
- **descrivi**: breve spiegazione dell'implementazione o della motivazione;
- **assunzione**: scelta non prevista dalla traccia, da motivare.

---

## Step 1 — Lessico, grammatica e serializzazione (stima 4 h)

| Voce | Stato | In relazione |
|---|---|---|
| Lexer: commenti `//` e `/* */`, letterali, escape, notazione scientifica | ✅ | cita |
| Precedenze con categorie numerate e coercions, nessun conflitto | ✅ | cita (numero di regole, zero conflitti) |
| Dichiarazioni `var`/`proc` in qualsiasi blocco, procedure come funzioni `void` | ✅ | cita |
| Tipi: base, `[lo..hi] T`, `c_ptr(T)`, `c_ptrTo(e)`, `*e` | ✅ | assunzione (sintassi di array e puntatori) |
| Passaggio per valore (default) e `ref` | ✅ | cita |
| if, if-else, while con sintassi Chapel | ✅ | cita |
| Pretty-print del sorgente con formattazione minima | ✅ | cita |
| do-while (R8) | ⬜ | cita |
| `for i in a..b` (R8) | ⬜ | descrivi (scelta della forma) |
| `break`/`continue` (R9) | ⬜ | cita |
| `+=`, `-=`, `*=` (R7) | ⬜ | cita |
| if-then-else come espressione (R6) | ⬜ | descrivi (sintassi e precedenza) |
| Controllo dei conflitti dopo le modifiche | ⬜ | cita |

**Note per la relazione:**
- _(da compilare)_

---

## Step 2 — Progettazione del sistema di tipi, su carta (stima 2 h)

| Voce | Stato | In relazione |
|---|---|---|
| Tipi base e composti; int compatibile con real e non viceversa | ✅ | grafico |
| Array e puntatori compatibili solo con tipi identici | ✅ | descrivi con regole formali (da scrivere) |
| Visibilità delle variabili: dal punto di dichiarazione a fine blocco | ✅ | descrivi |
| Visibilità delle funzioni: tutto il blocco | ✅ | descrivi la regola; la pre-scansione va solo citata |
| Parametri: visibili in tutto il corpo | ✅ | descrivi |
| Ridichiarazione e shadowing (R10) | ⬜ | descrivi |
| Overloading di `==`/`!=` e degli operatori d'ordine (R1) | ⬜ | descrivi (tabella delle istanze) |
| Variabile del for: dichiarazione implicita e non modificabile | ⬜ | descrivi |
| Tipo dell'if-espressione e regola di tipo per `op=` | ⬜ | descrivi |

**Note per la relazione:**
- _(da compilare)_

---

## Step 3 — Type checker (stima 9 h)

| Voce | Stato | In relazione |
|---|---|---|
| Ambiente con mappe separate per variabili e funzioni, passato esplicitamente | ✅ | cita |
| Funzioni predefinite nell'ambiente iniziale | ✅ | cita |
| Raccolta di tutti gli errori, senza errori a cascata | ✅ | cita |
| Cast espliciti nell'AST tipizzato | ✅ | cita |
| Mutua ricorsione | ✅ | cita |
| Parametri `ref`: l-expression di tipo identico | ✅ | cita |
| Controllo dei `return`, delle guardie bool e degli indici int | ✅ | cita |
| Tipo dichiarato mantenuto anche con un inizializzatore errato | ✅ | assunzione |
| Restrizione dei confronti (R1) | 🔧 | vedi Step 2 |
| Operazioni aritmetiche solo su tipi numerici (R2) | 🔧 | — |
| Ridichiarazione e falso errore sullo shadowing di funzioni (R10) | 🔧 | vedi Step 2 |
| Messaggi con i tipi e i nomi coinvolti (R11) | 🔧 | cita |
| Posizione dei parametri passati per valore (R12) | 🔧 | — |
| Marcatura dei parametri `ref` nell'AST tipizzato (serve per R3) | ⬜ | descrivi brevemente |
| if-espressione, `op=`, do-while, for, break/continue (R6–R9) | ⬜ | cita |

**Note per la relazione:**
- _(da compilare)_

---

## Step 4 — Generazione del TAC (stima 12 h, include lo Step 5)

| Voce | Stato | In relazione |
|---|---|---|
| Datatype TAC (non stringhe), indirizzi di tre categorie | ✅ | cita |
| Etichette come elemento a sé nella sequenza di codice | ✅ | descrivi (scelta non standard) |
| State monad per temporanei ed etichette | ✅ | cita |
| Ordine di valutazione da sinistra a destra | ✅ | descrivi (motivazione richiesta, R15) |
| l-value prima di r-value | ✅ | cita |
| Short-cut nelle guardie | ✅ | cita |
| Valutazione dei booleani fuori dalle guardie | ✅ | descrivi (motivazione richiesta, R15) |
| Array multidimensionali per righe, offset in elementi | ✅ | assunzione |
| `IIndexAddr` per l'indirizzo di un elemento, stringhe letterali nel TAC | ✅ | assunzione |
| Funzioni annidate generate come routine separate | ✅ | cita |
| Array dichiarati senza inizializzazione | ✅ | assunzione |
| Uso dei parametri `ref` tramite puntatore nel chiamato (R3) | 🔧 | descrivi brevemente |
| Copia degli array passati per valore e in `a = b` (R4) | ⬜ | descrivi |
| Indicizzazione tramite puntatore, `(*p)[i]` (R5) | 🔧 | cita |
| `return` finale delle procedure (R13) | 🔧 | cita |
| do-while (R8) | ⬜ | cita (schema visto a lezione) |
| `for`, `op=`, if-espressione, break/continue (R6–R9) | ⬜ | descrivi gli schemi TAC (non forniti a lezione) |

**Note per la relazione:**
- _(da compilare)_

---

## Step 5 — Pretty-print del TAC e Main (compreso nello Step 4)

| Voce | Stato | In relazione |
|---|---|---|
| `Main`: parsing → semantica statica → stampa del sorgente → TAC | ✅ | cita |
| Errori di parsing ed errori di tipo mostrati separatamente | ✅ | cita |
| Identificatori annotati con la riga di dichiarazione (`x_12`) | ✅ | cita |
| Riga anche per i parametri senza `ref` e per i nomi di funzione (R12) | 🔧 | — |

**Note per la relazione:**
- _(da compilare)_

---

## Step 6 — Test, Makefile e consegna (stima 3 h)

| Voce | Stato | In relazione |
|---|---|---|
| `make` costruisce tutto da `.x`/`.y` (alex, happy, ghc) | ✅ | cita |
| `make demo` sui test organizzati per cartella | ✅ | cita l'organizzazione dei test |
| Un test per ogni requisito nuovo o corretto (R16) | ⬜ | cita |
| Checklist di consegna (sotto) | ⬜ | — |

**Checklist di consegna:**
- [ ] `make distclean` eseguito (niente `.o`, `.hi`, `Main`, `LexLinguaggio.hs`, `ParLinguaggio.hs`, `.info`)
- [ ] `readme.md` e file temporanei (dump, log) rimossi
- [ ] Nessun file o cartella nascosti (`find . -name '.*'`)
- [ ] Tutto scrivibile (`chmod -R u+w .`)
- [ ] `Linguaggio.cf` incluso
- [ ] Relazione PDF con il nome esatto richiesto
- [ ] ZIP con il nome esatto richiesto
- [ ] Prova finale: estrarre lo ZIP in una cartella vuota, poi `make` e `make demo`

**Note per la relazione:**
- _(da compilare)_

---

## Step 7 — Relazione (stima 8 h)

| Voce | Stato |
|---|---|
| Versioni di BNFC, Happy, Alex e GHC all'inizio | ✅ (da riportare) |
| Descrizione sintetica generale della soluzione | ⬜ |
| Tutte le voci "cita", "descrivi" e "assunzione" degli step precedenti | ⬜ |
| Nessun riferimento al parziale e nessun riassunto del testo della traccia | ⬜ |

---

## Scelte lasciate fuori (da dichiarare come assunzioni in relazione)

Non richieste dalla traccia, ma presenti come regole nelle slide del corso:
- offset degli array in elementi invece che in byte con `sizeof` (slide 301–303);
- istruzione `IIndexAddr` aggiuntiva al set TAC del corso (slide 293, C2);
- stringhe letterali direttamente nel TAC (G4, slide 359);
- operatori TAC non monomorfi (C2, slide 358);
- array senza inizializzazione obbligatoria (S3, slide 257).

**Totale: 38 ore**, tutte sulle voci ⬜ e 🔧. Le voci ✅ costano solo le righe di relazione, già conteggiate nello Step 7.