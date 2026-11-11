"""D-1106: generates the wide War Cry wave texture (white / ash, semi-transparent).
Run: python tools/generate_war_cry_texture.py
Output: assets/vfx/war_cry_wave_tex.png (1024x512, RGBA, horizontal wrap).
"""
import math
import random
from PIL import Image, ImageDraw

W, H = 1024, 512
OUT = "assets/vfx/war_cry_wave_tex.png"

WHITE = (255, 253, 246)
CREAM = (240, 235, 222)
ASH = (156, 150, 138)

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
px = img.load()


def n2(xx, yy):
    return 0.5 + 0.5 * (
        math.sin(2 * math.pi * (3 * xx + 2 * yy) + 0.7) * 0.45
        + math.sin(2 * math.pi * (7 * xx - 5 * yy) + 2.1) * 0.30
        + math.sin(2 * math.pi * (13 * xx + 11 * yy) + 4.3) * 0.25
    )


for y in range(H):
    yy = y / H
    for x in range(W):
        xx = x / W
        band = 0.0
        for i in range(9):
            cy = 0.06 + i * 0.11
            cy += 0.022 * (n2(xx * 0.55 + i * 0.11, yy * 0.3) - 0.5)
            cy += 0.010 * math.sin(2 * math.pi * (5 * xx) + i * 1.9)
            thick = 0.020 + 0.026 * n2(xx * 0.8 + i * 0.3, 0.5)
            d = abs(yy - cy)
            b = max(0.0, 1.0 - d / thick)
            b = b * b * (3.0 - 2.0 * b)  # smoothstep
            b *= 0.28 + 0.72 * n2(xx * 0.9 + i * 0.7, yy * 0.7 + i * 0.2)
            band = max(band, b)
        haze = 0.16 * max(0.0, n2(xx * 0.35 + 0.3, yy * 0.45) - 0.42)
        streak = 0.12 * (max(0.0, math.sin(2 * math.pi * (31 * xx + 2 * yy))) ** 8)
        # Semi-transparent mask: never above 0.55 alpha.
        a = min(0.55, band * 0.55 + haze * 0.35 + streak * 0.30)
        if a <= 0.01:
            continue
        if band > 0.55:
            col = WHITE if band > 0.8 else CREAM
        elif band > 0.2:
            col = CREAM
        else:
            col = ASH
            a *= 0.7
        r = int(min(255, col[0] * (0.92 + 0.08 * band)))
        g = int(min(255, col[1] * (0.92 + 0.08 * band)))
        bch = int(min(255, col[2] * (0.92 + 0.08 * band)))
        px[x, y] = (r, g, bch, int(255 * a))

# Ash/white embers: small dots on a periodic grid (wrap horizontally).
draw = ImageDraw.Draw(img)
rng = random.Random(1106)
for i in range(180):
    cx = rng.randrange(W)
    cy = int((0.5 + 0.5 * math.sin(i * 1.7)) * H)
    radius = rng.choice([1, 1, 1, 2])
    color = rng.choice([(255, 253, 246, 170), (235, 230, 218, 150), (180, 174, 160, 130)])
    for dx in (-W, 0, W):
        draw.ellipse([cx + dx - radius, cy - radius, cx + dx + radius, cy + radius], fill=color)

img.save(OUT)
print("saved", OUT)
