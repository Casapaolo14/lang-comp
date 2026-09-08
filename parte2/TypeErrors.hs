module TypeErrors where

data TypeError = TypeError
  { errPos :: Maybe (Int, Int)
  , errMsg :: String
  } deriving (Eq, Show)

mkError :: Maybe (Int, Int) -> String -> TypeError
mkError pos msg = TypeError pos msg

showPos :: Maybe (Int, Int) -> String
showPos Nothing       = "posizione sconosciuta"
showPos (Just (l, c)) = "riga " ++ show l ++ ", colonna " ++ show c