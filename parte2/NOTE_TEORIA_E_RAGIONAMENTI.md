# Note di teoria e ragionamenti — Progetto LC 24-14, Parte 2

## Avvertenza importante

**Questo NON è il documento da consegnare.** La relazione ufficiale (`ProgettoLC parte2parz Gruppo 24-14 Relazione.pdf`, nome esatto obbligatorio, formato PDF) ha regole molto più severe: niente riassunto del testo dell'esercizio, solo le tecniche *non* standard e le assunzioni fatte, con le versioni degli strumenti in cima. Questo file è invece un **quaderno di studio personale**: spiega passo per passo cosa abbiamo fatto, perché, e quale teoria del corso abbiamo usato per farlo — come se chi legge non sapesse nulla del progetto. Servirà come base da cui poi *estrarre* la relazione ufficiale, molto più breve.

Per lo stesso motivo, qui sotto non troverete il testo dell'esercizio né un suo riassunto: solo descrizioni generiche dei problemi da risolvere (per rispettare comunque lo spirito della policy del testo d'esame, che vieta di diffonderlo) e la soluzione.

Le citazioni di teoria fanno riferimento a `lezioni-LC-corso.pdf` (Marco Comini, "Course of Languages and Compilers", 756 pagine fisiche del PDF; ogni slide mostra in basso a destra un contatore logico `N/460` che **non coincide** col numero di pagina PDF, perché alcune slide "animate" occupano più pagine fisiche con lo stesso numero logico — dove rilevante cito entrambi).

## Toolchain e vincoli trasversali

- GHC 9.2.8, BNFC 2.9.1, Alex 3.5.4.2, Happy 2.2 — verificati installati localmente e coincidenti con quanto richiesto dal testo (GHC ≥ 9.2.8, BNFC ≥ 2.9.1).
- **Vietato** l'uso di `Data.IORef`/`Data.STRef` in qualunque punto del progetto. Verificato con una ricerca su tutti i file `.hs`/`.x`/`.y` di `parte2/`: l'unico riferimento a mutabilità (`unsafePerformIO`) si trova in `ParLinguaggio.hs`, generato automaticamente da Happy per una funzionalità di debug interna (`happyTrace`), non scritto né usato dal progetto. Il codice scritto a mano (`Environment.hs`, `TypeCheck.hs`, `TacGen.hs`) è interamente puro: l'ambiente è una mappa passata esplicitamente, il generatore di codice usa `Control.Monad.Trans.State`.

## Pipeline generale del progetto

```
sorgente .lang
   │  Alex (LexLinguaggio.x)
   ▼
token stream
   │  Happy (ParLinguaggio.y), monade Either String
   ▼
AbsLinguaggio.Program           (sintassi astratta "grezza", non tipizzata)
   │  TypeCheck.checkProgram
   ▼
TypedAst.TProgram + [TypeError] (sintassi astratta aumentata con i tipi)
   │  TacGen.genProgram (State monad)
   ▼
Tac.Code (per il blocco globale + una per ogni funzione/procedura)
```

Questa è esattamente l'architettura standard "a sette moduli" presentata a inizio corso (front-end: lexer, parser, static semantics; back-end: intermediate/target code generator + relativi optimizer) — pag. PDF 7 (slide "Structure of a Compiler/1", 7/460) — semplificata nel nostro caso perché non si richiede backend/ottimizzazione: ci si ferma al three-address code come output finale.

---

## Step 1 — Architettura generale e grammatiche libere dal contesto

### Il problema
Prima di scrivere una riga di codice, bisognava decidere la struttura complessiva del progetto (quali moduli, in che ordine, con quali responsabilità) e ripassare la teoria di base delle grammatiche libere dal contesto, che è il linguaggio con cui si descriverà la sintassi.

