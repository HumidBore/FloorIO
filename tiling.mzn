% ----------- PARAMETRI (modifica qui) -----------
int: ROOM_W = 13;  % larghezza stanza (mm)
int: ROOM_H = 13;  % altezza stanza (mm)
int: TILE_W = 10;  % larghezza piastrella (mm)
int: TILE_H = 10;  % altezza piastrella (mm)
int: MIN_PIECE = 2; % lato minimo accettabile per pezzo tagliato (mm)
int: GIUNTO = 2;     % distanza minima tra giunti (mm)
int: MAX_PIECES = 5; % Upper bound pezzi posati (piccolo per demo)
int: MAX_MOTHERS = 4; % Upper bound piastrelle acquistate (piccolo per demo)

set of int: PIECE = 1..MAX_PIECES;
set of int: MOTHERS = 1..MAX_MOTHERS;
set of int: ANGOLI = 1..4;  % 1=BL, 2=BR, 3=TL, 4=TR

% ----------- VARIABILI PRINCIPALI -----------

array[PIECE] of var 0..ROOM_W: x;       % inizio X pezzo posato
array[PIECE] of var 0..ROOM_H: y;       % inizio Y pezzo posato
array[PIECE] of var MIN_PIECE..TILE_W: w; % larghezza pezzo
array[PIECE] of var MIN_PIECE..TILE_H: h; % altezza pezzo
array[PIECE] of var bool: used;         % true se pezzo posato
array[PIECE] of var bool: intero;       % true se piastrella intera (non tagliata)
array[PIECE] of var 0..MAX_MOTHERS: madre;  % madre[j]=0 se intero, >0 se taglio
array[PIECE] of var 0..4: angolo;           % quale angolo nella madre (1-4 se taglio, 0 se intero)

% Indica se la piastrella madre j è usata almeno una volta
array[MOTHERS] of var bool: madre_usata;

% ----------- VINCOLI -----------

% 1. Ogni pezzo usato sta dentro la stanza
constraint forall(i in PIECE)(
  used[i] -> x[i]+w[i] <= ROOM_W /\ y[i]+h[i] <= ROOM_H
);

% 2. Nessuna sovrapposizione tra pezzi posati
constraint forall(i,j in PIECE where i < j)(
  used[i] /\ used[j] ->
    x[i]+w[i] <= x[j] \/ x[j]+w[j] <= x[i] \/
    y[i]+h[i] <= y[j] \/ y[j]+h[j] <= y[i]
);

% 3. Vincolo: copertura completa della stanza (grezzo, ogni cella almeno 1 pezzo la copre)
constraint
  forall(xx in 0..ROOM_W-1, yy in 0..ROOM_H-1)(
    exists(i in PIECE)(
      used[i] /\
      xx >= x[i] /\ xx < x[i]+w[i] /\
      yy >= y[i] /\ yy < y[i]+h[i]
    )
  );

% 4. Pezzo intero: dimensioni esatte e no madre
constraint forall(i in PIECE)(
  intero[i] <-> (w[i]=TILE_W /\ h[i]=TILE_H /\ madre[i]=0 /\ angolo[i]=0)
);

% 5. Pezzo tagliato: madre >0 e occupa uno degli angoli della madre
constraint forall(i in PIECE)(
  used[i] /\ not intero[i] -> (
    madre[i] > 0 /\ angolo[i] >= 1 /\ angolo[i] <= 4 /\
    w[i] <= TILE_W /\ h[i] <= TILE_H /\
    % La posizione relativa nella madre dipende dall'angolo
    let {
      var 0..TILE_W: rel_x = 
        if angolo[i]=1 \/ angolo[i]=3 then 0 else TILE_W-w[i] endif,
      var 0..TILE_H: rel_y =
        if angolo[i]=1 \/ angolo[i]=2 then 0 else TILE_H-h[i] endif
    } in
      rel_x >= 0 /\ rel_y >= 0
  )
);





