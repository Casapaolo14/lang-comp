module TypeCheck where

import qualified Data.Map as Map
import qualified AbsLinguaggio as Abs
import SemTypes
import Environment
import TypedAst
import TypeErrors

-- ============================================================
-- checkExp: TUTTE le equazioni insieme, senza altro in mezzo
-- ============================================================

checkExp :: Env -> Abs.Exp -> (TExp, [TypeError])
checkExp _ (Abs.EInt _ n)   = (TEInt STInt n, [])
checkExp _ (Abs.EReal _ d)  = (TEReal STReal d, [])
checkExp _ (Abs.EChar _ c)  = (TEChar STChar c, [])
checkExp _ (Abs.EStr _ s)   = (TEStr STStr s, [])
checkExp _ (Abs.ETrue _)    = (TETrue STBool, [])
checkExp _ (Abs.EFalse _)   = (TEFalse STBool, [])
checkExp env (Abs.EVar pos (Abs.Ident name)) =
  case Map.lookup name (envVars env) of
    Just vi -> (TEVar (viType vi) (viDeclPos vi) name, [])
    Nothing -> (TEVar STError Nothing name,
                [mkError pos ("variabile non dichiarata: " ++ name)])
checkExp env (Abs.EAdd pos e1 e2) = checkArith pos env e1 e2 TEAdd
checkExp env (Abs.ESub pos e1 e2) = checkArith pos env e1 e2 TESub
checkExp env (Abs.EMul pos e1 e2) = checkArith pos env e1 e2 TEMul
checkExp env (Abs.EDiv pos e1 e2) = checkArith pos env e1 e2 TEDiv
checkExp env (Abs.EOr  pos e1 e2) = checkBoolOp pos env e1 e2 TEOr
checkExp env (Abs.EAnd pos e1 e2) = checkBoolOp pos env e1 e2 TEAnd
checkExp env (Abs.EEq  pos e1 e2) = checkRel pos env e1 e2 TEEq
checkExp env (Abs.ENeq pos e1 e2) = checkRel pos env e1 e2 TENeq
checkExp env (Abs.ELt  pos e1 e2) = checkRel pos env e1 e2 TELt
checkExp env (Abs.ELe  pos e1 e2) = checkRel pos env e1 e2 TELe
checkExp env (Abs.EGt  pos e1 e2) = checkRel pos env e1 e2 TEGt
checkExp env (Abs.EGe  pos e1 e2) = checkRel pos env e1 e2 TEGe
checkExp env (Abs.ENeg pos e1) = checkUnaryMath pos env e1 TENeg
checkExp env (Abs.ENot pos e1) = checkUnaryBool pos env e1 TENot
checkExp env (Abs.EDeref pos e1) = checkDeref pos env e1
checkExp env (Abs.EAddr pos e1) = checkAddr pos env e1
checkExp env (Abs.EIdx pos e1 e2) = checkIdx pos env e1 e2
checkExp env (Abs.ECall pos (Abs.Ident name) args) = checkCall pos env name args

-- ============================================================
-- Funzioni ausiliarie per checkExp
-- ============================================================

checkArith :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp
           -> (SemType -> TExp -> TExp -> TExp) -> (TExp, [TypeError])
checkArith pos env e1 e2 mkNode =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1           = typeOf te1
      t2           = typeOf te2
      resultType   = sup t1 t2
      te1'         = insertCast resultType te1
      te2'         = insertCast resultType te2
      errs3
        | resultType /= STError          = []
        | t1 == STError || t2 == STError = []
        | otherwise = [mkError pos "operandi di tipo incompatibile nell'operazione aritmetica"]
  in (mkNode resultType te1' te2', errs1 ++ errs2 ++ errs3)

insertCast :: SemType -> TExp -> TExp
insertCast target texp
  | typeOf texp == target = texp
  | otherwise             = TECast target texp

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
        | otherwise = (STError, [mkError pos "gli operandi di || e && devono essere entrambi bool"])
  in (mkNode resultType te1 te2, errs1 ++ errs2 ++ errs3)

checkRel :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp
         -> (SemType -> TExp -> TExp -> TExp) -> (TExp, [TypeError])
checkRel pos env e1 e2 mkNode =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1         = typeOf te1
      t2         = typeOf te2
      supType    = sup t1 t2
      resultType = rel t1 t2
      te1'       = insertCast supType te1
      te2'       = insertCast supType te2
      errs3
        | resultType /= STError          = []
        | t1 == STError || t2 == STError = []
        | otherwise = [mkError pos "operandi di tipo incompatibile nel confronto"]
  in (mkNode resultType te1' te2', errs1 ++ errs2 ++ errs3)

checkUnaryMath :: Maybe (Int, Int) -> Env -> Abs.Exp
               -> (SemType -> TExp -> TExp) -> (TExp, [TypeError])
checkUnaryMath pos env e1 mkNode =
  let (te1, errs1) = checkExp env e1
      t1           = typeOf te1
      resultType   = mathtype t1
      errs2
        | resultType /= STError = []
        | t1 == STError         = []
        | otherwise = [mkError pos "operando non numerico per l'operatore unario"]
  in (mkNode resultType te1, errs1 ++ errs2)

