import pathlib
from PIL import Image, ImageDraw

root = pathlib.Path(r"prototypes/vfx_library/captures")
ids = ["vortex", "funnel", "ribbon", "helix", "dissolve", "thrust", "speedlines",
       "motiontrail", "aura", "dust", "scuff", "scratch", "shockwave", "crown",
       "blastcone", "fracture", "flipbook", "sparks", "debris", "slash",
       "animeDash", "punchyImpact", "energyHelix", "vortexStudy", "stylizedSlash", "prelude"]
ps = [15, 50, 85]
cell_w, cell_h, label_h = 320, 180, 22
per_sheet = 7

for s in range(0, len(ids), per_sheet):
    chunk = ids[s:s + per_sheet]
    sheet = Image.new("RGB", (cell_w * 3, (cell_h + label_h) * len(chunk)), (10, 14, 20))
    d = ImageDraw.Draw(sheet)
    for row, eid in enumerate(chunk):
        for col, p in enumerate(ps):
            f = root / f"s2-{eid}-{p}.png"
            if not f.exists():
                continue
            im = Image.open(f).convert("RGB").resize((cell_w, cell_h))
            x, y = col * cell_w, row * (cell_h + label_h)
            sheet.paste(im, (x, y))
            d.text((x + 6, y + cell_h + 4), f"{eid}  t={p/100:.2f}", fill=(200, 230, 255))
    out = root / f"contact2-{s//per_sheet + 1}.png"
    sheet.save(out)
    print(out, sheet.size)
