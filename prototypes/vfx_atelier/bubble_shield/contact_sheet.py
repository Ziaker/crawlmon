from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(r"C:\Users\zerke\OneDrive\Área de Trabalho\Z\crawlmon")
SRC = ROOT / "test_captures" / "bubble_shield_sheet"
OUT = ROOT / "test_captures" / "bubble_shield_options.png"

P = {
    "Aw": SRC / "A_windup.png",
    "Bw": SRC / "B_windup.png",
    "Cw": SRC / "C_windup.png",
    "Dw": SRC / "D_windup.png",
    "Aa": SRC / "A_active.png",
    "Ah": SRC / "A_hit.png",
    "Ae": SRC / "A_expire.png",
    "Ba": SRC / "B_active.png",
    "Bh": SRC / "B_hit.png",
    "Be": SRC / "B_expire.png",
    "Ca": SRC / "C_active.png",
    "Ch": SRC / "C_hit.png",
    "Ce": SRC / "C_expire.png",
    "Da": SRC / "D_active.png",
    "Dh": SRC / "D_hit.png",
    "De": SRC / "D_expire.png",
}
W, H = 1920, 1264
BG = (5, 11, 18)
MINT = (183, 255, 201)
MUTED = (122, 160, 170)
WHITE = (233, 246, 247)
F_BIG = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 52)
F_SUB = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 21)
F_LABEL = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 22)
F_SMALL = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 17)

canvas = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(canvas)
draw.rectangle([0, 0, W, 108], fill=(4, 10, 15))
draw.text((44, 24), "BUBBLE SHIELD", font=F_BIG, fill=MINT)
draw.text(
    (46, 82),
    "4 opções visuais · wind-up em coroa-vórtice · Three.js + Quarks",
    font=F_SMALL,
    fill=MUTED,
)
draw.text(
    (W - 46, 28),
    "25 + MAG POR ALIADO   ·   8,0 s   ·   ALL ALLIES",
    font=F_SUB,
    fill=WHITE,
    anchor="ra",
)
draw.text(
    (W - 46, 60),
    "SEM TIPO   ·   MAG demo 9 → escudo 34",
    font=F_SUB,
    fill=MINT,
    anchor="ra",
)

MX, GAP = 44, 12
CW = (W - MX * 2 - GAP * 3) // 4
CH = 252


def cell(key, x, y, caption, sub=""):
    ih = CH - 44
    im = ImageOps.fit(Image.open(P[key]).convert("RGB"), (CW, ih), method=Image.LANCZOS)
    canvas.paste(im, (x, y + 44))
    draw.rectangle([x, y, x + CW, y + 44], fill=(4, 12, 18))
    draw.text((x + 12, y + 10), caption, font=F_LABEL, fill=WHITE)
    if sub:
        draw.text((x + 12, y + 31), sub, font=F_SMALL, fill=MUTED)
    draw.rectangle([x, y, x + CW, y + CH], outline=(38, 82, 94), width=1)


ty = 126
cell("Aw", MX, ty, "WIND-UP · A", "coroa de espuma")
cell("Bw", MX + (CW + GAP), ty, "WIND-UP · B", "coroa de colmeia")
cell("Cw", MX + (CW + GAP) * 2, ty, "WIND-UP · C", "coroa prismática")
cell("Dw", MX + (CW + GAP) * 3, ty, "WIND-UP · D", "coroa de lâminas de água")

gy = ty + CH + 26
cols = [
    ("A", "BOLHA DE SABÃO", "A"),
    ("B", "COLMEIA", "B"),
    ("C", "PRISMÁTICA", "C"),
    ("D", "AEGIS AQUÁTICA", "D"),
]
rows = [("ATIVO", "a"), ("ACERTO", "h"), ("EXPIRAÇÃO", "e")]
for ci, (letter, name, key) in enumerate(cols):
    x = MX + ci * (CW + GAP)
    for ri, (row_name, suffix) in enumerate(rows):
        y = gy + ri * (CH + GAP)
        cell(key + suffix, x, y, f"{letter} · {name}", row_name)

fy = H - 66
draw.rectangle([0, fy, W, H], fill=(4, 10, 15))
draw.text(
    (44, fy + 18),
    "D-323 · 25 + MAG por aliado · 8,0 s · reserva individual · SEM TIPO",
    font=F_SMALL,
    fill=MUTED,
)
draw.text(
    (W - 44, fy + 18),
    "opção D incorpora a referência externa · nenhum código do jogo alterado",
    font=F_SMALL,
    fill=MUTED,
    anchor="ra",
)

OUT.parent.mkdir(parents=True, exist_ok=True)
canvas.save(OUT, quality=95)
print(OUT, canvas.size)