checkUnaryBool :: Maybe (Int, Int) -> Env -> Abs.Exp
               -> (SemType -> TExp -> TExp) -> (TExp, [TypeError])
checkUnaryBool pos env e1 mkNode =
  let (te1, errs1) = checkExp env e1
      t1           = typeOf te1
      (resultType, errs2)
        | t1 == STError = (STError, [])
        | t1 == STBool  = (STBool, [])
        | otherwise = (STError, [mkError pos "l'operando di ! deve essere bool"])
  in (mkNode resultType te1, errs1 ++ errs2)

checkDeref :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkDeref pos env e1 =
  let (te1, errs1) = checkExp env e1
      t1            = typeOf te1
      (resultType, errs2) = case t1 of
        STPtr inner -> (inner, [])
        STError     -> (STError, [])
        _           -> (STError, [mkError pos "dereferenziazione (*) applicata a un tipo che non è un puntatore"])
  in (TEDeref resultType te1, errs1 ++ errs2)

checkAddr :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkAddr pos env e1 =
  let (te1, errs1) = checkExp env e1
      t1            = typeOf te1
      (resultType, errs2)
        | t1 == STError    = (STError, [])
        | isLExpr e1        = (STPtr t1, [])
        | otherwise = (STError, [mkError pos "c_ptrTo richiede un'l-expression (una variabile, non un'espressione qualsiasi)"])
  in (TEAddr resultType te1, errs1 ++ errs2)

isLExpr :: Abs.Exp -> Bool
isLExpr (Abs.EVar _ _)   = True
isLExpr (Abs.EIdx _ e _) = isLExpr e
isLExpr (Abs.EDeref _ _) = True
isLExpr _                = False

checkIdx :: Maybe (Int, Int) -> Env -> Abs.Exp -> Abs.Exp -> (TExp, [TypeError])
checkIdx pos env e1 e2 =
  let (te1, errs1) = checkExp env e1
      (te2, errs2) = checkExp env e2
      t1 = typeOf te1
      t2 = typeOf te2
      errsIdx
        | t2 == STInt   = []
        | t2 == STError = []
        | otherwise = [mkError pos "l'indice di un array deve essere di tipo int"]
      (resultType, errsBase) = case t1 of
        STArr _ _ inner -> (inner, [])
        STError         -> (STError, [])
        _               -> (STError, [mkError pos "indicizzazione [] applicata a un tipo che non è un array"])
  in (TEIdx resultType te1 te2, errs1 ++ errs2 ++ errsIdx ++ errsBase)

