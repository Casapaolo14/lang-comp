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

-- Traduzione tra i tipi che avevamo prima ai nuovi tipi che andremo ad utilizzare adesso
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

-- Dati i tipi dei due lati di un'operazione, dice quale tipo risulta dalla loro combinazione, oppure STError se i due tipi non vanno d'accordo
sup :: SemType -> SemType -> SemType
sup STError _ = STError
sup _ STError = STError
sup STInt STReal = STReal
sup STReal STInt = STReal
sup t1 t2
  | t1 == t2  = t1
  | otherwise = STError

-- Controlla che un tipo sia adatto a un'operazione matematica: solo interi e reali vanno bene, qualsiasi altro tipo produce STError
mathtype :: SemType -> SemType
mathtype STReal = STReal
mathtype STInt  = STInt
mathtype _      = STError

-- Tipo risultante da un confronto di uguaglianza (==, !=): ammesso solo fra bool, char, int, real
-- "sup" decide la coercizione fra i due operandi, poi si controlla che il tipo risultante sia fra quelli ammessi
eqOp :: SemType -> SemType -> SemType
eqOp t1 t2
  | t1 == STError || t2 == STError = STError
  | sup t1 t2 `elem` [STBool, STChar, STInt, STReal] = STBool
  | otherwise = STError

-- Tipo risultante da un confronto d'ordine (<, <=, >, >=): ammesso solo fra int e real
ordOp :: SemType -> SemType -> SemType
ordOp t1 t2
  | t1 == STError || t2 == STError = STError
  | sup t1 t2 `elem` [STInt, STReal] = STBool
  | otherwise = STError

-- Controlla se un SemType è un tipo array
isArrayType :: SemType -> Bool
isArrayType (STArr _ _ _) = True
isArrayType _             = False

-- Dice se un valore di tipo t può essere assegnato a qualcosa che si aspetta il tipo target: vale se sono esattamente lo stesso tipo, oppure nel solo caso di un intero assegnato dove serve un reale
assignableTo :: SemType -> SemType -> Bool
assignableTo t target
  | t == target           = True
  | t == STInt && target == STReal = True
  | otherwise             = False
