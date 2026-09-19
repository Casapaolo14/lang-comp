module TacGen where

import Control.Monad.Trans.State
import SemTypes
import Tac
import TypedAst
import Environment

-- Lo stato che il generatore si porta dietro durante tutta la
-- traduzione: quanti temporanei e quante etichette sono gia' stati
-- creati finora, per non ripetere mai lo stesso nome due volte.
data GenState = GenState
  { nextTemp :: Int,
    nextLabel :: Int
  }

-- Il "contenitore" dentro cui gira tutta la generazione di codice: una
-- computazione che, oltre al suo vero risultato, si porta dietro anche
-- lo stato (i due contatori) da un passo al successivo, senza bisogno
-- di nessuna variabile modificabile.
type TacM a = State GenState a

-- Il codice generato per una singola funzione: il suo nome, e la
-- sequenza di istruzioni del suo corpo.
type FuncCode = (String, Code)

-- Lo stato di partenza: nessun temporaneo e nessuna etichetta ancora
-- creati.
initGenState :: GenState
initGenState = GenState 0 0

-- Crea un nuovo temporaneo con il tipo indicato: legge il contatore
-- attuale, lo aggiorna incrementandolo di uno, e restituisce un
-- indirizzo temporaneo che usa il valore di prima dell'incremento.
newtemp :: SemType -> TacM Address
newtemp t = do
  st <- get
  put st {nextTemp = nextTemp st + 1}
  return (AddrTemp (nextTemp st) t)

-- Crea una nuova etichetta (es. "L3"), con lo stesso meccanismo di
-- newtemp ma su un contatore separato.
newlabel :: TacM String
newlabel = do
  st <- get
  put st {nextLabel = nextLabel st + 1}
  return ("L" ++ show (nextLabel st))

-- Avvia una computazione TacM partendo dallo stato iniziale e restituisce
-- solo il suo risultato finale, buttando via il conteggio residuo.
runTacM :: TacM a -> a
runTacM m = evalState m initGenState

-- Genera il codice per un'espressione, restituendo sia la sequenza di
-- istruzioni necessarie a calcolarla sia l'indirizzo in cui si trova il
-- suo risultato finale. I letterali e le variabili non generano nessuna
-- istruzione: il loro "risultato" e' semplicemente il loro stesso
-- indirizzo, gia' disponibile. Le operazioni binarie/unarie sono
-- delegate a genArith/genUnary. TECast genera prima il codice
-- dell'espressione da convertire, poi un nuovo temporaneo con
-- l'istruzione di conversione vera e propria. Un accesso a un elemento
-- di array calcola prima il suo indirizzo (genArrayAddr) e poi legge il
-- valore da li'. Una dereferenziazione genera il codice del puntatore e
-- poi legge il valore puntato. Una chiamata di funzione genera il
-- codice di tutti gli argomenti, li passa uno per uno con IParam, e
-- infine chiama la funzione salvando il risultato in un nuovo
-- temporaneo.
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

-- Genera un'operazione binaria: prima il codice del primo operando, poi
-- del secondo, poi l'istruzione che li combina in un nuovo temporaneo.
-- Usata sia per le operazioni aritmetiche sia per "&&"/"||" quando non
-- servono in una condizione con short-circuit (si veda genCond per
-- quel caso).
genArith :: SemType -> BinOp -> TExp -> TExp -> TacM (Code, Address)
genArith t op e1 e2 = do
  (c1, a1) <- genExpr e1
  (c2, a2) <- genExpr e2
  temp <- newtemp t
  let instr = gen (IBinAssign temp op a1 a2)
  return (c1 ++ c2 ++ instr, temp)

-- Genera un'operazione unaria (meno, negazione): il codice
-- dell'operando seguito dall'istruzione che applica l'operatore in un
-- nuovo temporaneo.
genUnary :: SemType -> UnOp -> TExp -> TacM (Code, Address)
genUnary t op e1 = do
  (c1, a1) <- genExpr e1
  temp <- newtemp t
  let instr = gen (IUnAssign temp op a1)
  return (c1 ++ instr, temp)

