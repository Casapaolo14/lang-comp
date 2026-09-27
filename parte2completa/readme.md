# Roadmap di lavoro — Progetto LC Parte 2, Gruppo 24-14

> ⚠️ **File di lavoro interno: NON va incluso nello ZIP di consegna.**
> Contiene una rielaborazione dei requisiti della traccia, che la traccia vieta di includere sia nella relazione sia nello ZIP.
> Tenerlo fuori dalla cartella del progetto, oppure cancellarlo prima di creare lo ZIP.

## Modifiche rispetto alla versione precedente

- **Array come tipo di ritorno**: deciso di **vietarlo** (errore di tipo alla dichiarazione della funzione). Il risultato di una chiamata sta in un temporaneo, che contiene solo tipi primitivi del TAC (G6, slide 360); i puntatori ad array restano ammessi come tipo di ritorno. Di conseguenza **R4 non riguarda più il `return`**: la copia degli array vale solo per il passaggio per valore e per `a = b`.
- **R1**: aggiunta una nota tecnica importante — la tecnica standard vista a lezione (`rel x y = case sup x y of ERROR -> ERROR; _ -> BOOL`) **da sola non basta** a rispettare il vincolo della traccia. Va sostituita da un controllo esplicito di appartenenza ai due insiemi ammessi (vedi Step 2).
- **R1**: aggiunto un test consigliato — verificare esplicitamente che `==`/`!=` vengano *rifiutati* su array e puntatori (non solo che vengano accettati sui quattro tipi giusti).
- **Pretty-print del sorgente** (Step 1): verificato col diff fra `PrintLinguaggio.hs` presente e quello rigenerato da BNFC — nessuna differenza, è tecnica standard non modificata a mano. Riclassificata da "da verificare" a "cita".
- **Regole delle slide finora escluse** (offset con `sizeof`, operazioni TAC monomorfe, niente `IIndexAddr`, stringhe simulate, inizializzazione obbligatoria degli array): non sono più assunzioni da dichiarare come scelte alternative, ma **requisiti da implementare** nello step pertinente, con test e prova dell'output (decisione dell'utente: "dobbiamo avere prova di tutto quello che abbiamo fatto"). Vedi la sezione in fondo, ora "Regole delle slide da implementare".
- **`break`/`continue` nel `for`**: deciso di ammetterli, con la stessa regola dei cicli indeterminati (ammessi nel corpo di un ciclo, vietati fuori).
- Completata la sezione "Note per la relazione" dello **Step 2**: le regole erano una proposta, ora sono le regole definitive da implementare allo Step 3.

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
| R1 | `==`/`!=` solo su bool, char, int, real; `<` `<=` `>` `>=` solo su int, real — **non tramite il semplice successo di `sup`** | ✅ |
| R2 | Operazioni aritmetiche solo su tipi numerici | ✅ |
| R3 | Semantica canonica del passaggio per riferimento | ✅ |
| R4 | Array passato per valore o assegnato (`a = b`) non condivide memoria col chiamante/sorgente; puntatori esclusi da questa regola | ✅ |
| R5 | Puntatori a tipi qualsiasi con selezione, incluso `(*p)[i]` | ✅ |
| R6 | if-then-else come espressione | ✅ |
| R7 | `+=`, `-=`, `*=` con semantica canonica | ✅ |
| R8 | do-while e iterazione determinata (`for`) | ✅ |
| R9 | `break`/`continue` ammessi solo nei cicli (indeterminati e nel `for`) | ✅ |
| R18 | Letterali array (sintassi) e inizializzazione obbligatoria degli array alla dichiarazione (S3, slide 257) | ✅ |
| R19 | Array vietato come tipo di ritorno di una funzione (G6, slide 360); puntatori ad array ammessi | ✅ |
| R10 | Visibilità definita e coerente per ogni dichiarazione (ridichiarazione, shadowing) — occhio all'interazione con la pre-scansione per mutua ricorsione | ✅ |
| R11 | Messaggi d'errore con entità coinvolte e posizione | ✅ |
| R12 | Identificatori del programma annotati con la riga nel TAC | ✅ (limite noto sullo shadowing di funzioni, vedi Step 4) |
| R13 | TAC corretto per le procedure (`return` finale) | ✅ |
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
| do-while (R8) | ✅ | cita |
| `for i in a..b` (R8) | ✅ | descrivi (scelta della forma) |
| `break`/`continue` (R9) | ✅ | cita |
| `+=`, `-=`, `*=` (R7) | ✅ | cita |
| if-then-else come espressione (R6) | ✅ | descrivi (sintassi e precedenza) |
| Controllo dei conflitti dopo le modifiche | ✅ | cita |

