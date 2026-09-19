module TypeErrors where

-- Un singolo errore di tipo trovato durante il controllo: il messaggio
-- che lo descrive, e la posizione nel sorgente in cui e' stato trovato
-- (Nothing quando non c'e' una posizione precisa da indicare, per
-- esempio per un errore che riguarda l'intero programma).
data TypeError = TypeError
  { errPos :: Maybe (Int, Int)
  , errMsg :: String
  } deriving (Eq, Show)

-- Costruisce un TypeError a partire da una posizione e un messaggio.
mkError :: Maybe (Int, Int) -> String -> TypeError
mkError pos msg = TypeError pos msg

-- Trasforma una posizione (o la sua assenza) in un testo leggibile, da
-- inserire nei messaggi d'errore mostrati all'utente.
showPos :: Maybe (Int, Int) -> String
showPos Nothing       = "posizione sconosciuta"
showPos (Just (l, c)) = "riga " ++ show l ++ ", colonna " ++ show c
