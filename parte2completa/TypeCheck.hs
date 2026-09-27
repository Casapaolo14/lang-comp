module TypeCheck where

import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified AbsLinguaggio as Abs
import SemTypes
import Environment
import TypedAst
import TypeErrors

-- Type-check espressione: I letterali hanno tipo fisso e nessun errore; le variabili recuperano tipo ed intent
-- dalla rubrica o restituiscono STError; tutti gli altri casi sono delegati alle funzioni ausiliarie per famiglia di operatori
checkExp :: Env -> Abs.Exp -> (TExp, [TypeError])
checkExp _ (Abs.EInt _ n)   = (TEInt STInt n, [])
checkExp _ (Abs.EReal _ d)  = (TEReal STReal d, [])
checkExp _ (Abs.EChar _ c)  = (TEChar STChar c, [])
checkExp _ (Abs.EStr _ s)   = (TEStr STStr s, [])
checkExp _ (Abs.ETrue _)    = (TETrue STBool, [])
checkExp _ (Abs.EFalse _)   = (TEFalse STBool, [])
checkExp env (Abs.EVar pos (Abs.Ident name)) =
  case Map.lookup name (envVars env) of
    Just vi -> (TEVar (viType vi) (viDeclPos vi) name (viIntent vi), [])
    Nothing -> (TEVar STError Nothing name ByValue,
                [mkError pos ("variabile non dichiarata: " ++ name)])
checkExp env (Abs.EAdd pos e1 e2) = checkArith pos env e1 e2 TEAdd
checkExp env (Abs.ESub pos e1 e2) = checkArith pos env e1 e2 TESub
checkExp env (Abs.EMul pos e1 e2) = checkArith pos env e1 e2 TEMul
checkExp env (Abs.EDiv pos e1 e2) = checkArith pos env e1 e2 TEDiv
checkExp env (Abs.EOr  pos e1 e2) = checkBoolOp pos env e1 e2 TEOr
checkExp env (Abs.EAnd pos e1 e2) = checkBoolOp pos env e1 e2 TEAnd
checkExp env (Abs.EEq  pos e1 e2) = checkRel pos env e1 e2 eqOp  TEEq
checkExp env (Abs.ENeq pos e1 e2) = checkRel pos env e1 e2 eqOp  TENeq
checkExp env (Abs.ELt  pos e1 e2) = checkRel pos env e1 e2 ordOp TELt
checkExp env (Abs.ELe  pos e1 e2) = checkRel pos env e1 e2 ordOp TELe
checkExp env (Abs.EGt  pos e1 e2) = checkRel pos env e1 e2 ordOp TEGt
checkExp env (Abs.EGe  pos e1 e2) = checkRel pos env e1 e2 ordOp TEGe
checkExp env (Abs.ENeg pos e1) = checkUnaryMath pos env e1 TENeg
checkExp env (Abs.ENot pos e1) = checkUnaryBool pos env e1 TENot
checkExp env (Abs.EDeref pos e1) = checkDeref pos env e1
checkExp env (Abs.EAddr pos e1) = checkAddr pos env e1
checkExp env (Abs.EIdx pos e1 e2) = checkIdx pos env e1 e2
checkExp env (Abs.ECall pos (Abs.Ident name) args) = checkCall pos env name args
checkExp env (Abs.EIf pos cond e1 e2) = checkIfExp pos env cond e1 e2
checkExp _ (Abs.EArr pos _) =
  (TEArr STError [],
   [mkError pos "letterale array non ammesso in questo contesto (solo come inizializzatore di un array o come lato destro di un assegnamento ad array)"])

-- Operazione aritmetica binaria (+ - * /)
checkArith :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp
           -> (SemType -> TExp -> TExp -> TExp) -> (TExp, [TypeError])