**Stato: ✅ completato.** Test di sintassi aggiunti: `tests/parser/cicli.lang`, `tests/parser/break_opassign.lang`, `tests/parser/ifexpr.lang`.
Verificato che tutti i test precedenti di `tests/lexer` e `tests/parser` vengano ancora riconosciuti.
Nota operativa: finché il type checker non gestisce i nuovi costrutti (Step 3), `make demo` si ferma sui nuovi test.

**Nota sul pretty-printer (verificata):** confrontando `PrintLinguaggio.hs` presente nel progetto con quello rigenerato da BNFC a partire dall'attuale `Linguaggio.cf` (`bnfc --haskell --functor -o <tmp> Linguaggio.cf`, poi `diff`), non ci sono differenze. Il pretty-printer, incluso l'andare a capo sui blocchi e il reinserimento delle parentesi, è quindi tecnica standard di BNFC, non modificata a mano: in relazione basta citarlo.

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
| Array e puntatori compatibili solo con tipi identici | ✅ | descrivi con regole formali |
| Visibilità delle variabili: dal punto di dichiarazione a fine blocco | ✅ | descrivi |
| Visibilità delle funzioni: tutto il blocco | ✅ | descrivi la regola; la pre-scansione va solo citata |
| Parametri: visibili in tutto il corpo | ✅ | descrivi |
| Ridichiarazione e shadowing (R10) | ✅ | descrivi |
| Overloading di `==`/`!=` e degli operatori d'ordine (R1) | ✅ | descrivi |
| Variabile del for: dichiarazione implicita e non modificabile (R8) | ✅ | descrivi |
| Tipo dell'if-espressione (R6) | ✅ | descrivi |
| Regola di tipo per `op=` (R7) | ✅ | descrivi |
| break/continue ammessi solo nel corpo di un ciclo (R9) | ✅ | cita |
| Array vietato come tipo di ritorno (R19) | ✅ | descrivi |
| Letterali array e inizializzazione obbligatoria degli array (R18, S3) | ✅ | descrivi |

**Stato: ✅ completato.** Regole decise, da implementare allo Step 1b (grammatica dei letterali array) e allo Step 3 (type checker).

**Note per la relazione — regole definitive:**

- **Compatibilità formale dei tipi composti.**
  `ARRAY(lo1,hi1,τ1) ~ ARRAY(lo2,hi2,τ2) ⟺ lo1=lo2 ∧ hi1=hi2 ∧ τ1=τ2`
  `PTR(τ1) ~ PTR(τ2) ⟺ τ1=τ2`
  Nessuna coercion definita per ARRAY/PTR: `sup` con qualunque altro tipo (incluso un altro ARRAY/PTR non identico) restituisce ERROR.

- **Overloading di `==`/`!=`/ordine (R1) — perché `rel` da solo non basta (regola definitiva).**
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

