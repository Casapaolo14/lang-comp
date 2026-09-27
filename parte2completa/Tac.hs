module Tac where

import SemTypes

-- Indirizzo: variabile del programma
data Address
  = AddrVar    String (Maybe (Int, Int)) SemType
  | AddrLit    Literal SemType
  | AddrTemp   Int SemType
  | AddrStatic String SemType
  deriving (Eq, Show)

-- Un valore letterale  diviso per tipo
data Literal
  = LInt Integer
  | LReal Double
  | LChar Char
  | LBool Bool
  | LStr String
  deriving (Eq, Show)

-- Legge il tipo già allegato a un indirizzo, qualunque sia la sua categoria
addrType :: Address -> SemType
addrType (AddrVar _ _ t)    = t
addrType (AddrLit _ t)      = t
addrType (AddrTemp _ t)     = t
addrType (AddrStatic _ t)   = t

-- Operatori binari aritmetici, monomorfi per tipo
data BinOp = IntAdd | IntSub | IntMul | IntDiv | RealAdd | RealSub | RealMul | RealDiv
  deriving (Eq, Show)

-- Operatori di confronto, anch'essi monomorfi: uguaglianza ammessa su bool/char/int/real
data RelOp
  = IntEq  | IntNeq  | IntLt  | IntLe  | IntGt  | IntGe
  | RealEq | RealNeq | RealLt | RealLe | RealGt | RealGe
  | BoolEq | BoolNeq
  | CharEq | CharNeq
  deriving (Eq, Show)

-- Operatori unari
data UnOp = IntNeg | RealNeg | BoolNot | OpCast SemType
  deriving (Eq, Show)

data Instr
  = IBinAssign  Address BinOp Address Address   -- l = r1 bop r2          (somma/prodotto/... monomorfi)
  | IUnAssign   Address UnOp  Address           -- l = uop r              (meno, negazione, o conversione di tipo)
  | ICopy       Address Address                 -- l = r                  (copia semplice, senza operazioni)
  | IGoto       String                          -- goto label             (salto incondizionato)
  | IIfTrue     Address String                  -- if r goto label        (salta se r è vero)
  | IIfFalse    Address String                  -- ifFalse r goto label   (salta se r è falso)
  | IIfRel      Address RelOp Address String    -- if r1 rel r2 goto label    (salta se il confronto è vero)
  | IAddrAdd    Address Address Address         -- l = base + offset      (indirizzo di base più un offset in byte, slide 293: sostituisce l'indicizzazione "in un colpo solo")
  | IAddrOf     Address Address                 -- l = &id                 (prendere l'indirizzo di una variabile)
  | IDerefGet   Address Address                 -- l1 = *l2                (leggere il contenuto puntato da un indirizzo, sia esso un puntatore vero o l'indirizzo di un elemento di array appena calcolato)
  | IDerefSet   Address Address                 -- *l = r                  (scrivere nel contenuto puntato, idem)
  | IParam      Address                         -- param r                 (passare un argomento prima di una chiamata)
  | IPCall      String (Maybe (Int, Int)) Int    -- pcall proc_riga, n      (chiamare una procedura void con n argomenti; la riga è quella della dichiarazione, R12)
  | IFCall      Address String (Maybe (Int, Int)) Int  -- l = fcall fun_riga, n   (chiamare una funzione con valore di ritorno)
  | IReturn                                     -- return                  (uscire da una funzione void)
  | IReturnVal  Address                         -- return r                (uscire restituendo un valore)
  deriving (Eq, Show)

-- un'etichetta o una vera istruzione sono tenute separate dall'istruzione che segue, così anche un blocco privo di istruzioni può avere la propria
data CodeItem = Lbl String | Ins Instr
  deriving (Eq, Show)


type Code = [CodeItem]

gen :: Instr -> Code
gen i = [Ins i]

-- Attacca un'etichetta davanti a un pezzo di codice già pronto.
label :: String -> Code -> Code
label l c = Lbl l : c

-- Dimensione in byte di un valore del tipo dato
sizeOf :: SemType -> Integer
sizeOf STInt  = 8
sizeOf STReal = 8
sizeOf STBool = 1
sizeOf STChar = 1
sizeOf STStr  = 8
sizeOf (STPtr _) = 8
sizeOf (STArr lo hi t) = (hi - lo + 1) * sizeOf t
sizeOf t = error ("sizeOf: " ++ show t ++ " non ha una rappresentazione a runtime")

-- Un'entrata dell'area dati statici
data StaticString = StaticString { ssLabel :: String, ssValue :: String }
  deriving (Eq, Show)
