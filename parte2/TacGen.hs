module TacGen where

import Control.Monad.Trans.State
import SemTypes
import Tac
import TypedAst
import Environment

-- Lo stato che il generatore si porta dietro durante tutta la traduzione
data GenState = GenState
  { nextTemp :: Int,
    nextLabel :: Int
  }

-- Il contenitore dentro cui gira tutta la generazione di codice
type TacM a = State GenState a

-- Il codice generato per una singola funzione
type FuncCode = (String, Code)

-- Lo stato di partenza
initGenState :: GenState
initGenState = GenState 0 0

-- Crea un nuovo temporaneo: incrementa il contatore e lo usa come id.
newtemp :: SemType -> TacM Address
newtemp t = do
  st <- get
  put st {nextTemp = nextTemp st + 1}
  return (AddrTemp (nextTemp st) t)

-- Crea una nuova etichetta
newlabel :: TacM String
newlabel = do
  st <- get
  put st {nextLabel = nextLabel st + 1}
  return ("L" ++ show (nextLabel st))

-- Avvia una computazione TacM partendo dallo stato iniziale e restituisce solo il suo risultato finale
runTacM :: TacM a -> a
runTacM m = evalState m initGenState

-- Genera codice + indirizzo del risultato di un'espressione. Letterali
-- e variabili non generano nulla; il resto delega a genArith/genUnary/
-- genRel/genArrayAddr/genLValueAddr a seconda del caso.
genExpr :: TExp -> TacM (Code, Address)
genExpr (TEInt _ n) = return ([], AddrLit (LInt n) STInt)
genExpr (TEReal _ d) = return ([], AddrLit (LReal d) STReal)
genExpr (TEChar _ c) = return ([], AddrLit (LChar c) STChar)
genExpr (TEStr _ s) = return ([], AddrLit (LStr s) STStr)
genExpr (TETrue _) = return ([], AddrLit (LBool True) STBool)
genExpr (TEFalse _) = return ([], AddrLit (LBool False) STBool)
genExpr (TEVar t pos name) = return ([], AddrVar name pos t)
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
  let instr = gen (IIndexGet resultTemp (AddrVar (arrBase arr) (arrPos arr) (arrElemTy arr)) (arrOffset arr))
  return (arrCode arr ++ instr, resultTemp)
genExpr (TEDeref t e1) = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IDerefGet temp a1)
  return (c1 ++ instr, temp)
genExpr (TEAddr t e1) = genLValueAddr t e1
genExpr (TEAnd t e1 e2) = genArith t OpAnd e1 e2
genExpr (TEOr  t e1 e2) = genArith t OpOr  e1 e2
genExpr (TEEq  t e1 e2) = genRel t OpEq  e1 e2
genExpr (TENeq t e1 e2) = genRel t OpNeq e1 e2
genExpr (TELt  t e1 e2) = genRel t OpLt  e1 e2
genExpr (TELe  t e1 e2) = genRel t OpLe  e1 e2
genExpr (TEGt  t e1 e2) = genRel t OpGt  e1 e2
genExpr (TEGe  t e1 e2) = genRel t OpGe  e1 e2
genExpr (TECall t name args) = do
  (argsCode, argAddrs) <- genCallArgs args
  let paramInstrs = concatMap (gen . IParam) argAddrs
  resultTemp <- newtemp t
  let callInstr = gen (IFCall resultTemp name (length args))
  return (argsCode ++ paramInstrs ++ callInstr, resultTemp)

-- Operazione binaria generica: valuta i due operandi (ordine sx-dx),
-- poi combina in un nuovo temp. Usata anche per &&/|| 
genArith :: SemType -> BinOp -> TExp -> TExp -> TacM (Code, Address)
genArith t op e1 e2 = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  temp <- newtemp t
  let instr = gen (IBinAssign temp op a1 a2)
  return (c1 ++ c2 ++ instr, temp)

