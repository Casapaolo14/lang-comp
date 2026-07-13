# Parser per file di configurazione (alternativa senza BNFC)

Implementazione fatta a mano con Flex + Bison, senza passare da BNFC. Compila con
`make`, gira il tutto (inclusi i casi di errore attesi) con `make demo`.

## File

- `lessico.l` (Flex) — tokenizza il linguaggio. I commenti che iniziano con `#`
  non diventano token: vengono salvati a parte insieme al numero di riga, cosi'
  il pretty-printer li puo' rimettere al posto giusto.
- `grammatica.y` (Bison) — la grammatica. L'intestazione di una sezione e' una
  regola a se' stante, cosi' una sezione duplicata da' errore bloccante appena
  viene aperta, e i riferimenti locali `$var` possono vedere anche la sezione
  che si sta ancora costruendo. Se un campo viene ridefinito nella stessa
  sezione stampiamo un warning su stderr e teniamo l'ultimo valore.
- `configurazione.h` / `configurazione.cpp` — la struttura dati (alternativa 1
  della consegna): sezioni che contengono coppie nome/valore, dove il valore e'
  sempre un int/bool/stringa di base. I riferimenti `$var` e `$sezione.var`
  vengono risolti direttamente dal parser mentre legge, quindi dopo il parsing
  basta una lettura sola per avere il valore finale, senza dover risalire
  catene di riferimenti. Ci sono anche `deleteSection` e `deleteBinding`
  richieste dalla consegna, e il pretty-printer, che rimette i commenti salvati
  in base al numero di riga originale (i commenti "orfani", cioe' quelli il cui
  elemento vicino e' stato cancellato o modificato dopo il parsing, vengono
  stampati in fondo invece di perderli).
- `main.cpp` — l'eseguibile richiesto: legge un file e stampa la
  serializzazione della struttura.
- `Makefile` — target `all`, `demo`, `clean`.
- `tests/` — l'esempio del testo, catene di riferimenti locali e tra sezioni,
  warning di ridefinizione, errore di sezione duplicata, e un test di
  round-trip (parse, stampa, ri-parse, ri-stampa: deve uscire lo stesso
  testo).

## Assunzioni fatte

- `section`, `field`, `name` sono parole chiave riservate.
- le stringhe non hanno escape e non possono andare a capo.
- gli interi possono essere negativi.
- un riferimento deve puntare a una variabile gia' definita quando viene letto
  (nell'esempio del testo e' sempre cosi'; con l'alternativa 1 la risoluzione
  e' "eager", cioe' avviene subito durante il parsing e non dopo).
- per la posizione dei commenti in output usiamo la regola "vicino
  all'elemento superstite piu' vicino", visto che il testo non la specifica.

## Cose non fatte

Il prototipo BNFC (facoltativo) e le funzioni di modifica (esplicitamente
facoltative anch'esse) non sono state implementate qui, dato che la versione
con BNFC e' nell'altra cartella del progetto.

Prima di consegnare ricordarsi di lanciare `make clean`: lo zip non deve
contenere i file generati (`confparser`, `grammatica.tab.*`, `lessico.yy.cpp`).
