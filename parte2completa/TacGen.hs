module TacGen where

import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Reader
import Control.Monad.Trans.State
import qualified Data.Map as Map
import qualified Data.Set as Set
import SemTypes
import Tac
import TypedAst
import Environment

-- scendendo nell'albero: si aggiorna solo con "local" nei pochi punti che ne cambiano il valore (entrata in un ciclo, entrata nel corpo
-- di una funzione), così le firme di genExpr/genStmt restano quelle di sempre invece di dover passare esplicitamente questi tre dati ovunque
data GenCtx = GenCtx
  { ctxLoop        :: Maybe (String, String)
    -- (etichetta di "continue", etichetta di "break") del ciclo più interno; Nothing fuori da ogni ciclo (R9)
  , ctxByValArrays :: Set.Set String
    -- nomi dei parametri ARRAY passati per valore della funzione in generazione (R4): fisicamente
    -- ricevuti come indirizzo di una copia privata fatta dal chiamante, quindi vanno letti come un
    -- indirizzo già pronto, esattamente come un parametro ref (R3), non come storage inline
  , ctxFunPos      :: Map.Map String (Maybe (Int, Int))
    -- riga di dichiarazione di ogni funzione del programma, per annotare le chiamate (R12)
  }

initGenCtx :: GenCtx
initGenCtx = GenCtx Nothing Set.empty Map.empty

-- Lo stato che il generatore si porta dietro durante tutta la traduzione
data GenState = GenState
  { nextTemp   :: Int
  , nextLabel  :: Int
  , nextSynth  :: Int
  , nextStrLbl :: Int
  , strTable   :: [(String, String)]
    -- stringhe letterali già incontrate: etichetta nell'area dati statici -> contenuto (G4)
  }

-- Il contenitore dentro cui gira tutta la generazione di codice
type TacM a = ReaderT GenCtx (State GenState) a

-- Il codice generato per una singola funzione
type FuncCode = (String, Code)

-- Lo stato di partenza
initGenState :: GenState
initGenState = GenState 0 0 0 0 []

-- Crea un nuovo temporaneo: incrementa il contatore e lo usa come id
newtemp :: SemType -> TacM Address
newtemp t = lift $ do
  st <- get
  put st {nextTemp = nextTemp st + 1}
  return (AddrTemp (nextTemp st) t)

-- Crea una nuova etichetta
newlabel :: TacM String
newlabel = lift $ do
  st <- get
  put st {nextLabel = nextLabel st + 1}
  return ("L" ++ show (nextLabel st))

-- Crea il nome di una nuova variabile sintetica
newSynthVarName :: TacM String
newSynthVarName = lift $ do
  st <- get
  put st {nextSynth = nextSynth st + 1}
  return ("$arr" ++ show (nextSynth st))

-- Restituisce l'etichetta dell'area dati statici per una stringa letterale, riusando quella già assegnata se la stessa stringa è già comparsa 
internString :: String -> TacM String
internString s = lift $ do
  st <- get
  case lookup s [ (v, k) | (k, v) <- strTable st ] of
    Just lbl -> return lbl
    Nothing -> do
      let lbl = "STR" ++ show (nextStrLbl st)
      put st { nextStrLbl = nextStrLbl st + 1, strTable = strTable st ++ [(lbl, s)] }
      return lbl

-- Avvia una computazione TacM con il contesto e lo stato iniziali, restituendo il risultato e lo stato finale
runTacM :: GenCtx -> TacM a -> (a, GenState)
runTacM ctx m = runState (runReaderT m ctx) initGenState

-- Dentro il corpo di un ciclo: break salta a "brkLbl", continue a "contLbl"
withLoop :: String -> String -> TacM a -> TacM a
withLoop contLbl brkLbl = local (\c -> c { ctxLoop = Just (contLbl, brkLbl) })

