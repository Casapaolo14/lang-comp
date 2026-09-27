module TypeErrors where

import SemTypes

-- Un errore di tipo trovato durante il controllo, il messaggio che lo descrive, e la posizione nel sorgente in cui è stato trovato
data TypeError = TypeError
  { errPos :: Maybe (Int, Int)
  , errMsg :: String
  } deriving (Eq, Show)

-- Costruisce un TypeError a partire da una posizione e un messaggio
mkError :: Maybe (Int, Int) -> String -> TypeError
mkError pos msg = TypeError pos msg

-- Trasforma una posizione in un testo leggibile, da inserire nei messaggi d'errore mostrati all'utente
showPos :: Maybe (Int, Int) -> String
showPos Nothing       = "posizione sconosciuta"
showPos (Just (l, c)) = "riga " ++ show l ++ ", colonna " ++ show c

-- Rappresentazione leggibile di un SemType, usata nei messaggi d'errore 
showType :: SemType -> String
showType STInt  = "int"
showType STBool = "bool"
showType STReal = "real"
showType STChar = "char"
showType STStr  = "string"
showType STVoid = "void"
showType (STArr lo hi t) = "[" ++ show lo ++ ".." ++ show hi ++ "] " ++ showType t
showType (STPtr t) = "c_ptr(" ++ showType t ++ ")"
showType STError = "<errore>"
