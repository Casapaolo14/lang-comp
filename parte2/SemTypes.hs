module SemTypes where

import qualified AbsLinguaggio as Abs

data SemType
    = STInt
    | STBool
    | STReal
    | STChar
    | STStr
    | STVoid
    | STArr Integer Integer SemType
    | STPtr SemType
    | STError
  deriving (Eq, Show)

fromSyntacticType :: Abs.Type -> SemType
fromSyntacticType t = case t of
  Abs.TInt  _         -> STInt
  Abs.TBool _         -> STBool
  Abs.TReal _         -> STReal
  Abs.TChar _         -> STChar
  Abs.TStr  _         -> STStr
  Abs.TVoid _         -> STVoid
  Abs.TArr  _ lo hi t1 -> STArr lo hi (fromSyntacticType t1)
  Abs.TPtr  _ t1       -> STPtr (fromSyntacticType t1)

sup :: SemType -> SemType -> SemType
sup STError _ = STError
sup _ STError = STError
sup STInt STReal = STReal
sup STReal STInt = STReal
sup t1 t2
  | t1 == t2  = t1
  | otherwise = STError

mathtype :: SemType -> SemType
mathtype STReal = STReal
mathtype STInt  = STInt
mathtype _      = STError

rel :: SemType -> SemType -> SemType
rel t1 t2 = case sup t1 t2 of
  STError -> STError
  _       -> STBool