-- Le "kind" degli operatori aritmetici e di confronto, indipendenti dal tipo 
-- Servono solo a scegliere la variante monomorfa giusta in base al tipo effettivo degli operandi
data ArithKind = KAdd | KSub | KMul | KDiv

arithOpFor :: ArithKind -> SemType -> BinOp
arithOpFor KAdd STInt  = IntAdd
arithOpFor KAdd STReal = RealAdd
arithOpFor KSub STInt  = IntSub
arithOpFor KSub STReal = RealSub
arithOpFor KMul STInt  = IntMul
arithOpFor KMul STReal = RealMul
arithOpFor KDiv STInt  = IntDiv
arithOpFor KDiv STReal = RealDiv
arithOpFor _ t = error ("arithOpFor: combinazione inattesa per il tipo " ++ show t)

negOpFor :: SemType -> UnOp
negOpFor STInt  = IntNeg
negOpFor STReal = RealNeg
negOpFor t      = error ("negOpFor: tipo inatteso " ++ show t)

data RelKind = KEq | KNeq | KLt | KLe | KGt | KGe

relOpFor :: RelKind -> SemType -> RelOp
relOpFor KEq  STBool = BoolEq
relOpFor KNeq STBool = BoolNeq
relOpFor KEq  STChar = CharEq
relOpFor KNeq STChar = CharNeq
relOpFor KEq  STInt  = IntEq
relOpFor KNeq STInt  = IntNeq
relOpFor KEq  STReal = RealEq
relOpFor KNeq STReal = RealNeq
relOpFor KLt  STInt  = IntLt
relOpFor KLe  STInt  = IntLe
relOpFor KGt  STInt  = IntGt
relOpFor KGe  STInt  = IntGe
relOpFor KLt  STReal = RealLt
relOpFor KLe  STReal = RealLe
relOpFor KGt  STReal = RealGt
relOpFor KGe  STReal = RealGe
relOpFor _ t = error ("relOpFor: combinazione non ammessa per il tipo " ++ show t)

opKindOf :: TAssignOp -> ArithKind
opKindOf TAAdd = KAdd
opKindOf TASub = KSub
opKindOf TAMul = KMul

-- Genera codice + indirizzo del risultato di un'espressione. Letterali e variabili non generano nulla
genExpr :: TExp -> TacM (Code, Address)
genExpr (TEInt _ n) = return ([], AddrLit (LInt n) STInt)
genExpr (TEReal _ d) = return ([], AddrLit (LReal d) STReal)
genExpr (TEChar _ c) = return ([], AddrLit (LChar c) STChar)
genExpr (TEStr _ s) = do
  lbl <- internString s
  temp <- newtemp STStr
  return (gen (IAddrOf temp (AddrStatic lbl STStr)), temp)
genExpr (TETrue _) = return ([], AddrLit (LBool True) STBool)
genExpr (TEFalse _) = return ([], AddrLit (LBool False) STBool)
genExpr (TEVar t pos name intent)
  | isArrayType t = error "genExpr: un array non produce mai un valore diretto (si accede sempre tramite il suo indirizzo)"
  | intent == ByRef = do
      temp <- newtemp t
      return (gen (IDerefGet temp (AddrVar name pos (STPtr t))), temp)
  | otherwise = return ([], AddrVar name pos t)
genExpr (TEAdd t e1 e2) = genArith t (arithOpFor KAdd t) e1 e2
genExpr (TESub t e1 e2) = genArith t (arithOpFor KSub t) e1 e2
genExpr (TEMul t e1 e2) = genArith t (arithOpFor KMul t) e1 e2
genExpr (TEDiv t e1 e2) = genArith t (arithOpFor KDiv t) e1 e2
genExpr (TENeg t e1) = genUnary t (negOpFor t) e1
genExpr (TENot t e1) = genUnary t BoolNot e1
genExpr (TECast t e1) = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp (OpCast t) a1)
  return (c1 ++ instr, temp)
