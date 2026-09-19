module PrintTac
  ( printAddr
  , printSemType
  , printInstr
  , printCode
  , printProgram
  ) where

import Tac
import SemTypes

-- Stampa un tipo semantico con una sintassi vicina a quella concreta
-- del linguaggio, usata sia qui (per l'operatore di cast) sia altrove
-- se serve descrivere un tipo a parole.
printSemType :: SemType -> String
printSemType STInt        = "int"
printSemType STBool       = "bool"
printSemType STReal       = "real"
printSemType STChar       = "char"
printSemType STStr        = "string"
printSemType STVoid       = "void"
printSemType (STArr l h t) = "[" ++ show l ++ ".." ++ show h ++ "]" ++ printSemType t
printSemType (STPtr t)     = "c_ptr(" ++ printSemType t ++ ")"
printSemType STError       = "ERROR"

-- Stampa un indirizzo. Il caso importante è AddrVar: se porta con sè
-- una posizione di dichiarazione, la aggiunge al nome come richiesto
-- dal testo dell'esercizio se la posizione non è nota si stampa solo il
-- nome, senza inventare nulla.
printAddr :: Address -> String
printAddr (AddrVar name pos _) = name ++ suffix
  where
    suffix = case pos of
      Just (line, _) -> "_" ++ show line
      Nothing        -> ""
printAddr (AddrLit lit _)  = printLiteral lit
printAddr (AddrTemp i _)   = "t" ++ show i

printLiteral :: Literal -> String
printLiteral (LInt n)  = show n
printLiteral (LReal d) = show d
printLiteral (LChar c) = show c
printLiteral (LBool b) = if b then "true" else "false"
printLiteral (LStr s)  = show s

printBinOp :: BinOp -> String
printBinOp OpAdd = "+"
printBinOp OpSub = "-"
printBinOp OpMul = "*"
printBinOp OpDiv = "/"
printBinOp OpAnd = "&&"
printBinOp OpOr  = "||"

printRelOp :: RelOp -> String
printRelOp OpEq  = "=="
printRelOp OpNeq = "!="
printRelOp OpLt  = "<"
printRelOp OpLe  = "<="
printRelOp OpGt  = ">"
printRelOp OpGe  = ">="

printUnOp :: UnOp -> String
printUnOp OpNeg      = "-"
printUnOp OpNot      = "!"
printUnOp (OpCast t) = "(" ++ printSemType t ++ ") "

-- Stampa una singola istruzione, in una notazione leggibile vicina a
-- quella usata a lezione (un'operazione per riga).
printInstr :: Instr -> String
printInstr (IBinAssign l op r1 r2) = printAddr l ++ " = " ++ printAddr r1 ++ " " ++ printBinOp op ++ " " ++ printAddr r2
printInstr (IUnAssign l op r)      = printAddr l ++ " = " ++ printUnOp op ++ printAddr r
printInstr (ICopy l r)             = printAddr l ++ " = " ++ printAddr r
printInstr (IGoto lbl)             = "goto " ++ lbl
printInstr (IIfTrue r lbl)         = "if " ++ printAddr r ++ " goto " ++ lbl
printInstr (IIfFalse r lbl)        = "ifFalse " ++ printAddr r ++ " goto " ++ lbl
printInstr (IIfRel r1 op r2 lbl)   = "if " ++ printAddr r1 ++ " " ++ printRelOp op ++ " " ++ printAddr r2 ++ " goto " ++ lbl
printInstr (IIndexGet l b r)       = printAddr l ++ " = " ++ printAddr b ++ "[" ++ printAddr r ++ "]"
printInstr (IIndexAddr l b r)      = printAddr l ++ " = &" ++ printAddr b ++ "[" ++ printAddr r ++ "]"
printInstr (IIndexSet b r1 r2)     = printAddr b ++ "[" ++ printAddr r1 ++ "] = " ++ printAddr r2
printInstr (IAddrOf l r)           = printAddr l ++ " = &" ++ printAddr r
printInstr (IDerefGet l r)         = printAddr l ++ " = *" ++ printAddr r
printInstr (IDerefSet l r)         = "*" ++ printAddr l ++ " = " ++ printAddr r
printInstr (IParam r)              = "param " ++ printAddr r
printInstr (IPCall n k)            = "pcall " ++ n ++ ", " ++ show k
printInstr (IFCall l n k)          = printAddr l ++ " = fcall " ++ n ++ ", " ++ show k
printInstr IReturn                 = "return"
printInstr (IReturnVal r)          = "return " ++ printAddr r

printCodeItem :: CodeItem -> String
printCodeItem (Lbl l) = l ++ ":"
printCodeItem (Ins i) = "    " ++ printInstr i

-- Stampa una sequenza di codice, un'istruzione per riga.
printCode :: Code -> String
printCode = unlines . map printCodeItem

-- Stampa il risultato completo della generazione
printProgram :: Code -> [(String, Code)] -> String
printProgram globalCode funcs =
  unlines (("=== codice globale ===") : lines (printCode globalCode))
  ++ concatMap printFunc funcs
  where
    printFunc (name, code) =
      unlines (("=== " ++ name ++ " ===") : lines (printCode code))
