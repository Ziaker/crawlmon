"""Monta as evidências por componente: 3 instantes + identificação.

Uso: python prototypes/vfx_library/build_evidence.py
Lê captures/f-<id>-<15|50|85>.png e grava evidence/<LIB>-<id>.png.
"""
from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent
SRC = ROOT / "captures"
OUT = ROOT / "evidence"
OUT.mkdir(exist_ok=True)

def font(size: int):
    for f in ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/segoeui.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()

FONT_T = font(18)
FONT_S = font(12)

ITEMS = [
    ("LIB-VFX-01", "vortex", "Vortex Mesh", "cascas de funil + disco espiral + partículas"),
    ("LIB-VFX-02", "funnel", "Tornado / Funnel", "três funis com twist e ondulação"),
    ("LIB-VFX-03", "ribbon", "Spiral Ribbon", "fita 3D sobre hélice"),
    ("LIB-VFX-04", "helix", "Helix Cylinder", "três correntes + núcleo"),
    ("LIB-VFX-05", "dissolve", "Spiral Erosion", "ruído + espiral + discard"),
    ("LIB-VFX-06", "thrust", "Thrust Cone", "cone com listras longitudinais"),
    ("LIB-VFX-07", "speedlines", "Speed Lines", "instâncias com espessura"),
    ("LIB-VFX-08", "motiontrail", "Motion Trail", "fita do histórico de posição"),
    ("LIB-VFX-09", "aura", "Aura Burst", "traços radiais + anel"),
    ("LIB-VFX-10", "dust", "Dust Trail", "poeira emitida no percurso"),
    ("LIB-VFX-11", "scuff", "Brake Dust", "leque + jato direcional"),
    ("LIB-VFX-12", "scratch", "Ground Scratch", "sulcos + fragmentos"),
    ("LIB-VFX-13", "shockwave", "Shockwave Ring", "anéis com atraso"),
    ("LIB-VFX-14", "crown", "Impact Crown", "coroa de pontas com base"),
    ("LIB-VFX-15", "blastcone", "Blast Cone", "cone no contato, boca para fora"),
    ("LIB-VFX-16", "fracture", "Ground Fracture", "rachaduras radiais ramificadas"),
    ("LIB-VFX-17", "flipbook", "Anime Impact Flipbook", "atlas real 4×4 do projeto"),
    ("LIB-VFX-18", "sparks", "Kinetic Sparks", "faíscas orientadas pela velocidade"),
    ("LIB-VFX-19", "debris", "Directional Debris", "fragmentos com rotação"),
    ("LIB-VFX-20", "slash", "Slash Arc", "fita em arco com revelação"),
    ("DEMO-01", "animeDash", "Anime Dash", "aura + propulsão + linhas + rastro + poeira + frenagem"),
    ("DEMO-02", "punchyImpact", "Punchy Anime Impact", "flipbook + coroa + onda + cone + faíscas + fragmentos"),
    ("DEMO-03", "energyHelix", "Energy Helix", "fita + feixe + erosão"),
    ("DEMO-04", "vortexStudy", "Vortex / Tornado Study", "vórtice + tornado + erosão"),
    ("DEMO-05", "stylizedSlash", "Stylized Slash", "rastro + arco + faíscas"),
    ("EXTRA", "prelude", "Attack Prelude", "carga + traço + trava no alvo"),
]

PANEL_W, PANEL_H = 640, 360
BAR_H = 46

for lib, eid, name, tech in ITEMS:
    frames = [SRC / f"f-{eid}-{p}.png" for p in (15, 50, 85)]
    if not all(f.exists() for f in frames):
        print("faltando:", eid)
        continue
    canvas = Image.new("RGB", (PANEL_W * 3, PANEL_H + BAR_H), (8, 12, 18))
    d = ImageDraw.Draw(canvas)
    for i, f in enumerate(frames):
        canvas.paste(Image.open(f).convert("RGB"), (i * PANEL_W, BAR_H))
    d.text((10, 6), f"{lib} · {name}", font=FONT_T, fill=(230, 245, 255))
    d.text((10, 28), f"{tech}   |   t = 15% / 50% / 85%   |   protótipo funcional, aprovação visual pendente", font=FONT_S, fill=(130, 160, 185))
    out = OUT / f"{lib}-{eid}.png"
    canvas.save(out)
    print(out.name)