genExpr (TEIdx t base idx) = do
  arr <- genArrayAddr (TEIdx t base idx)
  (fc, ea) <- finalizeArrayAddr arr
  resultTemp <- newtemp t
  let instr = gen (IDerefGet resultTemp ea)
  return (fc ++ instr, resultTemp)
genExpr (TEDeref t e1) = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IDerefGet temp a1)
  return (c1 ++ instr, temp)
genExpr (TEAddr t e1) = genLValueAddr t e1
genExpr e@(TEAnd _ _ _) = genBoolValue e
genExpr e@(TEOr  _ _ _) = genBoolValue e
genExpr (TEEq  _ e1 e2) = genRel STBool (relOpFor KEq  (typeOf e1)) e1 e2
genExpr (TENeq _ e1 e2) = genRel STBool (relOpFor KNeq (typeOf e1)) e1 e2
genExpr (TELt  _ e1 e2) = genRel STBool (relOpFor KLt  (typeOf e1)) e1 e2
genExpr (TELe  _ e1 e2) = genRel STBool (relOpFor KLe  (typeOf e1)) e1 e2
genExpr (TEGt  _ e1 e2) = genRel STBool (relOpFor KGt  (typeOf e1)) e1 e2
genExpr (TEGe  _ e1 e2) = genRel STBool (relOpFor KGe  (typeOf e1)) e1 e2
genExpr (TECall t name args) = do
  ctx <- ask
  (argsCode, argAddrs) <- genCallArgs args
  let paramInstrs = concatMap (gen . IParam) argAddrs
  resultTemp <- newtemp t
  let pos = Map.findWithDefault Nothing name (ctxFunPos ctx)
      callInstr = gen (IFCall resultTemp name pos (length args))
  return (argsCode ++ paramInstrs ++ callInstr, resultTemp)
genExpr (TEIf t cond e1 e2) = do
  trueLbl  <- newlabel
  falseLbl <- newlabel
  endLbl   <- newlabel
  condCode <- genCond cond trueLbl falseLbl
  resTemp <- newtemp t
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  return (condCode
          ++ label trueLbl  (c1 ++ gen (ICopy resTemp a1) ++ gen (IGoto endLbl))
          ++ label falseLbl (c2 ++ gen (ICopy resTemp a2) ++ gen (IGoto endLbl))
          ++ [Lbl endLbl], resTemp)
genExpr (TEArr {}) =
  error "genExpr: un letterale array non deve mai passare da genExpr (va sempre scritto direttamente con genArrLitStore)"

-- Operazione aritmetica binaria (+ - * /)
genArith :: SemType -> BinOp -> TExp -> TExp -> TacM (Code, Address)
genArith t op e1 e2 = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  temp <- newtemp t
  let instr = gen (IBinAssign temp op a1 a2)
  return (c1 ++ c2 ++ instr, temp)

-- Operazione unaria generica (neg, not): valuta l'operando, applica l'operatore in un nuovo temp
genUnary :: SemType -> UnOp -> TExp -> TacM (Code, Address)
genUnary t op e1 = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp op a1)
  return (c1 ++ instr, temp)

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

-- Genera il valore di un'espressione booleana con corto circuito
genBoolValue :: TExp -> TacM (Code, Address)
genBoolValue e = do
  temp <- newtemp STBool
  trueLbl <- newlabel
  falseLbl <- newlabel
  endLbl <- newlabel
  condCode <- genCond e trueLbl falseLbl
  return (condCode
          ++ label trueLbl  (gen (ICopy temp (AddrLit (LBool True) STBool))  ++ gen (IGoto endLbl))
          ++ label falseLbl (gen (ICopy temp (AddrLit (LBool False) STBool)))
          ++ [Lbl endLbl], temp)

-- Indirizzo di un elemento di array, non ancora messo in byte
data ArrayAddr = ArrayAddr
  { arrCode     :: Code
  , arrBaseAddr :: Address
  , arrOffset   :: Address
  , arrElemTy   :: SemType
  }