-- Genera un confronto (==, !=, <, <=, >, >=) usato come vero e proprio
-- valore (non come guardia di un if/while, quel caso passa da genCond):
-- il nostro set di istruzioni non ha un'operazione che calcoli
-- direttamente un booleano da un confronto, solo un salto condizionato
-- (IIfRel). Per ottenere comunque un valore si usa il trucco classico
-- del "materializzare" un booleano a partire dal jumping code: si salta
-- a un'etichetta se il confronto e' vero, altrimenti si prosegue dritti
-- mettendo "falso" nel temporaneo e saltando alla fine; l'etichetta di
-- salto invece mette "vero" nello stesso temporaneo.
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

-- Il risultato di aver calcolato l'indirizzo di un elemento di array:
-- il codice generato per arrivarci, il nome della variabile array di
-- base (con la sua posizione di dichiarazione, per il pretty-print),
-- l'offset finale gia' calcolato, e il tipo degli elementi.
data ArrayAddr = ArrayAddr
  { arrCode :: Code,
    arrBase :: String,
    arrPos :: Maybe (Int, Int),
    arrOffset :: Address,
    arrElemTy :: SemType
  }

-- Calcola l'indirizzo di un elemento di array (a[i], oppure a[i][j] per
-- un array a piu' dimensioni), normalizzando l'indice rispetto
-- all'estremo minimo dichiarato dell'array (cosi' un array dichiarato
-- come [5..10] usa comunque un offset che parte da 0). Nel caso di piu'
-- dimensioni, l'offset del livello piu' esterno si combina con quello
-- del livello interno moltiplicandolo per la dimensione di una "riga"
-- e sommando il nuovo indice, seguendo lo schema "per righe" gia'
-- deciso allo step 7. L'ultimo caso e' una limitazione nota, documentata
-- nella relazione: non e' supportato indicizzare un array ottenuto
-- dereferenziando un puntatore.
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

-- Calcola l'indirizzo di una qualsiasi l-expression (qualcosa con un
-- vero posto in memoria): per una variabile semplice basta
-- un'istruzione IAddrOf; per un elemento di array si riusa
-- genArrayAddr e si prende il suo indirizzo con IIndexAddr; per il
-- contenuto puntato da un puntatore, l'indirizzo e' semplicemente il
-- valore del puntatore stesso, senza bisogno di nessuna istruzione in
-- piu' (per questo si richiama direttamente genExpr).
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

-- Genera il "jumping code" per una condizione booleana usata in un
-- if/while: invece di calcolare un vero valore vero/falso, genera
-- direttamente il codice che salta a trueLbl se la condizione e' vera o
-- a falseLbl se e' falsa. I casi TEAnd/TEOr implementano lo
-- short-circuit richiesto: per "e1 && e2", se e1 e' gia' falsa si salta
-- subito a falseLbl senza nemmeno generare il codice di e2; solo se e1
-- e' vera si passa a un'etichetta intermedia da cui si valuta e2. I
-- confronti (TEEq, TELt, ...) sono delegati a genCondRel. Il caso
-- generico (un'espressione booleana qualsiasi, es. una chiamata di
-- funzione che restituisce bool) calcola il suo valore con genExpr e
-- genera un salto condizionato esplicito.
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

-- Genera il codice per una singola istruzione, restituendo sia la
-- sequenza di istruzioni sia il codice di eventuali funzioni annidate
-- incontrate lungo la strada (tenuto separato, per non mischiarlo con
-- il codice del blocco che le contiene). Per un assegnamento, il tipo
-- del lato sinistro decide quale istruzione generare: una variabile usa
-- una semplice copia, un elemento di array calcola prima il proprio
-- indirizzo e poi scrive li' (rispettando l'ordine l-value-prima-di-
-- r-value), un puntatore dereferenziato genera il codice del puntatore
-- e poi scrive nel suo contenuto. Una chiamata come istruzione genera
-- gli argomenti, li passa, e chiama la funzione scartando il risultato.
-- if/if-else/while sono tradotti secondo gli schemi decisi allo step 7:
-- notare in particolare TSWhile, lo schema pensato appositamente per
-- questo progetto (salta subito alla condizione, esegue il corpo, poi
-- valuta la condizione alla fine per decidere se ripetere).
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

