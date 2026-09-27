# Roadmap di lavoro — Progetto LC Parte 2, Gruppo 24-14

> ⚠️ **File di lavoro interno: NON va incluso nello ZIP di consegna.**
> Contiene una rielaborazione dei requisiti della traccia, che la traccia vieta di includere sia nella relazione sia nello ZIP.
> Tenerlo fuori dalla cartella del progetto, oppure cancellarlo prima di creare lo ZIP.

## Modifiche rispetto alla versione precedente

- **R4**: chiarito che la copia riguarda solo gli array; l'assegnamento fra puntatori resta copia del solo indirizzo (nessuna modifica di comportamento, solo esplicitato per non fare confusione in fase di codice).
- **R4**: aggiunto un controllo da fare — se il linguaggio ammette array come tipo di ritorno di una funzione, il `return` di un array richiede la stessa semantica di copia (altrimenti il chiamante otterrebbe un alias sulla cella locale della funzione, che nel frattempo viene deallocata/riusata).
- **R1**: aggiunta una nota tecnica importante — la tecnica standard vista a lezione (`rel x y = case sup x y of ERROR -> ERROR; _ -> BOOL`) **da sola non basta** a rispettare il vincolo della traccia. Va sostituita da un controllo esplicito di appartenenza ai due insiemi ammessi (vedi Step 2).
- **R1**: aggiunto un test consigliato — verificare esplicitamente che `==`/`!=` vengano *rifiutati* su array e puntatori (non solo che vengano accettati sui quattro tipi giusti).
- **Pretty-print del sorgente** (Step 1): declassata da "✅ / cita" a "da verificare" — vedi nota nello Step 1.
- Popolata la sezione "Note per la relazione" dello **Step 2** con una proposta di regole formali, da confermare prima di passare allo Step 3.

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
| R1 | `==`/`!=` solo su bool, char, int, real; `<` `<=` `>` `>=` solo su int, real — **non tramite il semplice successo di `sup`** | 🔧 |
| R2 | Operazioni aritmetiche solo su tipi numerici | 🔧 |
| R3 | Semantica canonica del passaggio per riferimento | 🔧 |
| R4 | Array passato per valore o assegnato (`a = b`) non condivide memoria col chiamante/sorgente; puntatori esclusi da questa regola; verificare anche il `return` di un array | ⬜ |
| R5 | Puntatori a tipi qualsiasi con selezione, incluso `(*p)[i]` | 🔧 |
| R6 | if-then-else come espressione | ⬜ (grammatica ✅) |
| R7 | `+=`, `-=`, `*=` con semantica canonica | ⬜ (grammatica ✅) |
| R8 | do-while e iterazione determinata (`for`) | ⬜ (grammatica ✅) |
| R9 | `break`/`continue` ammessi solo nei cicli | ⬜ (grammatica ✅) |
| R10 | Visibilità definita e coerente per ogni dichiarazione (ridichiarazione, shadowing) — occhio all'interazione con la pre-scansione per mutua ricorsione | 🔧 |
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
| Pretty-print del sorgente con formattazione minima | ✅ | **da verificare** (vedi nota) |
| do-while (R8) | ✅ | cita |
| `for i in a..b` (R8) | ✅ | descrivi (scelta della forma) |
| `break`/`continue` (R9) | ✅ | cita |
| `+=`, `-=`, `*=` (R7) | ✅ | cita |
| if-then-else come espressione (R6) | ✅ | descrivi (sintassi e precedenza) |
| Controllo dei conflitti dopo le modifiche | ✅ | cita |

**Stato: ✅ completato.** Test di sintassi aggiunti: `tests/parser/cicli.lang`, `tests/parser/break_opassign.lang`, `tests/parser/ifexpr.lang`.
Verificato che tutti i test precedenti di `tests/lexer` e `tests/parser` vengano ancora riconosciuti.
Nota operativa: finché il type checker non gestisce i nuovi costrutti (Step 3), `make demo` si ferma sui nuovi test.

**Nota sul pretty-printer (da verificare prima di classificarlo "cita"):** il testo chiede una funzione di serializzazione con "minimo di formattazione (andando a capo in corrispondenza dei blocchi)". Se questo comportamento viene dal `Print.hs` generato da BNFC così com'è, è tecnica standard e basta citarla. Se invece è stato necessario modificare a mano il modulo generato per ottenere l'andare a capo sui blocchi o il reinserimento delle parentesi, quella parte va in "descrivi" perché non è più "solo" BNFC. Controllare il diff fra `Print.hs` generato e quello effettivamente usato.

