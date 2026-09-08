module Environment where

import qualified AbsLinguaggio as Abs
import qualified Data.Map as Map
import SemTypes

data ParamIntent = ByValue | ByRef
  deriving (Eq, Show)

fromSyntacticIntent :: Abs.Intent -> ParamIntent
fromSyntacticIntent intent = case intent of
  Abs.IIn  _ -> ByValue
  Abs.IRef _ -> ByRef

data VarInfo = VarInfo
  { viType     :: SemType
  , viDeclPos  :: Maybe (Int, Int)
  } deriving (Eq, Show)

data FunInfo = FunInfo
  { fiParams :: [(ParamIntent, SemType)]
  , fiReturn :: SemType
  } deriving (Eq, Show)

data Env = Env
  { envVars :: Map.Map String VarInfo
  , envFuns :: Map.Map String FunInfo
  } deriving (Eq, Show)

emptyEnv :: Env
emptyEnv = Env Map.empty Map.empty

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