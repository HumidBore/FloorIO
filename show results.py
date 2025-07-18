import matplotlib.pyplot as plt
import re

# ==== Parametri da modificare (o chiedere all'utente) ====
ROOM_W = 13
ROOM_H = 13
TILE_W = 10
TILE_H = 10

# ==== Inserisci qui l'output copincollato (puoi leggere da file se preferisci) ====
output = """
Pezzo 1: (4,0)  9x3  MADRE 1, angolo 3
Pezzo 2: (6,3)  7x10  MADRE 1, angolo 1, ROT
Pezzo 3: (0,3)  6x10  MADRE 2, angolo 1
Pezzo 4: (2,0)  2x3  MADRE 2, angolo 4
Pezzo 5: (0,0)  2x3  MADRE 2, angolo 2
"""  # <<-- Qui copia la tua soluzione MiniZinc

# ==== PARSING OUTPUT ====
pieces = []
madri_usate = set()
for line in output.strip().splitlines():
    m = re.match(r"Pezzo (\d+): \((\d+),(\d+)\)\s+(\d+)x(\d+)\s+(INTERO|MADRE (\d+), angolo (\d+)(, ROT)?)", line.strip())
    if not m: continue
    idx = int(m.group(1))
    x, y = int(m.group(2)), int(m.group(3))
    w, h = int(m.group(4)), int(m.group(5))
    if m.group(6) == "INTERO":
        tipo = "INTERO"
        madre = None
        angolo = None
        rot = False
    else:
        tipo = "MADRE"
        madre = int(m.group(7))
        madri_usate.add(madre)
        angolo = int(m.group(8))
        rot = (m.group(9) is not None)
    pieces.append(dict(idx=idx, x=x, y=y, w=w, h=h, tipo=tipo, madre=madre, angolo=angolo, rot=rot))

# ==== VISUALIZZA DISPOSIZIONE NELLA STANZA ====
plt.figure(figsize=(6,6))
for piece in pieces:
    color = "tab:green" if piece["tipo"]=="INTERO" else "tab:blue"
    plt.gca().add_patch(plt.Rectangle(
        (piece["x"], piece["y"]), piece["w"], piece["h"],
        fill=True, color=color, alpha=0.5, edgecolor="black", lw=2
    ))
    plt.text(piece["x"]+piece["w"]/2, piece["y"]+piece["h"]/2, f"{piece['idx']}", ha='center', va='center', fontsize=10)
plt.xlim(0, ROOM_W)
plt.ylim(0, ROOM_H)
plt.gca().set_aspect("equal")
plt.title("Disposizione pezzi nella stanza\nVerde=Intero, Blu=Taglio")
plt.xlabel("X [mm]")
plt.ylabel("Y [mm]")

# ==== VISUALIZZA DISPOSIZIONE TAGLI IN OGNI MADRE ====
for madre in sorted(madri_usate):
    fig, ax = plt.subplots(figsize=(4,4))
    ax.add_patch(plt.Rectangle((0,0), TILE_W, TILE_H, fill=False, edgecolor='black', lw=2))
    for piece in pieces:
        if piece["madre"] != madre: continue
        # Calcola posizione relativa nella madre considerando angolo e rotazione
        w, h = piece["w"], piece["h"]
        if piece["rot"]:
            w, h = h, w
        # Angoli: 1=BL, 2=BR, 3=TL, 4=TR
        if piece["angolo"] == 1: # bottom left
            rel_x, rel_y = 0, 0
        elif piece["angolo"] == 2: # bottom right
            rel_x, rel_y = TILE_W - w, 0
        elif piece["angolo"] == 3: # top left
            rel_x, rel_y = 0, TILE_H - h
        elif piece["angolo"] == 4: # top right
            rel_x, rel_y = TILE_W - w, TILE_H - h
        else:
            rel_x, rel_y = 0, 0
        ax.add_patch(plt.Rectangle(
            (rel_x, rel_y), w, h,
            fill=True, color="tab:orange", alpha=0.7, edgecolor="red", lw=2
        ))
        ax.text(rel_x+w/2, rel_y+h/2, f"P{piece['idx']}", ha='center', va='center', fontsize=10, color='black')
    ax.set_xlim(0, TILE_W)
    ax.set_ylim(0, TILE_H)
    ax.set_aspect("equal")
    ax.set_title(f"Tagli su MADRE {madre}")
    ax.set_xlabel("X in madre [mm]")
    ax.set_ylabel("Y in madre [mm]")

plt.show()
