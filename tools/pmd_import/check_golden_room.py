"""Golden room check (D-355).

Compares the unlit lab room crop (top wall face + floor) with the sheet's own
preview. It is a regression check, not a pixel-perfect diff: lighting, scale
and the compressed 1-tile wall make an exact match impossible.

Run after:
  Godot ... --path . scenes/tileset_lab.tscn -- --golden
  python tools/pmd_import/check_golden_room.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import pmd_sheet as ps
from audit_components import preview_crop

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "assets" / "pmd" / "dungeons" / "sky" / "raw" / "temporal_tower.png"
PROFILE = ROOT / "assets" / "pmd" / "dungeons" / "sky" / "atlas" / "temporal_tower_profile.json"
GOLDEN = ROOT / "scratch" / "tileset_lab_golden_room.png"
OUT = ROOT / "scratch" / "golden_room_compare.png"

TILE = 48
ZOOM = 2.3
VIEW_W, VIEW_H = 1280, 720
ROOM_ORIGIN = (0, 8)
CAMERA = (7 * TILE, 13 * TILE)
TOP_WALL_CELL = (6, 2)   # room row above the floor
FLOOR_CELL = (6, 3)


def font(size: int):
    for name in ("arial.ttf", "C:/Windows/Fonts/arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def screen_rect(cell: tuple[int, int]) -> tuple[int, int, int, int]:
    x0 = (ROOM_ORIGIN[0] + cell[0]) * TILE
    y0 = (ROOM_ORIGIN[1] + cell[1]) * TILE
    sx = (x0 - CAMERA[0]) * ZOOM + VIEW_W / 2
    sy = (y0 - CAMERA[1]) * ZOOM + VIEW_H / 2
    return int(sx), int(sy), int(sx + TILE * ZOOM), int(sy + TILE * ZOOM)


def resample(profile: np.ndarray, points: int = 64) -> np.ndarray:
    source = np.linspace(0.0, 1.0, profile.size)
    target = np.linspace(0.0, 1.0, points)
    return np.interp(target, source, profile)


def normalise(values: np.ndarray) -> np.ndarray:
    spread = float(values.std())
    return (values - float(values.mean())) / spread if spread > 0 else values * 0


def main() -> int:
    if not GOLDEN.exists():
        print(f"missing golden capture: {GOLDEN}")
        return 2
    sheet = Image.open(SHEET).convert("RGB")
    preview = preview_crop(sheet)
    room = Image.open(GOLDEN).convert("RGB")

    wall = room.crop(screen_rect(TOP_WALL_CELL)).convert("L")
    floor = room.crop(screen_rect(FLOOR_CELL)).convert("L")
    wall_profile = np.asarray(wall, dtype=float).mean(axis=1)
    floor_profile = np.asarray(floor, dtype=float).mean(axis=1)
    lab_profile = np.concatenate([wall_profile, floor_profile])

    # Preview centre column: row 1 top, row 2 face, ground below.
    centre = preview.crop((preview.width // 2 - 10, 0,
                           preview.width // 2 + 10, preview.height)).convert("L")
    preview_profile = np.asarray(centre, dtype=float).mean(axis=1)

    lab_norm = normalise(resample(lab_profile))
    preview_norm = normalise(resample(preview_profile))
    correlation = float(np.corrcoef(lab_norm, preview_norm)[0, 1])
    mae = float(np.abs(lab_norm - preview_norm).mean())

    # 2D band comparison: centre column of the preview resized to the lab
    # crop. It is still scale/lighting tolerant, but catches a wrong tile row.
    lab2d = Image.new("RGB", (max(wall.width, floor.width), wall.height + floor.height))
    lab2d.paste(wall.convert("RGB"), (0, 0))
    lab2d.paste(floor.convert("RGB"), (0, wall.height))
    preview2d = preview.crop((preview.width // 2 - 12, 0,
                              preview.width // 2 + 12, preview.height)).convert("RGB")
    preview2d = preview2d.resize((lab2d.width, lab2d.height), Image.BILINEAR)
    lab_arr = normalise(np.asarray(lab2d.convert("L"), dtype=float))
    prev_arr = normalise(np.asarray(preview2d.convert("L"), dtype=float))
    corr2d = float(np.corrcoef(lab_arr.ravel(), prev_arr.ravel())[0, 1])
    mae2d = float(np.abs(lab_arr - prev_arr).mean())

    wall_top = float(wall_profile[: wall_profile.size // 2].mean())
    wall_bottom = float(wall_profile[wall_profile.size // 2:].mean())
    floor_mean = float(floor_profile.mean())
    wall_ok = wall_top > wall_bottom + 4.0
    floor_ok = floor_mean < wall_top - 4.0
    ok = correlation > 0.3 and corr2d > 0.25 and wall_ok and floor_ok

    print(f"golden room: correlation {correlation:.2f}  MAE(z) {mae:.2f}  "
          f"2D corr {corr2d:.2f}  MAE2D {mae2d:.2f}")
    print(f"  wall top {wall_top:.1f} > bottom {wall_bottom:.1f}: {wall_ok}")
    print(f"  floor {floor_mean:.1f} < wall top {wall_top:.1f}: {floor_ok}")
    print(f"  result: {'OK' if ok else 'FAIL'}")

    # Side-by-side evidence.
    scale = 2
    lab_img = Image.new("RGB", (max(wall.width, floor.width), wall.height + floor.height))
    lab_img.paste(wall.convert("RGB"), (0, 0))
    lab_img.paste(floor.convert("RGB"), (0, wall.height))
    lab_big = lab_img.resize((lab_img.width * scale, lab_img.height * scale), Image.NEAREST)
    preview_big = preview.resize((preview.width * scale, preview.height * scale), Image.NEAREST)
    canvas = Image.new("RGB", (lab_big.width + preview_big.width + 30, max(lab_big.height, preview_big.height) + 50), (18, 18, 18))
    draw = ImageDraw.Draw(canvas)
    big, small = font(13), font(10)
    canvas.paste(lab_big, (10, 30))
    canvas.paste(preview_big, (lab_big.width + 20, 30))
    draw.text((10, 6), "lab room: top wall + floor", font=small, fill=(255, 220, 80))
    draw.text((lab_big.width + 20, 6), "sheet preview", font=small, fill=(255, 220, 80))
    draw.text((10, canvas.height - 16),
              f"corr {correlation:.2f} | 2D {corr2d:.2f} | wall {wall_top:.0f}>{wall_bottom:.0f} | floor {floor_mean:.0f} | {'OK' if ok else 'FAIL'}",
              font=small, fill=(160, 220, 160) if ok else (240, 130, 110))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)
    print(f"evidence: {OUT.relative_to(ROOT).as_posix()}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