-- Indirizzo di a[i] (o a[i][j]...), incluso il caso in cui la base sia raggiunta tramite dereferenziazione di un puntatore, (*p)[i]
genArrayAddr :: TExp -> TacM ArrayAddr
genArrayAddr (TEIdx _ base idxExpr) = do
  (idxCode, idxAddr) <- genExpr idxExpr
  case base of
    TEVar {} -> do
      let (STArr lo _ elemTy) = typeOf base
      (bc, baseAddr) <- genLValueAddr (STPtr elemTy) base
      normT <- newtemp STInt
      let subI = gen (IBinAssign normT IntSub idxAddr (AddrLit (LInt lo) STInt))
      return (ArrayAddr (bc ++ idxCode ++ subI) baseAddr normT elemTy)
    TEIdx {} -> do
      inner <- genArrayAddr base
      let (STArr lo hi elemTy) = arrElemTy inner
          dimCount = hi - lo + 1
      normT <- newtemp STInt
      let subI = gen (IBinAssign normT IntSub idxAddr (AddrLit (LInt lo) STInt))
      mulT <- newtemp STInt
      let mulI = gen (IBinAssign mulT IntMul (arrOffset inner) (AddrLit (LInt dimCount) STInt))
      combT <- newtemp STInt
      let addI = gen (IBinAssign combT IntAdd mulT normT)
      return (ArrayAddr (arrCode inner ++ idxCode ++ subI ++ mulI ++ addI) (arrBaseAddr inner) combT elemTy)
    TEDeref derefTy ptrExpr -> do
      (pc, pa) <- genExpr ptrExpr
      let (STArr lo _ elemTy) = derefTy
      normT <- newtemp STInt
      let subI = gen (IBinAssign normT IntSub idxAddr (AddrLit (LInt lo) STInt))
      return (ArrayAddr (idxCode ++ pc ++ subI) pa normT elemTy)
    _ -> error "genArrayAddr: base indicizzabile inattesa (invariante garantita dal type checker)"
genArrayAddr _ = error "genArrayAddr: atteso un accesso a elemento di array (TEIdx)"

-- Chiude un ArrayAddr nell'indirizzo finale in byte
finalizeArrayAddr :: ArrayAddr -> TacM (Code, Address)
finalizeArrayAddr arr = do
  byteOff <- newtemp STInt
  let mulI = gen (IBinAssign byteOff IntMul (arrOffset arr) (AddrLit (LInt (sizeOf (arrElemTy arr))) STInt))
  elemAddr <- newtemp (STPtr (arrElemTy arr))
  let addI = gen (IAddrAdd elemAddr (arrBaseAddr arr) byteOff)
  return (arrCode arr ++ mulI ++ addI, elemAddr)

-- Indirizzo di una l-expression
genLValueAddr :: SemType -> TExp -> TacM (Code, Address)
genLValueAddr t (TEVar _ pos name intent) = do
  ctx <- ask
  let pointeeTy = case t of STPtr inner -> inner; _ -> t
  if intent == ByRef || Set.member name (ctxByValArrays ctx)
    then return ([], AddrVar name pos (STPtr pointeeTy))
    else do
      temp <- newtemp t
      let instr = gen (IAddrOf temp (AddrVar name pos pointeeTy))
      return (instr, temp)
genLValueAddr _ idxExpr@(TEIdx {}) = do
  arr <- genArrayAddr idxExpr
  finalizeArrayAddr arr
genLValueAddr _ (TEDeref _ e1) = genExpr e1
genLValueAddr _ _ = error "genLValueAddr: espressione non una l-expression (invariante garantita dal type checker)"

-- Appiattisce un tipo array nel numero totale di elementi scalari e nel loro tipo 
flattenArray :: SemType -> (Integer, SemType)
flattenArray (STArr lo hi t) = let (n, l) = flattenArray t in ((hi - lo + 1) * n, l)
flattenArray t = (1, t)

