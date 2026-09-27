module PrintTac
  ( printAddr
  , printSemType
  , printInstr
  , printCode
  , printProgram
  ) where

import Tac
import SemTypes

-- Stampa i tipi
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

-- Stampa un indirizzo. AddrVar: se porta con sè una posizione di dichiarazione la aggiunge al nome
printAddr :: Address -> String
printAddr (AddrVar name pos _) = name ++ posSuffix pos
printAddr (AddrLit lit _)      = printLiteral lit
printAddr (AddrTemp i _)       = "t" ++ show i
printAddr (AddrStatic lbl _)   = lbl

-- Suffisso "_riga" per annotare un identificatore con la riga della sua dichiarazione
posSuffix :: Maybe (Int, Int) -> String
posSuffix (Just (line, _)) = "_" ++ show line
posSuffix Nothing          = ""

printLiteral :: Literal -> String
printLiteral (LInt n)  = show n
printLiteral (LReal d) = show d
printLiteral (LChar c) = show c
printLiteral (LBool b) = if b then "true" else "false"
printLiteral (LStr s)  = show s

-- Nomi delle operazioni monomorfe: un costruttore per ciascuna combinazione di operazione e tipo senza dover ricalcolare nulla dal tipo
printBinOp :: BinOp -> String
printBinOp IntAdd  = "intadd"
printBinOp IntSub  = "intsub"
printBinOp IntMul  = "intmul"
printBinOp IntDiv  = "intdiv"
printBinOp RealAdd = "floatadd"
printBinOp RealSub = "floatsub"
printBinOp RealMul = "floatmul"
printBinOp RealDiv = "floatdiv"

printRelOp :: RelOp -> String
printRelOp IntEq   = "inteq"
printRelOp IntNeq  = "intneq"
printRelOp IntLt   = "intlt"
printRelOp IntLe   = "intle"
printRelOp IntGt   = "intgt"
printRelOp IntGe   = "intge"
printRelOp RealEq  = "floateq"
printRelOp RealNeq = "floatneq"
printRelOp RealLt  = "floatlt"
printRelOp RealLe  = "floatle"
printRelOp RealGt  = "floatgt"
printRelOp RealGe  = "floatge"
printRelOp BoolEq  = "booleq"
printRelOp BoolNeq = "boolneq"
printRelOp CharEq  = "chareq"
printRelOp CharNeq = "charneq"

printUnOp :: UnOp -> String
printUnOp IntNeg     = "-"
printUnOp RealNeg    = "-"
printUnOp BoolNot    = "!"
printUnOp (OpCast t) = "(" ++ printSemType t ++ ") "

-- Stampa una singola istruzione
printInstr :: Instr -> String
printInstr (IBinAssign l op r1 r2) = printAddr l ++ " = " ++ printAddr r1 ++ " " ++ printBinOp op ++ " " ++ printAddr r2
printInstr (IUnAssign l op r)      = printAddr l ++ " = " ++ printUnOp op ++ printAddr r
printInstr (ICopy l r)             = printAddr l ++ " = " ++ printAddr r
printInstr (IGoto lbl)             = "goto " ++ lbl
printInstr (IIfTrue r lbl)         = "if " ++ printAddr r ++ " goto " ++ lbl
printInstr (IIfFalse r lbl)        = "ifFalse " ++ printAddr r ++ " goto " ++ lbl
printInstr (IIfRel r1 op r2 lbl)   = "if " ++ printAddr r1 ++ " " ++ printRelOp op ++ " " ++ printAddr r2 ++ " goto " ++ lbl
printInstr (IAddrAdd l base off)   = printAddr l ++ " = " ++ printAddr base ++ " + " ++ printAddr off
printInstr (IAddrOf l r)           = printAddr l ++ " = &" ++ printAddr r
printInstr (IDerefGet l r)         = printAddr l ++ " = *" ++ printAddr r
printInstr (IDerefSet l r)         = "*" ++ printAddr l ++ " = " ++ printAddr r
printInstr (IParam r)              = "param " ++ printAddr r
printInstr (IPCall n pos k)        = "pcall " ++ n ++ posSuffix pos ++ ", " ++ show k
printInstr (IFCall l n pos k)      = printAddr l ++ " = fcall " ++ n ++ posSuffix pos ++ ", " ++ show k
printInstr IReturn                 = "return"
printInstr (IReturnVal r)          = "return " ++ printAddr r

printCodeItem :: CodeItem -> String
printCodeItem (Lbl l) = l ++ ":"
printCodeItem (Ins i) = "    " ++ printInstr i

-- Stampa una sequenza di codice, un'istruzione per riga.
printCode :: Code -> String
printCode = unlines . map printCodeItem

-- Stampa l'area dati statici. Un'etichetta per ogni stringa letterale distinta incontrata
printStaticData :: [StaticString] -> String
printStaticData [] = ""
printStaticData strs =
  unlines (("=== dati statici ===") : [ ssLabel s ++ ": " ++ show (ssValue s) | s <- strs ])

-- Stampa il risultato completo della generazione
printProgram :: Code -> [(String, Code)] -> [StaticString] -> String
printProgram globalCode funcs statics =
  printStaticData statics
  ++ unlines (("=== codice globale ===") : lines (printCode globalCode))
  ++ concatMap printFunc funcs
  where
    printFunc (name, code) =
      unlines (("=== " ++ name ++ " ===") : lines (printCode code))