% 6. Ogni madre ha massimo 4 figli, in angoli diversi
constraint forall(j in MOTHERS)(
  sum(i in PIECE)(used[i] /\ madre[i]=j) <= 4 /\
  forall(a in ANGOLI)(
    sum(i in PIECE)(used[i] /\ madre[i]=j /\ angolo[i]=a) <= 1
  )
);

% CONSTRAINT NON SOVRAPPOSIZIONE INTERNA ALLA MADRE
% Per ogni coppia di figli della stessa madre con angolo diverso:
constraint forall(i, j in PIECE where i < j)(
    used[i] /\ used[j] /\ madre[i] = madre[j] /\ madre[i] > 0 /\ angolo[i] != angolo[j] ->
      (
        % Calcola la posizione relativa (rel_x, rel_y) in madre per i e j
        let {
          var 0..TILE_W: rel_xi = if angolo[i]=1 \/ angolo[i]=3 then 0 else TILE_W-w[i] endif,
          var 0..TILE_H: rel_yi = if angolo[i]=1 \/ angolo[i]=2 then 0 else TILE_H-h[i] endif,
          var 0..TILE_W: rel_xj = if angolo[j]=1 \/ angolo[j]=3 then 0 else TILE_W-w[j] endif,
          var 0..TILE_H: rel_yj = if angolo[j]=1 \/ angolo[j]=2 then 0 else TILE_H-h[j] endif
        } in
          (rel_xi + w[i] <= rel_xj \/ rel_xj + w[j] <= rel_xi \/
           rel_yi + h[i] <= rel_yj \/ rel_yj + h[j] <= rel_yi)
      )
);

% 7. Associazione: se una madre è usata almeno una volta, deve essere "acquistata"
constraint forall(j in MOTHERS)(
  madre_usata[j] <-> (exists(i in PIECE)(used[i] /\ madre[i]=j) \/
                      exists(i in PIECE)(used[i] /\ intero[i] /\ madre[i]=j))
);

% 8. Ogni pezzo tagliato deve toccare un bordo della stanza
constraint forall(i in PIECE)(
  used[i] /\ not intero[i] ->
    (x[i]=0 \/ x[i]+w[i]=ROOM_W \/ y[i]=0 \/ y[i]+h[i]=ROOM_H)
);

% 9. Pezzi completamente interni DEVONO essere interi
constraint forall(i in PIECE)(
  used[i] /\ x[i]>0 /\ x[i]+w[i]<ROOM_W /\ y[i]>0 /\ y[i]+h[i]<ROOM_H -> intero[i]
);

% 10. Pezzi tagliati devono essere posizionati all'angolo nella stanza coerente con l'angolo del taglio nella madre
% (Questo è opzionale e può essere raffinato in funzione della logica di posa desiderata)

% 11. Distanza minima tra giunti orizzontali e verticali tra pezzi adiacenti
constraint forall(i,j in PIECE where i < j)(
  used[i] /\ used[j] /\
  ((x[i]+w[i]=x[j] /\ y[i]=y[j]) \/ (y[i]+h[i]=y[j] /\ x[i]=x[j]))
  ->
    (abs(y[i]-y[j]) >= GIUNTO /\ abs(x[i]-x[j]) >= GIUNTO)
);

% ----------- OBIETTIVO -----------
var int: tot_madri = sum(j in MOTHERS)(madre_usata[j]);
var int: tot_intere = sum(j in PIECE)(intero[j]);
var int: tot_usate = tot_madri + tot_intere;
solve minimize tot_usate;

% ----------- OUTPUT -----------
output [
  "Numero piastrelle acquistate: ", show(tot_usate), "\n\n"
] ++
[
  if fix(used[i])=1 then
    "Pezzo " ++ show(i) ++ ": (" ++ show(fix(x[i])) ++ "," ++ show(fix(y[i])) ++ ")  " ++
    show(fix(w[i])) ++ "x" ++ show(fix(h[i])) ++
    (if fix(intero[i])=1 then "  INTERO" else "  MADRE " ++ show(fix(madre[i])) ++ ", angolo " ++ show(fix(angolo[i])) endif) ++ "\n"
  else "" endif
  | i in PIECE
];

