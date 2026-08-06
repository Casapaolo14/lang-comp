# Codice della parte A
Enumerando le istruzioni del codice scritto nell'esercizio 1 della parte A si ottiene:
```
R1 semplifica (Q (C a) (C b) (C c) (C d))
R2 semplifica qt

R3 somma x (C a) y (C b)
R4 somma x (Q a11 a12 a21 a22) y (Q b11 b12 b21 b22)
R5 somma _ _ _ _

R6 trasposta (C x)
R7 trasposta (Q q11 q12 q21 q22)

R8 tuc x y (Mat n m)
```
Le regole che verranno controllate sono:
- semplifica: R1-R2
- somma: R3-R4, R3-R5, R4-R5
- trasposta: R6-R7

Infine, la regola R8 tuc viene ignorata siccome è unica.

## semplifica

### R1-R2

R1 = semplifica (Q (C a) (C b) (C c) (C d))
R2 = semplifica qt

Equazione:
semplifica (Q (C a) (C b) (C c) (C d)) = semplifica qt

Decomposizione
{Q (C a) (C b) (C c) (C d) = qt}

- Q (C a) (C b) (C c) (C d) = qt -> caso termine = variabile => binding qt -> Q (C a) (C b) (C c) (C d)

Esito: OVERLAP
θ = mgu(R1, R2) = { qt -> Q (C a) (C b) (C c) (C d) }

Testimone
R1 θ = R2 θ =  semplifica (Q (C a) (C b) (C c) (C d))

## somma

### R3-R4

R3 somma x (C a) y (C b)
R4 somma x (Q a11 a12 a21 a22) y (Q b11 b12 b21 b22)

Rinomino le variabili di R3, sostituendo x e y con a3 e b3:
R3 = somma a3 (C a) b3 (C b)

Rinomino le variabili di R4, sostituendo x e y con a4 e b4:
R4 = somma a4 (Q a11 a12 a21 a22) b4 (Q b11 b12 b21 b22)


Equazione:
somma a3 (C a) b3 (C b) = somma a4 (Q a11 a12 a21 a22) b4 (Q b11 b12 b21 b22)

Decomposizione
{a3 = a4, (C a) = (Q a11 a12 a21 a22), b3 = b4, (C b) = (Q b11 b12 b21 b22)}

- a3 = a4 -> caso variabile = variabile => binding a3 -> a4
- (C a) = (Q a11 a12 a21 a22) -> FAIL per simboli diversi
- b3 = b4 -> caso variabile = variabile => binding b3 -> b4
- (C b) = (Q b11 b12 b21 b22) -> FAIL per simboli diversi

Esito: FAILURE - NESSUN OVERLAP
Fallimento su (C a) = (Q a11 a12 a21 a22) e su (C b) = (Q b11 b12 b21 b22)

### R3-R5
R3 somma x (C a) y (C b)
R5 somma _ _ _ _

Rinomino le variabili di R5, sostituendo tutti i _ con a5, b5, c5, d5:
R5 = somma a5 b5 c5 d5


Equazione:
somma x (C a) y (C b) = somma R5 = somma a5 b5 c5 d5

Decomposizione
{x = a5, (C a) = b5, y = c5, (C b) = d5}

- x = a5 -> caso variabile = variabile => binding x -> a5
- (C a) = b5 -> caso termine = variabile => binding b5 -> (C a)
- y = c5 -> caso variabile = variabile => binding y -> c5
- (C b) = d5 -> caso termine = variabile => binding d5 -> (C b)

Esito: OVERLAP
θ = mgu(R3, R5) = {x -> a5, b5 -> (C a), y -> c5, d5 -> (C b)}

Testimone
R3 θ = R5 θ =  somma a5 (C a) c5 (C b)

### R4-R5
R4 somma x (Q a11 a12 a21 a22) y (Q b11 b12 b21 b22)
R5 somma _ _ _ _

Rinomino le variabili di R5, sostituendo tutti i _ con a5, b5, c5, d5:
R5 = somma a5 b5 c5 d5

Equazione:
somma x (Q a11 a12 a21 a22) y (Q b11 b12 b21 b22) = somma R5 = somma a5 b5 c5 d5

Decomposizione
{x = a5, (Q a11 a12 a21 a22) = b5, y = c5, (Q b11 b12 b21 b22) = d5}

- x = a5 -> caso variabile = variabile => binding x -> a5
- (Q a11 a12 a21 a22) = b5 -> caso termine = variabile => binding b5 -> (Q a11 a12 a21 a22)
- y = c5 -> caso variabile = variabile => binding y -> c5
- (Q b11 b12 b21 b22) = d5 -> caso termine = variabile => binding d5 -> (Q b11 b12 b21 b22)

Esito: OVERLAP
θ = mgu(R4, R5) = {x -> a5, b5 -> (Q a11 a12 a21 a22), y -> c5, d5 -> (Q b11 b12 b21 b22)}

Testimone
R4 θ = R5 θ =  somma a5 (Q a11 a12 a21 a22) c5 (Q b11 b12 b21 b22)


## trasposta

### R6-R7
R6 trasposta (C x)
R7 trasposta (Q q11 q12 q21 q22)

Equazione:
trasposta (C x) = trasposta (Q q11 q12 q21 q22)

Decomposizione
{(C x) = (Q q11 q12 q21 q22)}

- (C x) = (Q q11 q12 q21 q22) -> FAIL per simboli diversi

Esito: FAILURE - NESSUN OVERLAP
Fallimento su (C x) = (Q q11 q12 q21 q22)
