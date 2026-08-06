# Esercizio 1
Nella soluzione, per rendere univoca l’applicazione delle occorrenze dei metodi di classe, si utilizzi la convenzione di denotare con meth@type una occorrenza del metodo meth ottenuta istan-
ziando il paramentro di tipo della classe con il tipo type (per esempio +@Int qualora il metodo
+ :: Num a=>a->a->a venga usato nel caso a = Int per il contesto Num a). Stesso discorso per le
funzioni il cui tipo abbia dei vincoli di classe. Si raccomanda di limitarsi a questi casi, evitando di adornare tutto ciò che non ha vincoli di classe (saper distinguere è parte della prova). Si considerino le eventuali valutazioni delle istanze — su tipi primitivi — del metodo succ come fossero “a grandi passi” per cui, per esempio, succ@Int 2@Int in un passo diventa direttamente 3@Int. Inoltre (sempre in caso di valutazione) se ne valutino gli argomenti in modo eager, quindi per esempio succ@Int (+@Int 1@Int 1@Int) prima diventa succ@Int 2@Int.
Qualora si usasse una notazione lineare per rappresentare le espressioni dei passi di esecuzione, si abbia cura di usare una forma per cui non ci siano ambiguità relativamente alle (sotto)espressioni condivise. 

## Enumerazione delle regole
```
R1 h k p = snd p > k

R2 filter _ [] = []
R3 filter p ( x : xs ) = if p x then x : ys else ys
    where
        ys = filter p xs

R4 zip ( x : xs ) ( y : ys ) = (x , y ) : zip xs ys
R5 zip [] _ = []
R6 zip _ [] = []
R7 zip _ _ = error " ouch !! "

R8 fromE n = n : fromE ( succ n )
```

## Query senza zucchero sintattico

```
filter (h@Char '3') (zip (error "ERR" : ('1':[])) (fromE@Char 'a'))
```

## Svolgimento


filter (h@Char '3') (zip (error "ERR" : ('1':[])) (fromE@Char 'a'))

[valuto filter dato che è la funzione più a sinistra; per decidere quale applicare tra R2 e R3 mi serve svolgere il simbolo più esterno zip (...)]
|| zip (error "ERR" : ('1':[])) (fromE@Char 'a')
|| [R4 combacia per il primo argomento (che è un cons) ma per capire se posso applicarla devo svolgere il secondo argomento]
|| (fromE@Char 'a')
|| [R8 combacia e lo applico con n := 'a']
|| 'a' : fromE@Char (succ@Char 'a')
|| [il secondo argomento di zip diventa quindi un cons]
|| zip (error "ERR" : ('1':[])) ('a' : fromE@Char (succ@Char 'a'))
|| [posso applicare R4: x := error "ERR", xs := ('1':[]), y := 'a', ys := (fromE@Char (succ@Char 'a'))]
|| (error "ERR", 'a') : zip ('1':[]) (fromE@Char (succ@Char 'a'))

filter (h@Char '3') ((error "ERR", 'a') : zip ('1':[]) (fromE@Char (succ@Char 'a')))

[R2 non combacia siccome il secondo argomento che è un cons non coincide con []; proseguo con R3]
[R3 combacia con entrambi gli argomenti: lo applico avendo p := (h@Char '3'), x := (error "ERR", 'a'), xs := zip ('1':[]) (fromE@Char (succ@Char 'a'))]
|| if h@Char '3' (error "ERR", 'a') then (error "ERR", 'a') : ys else ys
||      where ys = filter (h@Char '3') (zip ('1':[]) (fromE@Char (succ@Char 'a')))
|| [valuto la guardia per scegliere il ramo dell'if; h ha un'unica regola R1 e la applico con k := '3' e p := (error "ERR", 'a') ]
|| snd (error "ERR", 'a') >@Char '3'
|| [svolgo snd]
|| snd (error "ERR", 'a') := 'a'
|| 'a' >@Char '3'
|| True
|| [la guardia dell'if ha valore True; l'if svolge il ramo then]
|| (error "ERR", 'a') : ys 
||      where ys = filter (h@Char '3') (zip ('1':[]) (fromE@Char (succ@Char 'a')))
(error "ERR", 'a') : ys 
      where ys = filter (h@Char '3') (zip ('1':[]) (fromE@Char (succ@Char 'a')))

