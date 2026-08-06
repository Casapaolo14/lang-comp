
# Codice della parte B

Enumerando le istruzioni del codice dell'esercizio 1 della parte B si ottiene:

```
R1 h k p = snd p > k

R2 filter _ [] = []
R3 filter p (x:xs) = if p x then x : ys else ys
  where 
        ys = filter p xs

R4 zip (x:xs) (y:ys)  = (x, y) : zip xs ys
R5 zip [] _ = []
R6 zip _ [] = []
R7 zip _ _ = error "ouch !!"

R8 fromE n = n : fromE (succ n)
```

Le regole che verranno controllate sono:
- filter: R2-R3
- zip: R4-R5, R4-R6, R4-R7, R5-R6, R5-R7, R6-R7

Invece le regole R1 ed R8 (h e fromE) verranno ignorate siccome sono uniche.

## filter

### R2-R3
R2 = filter _ []
R3 = filter p (x:xs)

Rinomino le variabili di R2, sostituendo _ con a2:
R2 = filter a2 []

Equazione:
filter a2 [] = filter p3 (x:xs)

Decomposizione
{a2=p3, [] = (x:xs)}

- a2=p3 -> caso variabile = variabile => binding a2->p3
- [] = (x:xs) -> FAIL per simboli diversi

Esito: FAILURE - NESSUN OVERLAP
Fallimento su [] = (x:xs)

## zip

### R4-R5

R4 = zip (x:xs) (y:ys)
R5 = zip [] _

Rinomino le variabili di R5, sostituendo _ con a5:
R5 = zip [] a5

Equazione:
zip (x:xs) (y:ys) = zip [] a5

Decomposizione
{(x:xs) = [], (y:ys) = a5}

- (x:xs) = [] -> FAIL per simboli diversi
- (y:ys) = a5 -> caso termine = variabile => binding a5 -> (y:ys)

Esito: FAILURE - NESSUN OVERLAP
Fallimento su (x:xs) = []

### R4-R6

R4 = zip (x:xs) (y:ys)
R6 = zip _ []

Rinomino le variabili di R6, sostituendo _ con a6:
R6 = zip a6 []

Equazione:
zip (x:xs) (y:ys) = zip a6 []

Decomposizione
{(x:xs) = a6, (y:ys) = []}

- (x:xs) = a6 -> caso termine = variabile => binding a6 -> (x:xs)
- (y:ys) = [] -> FAIL per simboli diversi

Esito: FAILURE - NESSUN OVERLAP
Fallimento su (y:ys) = []

### R4-R7

R4 = zip (x:xs) (y:ys)
R7 = zip _ _

Rinomino le variabili di R7, sostituendo _ e _ con a7 e b7:
R7 = zip a7 b7

Equazione:
zip (x:xs) (y:ys) = zip a7 b7

Decomposizione
{(x:xs) = a7, (y:ys) = b7}

- (x:xs) = a7 -> caso termine = variabile => binding a7 -> (x:xs)
- (y:ys) = b7 -> caso termine = variabile => binding b7 -> (y:ys)

Esito: OVERLAP
θ = mgu(R4,R7) = { a7 -> (x:xs), b7 -> (y:ys) }

Testimone
R4 θ = R7 θ = zip (x:xs) (y:ys)

### R5-R6
R5 = zip [] _
R6 = zip _ []

Rinomino le variabili di R5, sostituendo _ con a5:
R5 = zip [] a5

Rinomino le variabili di R6, sostituendo _ con a6:
R6 = zip a6 []

Equazione:
zip [] a5 = zip a6 []

Decomposizione
{[] = a6, a5 = []}

- [] = a6 -> caso termine = variabile => binding a6 -> []
- a5 = [] -> caso termine = variabile => binding a5 -> []

Esito: OVERLAP
θ = mgu(R5,R6) = { a6 -> [], a5 -> [] }

Testimone
R5 θ = R6 θ = zip [] []

### R5-R7
R5 = zip [] _
R7 = zip _ _

Rinomino le variabili di R5, sostituendo _ con a5:
R5 = zip [] a5

Rinomino le variabili di R7, sostituendo _ e _ con a7 e b7:
R7 = zip a7 b7

Equazione:
zip [] a5 = zip a7 b7

Decomposizione
{[] = a7, a5 = b7}

- [] = a7 -> caso termine = variabile => binding a7 -> []
- a5 = b7 -> caso variabile = variabile => binding a5 -> b7

Esito: OVERLAP
θ = mgu(R5,R7) = { a7 -> [], a5 -> b7 }

Testimone
R5 θ = R7 θ = zip [] b7

### R6-R7
R6 = zip _ []
R7 = zip _ _

Rinomino le variabili di R6, sostituendo _ con a6:
R6 = zip a6 []

Rinomino le variabili di R7, sostituendo _ e _ con a7 e b7:
R7 = zip a7 b7

Equazione:
zip a6 [] = zip a7 b7

Decomposizione
{a6 = a7, [] = b7}

- a6 = a7 -> caso variabile = variabile => binding a6 -> a7
- [] = b7 -> caso termine = variabile => binding b7 -> []

Esito: OVERLAP
θ = mgu(R6,R7) = { a6 -> a7, b7 -> [] }

Testimone
R6 θ = R7 θ = zip a7 []
