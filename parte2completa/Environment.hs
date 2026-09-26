module Environment where

import qualified AbsLinguaggio as Abs
import qualified Data.Map as Map
import SemTypes

-- Passaggio parametro per valore oppure per riferimento
data ParamIntent = ByValue | ByRef
  deriving (Eq, Show)

-- Traduzione della modalità di passaggio nel corrispondente ParamIntent.
fromSyntacticIntent :: Abs.Intent -> ParamIntent
fromSyntacticIntent intent = case intent of
  Abs.IIn  _ -> ByValue
  Abs.IRef _ -> ByRef

-- Per ogni variabile, sappiamo: tipo + posizione (riga, colonna) in cui è stata dichiarata (Nothing se non c'è posizione)
data VarInfo = VarInfo
  { viType     :: SemType
  , viDeclPos  :: Maybe (Int, Int)
  } deriving (Eq, Show)

-- Per ogni funzione, sappiamo: la lista dei suoi parametri (per ognuno come viene passato + tipo) + tipo del valore di ritorno
data FunInfo = FunInfo
  { fiParams :: [(ParamIntent, SemType)]
  , fiReturn :: SemType
  } deriving (Eq, Show)

-- Elenco di tutte le dichiarazioni, sia per le variabili che per le funzioni
data Env = Env
  { envVars :: Map.Map String VarInfo
  , envFuns :: Map.Map String FunInfo
  } deriving (Eq, Show)

-- Ambiente
emptyEnv :: Env
emptyEnv = Env Map.empty Map.empty

-- Ambiente iniziale
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
