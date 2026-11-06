"""Build the active Temporal Tower atlas from the Time/Darkness sheet.

Reference: The Spriters Resource, Explorers of Time/Darkness > Backgrounds >
Temporal Tower (asset 84824). The top-right preview of that sheet shows the
intended order: wall top -> wall face -> ground -> water.

Atlas, 21 tiles of 48 px:

  0..8   wall top 3x3 (Walls, C3..C5 R0..R2)
  9..17  ground 3x3 (Ground, C12..C14 R0..R2)
  18..20 wall face row (Wall Alt. 1, C6..C8 R1)

The face row is the center row of the Wall Alt. 1 block; the left/center/right
tiles are used on the face overlay that sits on the floor cell in front of the
wall top (two-row PMD wall).

Usage (from the repository root):
    python tools/pmd_import/build_time_darkness_atlas.py
"""

from __future__ import annotations

import os

from PIL import Image

TILE = 24
ORIGIN_X = 14
ORIGIN_Y = 160
CROP_X = 4
CROP_Y = 3
CROP_SIZE = 19
OUT_SIZE = 48

WALL_TOP = [(c, r) for r in range(3) for c in range(3, 6)]
GROUND = [(c, r) for r in range(3) for c in range(12, 15)]
FACE = [(6, 1), (7, 1), (8, 1)]
CELLS = WALL_TOP + GROUND + FACE


def color_distance(a, b) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def make_cleaner(src: Image.Image):
    # The sheet background is the flat teal at the outer border; the cyan
    # grid lines are brighter. The art (blue stone, brown ground) is not
    # close to either, so the blue walls are preserved.
    bg = src.getpixel((2, 2))

    def is_bg(p) -> bool:
        r, g, b, a = p
        if a == 0:
            return True
        if color_distance((r, g, b), (bg[0], bg[1], bg[2])) <= 22:
            return True
        return b > 180 and g > 180 and r < 170

    def clean(im: Image.Image) -> None:
        px = im.load()
        for y in range(im.height):
            last = None
            for x in range(im.width):
                p = px[x, y]
                if is_bg(p):
                    if last is not None:
                        px[x, y] = last
                else:
                    last = p
            last = None
            for x in range(im.width - 1, -1, -1):
                p = px[x, y]
                if is_bg(p):
                    if last is not None:
                        px[x, y] = last
                else:
                    last = p
        for x in range(im.width):
            last = None
            for y in range(im.height):
                p = px[x, y]
                if is_bg(p):
                    if last is not None:
                        px[x, y] = last
                else:
                    last = p
            last = None
            for y in range(im.height - 1, -1, -1):
                p = px[x, y]
                if is_bg(p):
                    if last is not None:
                        px[x, y] = last
                else:
                    last = p

    return clean


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    src_path = os.path.join(root, "assets", "pmd", "dungeons", "time_darkness", "raw", "temporal_tower.png")
    out_path = os.path.join(root, "assets", "pmd", "dungeons", "time_darkness", "atlas", "temporal_tower_atlas.png")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    src = Image.open(src_path).convert("RGBA")
    clean = make_cleaner(src)
    out = Image.new("RGBA", (len(CELLS) * OUT_SIZE, OUT_SIZE), (0, 0, 0, 0))
    for i, (column, row) in enumerate(CELLS):
        x = ORIGIN_X + column * TILE + CROP_X
        y = ORIGIN_Y + row * TILE + CROP_Y
        tile = src.crop((x, y, x + CROP_SIZE, y + CROP_SIZE))
        tile = tile.resize((OUT_SIZE, OUT_SIZE), Image.NEAREST)
        clean(tile)
        out.paste(tile, (i * OUT_SIZE, 0))
    out.save(out_path)
    print(out_path, out.size, "background:", src.getpixel((2, 2)))


if __name__ == "__main__":
    main()