-- Copia un array elemento per elemento con un ciclo runtime 
genArrayCopyLoop :: Address -> Address -> SemType -> TacM Code
genArrayCopyLoop destBase srcBase arrTy = do
  let (count, leafTy) = flattenArray arrTy
  i <- newtemp STInt
  guardLbl <- newlabel
  bodyLbl  <- newlabel
  endLbl   <- newlabel
  off   <- newtemp STInt
  srcA  <- newtemp (STPtr leafTy)
  destA <- newtemp (STPtr leafTy)
  tmp   <- newtemp leafTy
  let initI = gen (ICopy i (AddrLit (LInt 0) STInt))
      bodyCode = gen (IBinAssign off IntMul i (AddrLit (LInt (sizeOf leafTy)) STInt))
              ++ gen (IAddrAdd srcA srcBase off)
              ++ gen (IAddrAdd destA destBase off)
              ++ gen (IDerefGet tmp srcA)
              ++ gen (IDerefSet destA tmp)
              ++ gen (IBinAssign i IntAdd i (AddrLit (LInt 1) STInt))
      guardCode = gen (IIfRel i IntLt (AddrLit (LInt count) STInt) bodyLbl) ++ gen (IGoto endLbl)
  return (initI ++ gen (IGoto guardLbl)
          ++ label bodyLbl bodyCode
          ++ label guardLbl guardCode
          ++ [Lbl endLbl])

-- Scrive un letterale array in un indirizzo di base già noto, elemento per elemento
genArrLitStore :: Address -> SemType -> [TExp] -> TacM Code
genArrLitStore base (STArr _ _ elemTy) elems = concat <$> mapM store (zip [0 ..] elems)
  where
    store (i, e) = do
      elemAddr <- newtemp (STPtr elemTy)
      let addI = gen (IAddrAdd elemAddr base (AddrLit (LInt (i * sizeOf elemTy)) STInt))
      case (elemTy, e) of
        (STArr {}, TEArr _ sub) -> do
          subCode <- genArrLitStore elemAddr elemTy sub
          return (addI ++ subCode)
        _ -> do
          (c, a) <- genExpr e
          return (addI ++ c ++ gen (IDerefSet elemAddr a))
genArrLitStore _ _ _ = error "genArrLitStore: tipo non-array (invariante garantita dal type checker)"

-- salta direttamente a trueLbl/falseLbl invece di calcolare un valore
-- And/Or realizzano lo short-circuit. I confronti vanno a genCondRel. Il caso generico valuta l'espressione e salta in base al suo valore
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

genCond (TEEq  _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KEq  (typeOf e1)) e1 e2 trueLbl falseLbl
genCond (TENeq _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KNeq (typeOf e1)) e1 e2 trueLbl falseLbl
genCond (TELt  _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KLt  (typeOf e1)) e1 e2 trueLbl falseLbl
genCond (TELe  _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KLe  (typeOf e1)) e1 e2 trueLbl falseLbl
genCond (TEGt  _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KGt  (typeOf e1)) e1 e2 trueLbl falseLbl
genCond (TEGe  _ e1 e2) trueLbl falseLbl = genCondRel (relOpFor KGe  (typeOf e1)) e1 e2 trueLbl falseLbl

genCond e trueLbl falseLbl = do
  (c, a) <- genExpr e
  return (c ++ gen (IIfTrue a trueLbl) ++ gen (IGoto falseLbl))

-- Genera il codice per un confronto usato come condizione
genCondRel :: RelOp -> TExp -> TExp -> String -> String -> TacM Code
genCondRel op e1 e2 trueLbl falseLbl = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  return (c1 ++ c2 ++ gen (IIfRel a1 op a2 trueLbl) ++ gen (IGoto falseLbl))