-- Operazione unaria generica (neg, not): valuta l'operando, applica l'operatore in un nuovo temp.
genUnary :: SemType -> UnOp -> TExp -> TacM (Code, Address)
genUnary t op e1 = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp op a1)
  return (c1 ++ instr, temp)

-- Confronto usato come valore (non come guardia, vedi genCond): non
-- abbiamo un'istruzione che produca un booleano direttamente, solo
-- IIfRel. Si "materializza" il booleano: salta a trueLbl se
-- vero, altrimenti temp=false e salta a endLbl; a trueLbl temp=true.
genRel :: SemType -> RelOp -> TExp -> TExp -> TacM (Code, Address)
genRel t op e1 e2 = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  temp <- newtemp t
  trueLbl <- newlabel
  endLbl <- newlabel
  let code = c1 ++ c2
          ++ gen (IIfRel a1 op a2 trueLbl)
          ++ gen (ICopy temp (AddrLit (LBool False) STBool))
          ++ gen (IGoto endLbl)
          ++ label trueLbl (gen (ICopy temp (AddrLit (LBool True) STBool)))
          ++ [Lbl endLbl]
  return (code, temp)

-- Indirizzo di un elemento di array: codice, nome+posizione della
-- variabile di base, offset lineare finale, tipo dell'elemento.
data ArrayAddr = ArrayAddr
  { arrCode :: Code,
    arrBase :: String,
    arrPos :: Maybe (Int, Int),
    arrOffset :: Address,
    arrElemTy :: SemType
  }

-- Indirizzo di a[i] (o a[i][j]...): normalizza l'indice rispetto al
-- minimo dichiarato; per più dimensioni combina gli offset per righe.
genArrayAddr :: TExp -> TacM ArrayAddr
genArrayAddr (TEIdx _ base idxExpr) = do
  (idxCode, idxAddr) <- genExpr idxExpr
  case base of
    TEVar _ pos name -> do
      let (STArr lo _ elemTy) = typeOf base
      normT <- newtemp STInt
      let subInstr = gen (IBinAssign normT OpSub idxAddr (AddrLit (LInt lo) STInt))
      return (ArrayAddr (idxCode ++ subInstr) name pos normT elemTy)
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
                         (arrBase inner) (arrPos inner) combT elemTy)
    _ -> error "genArrayAddr: indicizzazione di un array raggiunto tramite dereferenziazione di puntatore non supportata (limitazione nota, si veda relazione)"

-- Indirizzo di una l-expression: variabile (IAddrOf), elemento di array
-- (genArrayAddr + IIndexAddr), o puntatore dereferenziato (il suo
-- stesso valore, nessuna istruzione in più).
genLValueAddr :: SemType -> TExp -> TacM (Code, Address)
genLValueAddr t (TEVar _ pos name) = do
  temp <- newtemp t
  let pointeeTy = case t of STPtr inner -> inner; _ -> t
  let instr = gen (IAddrOf temp (AddrVar name pos pointeeTy))
  return (instr, temp)
genLValueAddr t idxExpr@(TEIdx {}) = do
  arr <- genArrayAddr idxExpr
  temp <- newtemp t
  let instr = gen (IIndexAddr temp (AddrVar (arrBase arr) (arrPos arr) (arrElemTy arr)) (arrOffset arr))
  return (arrCode arr ++ instr, temp)
genLValueAddr _ (TEDeref _ e1) = genExpr e1

-- Jumping code per una condizione (if/while): salta direttamente a
-- trueLbl/falseLbl invece di calcolare un valore. And/Or realizzano lo
-- short-circuit (il secondo operando non viene generato se il primo
-- basta a decidere); i confronti vanno a genCondRel; il caso generico
-- valuta l'espressione e salta in base al suo valore.
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

