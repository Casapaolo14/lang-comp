module Tac where

import SemTypes

data Address
  = AddrVar  String SemType
  | AddrLit  Literal SemType
  | AddrTemp Int SemType
  deriving (Eq, Show)

data Literal
  = LInt Integer
  | LReal Double
  | LChar Char
  | LBool Bool
  deriving (Eq, Show)

addrType :: Address -> SemType
addrType (AddrVar _ t)  = t
addrType (AddrLit _ t)  = t
addrType (AddrTemp _ t) = t

data BinOp = OpAdd | OpSub | OpMul | OpDiv | OpAnd | OpOr
  deriving (Eq, Show)

data RelOp = OpEq | OpNeq | OpLt | OpLe | OpGt | OpGe
  deriving (Eq, Show)

data UnOp = OpNeg | OpNot | OpCast SemType
  deriving (Eq, Show)

data Instr
  = IBinAssign  Address BinOp Address Address   -- l = r1 bop r2
  | IUnAssign   Address UnOp  Address           -- l = uop r
  | ICopy       Address Address                 -- l = r
  | IGoto       String                          -- goto label
  | IIfTrue     Address String                  -- if r goto label
  | IIfFalse    Address String                  -- ifFalse r goto label
  | IIfRel      Address RelOp Address String    -- if r1 rel r2 goto label
  | IIndexGet   Address Address Address         -- l = id[r]
  | IIndexAddr  Address Address Address         -- l = &id[r]
  | IIndexSet   Address Address Address         -- id[r1] = r2
  | IAddrOf     Address Address                 -- l = &id
  | IDerefGet   Address Address                 -- l1 = *l2
  | IDerefSet   Address Address                 -- *l = r
  | IParam      Address                         -- param r
  | IPCall      String Int                      -- pcall proc, n
  | IFCall      Address String Int              -- l = fcall fun, n
  | IReturn                                     -- return
  | IReturnVal  Address                         -- return r
  deriving (Eq, Show)

data CodeItem = Lbl String | Ins Instr
  deriving (Eq, Show)

type Code = [CodeItem]

gen :: Instr -> Code
gen i = [Ins i]

label :: String -> Code -> Code
label l c = Lbl l : c