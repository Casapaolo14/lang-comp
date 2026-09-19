module Main where

import System.Environment (getArgs)
import System.Exit (exitFailure)

import ParLinguaggio (pProgram, myLexer)
import PrintLinguaggio (printTree)
import TypeCheck (checkProgram)
import TypeErrors (errPos, errMsg, showPos)
import TacGen (genProgram)
import PrintTac (printProgram)

-- Esegue l'intera pipeline su un singolo file: parsing, analisi di
-- semantica statica, pretty-print del sorgente e, solo se non ci sono
-- errori di tipo, generazione e pretty-print del three-address code.
-- Un errore di parsing e un errore di tipo restano ben distinti fra
-- loro nell'output, invece di essere confusi in un unico messaggio.
runFile :: FilePath -> IO ()
runFile file = do
  putStrLn ("##### " ++ file ++ " #####")
  content <- readFile file
  case pProgram (myLexer content) of
    Left err -> putStrLn ("Errore di parsing: " ++ err)
    Right ast -> do
      putStrLn "--- Pretty-print del sorgente ---"
      putStrLn (printTree ast)
      let (tprog, errs) = checkProgram ast
      if not (null errs)
        then do
          putStrLn "--- Errori di tipo ---"
          mapM_ (\e -> putStrLn (showPos (errPos e) ++ ": " ++ errMsg e)) errs
        else do
          putStrLn "--- Three-address code ---"
          let (globalCode, funcs) = genProgram tprog
          putStr (printProgram globalCode funcs)
  putStrLn ""

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> putStrLn "Uso: Main <file1.lang> [file2.lang ...]" >> exitFailure
    fs -> mapM_ runFile fs
