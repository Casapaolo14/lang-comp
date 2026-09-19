module Environment where

import qualified AbsLinguaggio as Abs
import qualified Data.Map as Map
import SemTypes

-- Come e' stato passato un parametro: per valore (una copia, modificarlo
-- dentro la funzione non cambia nulla fuori) oppure per riferimento
-- (l'indirizzo vero della variabile del chiamante, modificarlo dentro la
-- funzione cambia anche fuori).
data ParamIntent = ByValue | ByRef
  deriving (Eq, Show)

-- Traduce la modalita' di passaggio cosi' come scritta nel sorgente
-- (assenza della parola "ref" oppure sua presenza) nel corrispondente
-- ParamIntent.
fromSyntacticIntent :: Abs.Intent -> ParamIntent
fromSyntacticIntent intent = case intent of
  Abs.IIn  _ -> ByValue
  Abs.IRef _ -> ByRef

-- Tutto quello che serve sapere di una variabile una volta dichiarata:
-- il suo tipo, e la posizione (riga, colonna) in cui e' stata dichiarata
-- nel sorgente (Nothing per le funzioni predefinite del linguaggio, che
-- non hanno una vera posizione nel file dell'utente).
data VarInfo = VarInfo
  { viType     :: SemType
  , viDeclPos  :: Maybe (Int, Int)
  } deriving (Eq, Show)

-- Tutto quello che serve sapere di una funzione una volta dichiarata:
-- la lista dei suoi parametri (con, per ciascuno, come viene passato e
-- il suo tipo) e il tipo del valore che restituisce.
data FunInfo = FunInfo
  { fiParams :: [(ParamIntent, SemType)]
  , fiReturn :: SemType
  } deriving (Eq, Show)

-- Il "quaderno" delle dichiarazioni visibili in un certo punto del
-- programma: due rubriche separate, una per le variabili e una per le
-- funzioni, entrambe indicizzate per nome.
data Env = Env
  { envVars :: Map.Map String VarInfo
  , envFuns :: Map.Map String FunInfo
  } deriving (Eq, Show)

-- Un quaderno completamente vuoto, senza nessuna variabile o funzione
-- ancora dichiarata.
emptyEnv :: Env
emptyEnv = Env Map.empty Map.empty

-- Il quaderno di partenza da cui parte il controllo di un programma:
-- vuoto per le variabili, ma gia' precompilato con le otto funzioni di
-- libreria (lettura/scrittura sui tipi base) che il programmatore puo'
-- usare senza doverle dichiarare lui stesso.
initialEnv :: Env
initialEnv = emptyEnv { envFuns = Map.fromList
  [ ("writeInt",    FunInfo [(ByValue, STInt)]  STVoid)
  , ("writeReal",   FunInfo [(ByValue, STReal)] STVoid)
  , ("writeChar",   FunInfo [(ByValue, STChar)] STVoid)
  , ("writeString", FunInfo [(ByValue, STStr)]  STVoid)
  , ("readInt",     FunInfo [] STInt)
  , ("readReal",    FunInfo [] STReal)
  , ("readChar",    FunInfo [] STChar)
  , ("readString",  FunInfo [] STStr)
  ]}
