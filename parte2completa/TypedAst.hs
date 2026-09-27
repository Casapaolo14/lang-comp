module TypedAst where

import SemTypes
import Environment

-- Stessaforma dell'albero sintattico prodotto dal parser, ma ogni nodo porta con sè anche il suo SemType
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
    | TEVar   SemType (Maybe (Int, Int)) String ParamIntent
    | TEInt   SemType Integer
    | TEReal  SemType Double
    | TEChar  SemType Char
    | TEStr   SemType String
    | TETrue  SemType
    | TEFalse SemType
    | TECast  SemType TExp
    | TEIf    SemType TExp TExp TExp   -- if-espressione (R6): condizione, ramo then, ramo else
    | TEArr   SemType [TExp]           -- letterale array (R18)
  deriving (Eq, Show)

-- Legge il tipo già calcolato e attaccato a un nodo, senza doverlo ricalcolare
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
  TEVar   t _ _ _ -> t
  TEInt   t _     -> t
  TEReal  t _     -> t
  TEChar  t _     -> t
  TEStr   t _     -> t
  TETrue  t       -> t
  TEFalse t       -> t
  TECast  t _     -> t
  TEIf    t _ _ _ -> t
  TEArr   t _     -> t

data TBlock = TBlock [TStmt]
  deriving (Eq, Show)

-- Versione semantica dell'operatore di un op= : AAdd/ASub/AMul del sorgente
data TAssignOp = TAAdd | TASub | TAMul
  deriving (Eq, Show)

-- Le istruzioni dopo il type check
data TStmt
    = TSBlock    TBlock
    | TSAssign   TExp TExp
    | TSCall     String [(ParamIntent, TExp)]
    | TSReturn   TExp
    | TSReturnV
    | TSDecl     TTopDecl
    | TSIf       TExp TBlock
    | TSIfElse   TExp TBlock TBlock
    | TSWhile    TExp TBlock
    | TSDoWhile  TBlock TExp                     -- R8
    | TSFor      String (Maybe (Int, Int)) TExp TExp TBlock  -- R8: nome+pos della variabile del for, estremo lo, estremo hi, corpo
    | TSBreak                                    -- R9
    | TSContinue                                 -- R9
    | TSOpAssign TExp TAssignOp TExp             -- R7
  deriving (Eq, Show)

data TParam = TParam
  { tparIntent :: ParamIntent
  , tparType   :: SemType
  , tparName   :: String
  , tparPos    :: Maybe (Int, Int)
  } deriving (Eq, Show)

data TTopDecl
    = TDVar     String SemType (Maybe (Int, Int))
    | TDVarInit String SemType (Maybe (Int, Int)) TExp
    | TDProc    String [TParam] SemType (Maybe (Int, Int)) TBlock
  deriving (Eq, Show)

data TProgram = TProgram [TTopDecl]
  deriving (Eq, Show)
