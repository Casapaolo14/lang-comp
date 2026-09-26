module TypeErrors where

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