### Teoria
- **Struttura di un compilatore** (pag. PDF 5-12, slide 5-12/460): un'implementazione di linguaggio di programmazione collega tre linguaggi — il linguaggio *sorgente* (quello da implementare), il linguaggio *intermedio dell'implementazione* (linguaggio macchina disponibile, es. l'ISA di una CPU reale o una VM), e il linguaggio *intermedio del compilatore* (un compromesso fra sorgente e target, tipicamente il **three-address code**). Un compilatore si scompone in sette moduli: *Lexical Analyzer* → *Syntax Analyzer* → *Static Semantics Analyzer* (front-end, produce un albero di sintassi astratta "aumentata" coi tipi) → *Intermediate Code Generator* → *Machine Independent Code Optimizer* → *Code Generator* → *Machine Dependent Code Optimizer* (back-end). Il nostro progetto copre esattamente il front-end più la sola generazione di codice intermedio (senza ottimizzazioni, senza backend).
- **Grammatiche libere dal contesto** (pag. PDF 15, slide 15/460): una grammatica `G = (T, NT, S, R)` è composta da un insieme finito di terminali `T`, un insieme finito di non-terminali `NT` disgiunto da `T`, un simbolo iniziale `S ∈ NT`, e un insieme finito di regole `A → w` con `A ∈ NT` e `w ∈ (T∪NT)*`.
- **Alberi di sintassi concreta (parse tree)** (pag. 16/460) e **linguaggio generato** da una grammatica, `𝓛(G)` (pag. 19/460).
- **Ambiguità** (pag. 22/460): una grammatica è ambigua se esiste una stringa generata da almeno due alberi di sintassi concreta distinti; **disambiguazione** (pag. 23/460) = grammatica equivalente ma non ambigua. Esempio canonico mostrato a lezione: la grammatica banale delle espressioni aritmetiche `E → E+E | E*E | num` è ambigua (non codifica precedenza né associatività); la sua disambiguazione standard introduce livelli: `E→E+T|T`, `T→T*F|F`, `F→num|id|(E)` (pag. 24/460).

### Ragionamento
Abbiamo scelto la pipeline "a moduli separati" (lexer → parser → AST non attribuita → type checker con ambiente esplicito → generatore TAC con State monad → pretty-printer), invece di infilare tutto dentro gli attributi Happy del parser. Il corso stesso (vedi Step 4/8 più sotto, pag. PDF 333, slide "Last remark") segnala che è una scelta di gusto legittima quanto la generazione "tutta nel parser", con un vantaggio pratico dalla nostra parte: un'AST non attribuita pensata per ridurre ridondanza semplifica molto il codice dell'analisi semantica successiva, mentre gestire molti attributi ereditati/sintetizzati in Happy è più fragile (Happy non controlla le definizioni di attributo mancanti).

### Cosa abbiamo fatto
Nessun codice in questo step: solo la decisione architetturale sopra e l'elenco dei costrutti del linguaggio da coprire (dichiarazioni di variabili/procedure, tipi base e composti, controllo di sequenza, funzioni predefinite di I/O).

### Validazione
Nessuna (step di sola progettazione); la validazione arriva a valle, quando ogni modulo della pipeline è stato effettivamente implementato e testato.

---

## Step 2 — Sintassi concreta/astratta e prototipo BNFC

### Il problema
Bisognava fissare la sintassi concreta del linguaggio (come si scrivono dichiarazioni, tipi, istruzioni, espressioni) e produrre in automatico un primo prototipo di lexer/parser/AST/pretty-printer, da cui partire per il lavoro manuale successivo.

### Teoria
- **BNFC** (pag. 31/460): "compiler construction tool that generates the source code for both a lexer and a parser from a labelled BNF grammar", con output in Haskell/C/C++/Java/OCaml.
- **Sintassi delle regole LBNF** (pag. 32/460): `label . NonTerminal ::= (Terminal | NonTerminal)* ;`. Ogni regola genera, nel backend Haskell, un costruttore di un tipo di dato algebrico per quel non-terminale — è così che BNFC produce insieme lexer, parser **e** una sintassi astratta coerente fra loro (pag. 33/460): "Technically, this is an abstract syntax, since it is the parser's output. However, it closely resembles the parse tree and is therefore more concrete than what we would usually call abstract syntax."
- **Macro `coercions`** (pag. 36/460): `coercions Exp 3 ;` è zucchero sintattico per la catena di regole "banali" che collegano i livelli di precedenza:
  ```
  _. Exp   ::= Exp1 ;
  _. Exp1  ::= Exp2 ;
  _. Exp2  ::= Exp3 ;
  _. Exp3  ::= "(" Exp ")" ;
  ```
  È esattamente lo strumento con cui si esprime la precedenza/associatività degli operatori **senza duplicare produzioni** (i "semantic dummies", label `_`, si possono usare quando il lato destro ha terminali e una sola occorrenza del non-terminale del lato sinistro, pag. 34/460).
- **Macro `separator`/`terminator`** (pag. 37-40/460): generano automaticamente le produzioni per liste `[NT]` (vuote o non, con o senza terminatore attaccato all'ultimo elemento). Nota pedagogica interessante trovata a lezione: `separator Stm ";"` senza `nonempty` genera in realtà regole che accettano *anche* sequenze terminate da `;` (non solo separate) — un dettaglio "sorprendente" del formalismo, di cui il docente stesso avverte esplicitamente lo studente (pag. 39-40/460).
- **Raccomandazioni pratiche del docente per il front-end, P1-P7** (pag. 180/460, slide "Regarding the syntax/1"): commenti single/multi-linea obbligatori (P1); escape sequence nei letterali stringa/carattere obbligatorie (P2); notazione scientifica per i reali obbligatoria (P3); conflitti shift/reduce o reduce/reduce ammessi ma vanno giustificati in relazione (P4); le funzioni predefinite (`print`, `write`, `read`, ...) **non** devono essere parole chiave della grammatica (P5); precedenza/associatività degli infissi vanno decise con cura e testate su casi significativi (P6); la serializzazione dell'AST deve produrre sintassi concreta legale e il roundtrip parse→serialize→parse deve dare la stessa AST (P7).

### Ragionamento
Abbiamo scritto `Linguaggio.cf` seguendo esattamente lo schema "categorie numerate + coercions" per la precedenza degli operatori (7 livelli, da `||` fino ai primari), invece di scrivere a mano un albero di produzioni ambigue e poi disambiguarlo via precedenze Happy: è l'approccio raccomandato per BNFC perché tiene sintassi concreta e astratta sincronizzate senza sforzo aggiuntivo, e più regole numerate significano meno probabilità di conflitti shift/reduce da giustificare (rispettando P4/P6).

Per array e puntatori — dove BNFC non offre una macro dedicata — abbiamo dovuto scegliere noi la sintassi concreta: `[lo..hi] Type` per gli array (range esplicito, coerente con lo stile Chapel) e `c_ptr(Type)`/`c_ptrTo(...)`/`*` per i puntatori (dichiarazione, address-of, dereferenziazione). Questa è un'**assunzione esplicita**, dato che il testo lascia libertà sulla sintassi concreta per i costrutti non specificati da Chapel.

### Cosa abbiamo fatto
`parte2/Linguaggio.cf` (73 righe): grammatica completa, 68 regole secondo la nota di stato del readme, generata/validata con `bnfc --haskell Linguaggio.cf` seguito da `make` (nessun conflitto shift/reduce segnalato in `ParLinguaggio.info`). Estratto rilevante (livelli di precedenza con `coercions`):

```
EOr.  Exp  ::= Exp  "||" Exp1 ;
EAnd. Exp1 ::= Exp1 "&&" Exp2 ;
EEq.  Exp2 ::= Exp3 "==" Exp3 ;
...
EAdd. Exp3 ::= Exp3 "+" Exp4 ;
EMul. Exp4 ::= Exp4 "*" Exp5 ;
ENeg.   Exp5 ::= "-" Exp5 ;
EDeref. Exp5 ::= "*" Exp5 ;
EAddr.  Exp5 ::= "c_ptrTo" "(" Exp ")" ;
EIdx.  Exp6 ::= Exp6 "[" Exp "]" ;
ECall. Exp6 ::= Ident "(" [Exp] ")" ;
...
coercions Exp 7 ;
```

### Assunzioni esplicite
- Sintassi concreta per array (`[lo..hi] Type`) e puntatori (`c_ptr(Type)`, `c_ptrTo(e)`, `*e`) non essendo previsti da Chapel in questa forma.
- `Intent` per il passaggio parametri: vuoto = per valore, `ref` = per riferimento (`IIn.`/`IRef.` in `Linguaggio.cf:15-16`).

### Validazione
Roundtrip pretty-printer verificato su 4 casi di prova come riportato nel `readme.md`: precedenza operatori, dangling-else, array-di-puntatori/l-expr composte, programma completo — tutti con AST corretta.

---

## Step 3 — Lexer con Alex

### Il problema
Il prototipo BNFC genera un lexer di partenza; va rifinito a mano per gestire correttamente tutti i casi richiesti (in particolare la notazione scientifica per i reali, obbligatoria per P3) e per capire *perché* funziona, non solo prenderlo per buono.

### Teoria
- **Lexeme e token** (pag. 9/460, slide "Structure of a Compiler/3"): un lexeme è una sottostringa del sorgente a cui viene assegnato un significato, convertita in un token (nome + eventuale attributo).
- **Espressioni regolari — definizione formale** (pag. 108/460, slide 108/460): dato un alfabeto Σ, una regex su Σ è: un simbolo `a ∈ Σ∪{ε}`; una concatenazione `e1·e2`; un'alternativa `e1|e2`; una stella di Kleene `e*`. La funzione `L : RE_Σ → ℘(Σ*)` associa a ogni regex il linguaggio che denota.
- **NFA e costruzione di Thompson** (pag. 109-111/460): ogni regex `e` può essere tradotta induttivamente in un automa a stati finiti non deterministico `NFA(e)` con **uno stato iniziale e uno finale**, tale che `R(NFA(e)) = L(e)`. Costruzioni elementari per simbolo singolo, concatenazione (arco ε), alternativa (nuovo stato iniziale/finale con archi ε) e stella (archi ε per zero occorrenze e per iterare).
- **DFA e minimizzazione** (pag. 112/460): ogni NFA si può convertire automaticamente in un DFA equivalente (deterministico, transizioni solo su Σ, un solo arco uscente per simbolo), poi minimizzato. `MDFA(NFA(e))` è ciò che strumenti come Alex/Flex calcolano automaticamente per ogni regola lessicale.
- **Simulazione parallela e "maximal munch"** (pag. 114-115/460): uno scanner generato simula in parallelo *tutti* gli NFA delle regole del file sorgente. Algoritmo: si avanza finché almeno un NFA è in stato finale; si sceglie il **prefisso più lungo** dell'input che porta un qualche NFA in stato finale (maximal munch); se più regole matchano lo stesso prefisso più lungo, **vince la prima nel file** (regola di ordine testuale).
- **Struttura di un sorgente Alex** (pag. 117-122/460): header, direttive (`%wrapper`), macro (`$ident = set-expr` per singoli caratteri, `@ident = regex` per pattern), poi `token :- regola { azione }`. Ogni regola definisce un token; `;` al posto dell'azione scarta il token (skip). **Regola pratica esplicita mostrata a lezione** (pag. 124/460, esempio col wrapper `"basic"`): la regola per gli identificatori generici (`$alpha [$alpha $digit \_ \']*`) **deve comparire dopo** quelle delle parole chiave (`let`, `in`, ...) nel file, altrimenti — essendo il match della stessa lunghezza — vincerebbe la prima regola testuale, che sarebbe quella sbagliata (l'identificatore, non la keyword).

### Ragionamento
`LexLinguaggio.x` (generato da BNFC/Alex) segue esattamente questo schema: usa un **albero binario di ricerca** (`resWords`) per distinguere keyword/simboli da identificatori generici a runtime — un'implementazione efficiente dello stesso principio "keyword prima, poi identificatore generico" della slide 124/460, ma realizzata cercando prima nell'albero delle parole riservate e ricadendo sull'identificatore solo se non trovata (`eitherResIdent`, `LexLinguaggio.x:104-115`), anziché con l'ordine testuale delle regole.

L'unica modifica manuale necessaria (rispetto all'output grezzo di BNFC) riguardava la regex dei letterali `Double`, per includere la notazione scientifica richiesta da P3. La regex regolare, coerente con la teoria "regex → NFA → DFA" della lezione, è:

