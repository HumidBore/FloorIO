% Questo script ottimizza i tagli partendo dai pezzi da produrre
int: n;
int: PW;
int: PH;
array[1..n] of int: w;
array[1..n] of int: h;
% Calcolo Lower Bound
int: lb = ceil(sum(i in 1..n)(w[i] * h[i]) / (PW * PH));
int: maxBins = n; % puoi anche mettere = lb se vuoi solo soluzioni ottimali

array[1..n] of var 0..PW: x;
array[1..n] of var 0..PH: y;
array[1..n] of var 1..maxBins: bin;
array[1..maxBins] of var bool: binUsed;
array[1..n] of var bool: rotated;

int: max_dim = max(PW, PH);
array[1..n] of var 0..max_dim: ww;
array[1..n] of var 0..max_dim: hh;

% Nuovo vincolo **lower bound**
constraint sum(j in 1..maxBins)(bool2int(binUsed[j])) >= lb;

% Collega le dimensioni effettive alla rotazione
constraint forall(i in 1..n)(
    (rotated[i] -> (ww[i] = h[i] /\ hh[i] = w[i]))
    /\
    (not rotated[i] -> (ww[i] = w[i] /\ hh[i] = h[i]))
);

% limitare direttamente i domini di x e y considerando disposizioni su angoli
constraint forall(i in 1..n)(
    (x[i]=0 \/ x[i]=PW-ww[i])
);
constraint forall(i in 1..n)(
    (y[i]=0 \/ y[i]=PH-hh[i])
);

% Rettangolo sta dentro il bin
constraint
    forall(i in 1..n)(
        x[i] + ww[i] <= PW /\
        y[i] + hh[i] <= PH
    );

% Se un rettangolo è assegnato al bin j, allora bin j è usato
constraint
    forall(i in 1..n, j in 1..maxBins)(
        (bin[i] == j) -> binUsed[j]
    );

% Non sovrapposizione tra rettangoli nello stesso bin
constraint
    forall(i, k in 1..n where i < k)(
        bin[i] == bin[k] -> (
            x[i] + ww[i] <= x[k] \/
            x[k] + ww[k] <= x[i] \/
            y[i] + hh[i] <= y[k] \/
            y[k] + hh[k] <= y[i]
        )
    );
    

% Riduzione dei domini considerando l'imposizione del contatto con almeno due bordi contigui
constraint forall(i in 1..n) (
    (x[i]=0 /\ y[i]=0) \/
    (x[i]=0 /\ y[i]=PH-hh[i]) \/
    (x[i]=PW-ww[i] /\ y[i]=0) \/
    (x[i]=PW-ww[i] /\ y[i]=PH-hh[i])
);



% Simmetria: usa sempre i primi bin
constraint
    forall(j in 1..maxBins-1)(
        binUsed[j] >= binUsed[j+1]
    );
% Simmetria: evita configurazioni bin=[2,1,1] e bin=[1,2,2] 
constraint forall(i in 1..n-1)(
    bin[i] <= bin[i+1]
);

% Simmetria: fissare ordine dei pezzi uguali
constraint forall(i, j in 1..n where i < j /\ w[i]=w[j] /\ h[i]=h[j])(
    bin[i] <= bin[j]
);

%Simmetria: covenzione rotazioni
% un pezzo nel BLC non è mai ruotato. Perchè la configurazione sarebbe speculare a rotazione e TLC
constraint forall(i in 1..n)(
    (x[i]=0 /\ y[i]=0) -> not rotated[i]
);
constraint forall(i in 1..n)(
    (x[i]=PW-ww[i] /\ y[i]=PH-hh[i]) -> not rotated[i]
);



% Simmetria: pezzi quadrati non possono ruotare
constraint forall(i in 1..n where w[i]=h[i])(
    rotated[i]=false
);



%solve minimize sum(j in 1..maxBins)(binUsed[j]);  % 41s

solve ::  % prima bin, poi rotazione (influenzano i valori di x, h e degli angoli toccati)
    int_search(
        [bin[i] | i in 1..n] ++ [rotated[i] | i in 1..n] ++ [x[i] | i in 1..n] ++ [y[i] | i in 1..n],
        first_fail,
        indomain_min,
        complete
    )
    minimize sum(j in 1..maxBins)(binUsed[j]);

