# Consegna
 Si consideri il seguente programma Haskell
```
g :: Int-> Int-> [Float]
g n k = take n (v:v:map f (enumFromThen ’a’ ’c’))
    where 
        v = f ’0’
        
        f x = toEnum ((+k) (fromEnum x)) 
        

take :: Int-> [a]-> [a] 
take _ [] = []
take n _ | n <= 0 = []
take n (x:xs) = x : take (n-1) xs


map f (x:xs) = f x : map f xs
map _ [] = []
```
### Query: 
```
let k = 4-2 in g (4-k) (5-k)
```

## Query senza zucchero sintattico

funzione k è ripetuta -> creo k'
utilizzo k'[-@Int 4@Int 2@Int]

```
g ( -@Int 4@Int k'[-@Int 4@Int 2@Int]) ( -@Int 5@Int k')
```

## Enumerazione delle regole
```
R1 g n k = take n (v:v:map f (enumFromThen ’a’ ’c’))
    where 
        v = f ’0’
        
R2 f x = toEnum ((+k) (fromEnum x)) 
        
R3 take _ [] = []
R4 take n _ | n <= 0 = []
R5 take n (x:xs) = x : take (n-1) xs


R6 map f (x:xs) = f x : map f xs
R7 map _ [] = []
```

## Svolgimento

g ( -@Int 4@Int k'[-@Int 4@Int 2@Int]) ( -@Int 5@Int k')

[   Siccome n e k sono variabili, R1 combacia e la applico. Assegno:
        n := ( -@Int 4@Int k'[-@Int 4@Int 2@Int])
        k := ( -@Int 5@Int k')
        v viene etichettata con v'[f -'0'], senza valutare [f '0'] finché non serve
]

take (-@Int 4@Int k'[-@Int 4@Int 2@Int]) (v'[f '0']:v':map f (enumFromThen ’a’ ’c’)) 

[ R3 fallisce perché l'argomento [] non combacia con il cons (v'[f '0']:v':map f (enumFromThen ’a’ ’c’)); proseguo con R4 ]
[ R4 combacia perché la variabile n combacia sempre e _ pure: controllo la guardia n <= 0]
|| assegno n := (-@Int 4@Int k'[-@Int 4@Int 2@Int])
|| devo calcolare n:
|| è necessario calcolare prima k' := -@Int 4@Int 2@Int = 2@Int
|| fisso k':= 2@Int ovunque
|| n := (-@Int 4@Int 2@Int) = 2@Int
|| n <= 0
|| 2@Int <=@Int 0@Int 
|| <=@Int: 2 non è <= 0
[ La guardia non è valida perché n = 2 non è minore o uguale a 0; R4 fallisce e proseguo con R5 ]
[ R5 combacia con entrambe le variabili e dunque la applico ]
|| n := 2@Int (già calcolato in precedenza)
|| (x:xs) := (v'[f '0']:v':map f (enumFromThen ’a’ ’c’))
|| di cui abbiamo:
|| x := v'[f '0']
|| xs := v':map f (enumFromThen ’a’ ’c’)

v'[f '0'] : take (-@Int 2@Int 1@Int) (v':map f (enumFromThen ’a’ ’c’))

[valuto v' dato che è la funzione più a sinistra ]
|| f '0'
|| [ R2 combacia e la applico, considerando x := '0' ]
|| toEnum@Float (+@Int (fromEnum@Char '0') k[-@Int 5@Int k'])
|| [calcolo fromEnum@Char '0' = 48@Int]
|| toEnum@Float (+@Int 48@Int k[-@Int 5@Int k'])
|| tenendo in considerazione la variabile k := -@Int 5@Int k' definita in precedenza 
|| calcolo k := -@Int 5@Int k' := -@Int 5@Int 2@Int := 3@Int che fisso ovunque
|| toEnum@Float ( +@Int 48@Int 3@Int)
|| toEnum@Float (51@Int)
|| 51.0@Float
|| [ v' viene fissato a 51.0@Float ovunque ]

51.0@Float : take (2@Int -@Int 1@Int) (51.0@Float : map f (enumFromThen 'a' 'c'))

[ valuto take (2@Int -@Int 1@Int) (51.0@Float : map f (enumFromThen 'a' 'c')) ]
[ R3 non combacia perché l'argomento [] non ombacia con il cons (51.0@Float : map f (enumFromThen 'a' 'c')); proseguo con R4]
[R4 combacia perché gli argomenti che possiede sono variabili e coincidono sempre. Applico dunque R4 e controllo la guardia n <= 0]
[ R4: n, _ combaciano sempre (n := 2@Int -@Int 1@Int); si valuta la guardia n<=0 ]
|| (2@Int -@Int 1@Int) <=@Int 0@Int
|| [ -@Int: 2@Int -@Int 1@Int = 1@Int ]
|| 1@Int <=@Int 0@Int
|| [ <=@Int: 1 non è ≤ 0 ]
|| False
[ La guardia non è valida perché n = 1 non è minore o uguale a 0; R4 fallisce e proseguo con R5 ]
[ R5 combacia siccome le variabili coincidono sempre; applico R5]
|| considero n := 1@Int e (x:xs) := (51.0@Float : map f (enumFromThen 'a' 'c'))
|| 51.0@Float : take (1@Int -@Int 1@Int) (map f (enumFromThen 'a' 'c'))

51.0@Float : 51.0@Float : take (1@Int -@Int 1@Int) (map f (enumFromThen 'a' 'c'))

[valuto take (1@Int -@Int 1@Int) (map f (enumFromThen 'a' 'c'))]
[ per sapere se applicare R3 o R4/R5 di take, serve il simbolo più esterno di map f (enumFromThen 'a' 'c'); si valuta map f (enumFromThen 'a' 'c') ]
|| [ R6: per far combaciare (x:xs), serve sapere il simbolo più esterno di enumFromThen 'a' 'c' ]

|| [R6: per controllare se n e (x:xs) combaciano, devo prima svolgere f (enumFromThen 'a' 'c') per controllare il valore in output; controllo se R2 combacia]
|| [R2: x è una variabile e combacia sempre; applico R2 con x := enumFromThen 'a' 'c']
|| 


[ per sapere se applicare R3 o R4/R5 di take, serve il simbolo più esterno di
  map f (enumFromThen 'a' 'c'); si valuta map f (enumFromThen 'a' 'c') ]
∥ [ enumFromThen 'a' 'c' si srotola in 'a' : enumFromThen 'c' 'e' (passo di 2 posizioni) ]
∥ [ R6 combacia ora: x := 'a', xs := enumFromThen 'c' 'e' ]
∥ f 'a' : map f (enumFromThen 'c' 'e')


R2 f x = toEnum ((+k) (fromEnum x)) 



R3 take _ [] = []
R4 take n _ | n <= 0 = []
R5 take n (x:xs) = x : take (n-1) xs

R6 map f (x:xs) = f x : map f xs
R7 map _ [] = []
