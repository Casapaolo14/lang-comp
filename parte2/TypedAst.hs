module TypedAst where

import SemTypes
import Environment

-- L'albero delle espressioni dopo il controllo dei tipi: e' la stessa
-- forma dell'albero sintattico prodotto dal parser, ma ogni nodo porta
-- con se' anche il suo SemType (il tipo che gli e' stato assegnato) e,
-- dove serve, la posizione di dichiarazione. TECast e' un costruttore
-- speciale, che non esiste nella grammatica: e' un "post-it" aggiunto dal
-- controllore dei tipi ogni volta che un intero deve diventare un reale
-- per combinarsi con un'altra espressione.
data TExp
    = TEOr    SemType TExp TExp
    | TEAnd   SemType TExp TExp
    | TEEq    SemType TExp TExp
    | TENeq   SemType TExp TExp
    | TELt    SemType TExp TExp
    | TELe    SemType TExp TExp
    | TEGt    SemType TExp TExp
    | TEGe    SemType TExp TExp
    | TEAdd   SemType TExp TExp
    | TESub   SemType TExp TExp
    | TEMul   SemType TExp TExp
    | TEDiv   SemType TExp TExp
    | TENeg   SemType TExp
    | TENot   SemType TExp
    | TEDeref SemType TExp
    | TEAddr  SemType TExp
    | TEIdx   SemType TExp TExp
    | TECall  SemType String [(ParamIntent, TExp)]
    | TEVar   SemType (Maybe (Int, Int)) String
    | TEInt   SemType Integer
    | TEReal  SemType Double
    | TEChar  SemType Char
    | TEStr   SemType String
    | TETrue  SemType
    | TEFalse SemType
    | TECast  SemType TExp
  deriving (Eq, Show)

-- Legge il tipo gia' calcolato e attaccato a un nodo, senza doverlo
-- ricalcolare: ogni costruttore porta il proprio SemType sempre nella
-- stessa posizione, quindi basta guardare quale caso e' e prendere quel
-- campo.
typeOf :: TExp -> SemType
typeOf texp = case texp of
  TEOr    t _ _   -> t
  TEAnd   t _ _   -> t
  TEEq    t _ _   -> t
  TENeq   t _ _   -> t
  TELt    t _ _   -> t
  TELe    t _ _   -> t
  TEGt    t _ _   -> t
  TEGe    t _ _   -> t
  TEAdd   t _ _   -> t
  TESub   t _ _   -> t
  TEMul   t _ _   -> t
  TEDiv   t _ _   -> t
  TENeg   t _     -> t
  TENot   t _     -> t
  TEDeref t _     -> t
  TEAddr  t _     -> t
  TEIdx   t _ _   -> t
  TECall  t _ _   -> t
  TEVar   t _ _   -> t
  TEInt   t _     -> t
  TEReal  t _     -> t
  TEChar  t _     -> t
  TEStr   t _     -> t
  TETrue  t       -> t
  TEFalse t       -> t
  TECast  t _     -> t

-- Un blocco di istruzioni gia' controllato, cioe' una sequenza di
-- TStmt.
data TBlock = TBlock [TStmt]
  deriving (Eq, Show)

-- Le istruzioni dopo il controllo dei tipi: stessa forma di quelle
-- prodotte dal parser, ma con le espressioni al loro interno gia'
-- sostituite dalla loro versione tipizzata (TExp).
data TStmt
    = TSBlock  TBlock
    | TSAssign TExp TExp
    | TSCall   String [(ParamIntent, TExp)]
    | TSReturn TExp
    | TSReturnV
    | TSDecl   TTopDecl
    | TSIf     TExp TBlock
    | TSIfElse TExp TBlock TBlock
    | TSWhile  TExp TBlock
  deriving (Eq, Show)

-- Un parametro di funzione gia' controllato: a differenza di VarInfo
-- (che vive dentro il quaderno delle dichiarazioni e non ha bisogno di
-- ripetere il proprio nome, dato che e' gia' la chiave con cui lo si
-- cerca), qui il parametro non e' dentro nessuna rubrica ma dentro una
-- lista dei parametri di TDProc: senza un campo nome esplicito non
-- sapremmo a quale variabile locale associarlo quando poi si controlla
-- il corpo della funzione.
data TParam = TParam
  { tparIntent :: ParamIntent
  , tparType   :: SemType
  , tparName   :: String
  , tparPos    :: Maybe (Int, Int)
  } deriving (Eq, Show)

-- Una dichiarazione globale (o locale, tramite TSDecl) gia' controllata:
-- variabile senza valore iniziale, variabile con valore iniziale gia'
-- tipizzato, oppure funzione con i suoi parametri gia' tipizzati e il
-- corpo gia' controllato.
data TTopDecl
    = TDVar     String SemType (Maybe (Int, Int))
    | TDVarInit String SemType (Maybe (Int, Int)) TExp
    | TDProc    String [TParam] SemType (Maybe (Int, Int)) TBlock
  deriving (Eq, Show)

-- Un intero programma dopo il controllo dei tipi: la lista di tutte le
-- sue dichiarazioni globali, gia' verificate.
data TProgram = TProgram [TTopDecl]
  deriving (Eq, Show)
