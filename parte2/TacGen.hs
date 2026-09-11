module TacGen where

import Control.Monad.Trans.State
import SemTypes
import Tac
import TypedAst
import Environment

data GenState = GenState
  { nextTemp :: Int,
    nextLabel :: Int
  }

type TacM a = State GenState a
type FuncCode = (String, Code)

initGenState :: GenState
initGenState = GenState 0 0

newtemp :: SemType -> TacM Address
newtemp t = do
  st <- get
  put st {nextTemp = nextTemp st + 1}
  return (AddrTemp (nextTemp st) t)

newlabel :: TacM String
newlabel = do
  st <- get
  put st {nextLabel = nextLabel st + 1}
  return ("L" ++ show (nextLabel st))

runTacM :: TacM a -> a
runTacM m = evalState m initGenState

genExpr :: TExp -> TacM (Code, Address)
genExpr (TEInt _ n) = return ([], AddrLit (LInt n) STInt)
genExpr (TEReal _ d) = return ([], AddrLit (LReal d) STReal)
genExpr (TEChar _ c) = return ([], AddrLit (LChar c) STChar)
genExpr (TETrue _) = return ([], AddrLit (LBool True) STBool)
genExpr (TEFalse _) = return ([], AddrLit (LBool False) STBool)
genExpr (TEVar t _ name) = return ([], AddrVar name t)
genExpr (TEAdd t e1 e2) = genArith t OpAdd e1 e2
genExpr (TESub t e1 e2) = genArith t OpSub e1 e2
genExpr (TEMul t e1 e2) = genArith t OpMul e1 e2
genExpr (TEDiv t e1 e2) = genArith t OpDiv e1 e2
genExpr (TENeg t e1) = genUnary t OpNeg e1
genExpr (TENot t e1) = genUnary t OpNot e1
genExpr (TECast t e1) = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp (OpCast t) a1)
  return (c1 ++ instr, temp)
genExpr (TEIdx t base idx) = do
  arr <- genArrayAddr (TEIdx t base idx)
  resultTemp <- newtemp t
  let instr = gen (IIndexGet resultTemp (AddrVar (arrBase arr) (arrElemTy arr)) (arrOffset arr))
  return (arrCode arr ++ instr, resultTemp)
genExpr (TEDeref t e1) = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IDerefGet temp a1)
  return (c1 ++ instr, temp)
genExpr (TEAddr t e1) = genLValueAddr t e1
genExpr (TEAnd t e1 e2) = genArith t OpAnd e1 e2
genExpr (TEOr  t e1 e2) = genArith t OpOr  e1 e2
genExpr (TECall t name args) = do
  (argsCode, argAddrs) <- genCallArgs args
  let paramInstrs = concatMap (gen . IParam) argAddrs
  resultTemp <- newtemp t
  let callInstr = gen (IFCall resultTemp name (length args))
  return (argsCode ++ paramInstrs ++ callInstr, resultTemp)

genArith :: SemType -> BinOp -> TExp -> TExp -> TacM (Code, Address)
genArith t op e1 e2 = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  temp <- newtemp t
  let instr = gen (IBinAssign temp op a1 a2)
  return (c1 ++ c2 ++ instr, temp)

genUnary :: SemType -> UnOp -> TExp -> TacM (Code, Address)
genUnary t op e1 = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp op a1)
  return (c1 ++ instr, temp)

data ArrayAddr = ArrayAddr
  { arrCode :: Code,
    arrBase :: String,
    arrOffset :: Address,
    arrElemTy :: SemType
  }

