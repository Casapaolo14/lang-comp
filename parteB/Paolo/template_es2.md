Coppia Ri - Rj

Teste in forma prefissa (variabili rinominate con pedice i, j):
Ri = ...
Rj = ...

Equazione:
Ri = Rj

Decomposizione (ricorsiva, un livello alla volta finché non si arriva 
a variabili/costanti):
{f(t1,...,tn) = f(s1,...,sn)}  =>  {t1=s1, ..., tn=sn}   [stesso simbolo]

Per ogni equazione ottenuta, quale caso si applica:
- x = x                        -> eliminata, nessun binding
- variabile = termine/variabile -> binding x -> t (se occur check ok)
- simbolo ≠ simbolo (entrambi costruiti) -> FAIL, stop

Esito:
- Se FAIL in qualche equazione -> Ri e Rj NON overlappano 
  (specifico quale equazione fallisce e perché)
- Se nessun FAIL -> Ri e Rj overlappano, 
  θ = mgu(Ri, Rj) = { binding1, binding2, ... }

Se overlap, testimone più generale:
Riθ = Rjθ = ...   (verifica che coincidano)
-> riscritto in Haskell: ...