checkArith pos env e1 e2 mkNode =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1           = typeOf te1
      t2           = typeOf te2
      resultType   = mathtype (sup t1 t2)
      te1'         = insertCast resultType te1
      te2'         = insertCast resultType te2
      errs3
        | resultType /= STError          = []
        | t1 == STError || t2 == STError = []
        | otherwise = [mkError pos ("operandi non numerici nell'operazione aritmetica: "
                                     ++ showType t1 ++ " e " ++ showType t2)]
  in (mkNode resultType te1' te2', errs1 ++ errs2 ++ errs3)

-- Avvolge in TECast solo se il tipo non è già quello richiesto altrimenti restituisce l'espressione invariata
insertCast :: SemType -> TExp -> TExp
insertCast target texp
  | typeOf texp == target = texp
  | otherwise             = TECast target texp

-- Operazione booleana binaria (&&/||)
checkBoolOp :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp
            -> (SemType -> TExp -> TExp -> TExp) -> (TExp, [TypeError])
checkBoolOp pos env e1 e2 mkNode =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1 = typeOf te1
      t2 = typeOf te2
      (resultType, errs3)
        | t1 == STError || t2 == STError = (STError, [])
        | t1 == STBool && t2 == STBool   = (STBool, [])
        | otherwise = (STError, [mkError pos ("gli operandi di || e && devono essere entrambi bool: ricevuti "
                                               ++ showType t1 ++ " e " ++ showType t2)])
  in (mkNode resultType te1 te2, errs1 ++ errs2 ++ errs3)

-- Confronto (==, !=, <, <=, >, >=, R1)
checkRel :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp
         -> (SemType -> SemType -> SemType)
         -> (SemType -> TExp -> TExp -> TExp) -> (TExp, [TypeError])
checkRel pos env e1 e2 admit mkNode =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1         = typeOf te1
      t2         = typeOf te2
      castType   = sup t1 t2
      resultType = admit t1 t2
      te1'       = insertCast castType te1
      te2'       = insertCast castType te2
      errs3
        | resultType /= STError          = []
        | t1 == STError || t2 == STError = []
        | otherwise = [mkError pos ("operandi di tipo incompatibile nel confronto: "
                                     ++ showType t1 ++ " e " ++ showType t2)]
  in (mkNode resultType te1' te2', errs1 ++ errs2 ++ errs3)

-- Controlla un operatore matematico unario (il meno, "-x")
checkUnaryMath :: Maybe (Int, Int) -> Env -> Abs.Exp
               -> (SemType -> TExp -> TExp) -> (TExp, [TypeError])
checkUnaryMath pos env e1 mkNode =
  let (te1, errs1) = checkExp env e1
      t1           = typeOf te1
      resultType   = mathtype t1
      errs2
        | resultType /= STError = []
        | t1 == STError         = []
        | otherwise = [mkError pos ("operando non numerico per l'operatore unario: " ++ showType t1)]
  in (mkNode resultType te1, errs1 ++ errs2)

-- Controlla la negazione booleana ("!x")
checkUnaryBool :: Maybe (Int, Int) -> Env -> Abs.Exp
               -> (SemType -> TExp -> TExp) -> (TExp, [TypeError])
checkUnaryBool pos env e1 mkNode =
  let (te1, errs1) = checkExp env e1
      t1           = typeOf te1
      (resultType, errs2)
        | t1 == STError = (STError, [])
        | t1 == STBool  = (STBool, [])
        | otherwise = (STError, [mkError pos ("l'operando di ! deve essere bool, non " ++ showType t1)])
  in (mkNode resultType te1, errs1 ++ errs2)

-- Controlla la dereferenziazione di un puntatore ("*p")
checkDeref :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkDeref pos env e1 =
  let (te1, errs1) = checkExp env e1
      t1            = typeOf te1
      (resultType, errs2) = case t1 of
        STPtr inner -> (inner, [])
        STError     -> (STError, [])
        _           -> (STError, [mkError pos ("dereferenziazione (*) applicata a un tipo che non è un puntatore: " ++ showType t1)])
  in (TEDeref resultType te1, errs1 ++ errs2)

