"""Monta as folhas de contato (3 referências selecionadas por efeito)."""
from __future__ import annotations

import json
import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent
IMG = ROOT / "images"
OUT = ROOT / "contatos"
OUT.mkdir(exist_ok=True)

def font(size):
    for f in ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/segoeui.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()

F_T = font(16)
F_S = font(11)
F_XS = font(10)

data = json.loads((ROOT / "refs.json").read_text(encoding="utf-8"))
W, H, BAR = 430, 242, 76

for cat in data:
    sheet = Image.new("RGB", (W * 3, H + BAR + 18), (9, 13, 19))
    d = ImageDraw.Draw(sheet)
    for col, n in enumerate(cat["selected"]):
        c = next(x for x in cat["candidates"] if x["n"] == n)
        f = IMG / f"{cat['id']}-{n}.jpg"
        x = col * W
        if f.exists():
            try:
                im = Image.open(f).convert("RGB")
                im.thumbnail((W, H))
                sheet.paste(im, (x + (W - im.width) // 2, (H - im.height) // 2))
            except Exception:
                pass
        else:
            d.rectangle([x + 8, 8, x + W - 8, H - 8], outline=(40, 60, 80), width=1)
            d.text((x + 18, 24), "imagem não baixada", font=F_T, fill=(120, 145, 170))
            d.text((x + 18, 48), "link verificado; ver refs.json", font=F_S, fill=(90, 110, 130))
        d.text((x + 8, H + 6), f"{n}. {c['title'][:58]}", font=F_T, fill=(225, 240, 255))
        d.text((x + 8, H + 28), c["why"][:82], font=F_XS, fill=(130, 160, 185))
        d.text((x + 8, H + 44), c["url"][:74], font=F_XS, fill=(80, 140, 175))
    d.text((8, H + BAR + 2), f"{cat['lib']} · {cat['name']}  —  contato de referências (3 selecionadas de 5)", font=F_S, fill=(85, 230, 255))
    sheet.save(OUT / f"contato-{cat['id']}.png")
    print("contato", cat["id"])