genArrayAddr :: TExp -> TacM ArrayAddr
genArrayAddr (TEIdx _ base idxExpr) = do
  (idxCode, idxAddr) <- genExpr idxExpr
  case base of
    TEVar _ _ name -> do
      let (STArr lo _ elemTy) = typeOf base
      normT <- newtemp STInt
      let subInstr = gen (IBinAssign normT OpSub idxAddr (AddrLit (LInt lo) STInt))
      return (ArrayAddr (idxCode ++ subInstr) name normT elemTy)
    TEIdx {} -> do
      inner <- genArrayAddr base
      let (STArr lo hi elemTy) = arrElemTy inner
          dimCount = hi - lo + 1
      normT <- newtemp STInt
      let subInstr = gen (IBinAssign normT OpSub idxAddr (AddrLit (LInt lo) STInt))
      mulT <- newtemp STInt
      let mulInstr = gen (IBinAssign mulT OpMul (arrOffset inner) (AddrLit (LInt dimCount) STInt))
      combT <- newtemp STInt
      let addInstr = gen (IBinAssign combT OpAdd mulT normT)
      return (ArrayAddr (arrCode inner ++ idxCode ++ subInstr ++ mulInstr ++ addInstr)
                         (arrBase inner) combT elemTy)
    _ -> error "genArrayAddr: indicizzazione di un array raggiunto tramite dereferenziazione di puntatore non supportata (limitazione nota, si veda relazione)"

genLValueAddr :: SemType -> TExp -> TacM (Code, Address)
genLValueAddr t (TEVar _ _ name) = do
  temp <- newtemp t
  let pointeeTy = case t of STPtr inner -> inner; _ -> t
  let instr = gen (IAddrOf temp (AddrVar name pointeeTy))
  return (instr, temp)
genLValueAddr t idxExpr@(TEIdx {}) = do
  arr <- genArrayAddr idxExpr
  temp <- newtemp t
  let instr = gen (IIndexAddr temp (AddrVar (arrBase arr) (arrElemTy arr)) (arrOffset arr))
  return (arrCode arr ++ instr, temp)
genLValueAddr _ (TEDeref _ e1) = genExpr e1

genCond :: TExp -> String -> String -> TacM Code
genCond (TETrue _) trueLbl _ =
  return (gen (IGoto trueLbl))
genCond (TEFalse _) _ falseLbl =
  return (gen (IGoto falseLbl))

genCond (TENot _ e1) trueLbl falseLbl =
  genCond e1 falseLbl trueLbl

genCond (TEAnd _ e1 e2) trueLbl falseLbl = do
  midLbl <- newlabel
  c1 <- genCond e1 midLbl falseLbl
  c2 <- genCond e2 trueLbl falseLbl
  return (c1 ++ label midLbl c2)

genCond (TEOr _ e1 e2) trueLbl falseLbl = do
  midLbl <- newlabel
  c1 <- genCond e1 trueLbl midLbl
  c2 <- genCond e2 trueLbl falseLbl
  return (c1 ++ label midLbl c2)

genCond (TEEq  _ e1 e2) trueLbl falseLbl = genCondRel OpEq  e1 e2 trueLbl falseLbl
genCond (TENeq _ e1 e2) trueLbl falseLbl = genCondRel OpNeq e1 e2 trueLbl falseLbl
genCond (TELt  _ e1 e2) trueLbl falseLbl = genCondRel OpLt  e1 e2 trueLbl falseLbl
genCond (TELe  _ e1 e2) trueLbl falseLbl = genCondRel OpLe  e1 e2 trueLbl falseLbl
genCond (TEGt  _ e1 e2) trueLbl falseLbl = genCondRel OpGt  e1 e2 trueLbl falseLbl
genCond (TEGe  _ e1 e2) trueLbl falseLbl = genCondRel OpGe  e1 e2 trueLbl falseLbl

genCond e trueLbl falseLbl = do
  (c, a) <- genExpr e
  return (c ++ gen (IIfTrue a trueLbl) ++ gen (IGoto falseLbl))

genCondRel :: RelOp -> TExp -> TExp -> String -> String -> TacM Code
genCondRel op e1 e2 trueLbl falseLbl = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  return (c1 ++ c2 ++ gen (IIfRel a1 op a2 trueLbl) ++ gen (IGoto falseLbl))

genStmt :: TStmt -> TacM (Code, [FuncCode])
genStmt (TSAssign lhs rhs) = case lhs of
  TEVar _ _ name -> do
    (rc, ra) <- genExpr rhs
    let instr = gen (ICopy (AddrVar name (typeOf lhs)) ra)
    return (rc ++ instr, [])
  TEIdx {} -> do
    arr <- genArrayAddr lhs
    (rc, ra) <- genExpr rhs
    let instr = gen (IIndexSet (AddrVar (arrBase arr) (arrElemTy arr)) (arrOffset arr) ra)
    return (arrCode arr ++ rc ++ instr, [])
  TEDeref _ ptrExpr -> do
    (pc, pa) <- genExpr ptrExpr
    (rc, ra) <- genExpr rhs
    let instr = gen (IDerefSet pa ra)
    return (pc ++ rc ++ instr, [])