checkArg :: Maybe (Int, Int) -> Env -> Int -> (ParamIntent, SemType) -> Abs.Exp -> (TExp, [TypeError])
checkArg pos env idx (intent, paramType) argExpr =
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
               | otherwise = [mkError pos ("tipo non compatibile per il parametro " ++ show idx)]
         in (te', errs1 ++ errs2)
       ByRef ->
         let errs2
               | t == STError       = []
               | t /= paramType     = [mkError pos ("il parametro " ++ show idx ++ " (per riferimento) richiede tipo identico")]
               | not (isLExpr argExpr) = [mkError pos ("il parametro " ++ show idx ++ " (per riferimento) richiede una variabile, non un'espressione")]
               | otherwise          = []
         in (te, errs1 ++ errs2)

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
          checkedPairs = [ (fst p, checkArg pos env idx p a) | (idx, p, a) <- matched ]
          extraArgs    = drop nParams args
          extraChecked = map (checkExp env) extraArgs
          allTe        = [ (intent, te) | (intent, (te, _)) <- checkedPairs ]
                         ++ [ (ByValue, te) | (te, _) <- extraChecked ]
          allErrs      = concatMap (snd . snd) checkedPairs ++ concatMap snd extraChecked
      in (TECall (fiReturn fi) name allTe, lenErrs ++ allErrs)


checkStmt :: Env -> Abs.Stmt -> (TStmt, [TypeError])
checkStmt env (Abs.SAssign pos lhs rhs) =
  let (tlhs, errsL) = checkExp env lhs
      (trhs, errsR) = checkExp env rhs
      tL = typeOf tlhs
      tR = typeOf trhs
      errsLValue
        | isLExpr lhs = []
        | otherwise   = [mkError pos "il lato sinistro di un assegnamento deve essere una l-expression"]
      (trhs', errsAssign)
        | tL == STError || tR == STError = (trhs, [])
        | assignableTo tR tL             = (insertCast tL trhs, [])
        | otherwise = (trhs, [mkError pos "tipo del lato destro non assegnabile al lato sinistro"])
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
      (tblk, errsBlk)   = checkBlock env blk
  in (TSWhile tcond tblk, errsCond ++ errsBlk)
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
               | otherwise = (te, [mkError pos "tipo del return non compatibile con il tipo di ritorno della funzione"])
         in (TSReturn te', errs1 ++ errs2)
checkStmt env (Abs.SReturnV pos) =
  case Map.lookup "$return" (envVars env) of
    Nothing -> (TSReturnV, [mkError pos "return fuori da una funzione"])
    Just vi
      | viType vi == STVoid -> (TSReturnV, [])
      | otherwise -> (TSReturnV, [mkError pos "questa funzione richiede un valore di ritorno (return con espressione)"])


checkCondition :: Maybe (Int, Int) -> Env -> Abs.Exp -> (TExp, [TypeError])
checkCondition pos env cond =
  let (tcond, errs1) = checkExp env cond
      t = typeOf tcond
      errs2
        | t == STBool  = []
        | t == STError = []
        | otherwise = [mkError pos "la condizione deve essere di tipo bool"]
  in (tcond, errs1 ++ errs2)

checkBlock :: Env -> Abs.Block -> (TBlock, [TypeError])
checkBlock env (Abs.BBlock _ stmts) =
  let (tstmts, errs) = checkStmtList env stmts
  in (TBlock tstmts, errs)

checkStmtList :: Env -> [Abs.Stmt] -> ([TStmt], [TypeError])
checkStmtList env stmts =
  let (env1, preErrs)   = preScanFunctions env stmts
      (tstmts, bodyErrs) = go env1 stmts
  in (tstmts, preErrs ++ bodyErrs)
  where
    go _ [] = ([], [])
    go e (s:ss) = case s of
      Abs.SDecl _ topDecl ->
        let (ttd, e', errs1) = checkTopDecl e topDecl
            (trest, errs2)   = go e' ss
        in (TSDecl ttd : trest, errs1 ++ errs2)
      _ ->
        let (ts, errs1)    = checkStmt e s
            (trest, errs2) = go e ss
        in (ts : trest, errs1 ++ errs2)

preScanFunctions :: Env -> [Abs.Stmt] -> (Env, [TypeError])
preScanFunctions env stmts = foldl addOne (env, []) stmts
  where
    addOne (e, errs) (Abs.SDecl _ (Abs.DProc pos (Abs.Ident name) params retType _)) =
      case Map.lookup name (envFuns e) of
        Just _  -> (e, errs ++ [mkError pos ("funzione già dichiarata in questo blocco: " ++ name)])
        Nothing ->
          let paramInfos = [ (fromSyntacticIntent intent, fromSyntacticType ptype)
                            | Abs.Par _ intent _ ptype <- params ]
              fi = FunInfo paramInfos (fromSyntacticType retType)
              e' = e { envFuns = Map.insert name fi (envFuns e) }
          in (e', errs)
    addOne acc _ = acc


checkTopDecl :: Env -> Abs.TopDecl -> (TTopDecl, Env, [TypeError])
checkTopDecl env (Abs.DVar pos (Abs.Ident name) ty) =
  let semTy = fromSyntacticType ty
      vi   = VarInfo semTy pos
      env' = env { envVars = Map.insert name vi (envVars env) }
  in (TDVar name semTy pos, env', [])
checkTopDecl env (Abs.DVarInit pos (Abs.Ident name) ty initExpr) =
  let semTy          = fromSyntacticType ty
      (tinit, errsI) = checkExp env initExpr
      tInitTy        = typeOf tinit
      (tinit', errsAssign)
        | tInitTy == STError || semTy == STError = (tinit, [])
        | assignableTo tInitTy semTy              = (insertCast semTy tinit, [])
        | otherwise = (tinit, [mkError pos "tipo dell'inizializzatore non assegnabile alla variabile dichiarata"])
      vi   = VarInfo semTy pos
      env' = env { envVars = Map.insert name vi (envVars env) }
  in (TDVarInit name semTy pos tinit', env', errsI ++ errsAssign)
checkTopDecl env (Abs.DProc pos (Abs.Ident name) params retType body) =
  let semParams = [ TParam (fromSyntacticIntent intent) (fromSyntacticType ptype) pname ppos
                   | Abs.Par ppos intent (Abs.Ident pname) ptype <- params ]
      semRet    = fromSyntacticType retType
      bodyEnvVars = foldl (\vm p -> Map.insert (tparName p)
                                       (VarInfo (tparType p) (tparPos p)) vm)
                          (envVars env) semParams
      bodyEnvVars' = Map.insert "$return" (VarInfo semRet pos) bodyEnvVars
      bodyEnv = env { envVars = bodyEnvVars' }
      (tbody, errsBody) = checkBlock bodyEnv body
      alreadyThere = Map.member name (envFuns env)
      env'
        | alreadyThere = env
        | otherwise =
            let fi = FunInfo [(tparIntent p, tparType p) | p <- semParams] semRet
            in env { envFuns = Map.insert name fi (envFuns env) }
  in (TDProc name semParams semRet pos tbody, env', errsBody)

isArrayType :: SemType -> Bool
isArrayType (STArr _ _ _) = True
isArrayType _             = False

checkProgram :: Abs.Program -> (TProgram, [TypeError])
checkProgram (Abs.Prog _ topDecls) =
  let stmts = map (Abs.SDecl (Just (0,0))) topDecls
      (tstmts, errs) = checkStmtList initialEnv stmts
      ttopDecls = [ td | TSDecl td <- tstmts ]
  in (TProgram ttopDecls, errs)