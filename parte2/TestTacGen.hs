import System.Environment (getArgs)
import ParLinguaggio (pProgram, myLexer)
import TypeCheck (checkProgram)
import TypeErrors (errPos, errMsg, showPos)
import TacGen (genProgram)
import Tac

showAddr :: Address -> String
showAddr (AddrVar n _)  = n
showAddr (AddrLit l _)  = showLit l
showAddr (AddrTemp i _) = "t" ++ show i

showLit :: Literal -> String
showLit (LInt n)  = show n
showLit (LReal d) = show d
showLit (LChar c) = show c
showLit (LBool b) = show b

showInstr :: Instr -> String
showInstr (IBinAssign l op r1 r2) = showAddr l ++ " = " ++ showAddr r1 ++ " " ++ show op ++ " " ++ showAddr r2
showInstr (IUnAssign l op r)      = showAddr l ++ " = " ++ show op ++ " " ++ showAddr r
showInstr (ICopy l r)             = showAddr l ++ " = " ++ showAddr r
showInstr (IGoto lbl)             = "goto " ++ lbl
showInstr (IIfTrue r lbl)         = "if " ++ showAddr r ++ " goto " ++ lbl
showInstr (IIfFalse r lbl)        = "ifFalse " ++ showAddr r ++ " goto " ++ lbl
showInstr (IIfRel r1 op r2 lbl)   = "if " ++ showAddr r1 ++ " " ++ show op ++ " " ++ showAddr r2 ++ " goto " ++ lbl
showInstr (IIndexGet l b r)       = showAddr l ++ " = " ++ showAddr b ++ "[" ++ showAddr r ++ "]"
showInstr (IIndexSet b r1 r2)     = showAddr b ++ "[" ++ showAddr r1 ++ "] = " ++ showAddr r2
showInstr (IAddrOf l r)           = showAddr l ++ " = &" ++ showAddr r
showInstr (IIndexAddr l b r)      = showAddr l ++ " = &" ++ showAddr b ++ "[" ++ showAddr r ++ "]"
showInstr (IDerefGet l r)         = showAddr l ++ " = *" ++ showAddr r
showInstr (IDerefSet l r)         = "*" ++ showAddr l ++ " = " ++ showAddr r
showInstr (IParam r)              = "param " ++ showAddr r
showInstr (IPCall n k)            = "pcall " ++ n ++ ", " ++ show k
showInstr (IFCall l n k)          = showAddr l ++ " = fcall " ++ n ++ ", " ++ show k
showInstr IReturn                 = "return"
showInstr (IReturnVal r)          = "return " ++ showAddr r

showCode :: Code -> String
showCode = unlines . map showItem
  where
    showItem (Lbl l)  = l ++ ":"
    showItem (Ins i)  = "    " ++ showInstr i

main :: IO ()
main = do
  [file] <- getArgs
  content <- readFile file
  case pProgram (myLexer content) of
    Left err -> putStrLn ("Errore di parsing: " ++ err)
    Right ast -> do
      let (tprog, errs) = checkProgram ast
      if not (null errs)
        then mapM_ (\e -> putStrLn (showPos (errPos e) ++ ": " ++ errMsg e)) errs
        else do
          let (globalCode, funcs) = genProgram tprog
          putStrLn "=== Codice globale ==="
          putStrLn (showCode globalCode)
          mapM_ (\(name, code) -> do
                   putStrLn ("=== " ++ name ++ " ===")
                   putStrLn (showCode code))
                funcs