-- Controlla la presa dell'indirizzo di qualcosa ("c_ptrTo(x)")
checkAddr :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkAddr pos env e1 =
  let (te1, errs1) = checkExp env e1
      t1            = typeOf te1
      (resultType, errs2)
        | t1 == STError = (STError, [])
        | otherwise = case checkMutableLExpr env e1 of
            Nothing  -> (STPtr t1, [])
            Just msg -> (STError, [mkError pos ("l'argomento di c_ptrTo " ++ msg)])
  in (TEAddr resultType te1, errs1 ++ errs2)

-- Restituisce Nothing se l'espressione è una l-expression modificabile altrimenti Just di un messaggio specifico del problema
checkMutableLExpr :: Env -> Abs.Exp -> Maybe String
checkMutableLExpr env (Abs.EVar _ (Abs.Ident name)) =
  case Map.lookup name (envVars env) of
    Just vi | not (viMutable vi) -> Just (name ++ " è la variabile di un ciclo for e non può essere modificata")
    _ -> Nothing
checkMutableLExpr env (Abs.EIdx _ e _) = checkMutableLExpr env e
checkMutableLExpr _   (Abs.EDeref _ _) = Nothing
checkMutableLExpr _   _                = Just "non è una l-expression modificabile (deve essere una variabile, un elemento di array o una dereferenziazione)"

-- Controlla un accesso a un elemento di array ("a[i]") l'indice deve essere di tipo int, e la base deve essere di tipo array
checkIdx :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp -> (TExp, [TypeError])
checkIdx pos env e1 e2 =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1 = typeOf te1
      t2 = typeOf te2
      errsIdx
        | t2 == STInt   = []
        | t2 == STError = []
        | otherwise = [mkError pos ("l'indice di un array deve essere di tipo int, non " ++ showType t2)]
      (resultType, errsBase) = case t1 of
        STArr _ _ inner -> (inner, [])
        STError         -> (STError, [])
        _               -> (STError, [mkError pos ("indicizzazione [] applicata a un tipo che non è un array: " ++ showType t1)])
  in (TEIdx resultType te1 te2, errs1 ++ errs2 ++ errsIdx ++ errsBase)