**Note per la relazione:**
- Grammatica: 78 regole, nessun conflitto shift/reduce o reduce/reduce.
- do-while e for con sintassi Chapel; corpo sempre un blocco, come if e while.
- Variabile del for senza tipo dichiarato (tipo determinato dall'intervallo).
- break/continue accettati sintatticamente ovunque; il vincolo "solo nei cicli" è controllato dalla semantica statica.
- `+=`, `-=`, `*=` con un'unica regola e una categoria `AssignOp`: un solo costruttore nell'AST.
- if-then-else espressione al livello di precedenza più basso: ramo else esteso il più a destra possibile, nessun conflitto con gli operatori binari; le parentesi le reinserisce il pretty-printer.
- Nuove parole riservate: `do`, `for`, `in`, `break`, `continue`, `then`.

**Testo per la relazione (bozza):**

> **Sintassi concreta e grammatica**
>
> La grammatica, scritta in LBNF e trattata con BNFC, conta 78 regole e non presenta conflitti shift/reduce né reduce/reduce. La precedenza degli operatori è codificata con categorie numerate e coercions. Il lexer riconosce commenti su riga singola (`//`) e su più righe (`/* */`), letterali interi, reali (anche in notazione scientifica con esponente `e`), caratteri e stringhe con sequenze di escape.
>
> Dove Chapel prevede una sintassi per i costrutti richiesti, si è adottata quella. Le variabili si dichiarano con `var x : T;` o `var x : T = e;`, le funzioni con `proc f(…) : T { … }`, e le procedure sono funzioni con tipo di ritorno `void`. Dichiarazioni di variabili e funzioni sono ammesse in qualsiasi blocco. I parametri sono passati per valore in assenza di intent e per riferimento con l'intent `ref`, come in Chapel.
>
> Per i tipi composti si è scelta la forma `[lo..hi] T` per gli array, con estremi interi letterali, così che la dimensione sia nota staticamente. Per i puntatori si usano `c_ptr(T)` per il tipo, `c_ptrTo(e)` per ottenere l'indirizzo di una l-expression e `*e` per la dereferenziazione. I nomi `c_ptr` e `c_ptrTo` sono presi dalla libreria di interoperabilità con il C di Chapel.
>
> I comandi di controllo seguono la sintassi di Chapel:
> - `if cond { … }` e `if cond { … } else { … }`;
> - `while cond { … }` e `do { … } while cond;` per l'iterazione indeterminata;
> - `for i in a..b { … }` per l'iterazione determinata.
>
> In tutti i costrutti il corpo è un blocco tra graffe. Questa uniformità evita l'ambiguità del *dangling else*. La variabile di iterazione del `for` non ha un tipo dichiarato: il suo tipo è determinato dall'intervallo di interi, e la sua visibilità è discussa nella sezione sul sistema di tipi.
>
> Le istruzioni `break;` e `continue;` sono accettate dalla grammatica in qualsiasi posizione di comando. Il vincolo che le ammette solo nel corpo di un ciclo è verificato dall'analisi di semantica statica, per non dover duplicare le categorie sintattiche dei comandi.
>
> Gli assegnamenti di aggiornamento `+=`, `-=` e `*=` usano la sintassi di Chapel. Sono descritti da un'unica produzione, `Exp AssignOp Exp ;`, con una categoria dedicata all'operatore: nella sintassi astratta c'è così un solo costruttore, parametrico nell'operazione.
>
> L'if-then-else nella categoria delle espressioni usa la forma di Chapel `if c then e1 else e2`, in cui entrambi i rami sono espressioni. È posto al livello di precedenza più basso, e gli operatori binari non possono avere un'espressione condizionale come operando se non tra parentesi. In questo modo il ramo `else` si estende il più a destra possibile (`if c then 1 else 2 + 3` equivale a `if c then 1 else (2 + 3)`), senza conflitti con gli operatori binari. Il comando e l'espressione condizionale si distinguono dal token che segue la condizione: `{` per il comando, `then` per l'espressione.
>
> Il pretty-printer del sorgente produce codice legale con indentazione per blocchi e reinserisce automaticamente le parentesi necessarie.

---

## Step 2 — Progettazione del sistema di tipi, su carta (stima 2 h)

| Voce | Stato | In relazione |
|---|---|---|
| Tipi base e composti; int compatibile con real e non viceversa | ✅ | grafico |
| Array e puntatori compatibili solo con tipi identici | ✅ | descrivi con regole formali (proposta sotto) |
| Visibilità delle variabili: dal punto di dichiarazione a fine blocco | ✅ | descrivi |
| Visibilità delle funzioni: tutto il blocco | ✅ | descrivi la regola; la pre-scansione va solo citata |
| Parametri: visibili in tutto il corpo | ✅ | descrivi |
| Ridichiarazione e shadowing (R10) | ⬜ | descrivi (proposta sotto) |
| Overloading di `==`/`!=` e degli operatori d'ordine (R1) | ⬜ | descrivi (proposta sotto) |
| Variabile del for: dichiarazione implicita e non modificabile | ⬜ | descrivi (proposta sotto) |
| Tipo dell'if-espressione e regola di tipo per `op=` | ⬜ | descrivi (proposta sotto) |

**Note per la relazione — PROPOSTA (da confermare prima di passare allo Step 3):**

- **Compatibilità formale dei tipi composti.**
  `ARRAY(lo1,hi1,τ1) ~ ARRAY(lo2,hi2,τ2) ⟺ lo1=lo2 ∧ hi1=hi2 ∧ τ1=τ2`
  `PTR(τ1) ~ PTR(τ2) ⟺ τ1=τ2`
  Nessuna coercion definita per ARRAY/PTR: `sup` con qualunque altro tipo (incluso un altro ARRAY/PTR non identico) restituisce ERROR.

- **Overloading di `==`/`!=`/ordine (R1) — perché `rel` da solo non basta.**
  La tecnica standard vista a lezione è
  `rel x y = case sup x y of ERROR -> ERROR; _ -> BOOL`
  Con la vostra `sup`, questa funzione accetterebbe `STRING == STRING` (perché `sup STRING STRING = STRING`, non ERROR) e accetterebbe `CHAR < CHAR` o `BOOL < BOOL` (perché `sup` di un tipo con se stesso ha successo). Nessuno dei due casi è ammesso dalla traccia. Serve quindi affiancare a `sup` un controllo di appartenenza esplicito:
  ```haskell
  eqOp t1 t2
    | isERROR t1 || isERROR t2 = ERROR
    | t' <- sup t1 t2, t' `elem` [BOOL,CHAR,INT,REAL] = BOOL
    | otherwise = ERROR

  ordOp t1 t2
    | isERROR t1 || isERROR t2 = ERROR
    | t' <- sup t1 t2, t' `elem` [INT,REAL] = BOOL
    | otherwise = ERROR
  ```
  (nomi indicativi, da adattare ai vostri moduli). Da qui il test consigliato: un caso con `arr1 == arr2` e uno con `'a' < 'b'` che devono **entrambi** essere respinti.

- **Variabile del `for`.** Dichiarazione locale implicita del corpo, tipo sempre `INT` (l'intervallo è di interi). Vincolo di semantica statica: `id` non può comparire come lato sinistro di un assegnamento (semplice o `op=`) nel corpo del ciclo, ma può essere letta liberamente. Proposta aggiuntiva: richiedere che gli estremi `a` e `b` siano esattamente di tipo `INT` (non solo compatibili con `INT`), per evitare l'ambiguità di un passo non intero.

- **Tipo dell'if-espressione.**
  `env⊢cond:BOOL   env⊢e1:τ1   env⊢e2:τ2   sup(τ1,τ2)=τ≠ERROR`
  `⟹ env⊢(if cond then e1 else e2):τ`
  Cast impliciti su entrambi i rami quando il loro tipo non coincide con `τ`, con lo stesso meccanismo (`mkCastNode`) già usato per gli operatori binari. Se `sup(τ1,τ2)=ERROR`: errore "i due rami hanno tipi incompatibili".

- **Tipo di `op=`.** Stessa regola di un binario ordinario (`+`,`-`,`*`) applicata a `(el, er)`, poi si riusa `mkAssignErrs` verificando che `sup(tipo_risultato, tipo(el)) = tipo(el)`, più il vincolo — già garantito dalla grammatica — che `el` sia una l-expression.

- **Ridichiarazione/shadowing (R10) — nota sull'interazione con la pre-scansione.**
  Il bug del falso errore su funzioni shadowate viene quasi certamente dal fatto che la pre-scansione per la mutua ricorsione raccoglie le intestazioni delle funzioni globalmente invece che per-blocco. Regola da applicare in Step 3: la pre-scansione va rifatta ad ogni blocco annidato, e un nome ridichiarato in un blocco interno **sostituisce** (shadow) il binding esterno nell'ambiente locale, senza generare errore; l'errore va segnalato solo per una doppia dichiarazione dello stesso nome **all'interno dello stesso blocco**.

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
| Copia dell'array anche sul `return`, se ammesso come tipo di ritorno (R4) | ⬜ | descrivi/verificare |
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
| Test che il tipo checker *rifiuti* correttamente: `arr==arr`, `char<char`, `break` fuori da un ciclo, `for`-var modificata nel corpo | ⬜ | cita |
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