module Tac where

import SemTypes

-- indirizzo
data Address
  = AddrVar  String (Maybe (Int, Int)) SemType
  | AddrLit  Literal SemType
  | AddrTemp Int SemType
  deriving (Eq, Show)

-- Un valore letterale  diviso per tipo
data Literal
  = LInt Integer
  | LReal Double
  | LChar Char
  | LBool Bool
  | LStr String
  deriving (Eq, Show)

-- Legge il tipo già allegato a un indirizzo, qualunque sia la sua categoria.
addrType :: Address -> SemType
addrType (AddrVar _ _ t) = t
addrType (AddrLit _ t)   = t
addrType (AddrTemp _ t)  = t

-- Gli operatori binari aritmetici e logici utilizzabili in un'istruzione di assegnamento binario.
data BinOp = OpAdd | OpSub | OpMul | OpDiv | OpAnd | OpOr
  deriving (Eq, Show)

-- Gli operatori di confronto, usati da IIfRel.
data RelOp = OpEq | OpNeq | OpLt | OpLe | OpGt | OpGe
  deriving (Eq, Show)

-- Gli operatori unari: meno, negazione logica, e la conversione di tipo
data UnOp = OpNeg | OpNot | OpCast SemType
  deriving (Eq, Show)


data Instr
  = IBinAssign  Address BinOp Address Address   -- l = r1 bop r2          (es. somma, prodotto, ...)
  | IUnAssign   Address UnOp  Address           -- l = uop r              (meno, negazione, o conversione di tipo)
  | ICopy       Address Address                 -- l = r                  (copia semplice, senza operazioni)
  | IGoto       String                          -- goto label             (salto incondizionato)
  | IIfTrue     Address String                  -- if r goto label        (salta se r è vero)
  | IIfFalse    Address String                  -- ifFalse r goto label   (salta se r è falso)
  | IIfRel      Address RelOp Address String    -- if r1 rel r2 goto label    (salta se il confronto è vero)
  | IIndexGet   Address Address Address         -- l = id[r]               (leggere un elemento di array)
  | IIndexAddr  Address Address Address         -- l = &id[r]              (calcolare solo l'indirizzo di un elemento di array)
  | IIndexSet   Address Address Address         -- id[r1] = r2             (scrivere un elemento di array)
  | IAddrOf     Address Address                 -- l = &id                 (prendere l'indirizzo di una variabile)
  | IDerefGet   Address Address                 -- l1 = *l2                (leggere il contenuto puntato da un puntatore)
  | IDerefSet   Address Address                 -- *l = r                  (scrivere nel contenuto puntato da un puntatore)
  | IParam      Address                         -- param r                 (passare un argomento prima di una chiamata)
  | IPCall      String Int                      -- pcall proc, n           (chiamare una procedura void con n argomenti)
  | IFCall      Address String Int              -- l = fcall fun, n        (chiamare una funzione con valore di ritorno)
  | IReturn                                     -- return                  (uscire da una funzione void)
  | IReturnVal  Address                         -- return r                (uscire restituendo un valore)
  deriving (Eq, Show)

-- un'etichetta o una vera istruzione. Le etichette sono tenute separate dall'istruzione che segue, così anche un blocco privo di istruzioni puo' comunque avere la propria etichetta.
data CodeItem = Lbl String | Ins Instr
  deriving (Eq, Show)


type Code = [CodeItem]

gen :: Instr -> Code
gen i = [Ins i]

-- Attacca un'etichetta davanti a un pezzo di codice già pronto.
label :: String -> Code -> Code
label l c = Lbl l : c