- **Variabile del `for` (R8).** Dichiarazione locale implicita del corpo, tipo sempre `INT` (l'intervallo è di interi), visibile solo nel corpo. Vincolo di semantica statica (slide 289: "il corpo stmt non può alterare il valore di id"): `id` non può comparire come lato sinistro di un assegnamento semplice o `op=`, come argomento passato per riferimento, né come argomento di `c_ptrTo` — in tutti questi casi si modificherebbe la cella che contiene `id`. Può essere letta liberamente. Gli estremi `a` e `b` devono essere esattamente di tipo `INT` (non solo compatibili con `INT`), per evitare l'ambiguità di un passo non intero. La variabile del for sta nello stesso ambito del blocco principale del corpo (vedi ridichiarazione sotto): ridichiararla lì è un errore, uno shadowing in un blocco più interno è ammesso.

- **Tipo dell'if-espressione (R6).**
  `env⊢cond:BOOL   env⊢e1:τ1   env⊢e2:τ2   sup(τ1,τ2)=τ≠ERROR   τ non è un array`
  `⟹ env⊢(if cond then e1 else e2):τ`
  Cast impliciti su entrambi i rami quando il loro tipo non coincide con `τ`, con lo stesso meccanismo già usato per gli operatori binari. Errore se `sup(τ1,τ2)=ERROR` ("i due rami hanno tipi incompatibili") o se `τ` è un array: il risultato di un'espressione deve stare in un temporaneo, che contiene solo tipi primitivi del TAC (G6, slide 360, stessa ragione di R19).

- **Tipo di `op=` (R7).** Slide 286: si valutano l-value e r-value di `el`, poi l'r-value di `er`, si esegue l'operazione fra i due r-value e si assegna il risultato a `el` — è un comando distinto da `el = el op er` (slide 287), non un'operazione di un'espressione. Regola di tipo: `el` deve essere una l-expression modificabile (stessa nozione usata per l'assegnamento e per la variabile del for); entrambi gli operandi devono essere aritmetici (stessa regola di R2); il tipo del risultato, `sup(tipo(el), tipo(er))`, deve coincidere con `tipo(el)` (altrimenti l'assegnamento implicito perderebbe informazione, es. `i += 1.5` con `i` intero); cast esplicito su `er` se è `INT` ed `el` è `REAL`.

- **Ridichiarazione/shadowing (R10) — regola definitiva.**
  Variabili e funzioni hanno spazi di nomi separati (una variabile e una funzione omonime non sono in conflitto). All'interno di uno stesso blocco, dichiarare due volte lo stesso nome (nello stesso spazio di nomi) è un errore; resta valida la prima dichiarazione. Uno shadowing in un blocco più interno è invece ammesso, comprese le funzioni predefinite. I parametri di una funzione (o la variabile del for) e le dichiarazioni del blocco principale del corpo formano un unico ambito (slide 230, regola `⊎`): un parametro ripetuto, o un nome di variabile/funzione del blocco principale uguale a un parametro, è un errore. La pre-scansione delle funzioni per la mutua ricorsione (slide 232: prima si raccolgono le intestazioni di tutte le funzioni di un blocco, poi si controllano i corpi) va fatta **per singolo blocco**, non sull'intero programma: è quello che permette allo shadowing di funzioni nei blocchi interni di funzionare senza falsi errori.

- **break/continue solo nei cicli (R9).** Ammessi nel corpo di `while`, `do-while` e `for` (compresi i blocchi annidati dentro quel corpo, ma non dentro il corpo di una funzione dichiarata lì in mezzo); errore di semantica statica se usati fuori da un ciclo. Verificato con un controllo esplicito nel type checker (un flag "sono dentro un ciclo?" propagato scendendo nell'albero), non con una categoria sintattica separata: la grammatica li ammette ovunque compaia uno `Stmt`, per non duplicare le regole.

- **Array vietato come tipo di ritorno (R19).** Il risultato di una chiamata di funzione sta in un singolo temporaneo (`l = fcall fun, n`, slide 293), e i temporanei contengono solo tipi primitivi del TAC (G6, slide 360): un array non è un valore singolo. Una funzione con tipo di ritorno array è quindi un errore di tipo alla sua dichiarazione. I puntatori ad array restano ammessi come tipo di ritorno (un puntatore è un indirizzo, un valore singolo).

- **Letterali array e inizializzazione obbligatoria (R18, S3).** Slide 257: "Array declarations should include explicit initialization, because otherwise static analysis cannot determine whether the array may later be used with uninitialized elements (it is an undecidable property)". Regola: ogni dichiarazione di un array, a qualsiasi livello, deve avere un inizializzatore, e l'inizializzatore deve essere un letterale array `[e1, ..., en]` (sintassi di Chapel), non un'altra variabile. Un letterale è tipizzato rispetto al tipo array atteso `[lo..hi] τ`: deve avere esattamente `hi-lo+1` elementi (il letterale vuoto è sempre un errore), ogni elemento deve avere tipo compatibile con `τ` (con cast esplicito `INT`→`REAL`), e se `τ` è a sua volta un array ogni elemento deve essere un letterale annidato che rispetta ricorsivamente la stessa regola. Un letterale array è ammesso solo in una posizione dove il tipo array atteso è già noto: come inizializzatore di una dichiarazione, o come lato destro di un assegnamento il cui lato sinistro è un array; altrove è un errore.

**Testo per la relazione (bozza):**

> **Sistema di tipi**
>
> I tipi base sono booleani, caratteri, interi, real e stringhe. L'unica coercizione ammessa fra tipi base è da intero a real: un intero può comparire ovunque sia atteso un real, con una conversione esplicita inserita nell'albero tipizzato; il viceversa non è ammesso. Il grafico delle relazioni di compatibilità fra i tipi semplici è quindi una singola freccia INT → REAL, con gli altri tre tipi base (BOOL, CHAR, STRING) isolati e compatibili solo con se stessi.
>
> Per i tipi composti la compatibilità è l'identità strutturale: un array `[lo1..hi1] τ1` è compatibile con `[lo2..hi2] τ2` solo se `lo1=lo2`, `hi1=hi2` e `τ1=τ2`; un puntatore `c_ptr(τ1)` è compatibile con `c_ptr(τ2)` solo se `τ1=τ2`. Non c'è nessuna coercizione fra array o puntatori di tipo diverso, nemmeno quando i tipi base sono compatibili fra loro (un array di interi non è compatibile con un array di real).
>
> Una variabile è visibile dal punto della sua dichiarazione fino alla fine del blocco che la contiene; un parametro è visibile in tutto il corpo della funzione; una funzione è visibile in tutto il blocco in cui è dichiarata, compreso il proprio corpo, per permettere la mutua ricorsione fra funzioni dichiarate nello stesso blocco. Variabili e funzioni occupano spazi di nomi distinti. All'interno dello stesso blocco non si può dichiarare due volte lo stesso nome nello stesso spazio di nomi; uno shadowing in un blocco più interno è invece ammesso, comprese le funzioni predefinite del linguaggio. I parametri di una funzione (e, per il costrutto di iterazione determinata, la sua variabile di ciclo) condividono l'ambito del blocco principale del corpo.
>
> I predicati di uguaglianza (`==`, `!=`) hanno un'istanza monomorfa `τ × τ → bool` per ciascuno dei quattro tipi base "atomici" (booleani, caratteri, interi, real); i predicati d'ordine (`<`, `<=`, `>`, `>=`) hanno un'istanza monomorfa solo per i tipi aritmetici (interi e real). In entrambi i casi il tipo dell'istanza applicabile è il sup dei tipi dei due operandi, con l'eventuale conversione resa esplicita; se il sup non esiste, o esiste ma non è fra i tipi ammessi dal predicato, è un errore. Le operazioni aritmetiche (`+`, `-`, `*`, `/`) sono ammesse solo fra tipi aritmetici, con lo stesso schema di calcolo del tipo risultante.
>
> Il costrutto di iterazione determinata dichiara implicitamente, all'inizio del proprio corpo, la propria variabile di ciclo, di tipo intero; tale variabile non può essere modificata all'interno del corpo (né con un assegnamento, né passandola per riferimento, né prendendone l'indirizzo), ma può essere letta liberamente. Gli estremi dell'intervallo iterato devono essere di tipo intero. Le istruzioni `break` e `continue` sono ammesse solo all'interno del corpo di un ciclo, indeterminato o determinato.
>
> Il costrutto condizionale nella categoria delle espressioni richiede che la condizione sia booleana e che i due rami abbiano un tipo in comune secondo la stessa relazione di sup usata per gli operatori binari, con conversione esplicita sul ramo il cui tipo non coincide col risultato; il tipo risultante non può essere un array, perché il valore di un'espressione deve poter stare in un singolo temporaneo. Lo stesso vincolo vale per il tipo di ritorno di una funzione: non può essere un array (un puntatore ad array è invece ammesso).
>
> Gli assegnamenti di aggiornamento (`+=`, `-=`, `*=`) richiedono che il lato sinistro sia una l-expression modificabile e che entrambi gli operandi siano di tipo aritmetico; il tipo del risultato dell'operazione deve coincidere con quello del lato sinistro, per evitare una perdita di informazione implicita.
>
> Un array deve essere sempre inizializzato al momento della dichiarazione, con un letterale della stessa forma del tipo dichiarato (tanti elementi quanti previsti dall'intervallo, con letterali annidati per gli array multidimensionali): senza questo vincolo l'analisi statica non potrebbe garantire che ogni elemento sia stato inizializzato prima dell'uso, essendo una proprietà in generale non decidibile.

Nota: nel documento consegnato, il grafico dei tipi semplici richiesto dalla traccia va disegnato (a mano o con strumento digitale) e inserito come immagine, non descritto solo a parole.

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
| Restrizione dei confronti (R1) | ✅ | vedi Step 2 |
| Operazioni aritmetiche solo su tipi numerici (R2) | ✅ | — |
| Ridichiarazione e falso errore sullo shadowing di funzioni (R10) | ✅ | vedi Step 2 |
| Messaggi con i tipi e i nomi coinvolti (R11) | ✅ | cita |
| Posizione dei parametri passati per valore (R12) | 🔧 | — |
| Marcatura dei parametri `ref` nell'AST tipizzato (serve per R3) | ✅ | descrivi brevemente |
| if-espressione, `op=`, do-while, for, break/continue (R6–R9), letterali array (R18) | ✅ | cita |

**Stato: ✅ type checker completato per R1, R2, R6-R10, R11, R18, R19** (R3 solo la marcatura; R12 non ancora toccato). Test aggiunti in `tests/typecheck/` (casi accettati) e `tests/errors/` (casi rifiutati), uno o più per requisito — elenco completo nella sezione Step 6. Verificato con un piccolo harness (`checkProgram` invocato direttamente, senza generare TAC) che ogni test "typecheck" accettato produce zero errori, e con `./Main` che ogni test "errors" produce esattamente l'errore atteso (un errore di tipo salta comunque la generazione del TAC, quindi questi ultimi passano già oggi per l'intera pipeline).

Nota operativa: i costrutti nuovi (`for`, `do-while`, `break`/`continue`, `op=`, if-espressione, letterali array) ora tipano correttamente, ma **TacGen non genera ancora il loro TAC** (schemi non forniti a lezione, da progettare allo Step 4): un programma che li usa e supera il type checking va in crash con `error "... non ancora implementato (Step 4)"` quando arriva alla generazione del codice. Per questo `tests/tacgen/array_while_puntatori.lang` (che ora deve avere un inizializzatore letterale per l'array `a`, R18) tipa correttamente ma la sua generazione di TAC si ferma su `[0, 0, 0, 0, 0]` (letterale array), non ancora gestito da TacGen.

**Note per la relazione:**
- Ambiente esteso con `envInLoop` (flag "dentro un ciclo", propagato scendendo nell'albero e azzerato entrando nel corpo di una funzione annidata, per non far attraversare a break/continue il confine di funzione) e `VarInfo` esteso con `viMutable` (`False` solo per la variabile del for) e `viIntent` (l'intent con cui un nome è stato introdotto come parametro, propaga fino a `TEVar` per lo Step 4).
- Unica funzione `checkMutableLExpr` per ogni punto che scrive un lato sinistro (assegnamento, `op=`, argomento per riferimento, `c_ptrTo`), al posto del precedente `isLExpr` che non distingueva la non-modificabilità della variabile del for.
- Meccanismo `localNames`/`checkStmtListWith`/`checkBlockWith`: un insieme di nomi "seminato" dall'esterno (i parametri di una funzione per il blocco principale del suo corpo, la variabile di un for per il proprio corpo) per rilevare la ridichiarazione nello stesso ambito, distinto dalla pre-scansione delle funzioni (che ora usa solo un accumulatore locale per blocco, non l'ambiente ereditato, per non generare falsi errori sullo shadowing).
- `eqOp`/`ordOp` in `SemTypes.hs` sostituiscono il precedente `rel`: usano `sup` solo per decidere il cast, non per l'ammissibilità del confronto.
- Letterale array tipizzato con una funzione dedicata (`checkArrLit`/`checkArrElem`), chiamata solo dai due punti dove il tipo array atteso è noto dal contesto (inizializzatore di dichiarazione, lato destro di un assegnamento ad array); altrove `Abs.EArr` produce sempre un errore nel `checkExp` generico.

---

## Step 4 — Generazione del TAC (stima 12 h, include lo Step 5)

| Voce | Stato | In relazione |
|---|---|---|
| Datatype TAC, indirizzi di quattro categorie (variabile, letterale, temporaneo, area dati statici) | ✅ | cita |
| Etichette come elemento a sé nella sequenza di codice | ✅ | descrivi (scelta non standard) |
| Reader (contesto: ciclo corrente, parametri array per valore, righe delle funzioni) + State (temporanei/etichette/stringhe) | ✅ | descrivi (evoluzione dal solo State) |
| Ordine di valutazione da sinistra a destra | ✅ | descrivi (motivazione richiesta, R15) |
| l-value prima di r-value | ✅ | cita |
| Short-cut nelle guardie | ✅ | cita |
| Valutazione dei booleani con corto circuito anche fuori dalle guardie | ✅ | descrivi (motivazione richiesta, R15) |
| Operazioni TAC monomorfe per tipo (`intadd`/`floatadd`/...) | ✅ | descrivi |
| Array multidimensionali per righe, offset in BYTE con `sizeOf` (non più in elementi) | ✅ | descrivi |
| Niente `IIndexAddr`: indirizzo di un elemento = `&base` più offset (`IAddrAdd`), lettura/scrittura con `IDerefGet`/`IDerefSet` | ✅ | descrivi (cambio rispetto all'assunzione precedente) |
| Stringhe simulate: area dati statici, le variabili portano solo l'indirizzo (G4) | ✅ | descrivi |
| Funzioni annidate generate come routine separate | ✅ | cita |
| Array dichiarati senza inizializzazione | — | superato: R18 ora vieta la dichiarazione di un array senza inizializzatore letterale (Step 3) |
| Uso dei parametri `ref` tramite puntatore nel chiamato (R3) | ✅ | descrivi brevemente |
| Copia degli array passati per valore e in `a = b` (R4) | ✅ | descrivi |
| Array vietato come tipo di ritorno (R19, Step 3): la questione "copia sul `return`" non si pone più | ✅ | — |
| Indicizzazione tramite puntatore, `(*p)[i]` (R5) | ✅ | cita |
| `return` finale delle procedure (R13) | ✅ | cita |
| do-while (R8) | ✅ | cita (schema non fornito a lezione, motivato sotto) |
| `for`, `op=`, if-espressione, break/continue (R6–R9) | ✅ | descrivi gli schemi TAC (non forniti a lezione) |
| Riga anche per i nomi di funzione nelle chiamate TAC (R12) | ✅ | descrivi (limite noto sotto) |

**Stato: ✅ completato.** Test aggiunti in `tests/tacgen/`: `arrlit_e_indicizzazione.lang` (letterali array, indicizzazione multidimensionale, offset in byte), `ref_param.lang` (R3), `array_per_valore.lang` (R4, sia passaggio per valore sia `a = b`, con verifica che la copia non condivida memoria), `ptr_array_index.lang` (R5, `(*p)[i]` sia in lettura sia in scrittura), `opassign_tac.lang` (R7, su variabile scalare e su elemento di array), `stringhe_tac.lang` (area dati statici e copia del solo indirizzo), `bool_short_circuit.lang` (dimostra che il secondo operando di `&&`/`||` non viene generato/eseguito quando il primo decide già, anche fuori da una guardia). Verificato anche che `tests/parser/cicli.lang`, `tests/parser/ifexpr.lang`, `tests/typecheck/mutua_ricorsione.lang` e tutti i test preesistenti producano TAC corretto con `make demo` (nessun crash sull'intera batteria).

**Note per la relazione:**
- **Refactor `TacM`**: da un semplice `State GenState` a `ReaderT GenCtx (State GenState)`. Il contesto (`GenCtx`) porta l'etichetta di continue/break del ciclo più interno (R9), l'insieme dei nomi dei parametri array passati per valore della funzione in generazione (servono a `genLValueAddr`/`genArrayAddr` per sapere se un nome è già esso stesso un indirizzo, R3/R4) e la mappa nome-funzione→riga di dichiarazione (R12). Usare un Reader invece di allargare le firme di `genExpr`/`genStmt` con parametri espliciti evita di dover toccare tutte le funzioni ogni volta che serve un'informazione di contesto in più.
- **Niente `IIndexAddr`/`IIndexGet`/`IIndexSet`** (slide 293): sostituite da una sola istruzione nuova, `IAddrAdd` ("somma un offset in byte a un indirizzo di base"), più `IDerefGet`/`IDerefSet` già esistenti per leggere/scrivere attraverso l'indirizzo così calcolato. Questo ha anche permesso di risolvere gratuitamente R5: l'indirizzo di base di `a[i]` per una variabile normale è `&a`, per un parametro `ref`/array-per-valore è il valore della variabile stessa (nessun `IAddrOf`), e per `(*p)[i]` è semplicemente il valore di `p` — tre casi già distinti da `genLValueAddr`, riusata da `genArrayAddr` invece di duplicarne la logica.
- **Operazioni monomorfe** (slide 358/360): un costruttore per ogni combinazione di operazione e tipo (`IntAdd`/`RealAdd`, `IntLt`/`RealLt`/`BoolEq`/`CharEq`, ...), scelto in `genArith`/`genRel`/`genCond` in base al tipo — sempre noto perché il type checker ha già reso uniformi i due operandi con i cast espliciti dello Step 3.
- **Array per valore (R4)**: rappresentati, nel corpo del chiamato, come un indirizzo (esattamente come un parametro `ref`), perché il nostro TAC non ha un'istruzione di "copia un blocco di memoria" nativa. La differenza sta lato chiamante: per un parametro per valore, il chiamante crea una variabile sintetica invisibile al sorgente (`$arr0`, `$arr1`, ...), ci copia dentro l'array con un ciclo runtime elemento per elemento, e passa l'indirizzo di quella copia. Lo stesso ciclo di copia realizza anche `a = b` fra due array già dichiarati (l'obbligo di inizializzatore-letterale, R18, riguarda solo la dichiarazione: un successivo `a = b` fra variabili resta un assegnamento valido, con la copia che qui garantisce la non condivisione di memoria).
- **Stringhe simulate (G4)**: un'area dati statici con un'etichetta per ogni stringa letterale distinta (deduplicate per contenuto); una variabile `string` contiene solo l'indirizzo, quindi `s1 = s2` resta un semplice `ICopy` che copia l'indirizzo, mai il contenuto.
- **Booleani con corto circuito anche fuori dalle guardie** (slide 322): quando `&&`/`||` compaiono come valore (non come condizione di un if/while), si riusa lo stesso schema di salti già usato per le guardie (`genCond`) per materializzare il risultato, invece di valutare sempre entrambi gli operandi con un'istruzione binaria generica.
- **`return` finale delle procedure (R13)**: si accoda sempre un `return` in fondo al corpo di una funzione `void`, anche se il sorgente non lo scrive esplicitamente come ultima istruzione. Se il corpo termina già con un `return` incondizionato, quello accodato è irraggiungibile (codice morto innocuo); altrimenti diventa il return effettivo. Non serve un'unica etichetta di uscita comune.
- **Schemi TAC per `for`/`do-while`/`op=`/if-espressione/`break`-`continue`**: non forniti a lezione, motivati singolarmente nel testo della relazione (schema di salti per ciascuno, analogo a quello di `while`/`if` visto a lezione).
- **R12, limite noto**: la riga annotata sul nome di una funzione chiamata viene da una mappa nome→riga costruita scandendo l'intero programma prima di generare il codice. Se due funzioni con lo stesso nome sono dichiarate in blocchi diversi (shadowing, ammesso da R10), questa mappa piatta non distingue quale sia effettivamente in scope nel punto di chiamata: resta un'approssimazione accettata, corretta nel caso comune (nessuno shadowing di funzioni), segnalata qui come assunzione.

---

## Step 5 — Pretty-print del TAC e Main (compreso nello Step 4)

| Voce | Stato | In relazione |
|---|---|---|
| `Main`: parsing → semantica statica → stampa del sorgente → TAC | ✅ | cita |
| Errori di parsing ed errori di tipo mostrati separatamente | ✅ | cita |
| Identificatori annotati con la riga di dichiarazione (`x_12`) | ✅ | cita |
| Riga anche per i parametri senza `ref` e per i nomi di funzione (R12) | ✅ | — |

**Note per la relazione:**
- I parametri per valore portano già la riga di dichiarazione perché `TEVar` la eredita dall'ambiente (`VarInfo`/`TParam`), popolato allo Step 3; il nome di una funzione chiamata la ottiene invece da una mappa nome→riga costruita da `TacGen` scandendo l'intero programma (vedi Step 4, limite noto sullo shadowing di funzioni).

---

## Step 6 — Test, Makefile e consegna (stima 3 h)

| Voce | Stato | In relazione |
|---|---|---|
| `make` costruisce tutto da `.x`/`.y` (alex, happy, ghc) | ✅ | cita |
| `make demo` sui test organizzati per cartella | ✅ | cita l'organizzazione dei test |
| Un test per ogni requisito nuovo o corretto (R16) | ✅ (scelta: minimi ma rappresentativi, vedi nota) | cita/descrivi la scelta |
| Test che il tipo checker *rifiuti* correttamente: `arr==arr`, `char<char`, `break` fuori da un ciclo, `for`-var modificata nel corpo | ✅ | cita |
| Checklist di consegna (sotto) | 🔧 (parziale, vedi note) | — |

**Nota su R16 (decisione dell'utente, definitiva).** Allo Step 3 erano stati scritti test `.lang` per (quasi) ogni requisito, sia per i casi accettati sia per quelli rifiutati; su richiesta esplicita dell'utente sono stati poi eliminati tutti tranne i quattro esplicitamente citati dalla traccia (`arr==arr`, `char<char`, `break` fuori ciclo, `for`-var modificata), per tenere la cartella `tests/` minima. Allo Step 4 sono stati invece mantenuti tutti i test scritti per la generazione del TAC (uno per requisito: `ref_param`, `array_per_valore`, `ptr_array_index`, `opassign_tac`, `stringhe_tac`, `bool_short_circuit`, `arrlit_e_indicizzazione`), perché dimostrano codice generato, non solo un accettato/rifiutato. **Decisione confermata dall'utente:** restano così, minimi ma rappresentativi — non un test per ogni singolo requisito del type checker. In relazione va scritto esplicitamente che è una scelta deliberata (non un'omissione), motivata con la volontà di tenere la cartella dei test snella; i quattro test esplicitamente richiesti dalla traccia sono comunque presenti e verificati.

**Checklist di consegna:**
- [x] `make distclean` verificato: rimuove `.o`, `.hi`, `Main`, `LexLinguaggio.hs`, `ParLinguaggio.hs`, `.info`; `make` e `make demo` rifunzionano dopo, da zero
- [ ] `readme.md` (questo file) e file temporanei (dump, log) rimossi — **da fare solo alla fine**, è il file di lavoro corrente
- [x] Nessun file o cartella nascosti (`find . -name '.*'` pulito, a parte `.git`)
- [x] Tutto scrivibile
- [x] `Linguaggio.cf` incluso
- [ ] Relazione PDF con il nome esatto richiesto — Step 7, non ancora scritta
- [ ] ZIP con il nome esatto richiesto — da fare alla consegna
- [ ] Prova finale: estrarre lo ZIP in una cartella vuota, poi `make` e `make demo` — da ripetere sull'artefatto finale, non sulla working copy

**Note per la relazione:**
- _(da compilare, dipende dalla decisione su R16 sopra)_

---

## Step 7 — Relazione (stima 8 h)

| Voce | Stato |
|---|---|
| Versioni di BNFC, Happy, Alex e GHC all'inizio | ✅ (da riportare) |
| Descrizione sintetica generale della soluzione | ⬜ |
| Tutte le voci "cita", "descrivi" e "assunzione" degli step precedenti | ⬜ |
| Nessun riferimento al parziale e nessun riassunto del testo della traccia | ⬜ |

---

## Regole delle slide da implementare (non solo da dichiarare come assunzioni)

Non sono richieste esplicitamente dal testo della traccia, ma sono regole del materiale del corso, quindi tecniche standard da rispettare, con test che ne dimostrino il funzionamento:

| Regola | Slide | Dove si implementa |
|---|---|---|
| Inizializzazione obbligatoria degli array con un letterale (S3) | 257 | Step 1b (grammatica dei letterali), Step 3 (type checker) |
| Offset degli array in byte con `sizeof`, non in elementi | 293, 301–303 | Step 4 |
| Operazioni TAC monomorfe sui tipi primitivi (`intadd`, `floatadd`, ...) | 358 (C2), 360 (G5) | Step 4 |
| Nessuna istruzione `IIndexAddr`: l'indirizzo di un elemento si calcola con `&id` più l'offset | 293 | Step 4 |
| Stringhe simulate: non sono un tipo primitivo del TAC, servono un'area dati statici e operazioni che copiano solo l'indirizzo | 359 (G4) | Step 4 |
| Booleani valutati con short-cut anche fuori dalle guardie (assegnamenti, argomenti, `return`) | 322 | Step 4 |

**Totale: 38 ore**, tutte sulle voci ⬜ e 🔧. Le voci ✅ costano solo le righe di relazione, già conteggiate nello Step 7.