```
$d+ \. $d+ ([eE] [\+\-]? $d+)?
    { tok (\p s -> PT p (TD s)) }
```
(`LexLinguaggio.x:46-47`) — cioè `digit+ '.' digit+ (('e'|'E') ('+'|'-')? digit+)?`, verificata a mano con `e`/`E`/`+`/`-` in tutte le combinazioni.

### Cosa abbiamo fatto
`parte2/LexLinguaggio.x`: token riconosciuti — identificatori (`$l $i*`, dove `$i` include lettere/cifre/`_`/apice), interi (`$d+`), reali con notazione scientifica (sopra), caratteri (`\' ... \'` con escape), stringhe (`\" ... \"` con escape gestiti da `unescapeInitTail`), commenti single-line (`// ...`) e multi-line (`/* ... */`, entrambi scartati con `;`), simboli/parole chiave via `@rsyms` e l'albero `resWords`.

### Assunzioni esplicite
Nessuna oltre alla fix della notazione scientifica: gli altri aspetti (P1 commenti, P2 escape) erano già corretti nell'output di default di BNFC.

### Validazione
Testato con programmi che combinano commenti multi-riga, escape nelle stringhe, notazione scientifica in tutte le combinazioni di segno/`e`/`E`, e un identificatore con prefisso uguale a una parola chiave (per verificare il maximal munch) — tutti superati secondo `readme.md`. File di test dedicati: `test/test_e1.lang`...`test_e4.lang` (varianti di notazione scientifica).

---

## Step 4 — Parser Happy monadico e sintassi astratta definitiva

### Il problema
Il prototipo BNFC genera anche un parser di partenza; va portato a un parser Happy scritto/raffinato a mano, con gestione monadica degli errori di parsing, e la sintassi astratta va consolidata nella sua forma definitiva.

### Teoria
- **Struttura di un sorgente Happy** (pag. 127-131/460): header, direttive (`%tokentype`, `%name`), dichiarazioni di token (`S { P }`, pattern Haskell che riconosce il token), poi produzioni `NT : α1 {expr1} | α2 {expr2} | ...` dove ogni `$i` nell'azione si riferisce al valore calcolato per l'i-esimo simbolo della produzione. **Fortemente raccomandato** annotare il tipo di ogni non-terminale con `NT :: {Type}` prima delle produzioni.
- **Precedenza e associatività** (pag. 132/460): `%left`/`%right`/`%nonassoc` seguiti da liste di token; **l'ordine delle dichiarazioni fissa la precedenza relativa** (dichiarato prima = lega meno). **Context precedence** con `%prec` (pag. 133/460) per casi come il meno unario, che ha precedenza diversa dal meno binario nello stesso token.
- **Conflitti non risolti** (pag. 134/460): Happy genera comunque il parser con un warning — shift/reduce risolto sempre a favore dello shift, reduce/reduce a favore della regola che appare per prima nel sorgente. "Obviously, such automatic resolutions may not produce the intended behaviour!" — da qui l'obbligo P4 di giustificare ogni conflitto residuo in relazione.
- **Parser monadici in Happy** (pag. 381/460, slide 274/460 — non alle pagine 155-177 come stimato inizialmente nella nostra roadmap, ma più avanti nel corso): la direttiva `%monad {M} [{then}{return}]` cambia il tipo del parser generato da `[Token] -> Out` a `[Token] -> M Out`. **L'uso più basilare**, esplicitamente descritto a lezione come "the approach used by BNFC" (pag. 276/460): dichiarare `%monad {Either String}`, definire `happyError :: [Token] -> Either String a` che produce `Left "error string"`, e lasciare le altre regole semantiche "normali" (il risultato finale sarà `Right valore` in caso di successo).
- **Perché non implementare l'error recovery avanzato di Happy** (il meccanismo `catch`, pag. 186-187/460): Happy supporta dalla 2.1 un error-recovery basato su un token speciale `catch` e "catch frame" sullo stack del parser, concettualmente simile al token `error` di Bison. È un meccanismo aggiuntivo e più complesso della semplice segnalazione di errore via `Either String`; il corso lo presenta come funzionalità disponibile, non come requisito.

### Ragionamento
Per il parsing degli errori abbiamo adottato esattamente lo schema "minimale" raccomandato a lezione — `%monad {Either String}` + `happyError` — invece del meccanismo `catch` di error-recovery. La scelta è duplice: (1) è lo stesso approccio usato da BNFC stesso, quindi il prototipo iniziale già lo suggeriva; (2) il testo dell'esercizio non richiede il recupero da errori multipli di parsing (a differenza del type-checker, dove invece riportare *tutti* gli errori è un requisito esplicito — vedi Step 6), quindi la complessità aggiuntiva del meccanismo `catch` non sarebbe stata giustificata.

Per la sintassi astratta abbiamo seguito il consiglio dato durante le "Live Session" del corso (pag. 138-143/460): prima si raffina il **tipo** dell'AST (unificando costruttori simili, eliminando ridondanza), *poi* si aggiorna il parser di conseguenza — non il contrario. Concretamente in `AbsLinguaggio.hs` questo si vede nell'unificazione dei livelli di precedenza (`Exp`...`Exp7`) in un solo tipo `Exp` dopo l'applicazione di `coercions` (i livelli sono un artefatto della grammatica concreta per gestire la precedenza, non hanno bisogno di sopravvivere nell'AST).

### Cosa abbiamo fatto
`parte2/ParLinguaggio.y`/`.hs`: parser Happy monadico, `%monad {Err} {(>>=)} {return}` con `type Err = Either String` (puro, nessun `IORef`), `happyError` definito esplicitamente (testato su tre casi: token inatteso, punto e virgola mancante, EOF — vedi `test/test_err1.lang`...`test_err3.lang`). Copre tutti i costrutti richiesti: dichiarazioni (var con/senza init, proc), parametri con `Intent` opzionale, if/if-else (dangling-else risolto per shift preferenziale, verificato con `test/danglingelse.lang`), while, array (dichiarazione e indicizzazione annidabile), puntatori (dichiarazione/dereferenziazione/address-of), chiamate come istruzione o espressione, operatori aritmetici/booleani/relazionali con la precedenza dei 7 livelli di `Linguaggio.cf`.

`parte2/AbsLinguaggio.hs`: sintassi astratta definitiva, parametrica in una posizione (`Program' a`, `Exp' a`, ...) per portare `Maybe (Int,Int)` su ogni nodo grazie all'opzione `--functor` di BNFC — informazione di posizione che si rivelerà essenziale per i messaggi di errore del type-checker (Step 6) e, come vedremo, per l'annotazione del punto di dichiarazione richiesta nel pretty-print del TAC (Step 9, ancora da fare).

### Assunzioni esplicite
Nessun error-recovery avanzato di Happy (`catch`): un solo errore di parsing viene riportato e basta, coerentemente con quanto il testo richiede solo per gli errori di tipo, non per quelli sintattici.

### Validazione
`happyError` verificato su tre scenari reali (vedi sopra). `AbsLinguaggio.hs` verificato conforme al design: `Exp` unificata, livelli di precedenza scomparsi dopo `coercions`, come atteso.

---

## Step 5 — Progettazione del sistema di tipi

### Il problema
Prima di scrivere il type checker vero e proprio, bisognava *progettare sulla carta* le regole di visibilità delle dichiarazioni e le relazioni di compatibilità fra tutti i tipi del linguaggio (semplici e composti), in modo coerente e uniforme per tutto il linguaggio.

### Teoria

**Ambienti, blocchi, visibilità** (pag. 305-306/460, slide 211-212/460): un **ambiente** è l'insieme delle associazioni nome↔oggetto denotabile valide a runtime in un punto/momento del programma; un **blocco** è una regione di testo (annidabile, non sovrapponibile) che può contenere dichiarazioni locali. Una dichiarazione locale è visibile nel proprio blocco e in tutti i blocchi annidati, salvo hiding da parte di una dichiarazione omonima più interna. Punto sottile discusso esplicitamente a lezione: da **dove** all'interno del proprio blocco una dichiarazione è effettivamente *utilizzabile*? Due famiglie di linguaggi:
- "dal punto di dichiarazione alla fine del blocco" (es. C, dove — nota il docente — questo produce spesso comportamenti sorprendenti quando una dichiarazione più interna "nasconde" una esterna solo a partire da un certo punto);
- "in tutto il blocco", cioè visibilità e utilizzabilità coincidono (Haskell, Modula-3, Python).