-- Genera un'istruzione, più il codice di eventuali funzioni annidate
genStmt :: TStmt -> TacM (Code, [FuncCode])
genStmt (TSAssign lhs rhs)
  | isArrayType (typeOf lhs) = do
      (lc, dest) <- genLValueAddr (STPtr (typeOf lhs)) lhs
      case rhs of
        TEArr _ elems -> do
          storeCode <- genArrLitStore dest (typeOf lhs) elems
          return (lc ++ storeCode, [])
        _ -> do
          (rc, src) <- genLValueAddr (STPtr (typeOf rhs)) rhs
          copyCode <- genArrayCopyLoop dest src (typeOf lhs)
          return (lc ++ rc ++ copyCode, [])
  | otherwise = case lhs of
      TEVar _ pos name intent -> do
        (rc, ra) <- genExpr rhs
        let instr
              | intent == ByRef = gen (IDerefSet (AddrVar name pos (STPtr (typeOf lhs))) ra)
              | otherwise       = gen (ICopy (AddrVar name pos (typeOf lhs)) ra)
        return (rc ++ instr, [])
      TEIdx {} -> do
        arr <- genArrayAddr lhs
        (fc, ea) <- finalizeArrayAddr arr
        (rc, ra) <- genExpr rhs
        let instr = gen (IDerefSet ea ra)
        return (fc ++ rc ++ instr, [])
      TEDeref _ ptrExpr -> do
        (pc, pa) <- genExpr ptrExpr
        (rc, ra) <- genExpr rhs
        let instr = gen (IDerefSet pa ra)
        return (pc ++ rc ++ instr, [])
      _ -> error "genStmt: assegnamento a una l-expression inattesa (invariante garantita dal type checker)"

genStmt (TSCall name args) = do
  ctx <- ask
  (argsCode, argAddrs) <- genCallArgs args
  let paramInstrs = concatMap (gen . IParam) argAddrs
      pos = Map.findWithDefault Nothing name (ctxFunPos ctx)
      callInstr = gen (IPCall name pos (length args))
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
  (bodyCode, bodyFuncs) <- withLoop guardLbl falseLbl (genBlock blk)
  return (gen (IGoto guardLbl)
          ++ label trueLbl bodyCode
          ++ label guardLbl condCode
          ++ [Lbl falseLbl],
          bodyFuncs)

-- do-while
genStmt (TSDoWhile blk cond) = do
  bodyLbl <- newlabel
  condLbl <- newlabel
  endLbl  <- newlabel
  (bodyCode, bodyFuncs) <- withLoop condLbl endLbl (genBlock blk)
  condCode <- genCond cond bodyLbl endLbl
  return ([Lbl bodyLbl] ++ bodyCode ++ [Lbl condLbl] ++ condCode ++ [Lbl endLbl], bodyFuncs)

-- for
genStmt (TSFor name pos loE hiE blk) = do
  (lc, loA) <- genExpr loE
  (hc, hiA) <- genExpr hiE
  let i = AddrVar name pos STInt
  bodyLbl  <- newlabel
  contLbl  <- newlabel
  guardLbl <- newlabel
  endLbl   <- newlabel
  (bodyCode, bodyFuncs) <- withLoop contLbl endLbl (genBlock blk)
  let initI  = gen (ICopy i loA)
      incrI  = gen (IBinAssign i IntAdd i (AddrLit (LInt 1) STInt))
      guardI = gen (IIfRel i IntLe hiA bodyLbl) ++ gen (IGoto endLbl)
  return (lc ++ hc ++ initI ++ gen (IGoto guardLbl)
          ++ label bodyLbl bodyCode
          ++ label contLbl incrI
          ++ label guardLbl guardI
          ++ [Lbl endLbl],
          bodyFuncs)

genStmt TSBreak = do
  ctx <- ask
  case ctxLoop ctx of
    Just (_, brk) -> return (gen (IGoto brk), [])
    Nothing       -> error "genStmt: break fuori da un ciclo (invariante garantita dal type checker)"

genStmt TSContinue = do
  ctx <- ask
  case ctxLoop ctx of
    Just (cont, _) -> return (gen (IGoto cont), [])
    Nothing        -> error "genStmt: continue fuori da un ciclo (invariante garantita dal type checker)"