[il primo elemento della lista risultato è fissato: (error "ERR", 'a'); per proseguire devo valutare ys per sapere se la lista continua]

[valuto ys = filter (h@Char '3') (zip ('1':[]) (fromE@Char (succ@Char 'a')))]
[per scegliere tra R2 e R3 di filter serve il simbolo più esterno di zip ('1':[]) (fromE@Char (succ@Char 'a')); lo valuto]
|| il primo argomento di zip, ('1':[]), è già un cons; per applicare R4 serve anche la forma del secondo argomento: valuto fromE@Char (succ@Char 'a')
|| [R8 combacia: n è variabile e combacia sempre; assegno n := succ@Char 'a']
|| fromE@Char (succ@Char 'a') = succ@Char 'a' : fromE@Char (succ@Char (succ@Char 'a'))
[il secondo argomento di zip è dunque un cons: posso applicare R4]
[R4 combacia: x := '1', xs := [], y := succ@Char 'a', ys := fromE@Char (succ@Char (succ@Char 'a'))]
|| zip ('1':[]) (fromE@Char (succ@Char 'a')) = ('1', succ@Char 'a') : zip [] (fromE@Char (succ@Char (succ@Char 'a')))

ys = filter (h@Char '3') (('1', succ@Char 'a') : zip [] (fromE@Char (succ@Char (succ@Char 'a'))))

[R2 non combacia perché il secondo argomento (il cons) non coincide con []; proseguo con R3]
[R3 combacia: p := h@Char '3', x := ('1', succ@Char 'a'), xs := zip [] (fromE@Char (succ@Char (succ@Char 'a')))]

ys = if h@Char '3' ('1', succ@Char 'a') then ('1', succ@Char 'a') : ys2 else ys2
      where ys2 = filter (h@Char '3') (zip [] (fromE@Char (succ@Char (succ@Char 'a'))))

[valuto la guardia dell'if; applico R1 con k := '3', p := ('1', succ@Char 'a')]
|| snd ('1', succ@Char 'a') >@Char '3'
|| [svolgo snd: snd ('1', succ@Char 'a') = succ@Char 'a']
|| [valuto succ@Char 'a' "a grandi passi": succ@Char 'a' = 'b'; fisso questo valore ovunque compaia]
|| 'b' >@Char '3'
|| [>@Char: confronto i codici carattere; 'b' è maggiore di '3']
|| True
[la guardia vale True; l'if restituisce il ramo then]

ys = ('1', 'b') : ys2
      where ys2 = filter (h@Char '3') (zip [] (fromE@Char (succ@Char (succ@Char 'a'))))

(error "ERR", 'a') : ('1', 'b') : ys2
      where ys2 = filter (h@Char '3') (zip [] (fromE@Char (succ@Char (succ@Char 'a'))))

[valuto ys2 = filter (h@Char '3') (zip [] (fromE@Char (succ@Char (succ@Char 'a'))))]
[per applicare R2 o R3 di filter serve il simbolo più esterno di zip [] (fromE@Char (succ@Char (succ@Char 'a'))); il primo argomento di zip è già [], quindi R4 fallisce subito (richiede un cons come primo argomento) e posso applicare direttamente R5 senza dover valutare il secondo argomento (il pattern _ combacia comunque)]
|| zip [] (fromE@Char (succ@Char (succ@Char 'a'))) = []

ys2 = filter (h@Char '3') []

[R2 combacia (secondo argomento [], primo _); applico R2]
|| ys2 = []

(error "ERR", 'a') : ('1', 'b') : []