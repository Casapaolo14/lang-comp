import System.Environment (getArgs)
import ParLinguaggio (pProgram, myLexer)
import TypeCheck (checkProgram)
import TypeErrors (errPos, errMsg, showPos)
import TacGen (genProgram)
import PrintTac (printProgram)

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
          putStr (printProgram globalCode funcs)