-- op=
genStmt (TSOpAssign lhs aop rhs) = case lhs of
  TEVar _ pos name intent -> do
    let ty = typeOf lhs
    (curCode, curVal) <-
      if intent == ByRef
        then do
          t <- newtemp ty
          return (gen (IDerefGet t (AddrVar name pos (STPtr ty))), t)
        else return ([], AddrVar name pos ty)
    (rc, ra) <- genExpr rhs
    resTemp <- newtemp ty
    let opInstr = gen (IBinAssign resTemp (arithOpFor (opKindOf aop) ty) curVal ra)
        writeInstr
          | intent == ByRef = gen (IDerefSet (AddrVar name pos (STPtr ty)) resTemp)
          | otherwise       = gen (ICopy (AddrVar name pos ty) resTemp)
    return (curCode ++ rc ++ opInstr ++ writeInstr, [])
  TEIdx {} -> do
    let ty = typeOf lhs
    arr <- genArrayAddr lhs
    (fc, ea) <- finalizeArrayAddr arr
    curVal <- newtemp ty
    let readInstr = gen (IDerefGet curVal ea)
    (rc, ra) <- genExpr rhs
    resTemp <- newtemp ty
    let opInstr = gen (IBinAssign resTemp (arithOpFor (opKindOf aop) ty) curVal ra)
        writeInstr = gen (IDerefSet ea resTemp)
    return (fc ++ readInstr ++ rc ++ opInstr ++ writeInstr, [])
  TEDeref _ ptrExpr -> do
    let ty = typeOf lhs
    (pc, pa) <- genExpr ptrExpr
    curVal <- newtemp ty
    let readInstr = gen (IDerefGet curVal pa)
    (rc, ra) <- genExpr rhs
    resTemp <- newtemp ty
    let opInstr = gen (IBinAssign resTemp (arithOpFor (opKindOf aop) ty) curVal ra)
        writeInstr = gen (IDerefSet pa resTemp)
    return (pc ++ readInstr ++ rc ++ opInstr ++ writeInstr, [])
  _ -> error "genStmt: op= su una l-expression inattesa (invariante garantita dal type checker)"

-- Un blocco "{ ... }": delega a genStmtList
genBlock :: TBlock -> TacM (Code, [FuncCode])
genBlock (TBlock stmts) = genStmtList stmts

-- Una sequenza di istruzioni: concatena codice e funzioni annidate di ciascuna
genStmtList :: [TStmt] -> TacM (Code, [FuncCode])
genStmtList [] = return ([], [])
genStmtList (s:ss) = do
  (c1, f1) <- genStmt s
  (c2, f2) <- genStmtList ss
  return (c1 ++ c2, f1 ++ f2)

-- Genera tutti gli argomenti di una chiamata con i loro indirizzi finali
genCallArgs :: [(ParamIntent, TExp)] -> TacM (Code, [Address])
genCallArgs [] = return ([], [])
genCallArgs ((intent, te):rest) = do
  (thisCode, thisAddr) <- genCallArg intent te
  (restCode, restAddrs) <- genCallArgs rest
  return (thisCode ++ restCode, thisAddr : restAddrs)

-- Per riferimento genera sempre l'indirizzo, così la funzione chiamata legge/scrive la
-- variabile del chiamante. Per valore: uno scalare genera direttamente il suo valore; un
-- array invece va copiato, perché nel chiamato l'array per valore è comunque rappresentato da un indirizzo 
genCallArg :: ParamIntent -> TExp -> TacM (Code, Address)
genCallArg ByRef te = genLValueAddr (STPtr (typeOf te)) te
genCallArg ByValue te
  | isArrayType ty = do
      (sc, srcAddr) <- genLValueAddr (STPtr ty) te
      synthName <- newSynthVarName
      destAddr <- newtemp (STPtr ty)
      let addrI = gen (IAddrOf destAddr (AddrVar synthName Nothing ty))
      copyCode <- genArrayCopyLoop destAddr srcAddr ty
      return (sc ++ addrI ++ copyCode, destAddr)
  | otherwise = genExpr te
  where ty = typeOf te

