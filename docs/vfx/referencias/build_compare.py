"""Comparativo visual: protótipo atual x 3 referências selecionadas."""
import json
import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent
IMG = ROOT / "images"
CAP = pathlib.Path(r"C:\Users\zerke\OneDrive\Área de Trabalho\Z\crawlmon\prototypes\vfx_library\captures")
OUT = ROOT / "contatos"
OUT.mkdir(exist_ok=True)

def font(size):
    for f in ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/segoeui.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()

F_T = font(15)
F_S = font(10)

data = {c["id"]: c for c in json.loads((ROOT / "refs.json").read_text(encoding="utf-8"))}

W, H, BAR = 380, 214, 58
for cid in ("crown", "vortex"):
    cat = data[cid]
    sheet = Image.new("RGB", (W * 4, H + BAR), (9, 13, 19))
    d = ImageDraw.Draw(sheet)

    # painel 0: protótipo atual
    cur = CAP / f"f-{cid}-50.png"
    if cur.exists():
        im = Image.open(cur).convert("RGB")
        im.thumbnail((W, H))
        sheet.paste(im, ((W - im.width) // 2, (H - im.height) // 2))
    d.text((8, H + 5), "ATUAL — protótipo Three.js", font=F_T, fill=(255, 140, 120))
    d.text((8, H + 25), "cones/anel + aditivo; sem hierarquia de silhueta", font=F_S, fill=(170, 140, 140))

    for k, n in enumerate(cat["selected"], start=1):
        c = next(x for x in cat["candidates"] if x["n"] == n)
        x = k * W
        f = IMG / f"{cid}-{n}.jpg"
        if f.exists():
            im = Image.open(f).convert("RGB")
            im.thumbnail((W, H))
            sheet.paste(im, (x + (W - im.width) // 2, (H - im.height) // 2))
        else:
            d.rectangle([x + 8, 8, x + W - 8, H - 8], outline=(40, 60, 80), width=1)
            d.text((x + 16, 24), "capa não baixada", font=F_T, fill=(120, 145, 170))
            d.text((x + 16, 46), "link verificado no dossiê", font=F_S, fill=(90, 110, 130))
        d.text((x + 8, H + 5), f"REF {k} — {c['title'][:44]}", font=F_T, fill=(200, 230, 255))
        d.text((x + 8, H + 25), c["why"][:62], font=F_S, fill=(130, 160, 185))

    out = OUT / f"COMPARATIVO-{cid}.png"
    sheet.save(out)
    print(out)