-- Controlla un argomento rispetto al parametro corrispondente
checkArg :: Maybe (Int, Int) -> Env -> String -> Int -> (ParamIntent, SemType) -> Abs.Exp -> (TExp, [TypeError])
checkArg pos env fname idx (intent, paramType) argExpr =
  let (te, errs1) = checkExp env argExpr
      t = typeOf te
  in case intent of
       ByValue ->
         let te'
               | t == STError        = te
               | assignableTo t paramType = insertCast paramType te
               | otherwise            = te
             errs2
               | t == STError               = []
               | assignableTo t paramType   = []
               | otherwise = [mkError pos ("tipo non compatibile per il parametro " ++ show idx
                                            ++ " di " ++ fname ++ ": atteso " ++ showType paramType
                                            ++ ", fornito " ++ showType t)]
         in (te', errs1 ++ errs2)
       ByRef ->
         let errs2
               | t == STError       = []
               | t /= paramType     = [mkError pos ("il parametro " ++ show idx ++ " di " ++ fname
                                                     ++ " (per riferimento) richiede tipo identico: atteso "
                                                     ++ showType paramType ++ ", fornito " ++ showType t)]
               | otherwise = case checkMutableLExpr env argExpr of
                   Just msg -> [mkError pos ("il parametro " ++ show idx ++ " di " ++ fname ++ " (per riferimento) " ++ msg)]
                   Nothing  -> []
         in (te, errs1 ++ errs2)

-- Controlla una chiamata di funzione: cerca il nome nella rubrica delle funzioni
checkCall :: Maybe (Int, Int) -> Env -> String -> [Abs.Exp] -> (TExp, [TypeError])
checkCall pos env name args =
  case Map.lookup name (envFuns env) of
    Nothing ->
      let checkedArgs = map (checkExp env) args
          argErrs      = concatMap snd checkedArgs
          pairedArgs   = [ (ByValue, te) | (te, _) <- checkedArgs ]
      in (TECall STError name pairedArgs,
          mkError pos ("funzione non dichiarata: " ++ name) : argErrs)
    Just fi ->
      let params  = fiParams fi
          nParams = length params
          nArgs   = length args
          lenErrs
            | nParams == nArgs = []
            | otherwise = [mkError pos ("numero di argomenti errato per " ++ name
                                         ++ ": attesi " ++ show nParams
                                         ++ ", forniti " ++ show nArgs)]
          matched      = zip3 [1 ..] params args
          checkedPairs = [ (fst p, checkArg pos env name idx p a) | (idx, p, a) <- matched ]
          extraArgs    = drop nParams args
          extraChecked = map (checkExp env) extraArgs
          allTe        = [ (intent, te) | (intent, (te, _)) <- checkedPairs ]
                         ++ [ (ByValue, te) | (te, _) <- extraChecked ]
          allErrs      = concatMap (snd . snd) checkedPairs ++ concatMap snd extraChecked
      in (TECall (fiReturn fi) name allTe, lenErrs ++ allErrs)

-- if-espressione
checkIfExp :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp -> Abs.Exp -> (TExp, [TypeError])
checkIfExp pos env cond e1 e2 =
  let (tcond, errsCond) = checkCondition pos env cond
      (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1 = typeOf te1
      t2 = typeOf te2
      supType = sup t1 t2
      (resultType, errs3)
        | t1 == STError || t2 == STError = (STError, [])
        | supType == STError = (STError, [mkError pos ("i due rami dell'if-espressione hanno tipi incompatibili: "
                                                          ++ showType t1 ++ " e " ++ showType t2)])
        | isArrayType supType = (STError, [mkError pos "il risultato di un'espressione if non può essere un array"])
        | otherwise = (supType, [])
      te1' = insertCast resultType te1
      te2' = insertCast resultType te2
  in (TEIf resultType tcond te1' te2', errsCond ++ errs1 ++ errs2 ++ errs3)

-- Letterale array: tipizzato rispetto al tipo array atteso "expected", noto dal contesto 
checkArrLit :: Maybe (Int, Int) -> Env -> SemType -> Abs.Exp -> (TExp, [TypeError])
checkArrLit pos env expected (Abs.EArr _ elems) = case expected of
  STArr lo hi elemTy ->
    let n = length elems
        nExpected = hi - lo + 1
        errsLen
          | n == 0 = [mkError pos "il letterale array non può essere vuoto"]
          | fromIntegral n == nExpected = []
          | otherwise = [mkError pos ("il letterale array ha " ++ show n
                                       ++ " elementi, attesi " ++ show nExpected)]
        checkedElems = map (checkArrElem pos env elemTy) elems
        telems = map fst checkedElems
        errsElems = concatMap snd checkedElems
    in (TEArr expected telems, errsLen ++ errsElems)
  _ -> (TEArr STError [], [mkError pos "letterale array usato dove non è atteso un tipo array"])
checkArrLit pos env _ other =
  let (te, errs) = checkExp env other
  in (te, errs ++ [mkError pos "un array richiede un inizializzatore che sia un letterale array, non un'altra espressione"])

-- Elemento di un letterale array rispetto al tipo elemento atteso.
checkArrElem :: Maybe (Int, Int) -> Env -> SemType -> Abs.Exp -> (TExp, [TypeError])
checkArrElem pos env elemTy@(STArr _ _ _) e@(Abs.EArr _ _) = checkArrLit pos env elemTy e
checkArrElem pos env (STArr _ _ _) e =
  let (te, _) = checkExp env e
  in (te, [mkError pos "un elemento di un array multidimensionale deve essere un letterale array annidato, non un'altra espressione"])
checkArrElem pos env elemTy e =
  let (te, errs1) = checkExp env e
      t = typeOf te
      (te', errs2)
        | t == STError             = (te, [])
        | assignableTo t elemTy    = (insertCast elemTy te, [])
        | otherwise = (te, [mkError pos ("elemento di tipo " ++ showType t
                                          ++ " non compatibile col tipo " ++ showType elemTy)])
  in (te', errs1 ++ errs2)

-- Assegnamento: controlla l-expression modificabile e compatibilità tipi; 
-- Chiamata: riusa checkCall scartando il ritorno; 
-- Controllo/Cicli (if, while, do-while, for): verificano la condizione (bool), controllano i blocchi ricorsivamente (checkBlock) e attivano il flag ciclo; 
-- Return: valida la compatibilità con il tipo restituito atteso o la conformità a void
checkStmt :: Env -> Abs.Stmt -> (TStmt, [TypeError])
checkStmt env (Abs.SAssign pos lhs rhs) =
  let (tlhs, errsL) = checkExp env lhs
      tL = typeOf tlhs
      (trhs, errsR) = case rhs of
        Abs.EArr _ _ | isArrayType tL -> checkArrLit pos env tL rhs
        Abs.EArr rpos _ -> (TEArr STError [], [mkError rpos "letterale array non ammesso qui: il lato sinistro non è un array"])
        _ -> checkExp env rhs
      tR = typeOf trhs
      errsLValue = case checkMutableLExpr env lhs of
        Just msg -> [mkError pos ("il lato sinistro dell'assegnamento " ++ msg)]
        Nothing  -> []
      (trhs', errsAssign)
        | tL == STError || tR == STError = (trhs, [])
        | assignableTo tR tL             = (insertCast tL trhs, [])
        | otherwise = (trhs, [mkError pos ("tipo del lato destro (" ++ showType tR
                                            ++ ") non assegnabile al lato sinistro (" ++ showType tL ++ ")")])
  in (TSAssign tlhs trhs', errsL ++ errsR ++ errsLValue ++ errsAssign)
checkStmt env (Abs.SCall pos (Abs.Ident name) args) =
  let (te, errs) = checkCall pos env name args
  in case te of
       TECall _ _ targs -> (TSCall name targs, errs)
       _                -> (TSCall name [], errs)
checkStmt env (Abs.SIf pos cond blk) =
  let (tcond, errsCond) = checkCondition pos env cond
      (tblk, errsBlk)   = checkBlock env blk
  in (TSIf tcond tblk, errsCond ++ errsBlk)
checkStmt env (Abs.SIfElse pos cond blk1 blk2) =
  let (tcond, errsCond) = checkCondition pos env cond
      (tblk1, errsBlk1) = checkBlock env blk1
      (tblk2, errsBlk2) = checkBlock env blk2
  in (TSIfElse tcond tblk1 tblk2, errsCond ++ errsBlk1 ++ errsBlk2)
checkStmt env (Abs.SWhile pos cond blk) =
  let (tcond, errsCond) = checkCondition pos env cond
      (tblk, errsBlk)   = checkBlock (env { envInLoop = True }) blk
  in (TSWhile tcond tblk, errsCond ++ errsBlk)
checkStmt env (Abs.SDoWhile pos blk cond) =
  let (tblk, errsBlk)   = checkBlock (env { envInLoop = True }) blk
      (tcond, errsCond) = checkCondition pos env cond
  in (TSDoWhile tblk tcond, errsBlk ++ errsCond)
checkStmt env (Abs.SFor pos (Abs.Ident name) elo ehi blk) =
  let (telo, errs1) = checkExp env elo
      (tehi, errs2) = checkExp env ehi
      errsBounds =
        [ mkError pos "l'estremo iniziale del for deve essere esattamente di tipo int"
        | typeOf telo /= STInt && typeOf telo /= STError ] ++
        [ mkError pos "l'estremo finale del for deve essere esattamente di tipo int"
        | typeOf tehi /= STInt && typeOf tehi /= STError ]
      loopVarInfo = VarInfo STInt pos False ByValue
      envFor = env { envVars = Map.insert name loopVarInfo (envVars env)
                   , envInLoop = True }
      (tblk, errsBlk) = checkBlockWith (Set.singleton name) envFor blk
  in (TSFor name pos telo tehi tblk, errs1 ++ errs2 ++ errsBounds ++ errsBlk)
checkStmt env (Abs.SBreak pos)
  | envInLoop env = (TSBreak, [])
  | otherwise     = (TSBreak, [mkError pos "break usato fuori da un ciclo"])
checkStmt env (Abs.SContinue pos)
  | envInLoop env = (TSContinue, [])
  | otherwise     = (TSContinue, [mkError pos "continue usato fuori da un ciclo"])
checkStmt env (Abs.SOpAssign pos lhs op rhs) =
  let (tlhs, errsL) = checkExp env lhs
      (trhs, errsR) = checkExp env rhs
      tL = typeOf tlhs
      tR = typeOf trhs
      errsMut = case checkMutableLExpr env lhs of
        Just msg -> [mkError pos ("il lato sinistro di op= " ++ msg)]
        Nothing  -> []
      supType = sup tL tR
      resultType = mathtype supType
      errsArith
        | resultType /= STError          = []
        | tL == STError || tR == STError = []
        | otherwise = [mkError pos ("operandi non numerici in op=: "
                                     ++ showType tL ++ " e " ++ showType tR)]
      errsResult
        | resultType == STError || tL == STError = []
        | resultType == tL = []
        | otherwise = [mkError pos ("il risultato dell'operazione (" ++ showType resultType
                                     ++ ") non coincide col tipo del lato sinistro ("
                                     ++ showType tL ++ ")")]
      trhs' = if tR == STInt && tL == STReal then insertCast STReal trhs else trhs
  in (TSOpAssign tlhs (fromSyntacticAssignOp op) trhs',
      errsL ++ errsR ++ errsMut ++ errsArith ++ errsResult)
checkStmt env (Abs.SBlock _ blk) =
  let (tblk, errs) = checkBlock env blk
  in (TSBlock tblk, errs)
checkStmt env (Abs.SReturn pos e) =
  let (te, errs1) = checkExp env e
      t = typeOf te
  in case Map.lookup "$return" (envVars env) of
       Nothing -> (TSReturn te, errs1 ++ [mkError pos "return fuori da una funzione"])
       Just vi ->
         let expected = viType vi
             (te', errs2)
               | t == STError || expected == STError = (te, [])
               | assignableTo t expected              = (insertCast expected te, [])
               | otherwise = (te, [mkError pos ("tipo del return (" ++ showType t
                                                 ++ ") non compatibile con il tipo di ritorno della funzione ("
                                                 ++ showType expected ++ ")")])
         in (TSReturn te', errs1 ++ errs2)
checkStmt env (Abs.SReturnV pos) =
  case Map.lookup "$return" (envVars env) of
    Nothing -> (TSReturnV, [mkError pos "return fuori da una funzione"])
    Just vi
      | viType vi == STVoid -> (TSReturnV, [])
      | otherwise -> (TSReturnV, [mkError pos ("questa funzione richiede un valore di ritorno di tipo "
                                                ++ showType (viType vi) ++ " (return con espressione)")])

-- Traduzione dell'operatore sintattico di un op= nella sua versione semantica.
fromSyntacticAssignOp :: Abs.AssignOp -> TAssignOp
fromSyntacticAssignOp (Abs.AAdd _) = TAAdd
fromSyntacticAssignOp (Abs.ASub _) = TASub
fromSyntacticAssignOp (Abs.AMul _) = TAMul

-- Controlla che un'espressione usata come condizione (di if/while/do-while) sia di tipo bool
checkCondition :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkCondition pos env cond =
  let (tcond, errs1) = checkExp env cond
      t = typeOf tcond
      errs2
        | t == STBool  = []
        | t == STError = []
        | otherwise = [mkError pos ("la condizione deve essere di tipo bool, non " ++ showType t)]
  in (tcond, errs1 ++ errs2)

-- Controlla un blocco "{ ... }": in pratica delega tutto a checkStmtList sulla lista di istruzioni al suo interno
checkBlock :: Env -> Abs.Block -> (TBlock, [TypeError])
checkBlock = checkBlockWith Set.empty

checkBlockWith :: Set.Set String -> Env -> Abs.Block -> (TBlock, [TypeError])
checkBlockWith seed env (Abs.BBlock _ stmts) =
  let (tstmts, errs) = checkStmtListWith seed env stmts
  in (TBlock tstmts, errs)

-- Controlla una sequenza di istruzioni. Prima preScanFunctions registra
-- tutte le funzioni del blocco, poi go scorre una istruzione alla volta
checkStmtList = checkStmtListWith Set.empty

checkStmtListWith :: Set.Set String -> Env -> [Abs.Stmt] -> ([TStmt], [TypeError])
checkStmtListWith seed env stmts =
  let (env1, preErrs)    = preScanFunctions seed env stmts
      (tstmts, bodyErrs) = go env1 seed stmts
  in (tstmts, preErrs ++ bodyErrs)
  where
    go _ _ [] = ([], [])
    go e localNames (s:ss) = case s of
      Abs.SDecl _ topDecl ->
        let (ttd, e', localNames', errs1) = checkTopDecl e localNames topDecl
            (trest, errs2)   = go e' localNames' ss
        in (TSDecl ttd : trest, errs1 ++ errs2)
      _ ->
        let (ts, errs1)    = checkStmt e s
            (trest, errs2) = go e localNames ss
        in (ts : trest, errs1 ++ errs2)

-- Pre-scansione: registra tutte le funzioni dichiarate nel blocco prima di controllare un
-- solo corpo, così la mutua ricorsione funziona
preScanFunctions :: Set.Set String -> Env -> [Abs.Stmt] -> (Env, [TypeError])
preScanFunctions reserved env stmts = go env Set.empty stmts
  where
    go e _ [] = (e, [])
    go e localFuns (Abs.SDecl ppos (Abs.DProc _ (Abs.Ident name) params retType _) : rest) =
      let errsDup
            | Set.member name localFuns = [mkError ppos ("funzione già dichiarata in questo blocco: " ++ name)]
            | otherwise = []
          errsReserved
            | Set.member name reserved = [mkError ppos ("il nome della funzione " ++ name ++ " è già utilizzato in questo ambito")]
            | otherwise = []
          paramInfos = [ (fromSyntacticIntent intent, fromSyntacticType ptype)
                        | Abs.Par _ intent _ ptype <- params ]
          fi = FunInfo paramInfos (fromSyntacticType retType)
          e'  = e { envFuns = Map.insert name fi (envFuns e) }
          localFuns' = Set.insert name localFuns
          (efinal, errsRest) = go e' localFuns' rest
      in (efinal, errsDup ++ errsReserved ++ errsRest)
    go e localFuns (_ : rest) = go e localFuns rest

-- Controlla una dichiarazione, restituisce anche il quaderno aggiornato per il resto del
-- blocco e l'insieme aggiornato dei nomi-variabile già introdotti in questo blocco.
checkTopDecl :: Env -> Set.Set String -> Abs.TopDecl -> (TTopDecl, Env, Set.Set String, [TypeError])
checkTopDecl env localNames (Abs.DVar pos (Abs.Ident name) ty) =
  let semTy = fromSyntacticType ty
      errsDup
        | Set.member name localNames = [mkError pos ("variabile già dichiarata in questo blocco: " ++ name)]
        | otherwise = []
      errsInit
        | isArrayType semTy = [mkError pos ("l'array " ++ name ++ " deve avere un inizializzatore che sia un letterale array")]
        | otherwise = []
      vi   = VarInfo semTy pos True ByValue
      env' = env { envVars = Map.insert name vi (envVars env) }
  in (TDVar name semTy pos, env', Set.insert name localNames, errsDup ++ errsInit)
checkTopDecl env localNames (Abs.DVarInit pos (Abs.Ident name) ty initExpr) =
  let semTy = fromSyntacticType ty
      errsDup
        | Set.member name localNames = [mkError pos ("variabile già dichiarata in questo blocco: " ++ name)]
        | otherwise = []
      (tinit, errsInit)
        | isArrayType semTy = case initExpr of
            Abs.EArr _ _ -> checkArrLit pos env semTy initExpr
            _ -> let (te, errs) = checkExp env initExpr
                 in (te, errs ++ [mkError pos ("l'array " ++ name ++ " deve avere un inizializzatore che sia un letterale array")])
        | otherwise =
            let (tinit0, errsI) = checkExp env initExpr
                tInitTy = typeOf tinit0
                (tinit0', errsAssign)
                  | tInitTy == STError || semTy == STError = (tinit0, [])
                  | assignableTo tInitTy semTy              = (insertCast semTy tinit0, [])
                  | otherwise = (tinit0, [mkError pos ("tipo dell'inizializzatore (" ++ showType tInitTy
                                                        ++ ") non assegnabile alla variabile dichiarata (" ++ showType semTy ++ ")")])
            in (tinit0', errsI ++ errsAssign)
      vi   = VarInfo semTy pos True ByValue
      env' = env { envVars = Map.insert name vi (envVars env) }
  in (TDVarInit name semTy pos tinit, env', Set.insert name localNames, errsDup ++ errsInit)
checkTopDecl env localNames (Abs.DProc pos (Abs.Ident name) params retType body) =
  let semParams = [ TParam (fromSyntacticIntent intent) (fromSyntacticType ptype) pname ppos
                   | Abs.Par ppos intent (Abs.Ident pname) ptype <- params ]
      paramNames = [ tparName p | p <- semParams ]
      paramNameSet = Set.fromList paramNames
      errsDupParam =
        [ mkError (tparPos p) ("parametro ripetuto: " ++ tparName p)
        | (p, i) <- zip semParams [0 :: Int ..]
        , tparName p `elem` take i paramNames ]
      semRet = fromSyntacticType retType
      errsRet
        | isArrayType semRet = [mkError pos ("il tipo di ritorno di " ++ name
                                              ++ " non può essere un array: " ++ showType semRet)]
        | otherwise = []
      bodyEnvVars = foldl (\vm p -> Map.insert (tparName p)
                                       (VarInfo (tparType p) (tparPos p) True (tparIntent p)) vm)
                          (envVars env) semParams
      bodyEnvVars' = Map.insert "$return" (VarInfo semRet pos True ByValue) bodyEnvVars
      bodyEnv = env { envVars = bodyEnvVars', envInLoop = False }
      (tbody, errsBody) = checkBlockWith paramNameSet bodyEnv body
      alreadyThere = Map.member name (envFuns env)
      env'
        | alreadyThere = env
        | otherwise =
            let fi = FunInfo [(tparIntent p, tparType p) | p <- semParams] semRet
            in env { envFuns = Map.insert name fi (envFuns env) }
  in (TDProc name semParams semRet pos tbody, env', localNames, errsDupParam ++ errsRet ++ errsBody)

-- Punto di ingresso del controllo dei tipi. Prende l'intero programma
checkProgram :: Abs.Program -> (TProgram, [TypeError])
checkProgram (Abs.Prog _ topDecls) =
  let stmts = map (Abs.SDecl (Just (0,0))) topDecls
      (tstmts, errs) = checkStmtList initialEnv stmts
      ttopDecls = [ td | TSDecl td <- tstmts ]
  in (TProgram ttopDecls, errs)