-- Variabile senza init
genTopDecl :: TTopDecl -> TacM (Code, [FuncCode])
genTopDecl (TDVar _ _ _) = return ([], [])

genTopDecl (TDVarInit name ty pos initExpr)
  | isArrayType ty = case initExpr of
      TEArr _ elems -> do
        baseAddr <- newtemp (STPtr ty)
        let addrI = gen (IAddrOf baseAddr (AddrVar name pos ty))
        storeCode <- genArrLitStore baseAddr ty elems
        return (addrI ++ storeCode, [])
      _ -> error "genTopDecl: un array deve essere inizializzato con un letterale (invariante garantita dal type checker, R18)"
  | otherwise = do
      (c, a) <- genExpr initExpr
      let instr = gen (ICopy (AddrVar name pos ty) a)
      return (c ++ instr, [])

genTopDecl (TDProc name params retTy _ body) = do
  let arrValParams = Set.fromList
        [ tparName p | p <- params, tparIntent p == ByValue, isArrayType (tparType p) ]
  (bodyCode, nestedFuncs) <-
    local (\c -> c { ctxLoop = Nothing, ctxByValArrays = arrValParams }) (genBlock body)
  let bodyCode' = if retTy == STVoid then bodyCode ++ gen IReturn else bodyCode
  return ([], (name, bodyCode') : nestedFuncs)

-- Punto di ingresso
genProgram :: TProgram -> (Code, [FuncCode], [StaticString])
genProgram prog@(TProgram topDecls) =
  let ctx = initGenCtx { ctxFunPos = collectFunPositions prog }
      ((code, funcs), finalSt) = runTacM ctx (genTopDeclList topDecls)
  in (code, funcs, [ StaticString lbl s | (lbl, s) <- strTable finalSt ])

-- Tutte le dichiarazioni globali, una dopo l'altra
genTopDeclList :: [TTopDecl] -> TacM (Code, [FuncCode])
genTopDeclList [] = return ([], [])
genTopDeclList (d:ds) = do
  (c1, f1) <- genTopDecl d
  (c2, f2) <- genTopDeclList ds
  return (c1 ++ c2, f1 ++ f2)

-- Costruisce la mappa nome-funzione -> riga di dichiarazione, scandendo ricorsivamente anche i
-- corpi (le funzioni annidate non sono in questa lista di primo livello).
collectFunPositions :: TProgram -> Map.Map String (Maybe (Int, Int))
collectFunPositions (TProgram topDecls) = foldr collectTopDecl Map.empty topDecls

collectTopDecl :: TTopDecl -> Map.Map String (Maybe (Int, Int)) -> Map.Map String (Maybe (Int, Int))
collectTopDecl (TDVar _ _ _) m = m
collectTopDecl (TDVarInit _ _ _ _) m = m
collectTopDecl (TDProc name _ _ pos body) m = collectBlock body (Map.insert name pos m)

collectBlock :: TBlock -> Map.Map String (Maybe (Int, Int)) -> Map.Map String (Maybe (Int, Int))
collectBlock (TBlock stmts) m = foldr collectStmt m stmts

collectStmt :: TStmt -> Map.Map String (Maybe (Int, Int)) -> Map.Map String (Maybe (Int, Int))
collectStmt (TSDecl td) m = collectTopDecl td m
collectStmt (TSBlock b) m = collectBlock b m
collectStmt (TSIf _ b) m = collectBlock b m
collectStmt (TSIfElse _ b1 b2) m = collectBlock b2 (collectBlock b1 m)
collectStmt (TSWhile _ b) m = collectBlock b m
collectStmt (TSDoWhile b _) m = collectBlock b m
collectStmt (TSFor _ _ _ _ b) m = collectBlock b m
collectStmt _ m = m