**Mutua ricorsione di funzioni** (pag. 306/460, slide 213/460): "non è considerata facoltativa" — va necessariamente supportata permettendo di usare un nome di funzione prima della sua dichiarazione testuale, tipicamente tramite un'analisi che scandisce **tutte** le intestazioni di funzione di un blocco prima di elaborarne i corpi.

**Scope statico vs dinamico** (pag. 307/460, slide 214/460): nello scope statico un nome non locale si risolve nei blocchi che testualmente lo racchiudono; l'informazione è nota interamente dal testo del programma e le associazioni sono note a tempo di compilazione (implementazione più efficiente a runtime, anche se più complessa da costruire). È la scelta richiesta dal testo dell'esercizio.

**Compatibilità fra tipi semplici, SDD e tipo ERROR** (pag. 310-318/460, slide 215-223/460): si modella il calcolo del tipo di un'espressione come attributo sintetizzato `type` di una SDD, con l'ambiente `env` come attributo ereditato e una funzione `sup` (limite superiore) che calcola il tipo risultante di un'operazione binaria fra tipi eventualmente diversi:
```
sup INT INT = INT
sup _   _   = FLOAT     -- esempio semplificato a due soli tipi
```
Regola del sistema di tipi corrispondente (notazione a sequente):
```
env ⊢_E e1:τ1   env ⊢_E e2:τ2
────────────────────────────────
env ⊢_E e1*e2 : sup(τ1,τ2)
```
Con più di due tipi si introduce un tipo speciale **ERROR**, "maggiore" di tutti gli altri nel grafo di compatibilità, che si propaga (`sup ERROR _ = ERROR`) per evitare che un singolo errore ne generi altri a cascata. Funzioni derivate: `mathtype` (tipo risultato di un operatore matematico unario, ERROR se l'operando non è numerico) e `rel` (tipo risultato di un confronto: BOOL se `sup` è definito, altrimenti ERROR).

**Compatibilità fra tipi composti — array** (pag. 318/460, slide 223/460): un tipo array `ARRAY(n,τ)` **è compatibile solo con se stesso** — invarianza totale, nessun widening. La stessa filosofia si applica, per analogia diretta discussa più avanti nel corso come principio guida generale T9 (pag. 361/460), ai tipi puntatore/riferimento: occorre attenzione perché un widening implicito tra tipi puntatore diversi porterebbe a violazioni di tipo a runtime.

**Regole di visibilità per le dichiarazioni di funzione — quattro tentativi progressivi** (pag. 331-334/460, slide 230/460): il caso più delicato di tutti. Il docente costruisce la regola per la dichiarazione di funzione/procedura per raffinamenti successivi:
1. un primo tentativo non fa vedere ai corpi/dichiarazioni locali i **parametri formali** — sbagliato;
2. un secondo tentativo aggiunge i parametri ma non fa vedere le **variabili non locali** — sbagliato;
3. un terzo tentativo aggiunge anche l'ambiente esterno, ma con priorità al locale in caso di collisione — **funziona solo se la visibilità è "dal punto di dichiarazione in poi"**, e comunque **non supporta la mutua ricorsione**;
4. il quarto e definitivo tentativo rende l'ambiente usato per tipizzare le dichiarazioni locali **auto-referenziale** (l'ambiente `env''` compare sia a sinistra che a destra del turnstile nella stessa premessa) — è l'unico che rende possibile la mutua ricorsione. Nota esplicita e molto rilevante del docente: *"This rule is not commonly used in type systems, since its implementation is not straightforward"* — perché richiede un meccanismo di **pre-scan** delle intestazioni (o un calcolo a punto fisso) prima di analizzare i corpi.

### Ragionamento
Abbiamo scelto la visibilità "dal punto di dichiarazione alla fine del blocco" (non "in tutto il blocco" come Haskell) perché è la scelta più comune per un linguaggio imperativo C-like/Chapel-like, e perché il testo del progetto richiede esplicitamente di *definire* (non necessariamente di scegliere in un modo specifico) tale regola: abbiamo optato per la semantica più familiare al programmatore di linguaggi imperativi, motivandola nella relazione ufficiale come scelta di design.

Per la mutua ricorsione — obbligatoria per teoria (slide 213/460) — abbiamo dovuto per forza implementare la "quarta regola" vista sopra, col suo meccanismo di pre-scan: è esattamente questo che diventerà, in Step 6, la funzione `preScanFunctions`.

Per array e puntatori abbiamo scelto **invarianza totale** (nessun widening), seguendo alla lettera quanto mostrato per gli array a slide 223/460 ed estendendo la stessa filosofia ai puntatori per coerenza (principio T5 di Step 6: le regole di compatibilità devono essere uniformi in tutto il linguaggio) — e per motivi di sicurezza dei tipi: un `c_ptr(int)` assegnato a un `c_ptr(real)` violerebbe silenziosamente l'invariante di tipo alla prima dereferenziazione.

L'unico widening ammesso nel nostro sistema è INT→REAL per i tipi semplici (l'esempio "a due tipi" della slide 215/460, esteso naturalmente al nostro caso con BOOL/CHAR/STRING/VOID tutti invarianti fra loro e verso INT/REAL).

### Cosa abbiamo fatto
Nessun codice eseguibile in questo step (è design), ma un grafo di compatibilità e le regole T6/T7 per i parametri (per valore: r-expr, tipo compatibile; per riferimento: l-expr, tipo identico) — che diventeranno `SemTypes.hs` e la logica di `checkArg` in Step 6.

### Assunzioni esplicite
- Visibilità "dal punto di dichiarazione alla fine del blocco" (non "in tutto il blocco").
- Invarianza totale per array e puntatori, nessuna covarianza.
- **Assunzione rivista più tardi, in Step 8**: inizialmente (seguendo alla lettera il principio S3 della slide 257/460 — "le dichiarazioni di array dovrebbero includere l'inizializzazione esplicita") avevamo previsto di *obbligare* l'inizializzazione degli array. Questa scelta si è rivelata incompatibile con l'assenza di letterali-array nella grammatica (non essendo richiesti): sarebbe stato impossibile dichiarare il *primo* array di un programma. Abbiamo quindi rimosso l'obbligo in Step 8, accettando il rischio noto di accesso a memoria non inizializzata (esattamente come avviene in C) — si veda Step 8 più sotto.

### Validazione
Design verificato "sulla carta"; la validazione concreta arriva con i test del type checker in Step 6.

---

## Step 6 — Implementazione del type checker

### Il problema
Tradurre il design dello Step 5 in codice Haskell che analizzi un programma dell'AST non tipizzata e produca (a) un'AST aumentata con i tipi inferiti/verificati e (b) l'elenco di tutti gli errori di tipo trovati.

### Teoria

