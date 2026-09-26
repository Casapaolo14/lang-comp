module SemTypes where

import qualified AbsLinguaggio as Abs

-- Definizione dei nuovi tipi usati per indicare Errore
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

-- Semplice traduzione tra i tipi che avevamo prima ai nuovi tipi che andremo ad utilizzare adesso
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

-- Dati i tipi dei due lati di un'operazione (es. una somma), dice quale tipo risulta dalla loro combinazione, oppure STError se i due tipi non vanno d'accordo
sup :: SemType -> SemType -> SemType
sup STError _ = STError
sup _ STError = STError
sup STInt STReal = STReal
sup STReal STInt = STReal
sup t1 t2
  | t1 == t2  = t1
  | otherwise = STError

-- Controlla che un tipo sia adatto a un'operazione matematica unaria solo interi e reali vanno bene, qualsiasi altro tipo produce STError
mathtype :: SemType -> SemType
mathtype STReal = STReal
mathtype STInt  = STInt
mathtype _      = STError

-- Tipo risultante da un confronto (==, <, >, ...) fra due valori. Se sono confrontabili il risultato è sempre booleano, altrimenti è STError
rel :: SemType -> SemType -> SemType
rel t1 t2 = case sup t1 t2 of
  STError -> STError
  _       -> STBool

-- Dice se un valore di tipo t può essere assegnato a qualcosa che si aspetta il tipo target: vale se sono
-- esattamente lo stesso tipo, oppure nel solo caso di un intero assegnato dove serve un reale
assignableTo :: SemType -> SemType -> Bool
assignableTo t target
  | t == target           = True
  | t == STInt && target == STReal = True
  | otherwise             = False
