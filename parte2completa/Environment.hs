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

-- Per ogni variabile, sappiamo: tipo, posizione di dichiarazione, se è modificabile (False solo per la
-- variabile del for) e con quale intent è stata introdotta (ByRef solo per un parametro ref: serve a
-- TacGen, per sapere quando un nome è in realtà un puntatore passato dal chiamante).
data VarInfo = VarInfo
  { viType     :: SemType
  , viDeclPos  :: Maybe (Int, Int)
  , viMutable  :: Bool
  , viIntent   :: ParamIntent
  } deriving (Eq, Show)

-- Per ogni funzione, sappiamo: la lista dei suoi parametri (per ognuno come viene passato + tipo) + tipo del valore di ritorno
data FunInfo = FunInfo
  { fiParams :: [(ParamIntent, SemType)]
  , fiReturn :: SemType
  } deriving (Eq, Show)

-- Elenco di tutte le dichiarazioni, sia per le variabili che per le funzioni, più un flag che dice se ci
-- troviamo nel corpo di un ciclo (while/do-while/for): serve per accettare break/continue solo lì.
data Env = Env
  { envVars   :: Map.Map String VarInfo
  , envFuns   :: Map.Map String FunInfo
  , envInLoop :: Bool
  } deriving (Eq, Show)

-- Ambiente
emptyEnv :: Env
emptyEnv = Env Map.empty Map.empty False

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