-- Genera il codice per un confronto usato come condizione: calcola i
-- due operandi, poi un salto condizionato diretto (IIfRel) verso
-- trueLbl, seguito da un salto incondizionato verso falseLbl nel caso
-- il confronto risulti falso.
genCondRel :: RelOp -> TExp -> TExp -> String -> String -> TacM Code
genCondRel op e1 e2 trueLbl falseLbl = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  return (c1 ++ c2 ++ gen (IIfRel a1 op a2 trueLbl) ++ gen (IGoto falseLbl))

-- Genera un'istruzione, più il codice di eventuali funzioni annidate
-- (tenuto separato dal blocco che le contiene). Nell'assegnamento
-- l'indirizzo di sinistra si calcola sempre prima del valore di destra.
-- TSWhile usa lo schema pensato per questo progetto: salta alla
-- guardia, esegue il corpo, poi valuta la condizione per ripetere.
genStmt :: TStmt -> TacM (Code, [FuncCode])
genStmt (TSAssign lhs rhs) = case lhs of
  TEVar _ pos name -> do
    (rc, ra) <- genExpr rhs
    let instr = gen (ICopy (AddrVar name pos (typeOf lhs)) ra)
    return (rc ++ instr, [])
  TEIdx {} -> do
    arr <- genArrayAddr lhs
    (rc, ra) <- genExpr rhs
    let instr = gen (IIndexSet (AddrVar (arrBase arr) (arrPos arr) (arrElemTy arr)) (arrOffset arr) ra)
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

-- Un blocco "{ ... }": delega a genStmtList.
genBlock :: TBlock -> TacM (Code, [FuncCode])
genBlock (TBlock stmts) = genStmtList stmts

-- Una sequenza di istruzioni: concatena codice e funzioni annidate di ciascuna.
genStmtList :: [TStmt] -> TacM (Code, [FuncCode])
genStmtList [] = return ([], [])
genStmtList (s:ss) = do
  (c1, f1) <- genStmt s
  (c2, f2) <- genStmtList ss
  return (c1 ++ c2, f1 ++ f2)

-- Genera tutti gli argomenti di una chiamata, in ordine, con i loro indirizzi finali.
genCallArgs :: [(ParamIntent, TExp)] -> TacM (Code, [Address])
genCallArgs [] = return ([], [])
genCallArgs ((intent, te):rest) = do
  (thisCode, thisAddr) <- genCallArg intent te
  (restCode, restAddrs) <- genCallArgs rest
  return (thisCode ++ restCode, thisAddr : restAddrs)

-- Per valore genera il valore vero e proprio; per riferimento genera
-- l'indirizzo, così la funzione chiamata legge/scrive la variabile del chiamante.
genCallArg :: ParamIntent -> TExp -> TacM (Code, Address)
genCallArg ByValue te = genExpr te
genCallArg ByRef   te = genLValueAddr (STPtr (typeOf te)) te

-- Variabile senza init: nessun codice. Con init: codice del valore più
-- una copia. Funzione: corpo generato a parte, come routine separata.
genTopDecl :: TTopDecl -> TacM (Code, [FuncCode])
genTopDecl (TDVar _ _ _) = return ([], [])

genTopDecl (TDVarInit name ty pos initExpr) = do
  (c, a) <- genExpr initExpr
  let instr = gen (ICopy (AddrVar name pos ty) a)
  return (c ++ instr, [])

genTopDecl (TDProc name _ _ _ body) = do
  (bodyCode, nestedFuncs) <- genBlock body
  return ([], (name, bodyCode) : nestedFuncs)

-- Punto di ingresso: genera il codice globale e quello di ogni funzione, da zero.
genProgram :: TProgram -> (Code, [FuncCode])
genProgram (TProgram topDecls) = runTacM (genTopDeclList topDecls)

-- Tutte le dichiarazioni globali, una dopo l'altra.
genTopDeclList :: [TTopDecl] -> TacM (Code, [FuncCode])
genTopDeclList [] = return ([], [])
genTopDeclList (d:ds) = do
  (c1, f1) <- genTopDecl d
  (c2, f2) <- genTopDeclList ds
  return (c1 ++ c2, f1 ++ f2)
