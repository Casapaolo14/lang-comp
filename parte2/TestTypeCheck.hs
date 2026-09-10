import System.Environment (getArgs)
import ParLinguaggio (pProgram, myLexer)
import TypeCheck (checkProgram)
import TypeErrors (errPos, errMsg, showPos)

main :: IO ()
main = do
  [file] <- getArgs
  content <- readFile file
  case pProgram (myLexer content) of
    Left err -> putStrLn ("Errore di parsing: " ++ err)
    Right ast -> do
      let (_, errs) = checkProgram ast
      if null errs
        then putStrLn "OK: nessun errore di tipo trovato."
        else mapM_ (\e -> putStrLn (showPos (errPos e) ++ ": " ++ errMsg e)) errs