**SDD per le istruzioni** (pag. 319-324/460, slide 224-227/460): le istruzioni non hanno un attributo `type` (non sono espressioni), ma hanno bisogno di un attributo ereditato `env` (propagato) e di un attributo sintetizzato `errs` (lista di errori, che si concatena via `++` risalendo l'albero). Esempio per l'assegnamento:
```
S → E1 = E2 {
  E1.env = S.env; E2.env = S.env;
  S.errs = mkAssignErrs(E1.pos, E1.type, E2.type)
}
```
con `mkAssignErrs` che produce un errore solo se `sup(t1,t2) ≠ t1` (cioè se il tipo del lato destro non è assegnabile a sinistra), evitando errori a cascata se uno dei due tipi è già ERROR.

**Modalità di passaggio parametri — vincoli sui parametri attuali** (pag. 349-354/460, slide 245-249/460): "per valore" ammette r-expr qualsiasi con tipo compatibile; "per riferimento" richiede l-expr con tipo che deve **coincidere esattamente**; le altre modalità (costante, risultato, valore-risultato) non sono richieste dal nostro linguaggio (solo valore e riferimento sono citate).

**Linee guida esplicite del docente per l'implementazione, E1-E3/T1-T9/S1-S5** (pag. 358-363/460, slide 253-258/460) — quelle che abbiamo seguito più da vicino:
- **E1**: ogni errore deve riportare almeno riga/colonna d'inizio.
- **E3**: evitare errori "a cascata" — un'espressione già in errore non deve generare un secondo errore nel nodo padre.
- **T1**: l'informazione inferita va nell'AST aumentata (non serve salvare l'intero ambiente in ogni nodo, solo l'informazione contestuale rilevante, es. il tipo).
- **T2**: dove si applicano coercizioni implicite, vanno creati nodi AST espliciti (nodi di cast), perché la generazione del TAC dovrà applicare la conversione corrispondente.
- **T4**: "la ricorsione e la mutua ricorsione sono obbligatorie!".
- **T5**: le regole di compatibilità devono essere uniformi in tutto il linguaggio, **eccetto** per i parametri per riferimento (dove il widening non è ammesso, perché il parametro attuale potrebbe essere scritto).
- **T6/T7**: per valore, r-expr con tipo compatibile; per riferimento (e le altre modalità non richieste da noi), l-expr con tipo identico.
- **S1**: l'analisi statica **non deve fermarsi al primo errore**, deve riportarli tutti.
- **S2**: gestire l'ambiente come uno stack mutabile è inutilmente complesso in un linguaggio funzionale — bastano ambienti immutabili passati esplicitamente alle funzioni per ogni sotto-componente.
- **S5**: le procedure (funzioni `void`) non sono tenute ad avere `return` espliciti in tutti i percorsi.

### Ragionamento
Il principio **S2** è la giustificazione teorica diretta, esplicita nelle slide del corso, della nostra scelta architetturale di non usare mai `IORef`/`STRef`: non è solo un vincolo imposto dal testo dell'esercizio, è anche la pratica raccomandata a lezione per un linguaggio funzionale.

Il principio **T2** (nodi di cast espliciti) è il motivo per cui `TypedAst.hs` include il costruttore `TECast SemType TExp`, inserito da `TypeCheck.insertCast` ogni volta che `assignableTo` autorizza un widening INT→REAL: senza questo nodo, `TacGen.hs` non saprebbe *dove* emettere l'istruzione di conversione a runtime (Step 8).

Il principio **E3** (niente errori a cascata) è realizzato sistematicamente in `TypeCheck.hs` controllando sempre, prima di generare un nuovo errore, se uno degli operandi ha già tipo `STError`:
```haskell
-- TypeCheck.hs:59-62, checkArith
errs3
  | resultType /= STError          = []
  | t1 == STError || t2 == STError = []
  | otherwise = [mkError pos "operandi di tipo incompatibile nell'operazione aritmetica"]
```

Il principio **T4** (mutua ricorsione obbligatoria) è realizzato con la tecnica di pre-scan disegnata in Step 5 (la "quarta regola"): `preScanFunctions` (`TypeCheck.hs:303-315`) scandisce tutte le dichiarazioni `proc` di un blocco *prima* di elaborarne i corpi, registrando le intestazioni (nome, parametri, tipo di ritorno) in un ambiente esteso che viene poi usato per tipizzare tutti gli statement del blocco (corpi inclusi) — realizzando esattamente l'ambiente auto-referenziale della slide 230/460 senza però dover implementare un vero calcolo a punto fisso: basta un'unica passata di raccolta delle intestazioni seguita da un'unica passata di verifica dei corpi.

### Cosa abbiamo fatto

Cinque moduli:
- **`SemTypes.hs`**: i tipi semantici (`SemType`) e le funzioni di compatibilità, immagine diretta della teoria di Step 5:
  ```haskell
  -- SemTypes.hs:28-35
  sup :: SemType -> SemType -> SemType
  sup STError _ = STError
  sup _ STError = STError
  sup STInt STReal = STReal
  sup STReal STInt = STReal
  sup t1 t2 | t1 == t2  = t1
            | otherwise = STError
  ```
  `mathtype`/`rel`/`assignableTo` (righe 37-51) derivano da `sup` esattamente come nelle slide 219-222/460.

- **`Environment.hs`**: l'ambiente come record di due mappe immutabili (`envVars`, `envFuns`), passato esplicitamente — mai come stato mutabile (principio S2). Contiene anche l'**ambiente iniziale** con le 8 funzioni predefinite richieste, modellate come normali voci di `envFuns` (non come regole di grammatica, secondo P5):
  ```haskell
  -- Environment.hs:34-43
  initialEnv = emptyEnv { envFuns = Map.fromList
    [ ("writeInt",    FunInfo [(ByValue, STInt)]  STVoid)
    , ("writeReal",   FunInfo [(ByValue, STReal)] STVoid)
    ...
    , ("readInt",     FunInfo [] STInt) ... ]}
  ```

- **`TypedAst.hs`**: l'AST aumentata (`TExp`/`TStmt`/`TTopDecl`), con un attributo `SemType` su ogni nodo espressione (`typeOf`, righe 35-62) e il nodo `TECast` per le coercizioni esplicite (T2).

- **`TypeErrors.hs`**: `TypeError { errPos, errMsg }` con posizione (E1) e funzione `showPos` per formattare "riga L, colonna C".

- **`TypeCheck.hs`** (361 righe): il cuore del type checker, `checkExp`/`checkStmt`/`checkTopDecl` che realizzano lo schema SDD sopra descritto per **tutti** i 24 costruttori di `Abs.Exp` e i 9 di `Abs.Stmt`. Esempio di regola per il passaggio parametri (T6/T7):
  ```haskell
  -- TypeCheck.hs:165-186, checkArg
  ByValue -> ... assignableTo t paramType ...   -- T6: r-expr, tipo compatibile
  ByRef   -> ... t /= paramType ... isLExpr argExpr ...  -- T7: l-expr, tipo identico
  ```

### Assunzioni esplicite
Nessuna al di là di quelle già dichiarate in Step 5 (di cui questo step è la realizzazione diretta).

### Validazione
Cinque errori distinti riportati insieme su un unico programma (S1), verificato con `test_tc_errors.lang` (variabile non dichiarata, assegnamento bool→int, indice array non intero, condizione `if` non booleana, uso di variabile con tipo sbagliato). Mutua ricorsione verificata con funzioni annidate mutuamente ricorsive (`test_tc_mutual.lang`, `isEven`/`isOdd`). Passaggio per riferimento e invarianza dei puntatori verificati con `test_tc_ref.lang` (`bump(5)` correttamente rifiutato perché non è un l-expr; `p = q` fra `c_ptr(int)` e `c_ptr(real)` correttamente rifiutato). Nessun falso positivo osservato su un caso di widening valido (INT→REAL).

---

## Step 7 — Datatype e schema per il three-address code

### Il problema
Prima di generare codice intermedio bisognava progettare (a) una rappresentazione dati per il three-address code — non una stringa di caratteri — e (b) gli schemi di traduzione per espressioni e controllo di flusso.

### Teoria

**Due famiglie di codice intermedio** (pag. 404/460, slide 291/460): per macchine "von Neumann" (three-address code, da cui derivano rappresentazioni mainstream come GIMPLE/LLVM IR) e per macchine a stack (P-code, bytecode Java). Il nostro progetto usa la prima famiglia, come richiesto.

**Indirizzi** (pag. 405/460, slide 292/460): gli operandi delle istruzioni TAC sono **indirizzi** di tre categorie:
1. **nomi di programma** (variabili sorgente, per nome — la loro allocazione a runtime è compito di un ipotetico backend, fuori scopo qui);
2. **letterali** di tipi *primitivi TAC* (intero, float, char, booleano, indirizzo) — da non confondere coi tipi primitivi del linguaggio sorgente;
3. **temporanei generati dal compilatore**, teoricamente illimitati, **senza l-value proprio** (non possono comparire come bersaglio di un puntatore, solo come contenitori intermedi).

Datatype-tipo mostrato a lezione:
```haskell
data Address = ProgVar   { progVar :: ProgVariable, addrT :: TacType }
             | TacLit    { tacLit  :: Literal,       addrT :: TacType }
             | Temporary { tempInt :: Int,            addrT :: TacType }
```

**Istruzioni** (pag. 406/460, slide 293/460): al più 3 indirizzi per istruzione, raggruppate in categorie — assegnamento binario/unario/copia, salto incondizionato/condizionale booleano/condizionale relazionale, accesso indicizzato (lettura/scrittura), indirizzo-di/dereferenziazione (lettura/scrittura), chiamata di funzione/procedura, `return` con/senza valore. Esempio (pag. 407/460):
```c
do i++ while (a[i]<max);
```
→
```
L1: i = i + 1
    t1 = i * 8
    t2 = a[t1]
    if t2 < max goto L1
```

**Schema per espressioni aritmetiche** (pag. 408-414/460, slide 295-298/460): attributi sintetizzati `addr` (dove il valore dell'espressione finisce) e `code` (lista di istruzioni, con `++` per concatenare) per ogni nodo espressione:
```
E → num  { E.addr = mkAddr(num);  E.code = [] }
E → id   { E.addr = getAddr(id, E.env);  E.code = [] }
E → E1+E2 {
  E.addr = newtemp();
  E.code = E1.code ++ E2.code ++ gen(E.addr '=' E1.addr '+' E2.addr)
}
S → id=E { S.code = E.code ++ gen(getAddr(id, S.env) '=' E.addr) }
```
La lezione segnala però (pag. 418-419/460, slide 299-300/460) che l'uso pervasivo di `++` degrada le prestazioni; l'alternativa preferita è trattare la generazione come **effetto collaterale** (una procedura `out(...)` che accoda l'istruzione a uno stream globale) invece che come attributo sintetizzato esplicito — tecnica ripresa in Step 8 col monad di stato.

**Array multidimensionali** (pag. 420-430/460, slide 301-305/460): l'accesso `a[i1]...[ik]` va tradotto in un unico offset lineare, calcolato "per righe" (**row-major**):
```
offset = Σ_{1≤m≤k} i_m · W_m ,   W_m = N_{m+1}·...·N_k · sizeof(τ)
```
Esempio completo mostrato a lezione per `c+a[i][j]` con `a: array(2, array(3, int))`, `sizeof(int)=4`:
```
t1 = i * 12    -- 12 = 3 (dimensione interna) * sizeof(int)=4
t2 = j * 4
t3 = t1 + t2
t4 = a[t3]
t5 = c + t4
```
(Nota: nel nostro caso il TAC lavora in "elementi", non byte — vedi assunzione sotto.)

**Booleani con short-circuit ("jumping code")** (pag. 431-435/460, slide 306-309/460): per le guardie di `if`/`while` si preferisce la valutazione *lazy* (short-circuit) alla *eager*. Nello schema *jumping code*, ogni sotto-espressione booleana `B` riceve due attributi **ereditati**, `true` e `false` (etichette), e genera codice che valuta `B` saltando direttamente all'etichetta giusta senza mai materializzare un valore booleano intermedio:
```
if-then:       B.code (con B.true = etichetta-corpo, B.false = S.next)
               [B.true:]  S1.code
               [B.false = S.next:]  seguito

if-then-else:  B.code
               [B.true:] S1.code; goto S.next
               [B.false:] S2.code
               [S.next:] seguito

do-while:      [B.true:] S1.code
               B.code (B.true = inizio corpo, B.false = S.next)
               [B.false = S.next:] seguito
```
**Nota di fedeltà importante**: nell'intervallo di pagine effettivamente disponibile nel materiale del corso, lo schema per il `while`-*do* puro (guardia prima del corpo, non dopo come nel `do`-*while*) non compare risolto esplicitamente — è lasciato come esercizio. Il nostro schema per `while` (si veda Step 8) è quindi una nostra estensione coerente, non una trascrizione diretta delle slide.

### Ragionamento
Il datatype `Address`/`Instr` di `Tac.hs` è la nostra trasposizione diretta delle tre categorie di indirizzi e delle categorie di istruzioni delle slide 292-293/460, con alcune scelte di adattamento al nostro linguaggio (puntatori/array espliciti nel linguaggio sorgente, quindi servono istruzioni dedicate per indicizzazione e dereferenziazione, non presenti nell'esempio minimale a lezione ma della stessa famiglia concettuale).

Per le etichette abbiamo scelto di rappresentarle come **elemento a sé stante** della sequenza di codice (`CodeItem = Lbl String | Ins Instr`) invece che "attaccate" alla prima istruzione che segue: è un'assunzione esplicita, motivata dalla necessità di rappresentare correttamente blocchi vuoti (es. un `if` il cui corpo non genera istruzioni) senza perdere l'etichetta corrispondente.

### Cosa abbiamo fatto
`parte2/Tac.hs`:
```haskell
-- Tac.hs:5-9
data Address
  = AddrVar  String SemType
  | AddrLit  Literal SemType
  | AddrTemp Int SemType
```
corrispondenza 1:1 con `ProgVar`/`TacLit`/`Temporary` della slide 292/460 (con l'aggiunta del tipo semantico su ogni indirizzo, utile per generare l'istruzione giusta in base al tipo — es. somma intera vs reale — e per l'annotazione richiesta nel pretty-printer finale).

```haskell
-- Tac.hs:32-51
data Instr
  = IBinAssign Address BinOp Address Address   -- l = r1 bop r2
  | IUnAssign  Address UnOp  Address           -- l = uop r
  | ICopy      Address Address                 -- l = r
  | IGoto      String
  | IIfTrue    Address String
  | IIfFalse   Address String
  | IIfRel     Address RelOp Address String
  | IIndexGet  Address Address Address         -- l = id[r]
  | IIndexAddr Address Address Address         -- l = &id[r]
  | IIndexSet  Address Address Address         -- id[r1] = r2
  | IAddrOf    Address Address                 -- l = &id
  | IDerefGet  Address Address                 -- l1 = *l2
  | IDerefSet  Address Address                 -- *l = r
  | IParam     Address
  | IPCall     String Int
  | IFCall     Address String Int
  | IReturn
  | IReturnVal Address
```
18 costruttori, che coprono tutte e 9 le categorie viste a lezione (binario/unario/copia, goto, if booleano, if relazionale, indicizzazione get/addr/set, address-of/deref get/set, param/pcall/fcall, return).

### Assunzioni esplicite
- Etichette come elemento a sé (`Lbl`) nella sequenza `Code`, non attaccate a un'istruzione — per gestire correttamente blocchi vuoti.
- Indicizzazione array in **elementi**, non byte (nessun `sizeof` esplicito: la formula della slide 301/460 viene applicata senza il fattore `sizeof(τ)`, dato che generare codice macchina reale — dove servirebbe la dimensione in byte — è esplicitamente fuori scopo del progetto).
- `IIndexAddr` (calcolo dell'indirizzo di un elemento d'array, non il suo valore) aggiunta rispetto al set-base della slide, per supportare `c_ptrTo` applicato a un elemento di array (assunzione P10 vista in Step 6: le stesse l-/r-expr ammesse nell'assegnamento devono esserlo anche altrove, incluso come argomento di `c_ptrTo`).

### Validazione
Solo di design in questo step (nessun generatore ancora implementato) — gli schemi sono stati "eseguiti a mano" su carta sui casi canonici (espressione aritmetica, assegnamento, `if`/`if-else`/`while`) prima di passare all'implementazione in Step 8.

---

## Step 8 — Generazione del TAC con State monad

### Il problema
Implementare concretamente gli schemi di Step 7 come un generatore Haskell che, presa l'AST tipizzata di Step 6, produca il `Code` di Step 7 — rispettando il vincolo di non usare variabili mutabili, la regola "l-value prima di r-value" negli assegnamenti, e lo short-circuit obbligatorio nelle guardie.

### Teoria

**State monad per newtemp/newlabel, senza IORef/STRef** (pag. 495-497/460, slide 329-331/460): la lezione mostra esplicitamente la progressione da uno stato "manuale" (una funzione che riceve e restituisce esplicitamente un contatore intero) a un monad di stato:
```haskell
-- pag. 496/460, slide 330/460
import Control.Monad.Trans.State
type MyMon = State Int

newtemp :: MyMon Addr
newtemp = do k <- get; put (k+1); return (int2TmpName k)
```
poi esteso per includere anche lo **stream di codice** nello stato (invece dell'attributo sintetizzato `code` con `++`, si usa una procedura `out` con effetto collaterale sullo stato — pag. 498/460, slide 331/460):
```haskell
type MyMon = State (Int, [TAC])
out instr = do (k, revcode) <- get; put (k, instr:revcode)
```
(le istruzioni si accumulano in ordine inverso per efficienza, e si invertono una sola volta alla fine).

**Attributo `genL` e tipo `XAddr` per unificare l-value/r-value** (pag. 517-520/460, slide 347-349/460): quando il linguaggio ha più modalità di passaggio parametro e costrutti come array/puntatori, non conviene avere produzioni sintattiche separate per l-expr e r-expr: si introduce un attributo **ereditato booleano** `genL` (vero se serve l'l-value) e un tipo di ritorno unificato:
```haskell
data XAddr = Addr Addr | ArrayAddr { base :: Addr, offset :: Addr } | RefAddr Addr
```
con schemi che, a seconda di `genL`, generano l'indirizzo (per poter scrivere) oppure lo dereferenziano subito (per leggere). Esempio per l'accesso array (pag. 519/460, slide 350/460): se `E.genL` è vero si costruisce `ArrayAddr base offset` (senza leggere); se falso si legge subito con un'istruzione aggiuntiva `t' = a[offset]`.

**Assegnamento generalizzato con genL/xval** (pag. 520/460, slide 351/460):
```
S → E1 = E2 {
  E1.genL = true;  E2.genL = false;
  case (E1.xval, E2.xval) of
    (Addr l, Addr r)        -> out(l '=' r);
    (RefAddr a, Addr r)     -> out('*' a '=' r);
    (ArrayAddr a t, Addr r) -> out(a '[' t ']' '=' r);
}
```
— la regola richiede esplicitamente di calcolare **prima** `E1.xval` con `genL=true` (l-value) e solo dopo `E2.xval` (r-value): è precisamente lo schema teorico dietro il requisito "l-value prima di r-value" del testo dell'esercizio.

**Modalità di passaggio parametro — semantica canonica e costi** (pag. 503-510/460, slide 339-343/460): per **valore**, in fase di chiamata si copia l'r-value dell'attuale in una cella dedicata al formale — ogni modifica del formale nel corpo non tocca l'attuale (è la garanzia richiesta dal testo, "il parametro attuale passato per valore non deve subire modifiche"); per **riferimento**, si calcola l'l-value dell'attuale e il formale accede sempre per indirezione — ogni scrittura sul formale è visibile sull'attuale.

**Generazione per chiamate — modalità VALUE vs REFERENCE** (pag. 523/460, slide 352/460):
```
Ẽ → Ẽ1 E {
  case head(Ẽ.modalities) of
    VALUE     -> E.genL = false; ... out('param' t)        -- passa l'r-value
    REFERENCE -> E.genL = true;  ... out('param' x)          -- passa l'l-value
                 [oppure calcola &x se E.xval era già un Addr]
}
```

**Stream di codice separati per funzione** (pag. 516/460, slide 346/460): generare il corpo di funzioni annidate "in linea" con quello del chiamante produrrebbe codice mescolato/nell'ordine sbagliato. Soluzione mostrata a lezione: mettere da parte lo stream corrente all'apertura di ogni dichiarazione di funzione, crearne uno nuovo dedicato, e ripristinare quello del chiamante alla chiusura — così ogni funzione produce il proprio blocco di codice a sé stante.

### Ragionamento

**State monad**: `TacGen.hs` usa esattamente lo schema della slide 330/460, con `GenState { nextTemp, nextLabel }` al posto del semplice `Int`, e **senza** portare lo stream di codice nello stato (a differenza della slide 331/460): abbiamo preferito continuare a restituire `(Code, Address)` come valore di ritorno di ogni funzione di generazione, con concatenazione esplicita `++`, invece di usare `out` con effetto collaterale sullo stato. È una scelta deliberata, diversa da quella "consigliata" per efficienza a lezione: dato che i nostri programmi di test sono di dimensione contenuta e la chiarezza del codice (poter leggere direttamente "che codice genera questa espressione" dal valore di ritorno, senza seguire lo stato) ci è sembrata preferibile alla marginale differenza di prestazioni asintotiche. La motiveremo esplicitamente come assunzione/scelta non standard nella relazione ufficiale.

**L-value prima di r-value**: non abbiamo introdotto un vero e proprio tipo `XAddr`/attributo `genL` generalizzato come nello schema delle slide 347-353/460 (che è pensato per **generalizzare a molte modalità di parametro**, mentre il nostro linguaggio ne richiede solo due: valore e riferimento). Abbiamo invece applicato lo stesso *principio* (calcolare prima l'indirizzo del lato sinistro, poi il valore del lato destro) in modo mirato nella funzione `genStmt` per `TSAssign`, con una funzione dedicata `genLValueAddr` che gioca lo stesso ruolo concettuale di "genL=true" ma solo dove serve (indicizzazione array, dereferenziazione puntatore):
```haskell
-- TacGen.hs:175-184, genStmt (TSAssign lhs rhs) — caso array
TEIdx {} -> do
  arr <- genArrayAddr lhs        -- 1) L-VALUE: indirizzo dell'elemento
  (rc, ra) <- genExpr rhs        -- 2) R-VALUE: valore da scrivere
  let instr = gen (IIndexSet (AddrVar (arrBase arr) (arrElemTy arr)) (arrOffset arr) ra)
  return (arrCode arr ++ rc ++ instr, [])
```
L'ordine `arr <- genArrayAddr lhs` **prima di** `(rc, ra) <- genExpr rhs` — e la concatenazione `arrCode arr ++ rc ++ instr` che rispetta lo stesso ordine nel codice generato — è la realizzazione diretta del vincolo "l-value prima di r-value" richiesto esplicitamente dal testo (non dalla teoria generale, che lascia scegliere "a piacere, motivandolo" l'ordine di valutazione degli argomenti in generale — qui invece l-value/r-value è un vincolo esplicito del testo).

**Short-circuit obbligatorio solo nelle guardie**: abbiamo implementato lo schema "jumping code" (`genCond`, con etichette `trueLbl`/`falseLbl` propagate esattamente come gli attributi ereditati `B.true`/`B.false` della slide 308/460) **solo** per le condizioni di `if`/`if-else`/`while`. Nelle espressioni booleane usate come valore ordinario (es. assegnate a una variabile `bool`), `TEAnd`/`TEOr` sono invece tradotte con la valutazione *eager* standard (`genArith` con `OpAnd`/`OpOr` come normali operatori binari). Il testo lascia esplicitamente libertà su questo punto fuori dalle guardie ("in altri contesti si può scegliere a piacere, motivandolo"): la nostra motivazione è la semplicità implementativa — un solo schema di generazione per le espressioni booleane "di valore", senza dover distinguere se il risultato serve per un salto o per essere materializzato in memoria.

**Schema per `while`**: non essendo risolto esplicitamente nel materiale del corso disponibile (si veda la nota di fedeltà in Step 7), abbiamo progettato autonomamente uno schema con un salto iniziale condiviso alla guardia, per evitare un salto incondizionato ridondante a ogni iterazione:
```haskell
-- TacGen.hs:223-233, genStmt (TSWhile cond blk)
genStmt (TSWhile cond blk) = do
  trueLbl  <- newlabel
  guardLbl <- newlabel
  falseLbl <- newlabel
  condCode <- genCond cond trueLbl falseLbl
  (bodyCode, bodyFuncs) <- genBlock blk
  return (gen (IGoto guardLbl)
          ++ label trueLbl bodyCode
          ++ label guardLbl condCode
          ++ [Lbl falseLbl],
          bodyFuncs)
```
cioè: `goto guardia; corpo: <corpo>; guardia: <valuta condizione, salta a corpo o esce>`. Questo evita di rivalutare la guardia due volte per iterazione (una in testa e una in coda) e produce codice equivalente allo schema "preferito" tipico dei compilatori didattici, pur non essendo trascritto da una slide specifica — è un contributo nostro, dichiarato come tale.

**Chiamate di funzione, modalità valore/riferimento**: `genCallArg` applica lo stesso principio di `Ẽ→Ẽ1 E` (slide 352/460) in modo diretto — per `ByValue` genera l'r-value (`genExpr`), per `ByRef` genera l'l-value (riusando elegantemente `genLValueAddr`, che gestisce correttamente anche il caso `*p` come parametro per riferimento, dove passare "l'indirizzo di `*p`" equivale a passare direttamente `p`):
```haskell
-- TacGen.hs:252-254
genCallArg ByValue te = genExpr te
genCallArg ByRef   te = genLValueAddr (STPtr (typeOf te)) te
```

**Funzioni annidate come routine separate**: `genTopDecl (TDProc name _ _ _ body)` restituisce una coppia `(name, bodyCode)` accumulata in una lista `[FuncCode]` separata dal codice del chiamante, esattamente secondo il principio "stream separati per funzione" della slide 346/460 — senza però dover implementare `putAsideCurrentStream`/`createNewStream` espliciti: nel nostro caso, dato che ogni funzione di generazione restituisce il proprio `Code` come valore puro (non tramite side-effect su uno stream globale nello stato), "mettere da parte" il codice del chiamante è semplicemente non includerlo nella concatenazione — una conseguenza naturale di aver scelto la strategia "attributo sintetizzato" invece di "side-effect sullo stato" per il codice (si veda sopra).

### Cosa abbiamo fatto
`parte2/TacGen.hs` (275 righe): `GenState { nextTemp, nextLabel }` con `Control.Monad.Trans.State` (nessun `IORef`/`STRef`); `genExpr` su tutti i costruttori di `TExp` (letterali, variabili, aritmetica, cast, array multidimensionali con offset in elementi, puntatori, booleani eager); `genCond` con jumping code per le guardie; `genStmt` con l-value-prima-di-r-value; `if`/`if-else`/`while`; chiamate con T6/T7 tradotti in TAC.

### Assunzioni esplicite (riepilogo)
1. Codice generato come attributo sintetizzato (`(Code, Address)` restituito puramente), non come side-effect su uno stream nello stato — diversamente dalla tecnica "consigliata" a lezione per l'efficienza.
2. Short-circuit obbligatorio **solo** nelle guardie di `if`/`while`; eager altrove (scelta esplicitamente lasciata libera dal testo).
3. Schema per `while` con salto iniziale condiviso alla guardia — nostro contributo, non trascritto da una slide specifica del materiale disponibile.
4. Indicizzazione array in elementi, non byte (continua l'assunzione di Step 7).
5. `S3` di Step 5/6 **rivista**: rimosso l'obbligo di inizializzazione degli array (si veda Step 5) dopo aver verificato che, combinato con l'assenza di letterali-array in grammatica, rendeva impossibile dichiarare il primo array di un programma.
6. Indicizzazione di un array raggiunto per dereferenziazione di puntatore **non supportata** — limite dichiarato esplicitamente nel codice:
   ```haskell
   -- TacGen.hs:116
   _ -> error "genArrayAddr: indicizzazione di un array raggiunto tramite
               dereferenziazione di puntatore non supportata (limitazione nota)"
   ```
7. Ordine di valutazione degli argomenti di chiamata: sinistra→destra (`genCallArgs`, ricorsione su lista) — scelta libera secondo il testo, qui motivata dalla naturale corrispondenza con l'ordine testuale del programma sorgente.

### Validazione
Due test end-to-end completi superati con verifica manuale istruzione-per-istruzione: `test_tac1.lang` (aritmetica/if), `test_tac2.lang` (array/while/puntatori/chiamata per riferimento). L-value-prima-di-r-value verificato nell'ordine reale delle istruzioni generate (non solo nell'ordine del codice sorgente Haskell, che con la valutazione lazy di Haskell potrebbe non coincidere) osservando l'output stampato.

---

## Cosa manca: Step 9 e oltre

Step 9 (pretty-printer, `Main`, test case, Makefile) non è ancora iniziato. Dal confronto fra il codice attuale e il testo ufficiale dell'esercizio, ecco cosa serve concretamente, in ordine di dipendenza:

### 1. Gap tecnico da risolvere per primo: posizione di dichiarazione nel TAC
Il testo richiede che il pretty-print del TAC annoti ogni identificatore col punto di dichiarazione nel sorgente (es. `t37 = x_12 + 5` se `x` è dichiarata alla linea 12). Oggi questo **non è possibile**: `Address` (`Tac.hs:5-9`) ha `AddrVar String SemType`, senza posizione. La posizione esiste in `TypedAst.hs` (`TEVar SemType (Maybe (Int,Int)) String`, popolata da `TypeCheck.hs` a partire da `viDeclPos` di `Environment.VarInfo`) ma si perde nel momento in cui `TacGen.hs` costruisce `AddrVar name t` (es. `TacGen.hs:41`, `genExpr (TEVar t _ name) = return ([], AddrVar name t)` — la posizione `_` viene scartata). **Soluzione**: aggiungere il campo posizione ad `AddrVar` (o un campo dedicato "riga di dichiarazione"), propagarlo da `TEVar`/`TParam` in tutti i punti di `TacGen.hs` che costruiscono un `AddrVar`.

### 2. Pretty-printer del TAC come modulo dedicato
`showAddr`/`showInstr`/`showCode` esistono già, ma solo ad-hoc dentro `TestTacGen.hs` (righe 8-43) — funzionanti, ma da estrarre in un modulo proprio (es. `PrintTac.hs`, sul modello di `PrintLinguaggio.hs` già generato da BNFC per la sintassi concreta) e da estendere con l'annotazione del punto 1.

### 3. `Main` unico con la pipeline completa
Serve una funzione che, dato un nome di file: esegua il parsing, il type-check, il **pretty-print del sorgente** (usando `PrintLinguaggio.hs`, generato da BNFC ma **mai richiamato** in una pipeline completa nel codice attuale — oggi lo si usa solo isolatamente in `TestLinguaggio.hs`), e infine generi e stampi il TAC. `TestTacGen.hs` ha già quasi tutto tranne il passaggio di pretty-print del sorgente.

### 4. Makefile conforme GNU make
L'attuale `Makefile` è quello grezzo generato da BNFC: costruisce solo `TestLinguaggio` (i soli moduli generati automaticamente), non include i moduli scritti a mano (`SemTypes.hs`, `Environment.hs`, `TypedAst.hs`, `TypeErrors.hs`, `TypeCheck.hs`, `Tac.hs`, `TacGen.hs`, il nuovo `PrintTac.hs`, il nuovo `Main.hs`). Serve un Makefile scritto a mano con target di default (compila tutto con GHC) e **target `make demo`** che esegua i test case più significativi.

### 5. Suite di test organizzata
Attualmente i test sono file `.lang` sparsi (`test/`, più diversi `test_*.lang` nella root di `parte2/`), eseguiti manualmente con tre eseguibili diversi (`TestLinguaggio`, `TestTypeCheck`, `TestTacGen`). Vanno raccolti/organizzati e resi eseguibili in un colpo solo da `make demo`, con un caso per ogni costrutto/caso limite rilevante.

### Osservazioni minori raccolte durante la verifica (da sistemare o solo documentare)
- `Tac.hs` ha **18** costruttori in `Instr`, non 16 come riportato nella nota di stato del `readme.md` — imprecisione cosmetica, da correggere nella nota o ignorare.
- `IIfFalse` è definito in `Tac.hs` ma **non è mai emesso** da `genCond`/`genStmt` — codice morto innocuo; da decidere se documentarlo come scelta di simmetria dell'API (per uso futuro) o rimuoverlo.

### La relazione ufficiale da consegnare
Va scritta **dopo** aver completato lo Step 9, come documento separato e molto più sintetico di queste note: nome file esatto `ProgettoLC parte2parz Gruppo 24-14 Relazione.pdf`, versioni degli strumenti in cima, solo tecniche non standard e assunzioni (niente riassunto del testo, niente spiegazioni di tecniche standard/già viste a lezione). Queste note di studio, con le assunzioni già raccolte per ogni step, sono la base diretta da cui estrarla.

---

## Riferimenti

- Testo ufficiale dell'esercizio: `ProgettoLC parte2parz Gruppo 24-14 Testo.pdf` (letto integralmente, 3 pagine).
- Teoria: `lezioni-LC-corso.pdf`, Marco Comini — pagine PDF citate puntualmente in ogni sezione sopra (con il corrispondente numero di slide logico `N/460` dove diverso).
- Codice: tutti i file di `parte2/` citati con percorso e, dove utile, numero di riga.
- Roadmap di lavoro (journal, non relazione): `parte2/readme.md`.