genStmt (TSCall name args) = do
  (argsCode, argAddrs) <- genCallArgs args
  let paramInstrs = concatMap (gen . IParam) argAddrs
  let callInstr = gen (IPCall name (length args))
  return (argsCode ++ paramInstrs ++ callInstr, [])

genStmt (TSReturn e) = do
  (c, a) <- genExpr e
  return (c ++ gen (IReturnVal a), [])

genStmt (TSReturnV) = return (gen IReturn, [])

genStmt (TSDecl topDecl) = genTopDecl topDecl

genStmt (TSBlock blk) = genBlock blk

genStmt (TSIf cond blk) = do
  trueLbl  <- newlabel
  falseLbl <- newlabel
  condCode <- genCond cond trueLbl falseLbl
  (bodyCode, bodyFuncs) <- genBlock blk
  return (condCode ++ label trueLbl bodyCode ++ [Lbl falseLbl], bodyFuncs)

genStmt (TSIfElse cond blk1 blk2) = do
  trueLbl  <- newlabel
  falseLbl <- newlabel
  nextLbl  <- newlabel
  condCode <- genCond cond trueLbl falseLbl
  (thenCode, thenFuncs) <- genBlock blk1
  (elseCode, elseFuncs) <- genBlock blk2
  return (condCode
          ++ label trueLbl thenCode
          ++ gen (IGoto nextLbl)
          ++ label falseLbl elseCode
          ++ [Lbl nextLbl],
          thenFuncs ++ elseFuncs)

genStmt (TSWhile cond blk) = do
  trueLbl  <- newlabel
  guardLbl <- newlabel
  falseLbl <- newlabel
  condCode <- genCond cond trueLbl falseLbl
  (bodyCode, bodyFuncs) <- genBlock blk
  return (gen (IGoto guardLbl)
          ++ label trueLbl bodyCode
          ++ label guardLbl condCode
          ++ [Lbl falseLbl],
          bodyFuncs)

genBlock :: TBlock -> TacM (Code, [FuncCode])
genBlock (TBlock stmts) = genStmtList stmts

genStmtList :: [TStmt] -> TacM (Code, [FuncCode])
genStmtList [] = return ([], [])
genStmtList (s:ss) = do
  (c1, f1) <- genStmt s
  (c2, f2) <- genStmtList ss
  return (c1 ++ c2, f1 ++ f2)   

genCallArgs :: [(ParamIntent, TExp)] -> TacM (Code, [Address])
genCallArgs [] = return ([], [])
genCallArgs ((intent, te):rest) = do
  (thisCode, thisAddr) <- genCallArg intent te
  (restCode, restAddrs) <- genCallArgs rest
  return (thisCode ++ restCode, thisAddr : restAddrs)

genCallArg :: ParamIntent -> TExp -> TacM (Code, Address)
genCallArg ByValue te = genExpr te
genCallArg ByRef   te = genLValueAddr (STPtr (typeOf te)) te

genTopDecl :: TTopDecl -> TacM (Code, [FuncCode])
genTopDecl (TDVar _ _ _) = return ([], [])

genTopDecl (TDVarInit name ty _ initExpr) = do
  (c, a) <- genExpr initExpr
  let instr = gen (ICopy (AddrVar name ty) a)
  return (c ++ instr, [])

genTopDecl (TDProc name _ _ _ body) = do
  (bodyCode, nestedFuncs) <- genBlock body
  return ([], (name, bodyCode) : nestedFuncs)

genProgram :: TProgram -> (Code, [FuncCode])
genProgram (TProgram topDecls) = runTacM (genTopDeclList topDecls)

genTopDeclList :: [TTopDecl] -> TacM (Code, [FuncCode])
genTopDeclList [] = return ([], [])
genTopDeclList (d:ds) = do
  (c1, f1) <- genTopDecl d
  (c2, f2) <- genTopDeclList ds
  return (c1 ++ c2, f1 ++ f2)