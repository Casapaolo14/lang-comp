module SemTypes where

import qualified AbsLinguaggio as Abs

-- I tipi che il controllore dei tipi conosce e usa internamente. Sono
-- diversi dai tipi scritti dal programmatore (quelli in Abs.Type): qui
-- in piu' c'e' STError, un tipo "finto" che non si puo' scrivere nel
-- sorgente e serve solo per segnalare che qualcosa e' andato storto
-- senza dover interrompere subito tutto il controllo.
data SemType
    = STInt
    | STBool
    | STReal
    | STChar
    | STStr
    | STVoid
    | STArr Integer Integer SemType  -- estremo minimo, estremo massimo, tipo degli elementi
    | STPtr SemType                  -- puntatore a un altro tipo
    | STError
  deriving (Eq, Show)

-- Traduce un tipo cosi' come l'ha scritto il programmatore (uscito dal
-- parser) nel corrispondente SemType usato da qui in poi. Per i tipi
-- composti (array, puntatore) la conversione richiama se stessa sul
-- tipo interno, cosi' anche un tipo annidato come un array di puntatori
-- viene tradotto correttamente fino in fondo.
fromSyntacticType :: Abs.Type -> SemType
fromSyntacticType t = case t of
  Abs.TInt  _         -> STInt
  Abs.TBool _         -> STBool
  Abs.TReal _         -> STReal
  Abs.TChar _         -> STChar
  Abs.TStr  _         -> STStr
  Abs.TVoid _         -> STVoid
  Abs.TArr  _ lo hi t1 -> STArr lo hi (fromSyntacticType t1)
  Abs.TPtr  _ t1       -> STPtr (fromSyntacticType t1)

-- Dati i tipi dei due lati di un'operazione (es. una somma), dice quale
-- tipo risulta dalla loro combinazione, oppure STError se i due tipi non
-- vanno d'accordo. Se anche uno solo dei due e' gia' STError, il
-- risultato resta STError senza generare un nuovo errore (cosi' un
-- singolo problema non si moltiplica in tanti messaggi ripetuti). Un
-- intero puo' sempre combinarsi con un reale, ottenendo un reale; in
-- tutti gli altri casi i due tipi devono essere identici, altrimenti e'
-- errore.
sup :: SemType -> SemType -> SemType
sup STError _ = STError
sup _ STError = STError
sup STInt STReal = STReal
sup STReal STInt = STReal
sup t1 t2
  | t1 == t2  = t1
  | otherwise = STError

-- Controlla che un tipo sia adatto a un'operazione matematica unaria
-- (es. il meno unario "-x"): solo interi e reali vanno bene, qualsiasi
-- altro tipo produce STError.
mathtype :: SemType -> SemType
mathtype STReal = STReal
mathtype STInt  = STInt
mathtype _      = STError

-- Tipo risultante da un confronto (==, <, >, ...) fra due valori: si
-- appoggia a "sup" per sapere se i due tipi sono confrontabili fra loro
-- (ignorando quale sia il tipo risultante, ci interessa solo se e'
-- STError oppure no); se sono confrontabili il risultato e' sempre
-- booleano, altrimenti e' STError.
rel :: SemType -> SemType -> SemType
rel t1 t2 = case sup t1 t2 of
  STError -> STError
  _       -> STBool

-- Dice se un valore di tipo "t" puo' essere assegnato (o passato come
-- argomento) a qualcosa che si aspetta il tipo "target": vale se sono
-- esattamente lo stesso tipo, oppure nel solo caso speciale di un intero
-- assegnato dove serve un reale.
assignableTo :: SemType -> SemType -> Bool
assignableTo t target
  | t == target           = True
  | t == STInt && target == STReal = True
  | otherwise             = False
