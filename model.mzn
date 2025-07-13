int: n;
int: maxBins;
int: PW;
int: PH;
array[1..n] of int: w;
array[1..n] of int: h;

array[1..n] of var 0..PW: x;
array[1..n] of var 0..PH: y;
array[1..n] of var 1..maxBins: bin;
array[1..maxBins] of var bool: binUsed;
array[1..n] of var bool: rotated;

array[1..n] of var int: ww;
array[1..n] of var int: hh;

% Collega le dimensioni effettive alla rotazione
constraint forall(i in 1..n)(
    (rotated[i] -> (ww[i] = h[i] /\ hh[i] = w[i]))
    /\
    (not rotated[i] -> (ww[i] = w[i] /\ hh[i] = h[i]))
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

% Simmetria
constraint
    forall(j in 1..maxBins-1)(
        binUsed[j] >= binUsed[j+1]
    );

solve minimize sum(j in 1..maxBins)(binUsed[j]);
