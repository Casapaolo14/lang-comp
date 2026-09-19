GHC        = ghc
HAPPY      = happy
HAPPY_OPTS = --array --info --ghc --coerce
ALEX       = alex
ALEX_OPTS  = --ghc

.PHONY : all clean distclean demo

# Obiettivo di default: costruisce l'eseguibile Main, che realizza
# l'intera pipeline richiesta (parsing, analisi semantica, pretty-print
# del sorgente, generazione e pretty-print del three-address code).
all : Main

# NOTA: Linguaggio.cf, LexLinguaggio.x, ParLinguaggio.y, PrintLinguaggio.hs
# e AbsLinguaggio.hs sono nati da "bnfc --haskell --functor Linguaggio.cf",
# ma LexLinguaggio.x in particolare e' stato poi rifinito a mano (regex
# della notazione scientifica dei numeri reali). Questa regola di
# rigenerazione automatica non e' collegata a "all" apposta: un `make`
# qualunque non deve rischiare di rilanciare bnfc e sovrascrivere le
# modifiche fatte a mano. Per rigenerare tutto da zero (perdendo le
# rifiniture manuali, da riapplicare a mano dopo), lanciare esplicitamente:
#   bnfc --haskell --functor Linguaggio.cf

%.hs : %.y
	${HAPPY} ${HAPPY_OPTS} $<

%.hs : %.x
	${ALEX} ${ALEX_OPTS} $<

Main : AbsLinguaggio.hs LexLinguaggio.hs ParLinguaggio.hs PrintLinguaggio.hs \
       TypeErrors.hs SemTypes.hs Environment.hs TypedAst.hs TypeCheck.hs \
       Tac.hs TacGen.hs PrintTac.hs Main.hs
	${GHC} ${GHC_OPTS} --make Main

# Esegue Main su tutti i casi di test significativi presenti in tests/
# (lexer, parser, errori di sintassi, type checker, generazione TAC),
# mostrando per ciascuno il pretty-print del sorgente e, quando il
# programma e' corretto, anche il three-address code generato.
demo : Main
	./Main $(sort $(wildcard tests/lexer/*.lang tests/parser/*.lang tests/errors/*.lang tests/typecheck/*.lang tests/tacgen/*.lang))

clean :
	-rm -f *.hi *.o *.log *.aux *.dvi

distclean : clean
	-rm -f Main TestLinguaggio TestTypeCheck TestTacGen LexLinguaggio.hs ParLinguaggio.hs ParLinguaggio.info

# EOF