-- Genera il codice per un intero blocco "{ ... }": delega tutto a
-- genStmtList sulla lista di istruzioni al suo interno.
genBlock :: TBlock -> TacM (Code, [FuncCode])
genBlock (TBlock stmts) = genStmtList stmts

-- Genera il codice per una sequenza di istruzioni, una dopo l'altra,
-- concatenando sia le istruzioni sia il codice delle eventuali funzioni
-- annidate incontrate.
genStmtList :: [TStmt] -> TacM (Code, [FuncCode])
genStmtList [] = return ([], [])
genStmtList (s:ss) = do
  (c1, f1) <- genStmt s
  (c2, f2) <- genStmtList ss
  return (c1 ++ c2, f1 ++ f2)

-- Genera il codice per tutti gli argomenti di una chiamata di funzione,
-- uno dopo l'altro, restituendo sia le istruzioni sia l'indirizzo finale
-- di ciascun argomento (nell'ordine giusto per generare poi le
-- istruzioni IParam).
genCallArgs :: [(ParamIntent, TExp)] -> TacM (Code, [Address])
genCallArgs [] = return ([], [])
genCallArgs ((intent, te):rest) = do
  (thisCode, thisAddr) <- genCallArg intent te
  (restCode, restAddrs) <- genCallArgs rest
  return (thisCode ++ restCode, thisAddr : restAddrs)

-- Genera il codice per un singolo argomento, in base a come deve essere
-- passato: per valore si genera il suo vero valore (una copia); per
-- riferimento si genera invece il suo indirizzo, cosi' la funzione
-- chiamata potra' leggere e modificare direttamente la variabile del
-- chiamante.
genCallArg :: ParamIntent -> TExp -> TacM (Code, Address)
genCallArg ByValue te = genExpr te
genCallArg ByRef   te = genLValueAddr (STPtr (typeOf te)) te

-- Genera il codice per una dichiarazione. Una variabile senza valore
-- iniziale non genera nulla (il suo contenuto restera' quello che gia'
-- si trova in memoria, finche' non viene assegnata esplicitamente). Una
-- variabile con valore iniziale genera il codice dell'espressione
-- seguito da una copia nella variabile. Una funzione genera il codice
-- del proprio corpo separatamente (non incluso nel codice del
-- chiamante, cosi' resta un pezzo a se' stante), insieme al codice di
-- eventuali funzioni annidate al suo interno.
genTopDecl :: TTopDecl -> TacM (Code, [FuncCode])
genTopDecl (TDVar _ _ _) = return ([], [])

genTopDecl (TDVarInit name ty pos initExpr) = do
  (c, a) <- genExpr initExpr
  let instr = gen (ICopy (AddrVar name pos ty) a)
  return (c ++ instr, [])

genTopDecl (TDProc name _ _ _ body) = do
  (bodyCode, nestedFuncs) <- genBlock body
  return ([], (name, bodyCode) : nestedFuncs)

-- Punto di ingresso della generazione: prende l'intero programma
-- tipizzato e restituisce il codice delle dichiarazioni globali insieme
-- alla lista del codice di ciascuna funzione, avviando la computazione
-- con runTacM (che parte dai contatori azzerati).
genProgram :: TProgram -> (Code, [FuncCode])
genProgram (TProgram topDecls) = runTacM (genTopDeclList topDecls)

-- Genera il codice per tutte le dichiarazioni globali di un programma,
-- una dopo l'altra, concatenando sia il codice sia le liste di funzioni
-- trovate.
genTopDeclList :: [TTopDecl] -> TacM (Code, [FuncCode])
genTopDeclList [] = return ([], [])
genTopDeclList (d:ds) = do
  (c1, f1) <- genTopDecl d
  (c2, f2) <- genTopDeclList ds
  return (c1 ++ c2, f1 ++ f2)
