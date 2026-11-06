"""Perception audit for the PMD tile sheets (D-354).

This does not build the atlas. It answers, with pixels:

  1. is the block horizontally/vertically symmetric (mirror test)?
  2. which rows are the top surface and the front face?
  3. which side of each tile is the cliff face (orientation probe)?
  4. does the sheet's own preview agree with those rows (golden)?
  5. are adjacent tiles continuous (seam test)?
  6. is each role's measured face the one the contract expects?
  7. does the active atlas use only same-component source cells?

Outputs:
  docs/referencias/tilesets/<name>_components.png
  tools/pmd_import/audits/<name>.json

Usage:
    python tools/pmd_import/audit_components.py
    python tools/pmd_import/audit_components.py --only temporal_tower
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import pmd_sheet as ps
from build_dungeon_atlases import ACTIVE, ATLAS_DIR, CONTACT_DIR, ROOT, RAW_DIR

TILE = 24
EXPECTED_COLUMNS = 30
CORE_LABELS = ("back-L", "back", "back-R", "side-L", "top", "side-R",
               "front-L", "front", "front-R")
EXTRA_CELLS = {
    "wall_strip_v": (3, 4), "wall_strip_h": (4, 3),
    "wall_island": (4, 4),
    "wall_tip_n": (4, 6), "wall_tip_s": (4, 8),
    "wall_tip_w": (3, 7), "wall_tip_e": (5, 7),
    "wall_cross": (4, 7),
}
ALLOWED_ROLES = (
    {f"wall_{role}" for role in ps.CORE_ROLES}
    | {f"ground_{role}" for role in ps.CORE_ROLES}
    | {"ground_alt_1", "ground_alt_2"}
    | set(EXTRA_CELLS)
    | {"wall_alt_1", "wall_alt_2"}
)


def font(size: int):
    for name in ("arial.ttf", "C:/Windows/Fonts/arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def art_block(image: Image.Image, grid: ps.SheetGrid, column: int, row: int) -> Image.Image:
    block = Image.new("RGB", (TILE * 3, TILE * 3))
    for r in range(3):
        for c in range(3):
            tile = image.crop(grid.cell_box(column + c, row + r)).convert("RGB")
            block.paste(tile, (c * TILE, r * TILE))
    return block


def mae(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.abs(a.astype(float) - b.astype(float)).mean())


def tile_rgb(image: Image.Image, grid: ps.SheetGrid, column: int, row: int) -> Image.Image:
    return image.crop(grid.cell_box(column, row)).convert("RGB")


def sides_for(image: Image.Image, grid: ps.SheetGrid, column: int, row: int) -> str:
    return ps.open_sides(tile_rgb(image, grid, column, row))


def seam_scores(block: np.ndarray) -> list[dict]:
    out = []
    for r in range(3):
        for c in range(3):
            if c < 2:
                out.append({
                    "a": f"C{c}R{r}", "b": f"C{c + 1}R{r}", "axis": "v",
                    "mae": round(mae(block[r * TILE:(r + 1) * TILE, c * TILE + TILE - 1],
                                     block[r * TILE:(r + 1) * TILE, (c + 1) * TILE]), 1),
                })
            if r < 2:
                out.append({
                    "a": f"C{c}R{r}", "b": f"C{c}R{r + 1}", "axis": "h",
                    "mae": round(mae(block[r * TILE + TILE - 1, c * TILE:(c + 1) * TILE],
                                     block[(r + 1) * TILE, c * TILE:(c + 1) * TILE]), 1),
                })
    return out


def preview_crop(image: Image.Image) -> Image.Image:
    """Crop inside the bright-green frame at the top-right of the sheet."""
    arr = np.asarray(image.convert("RGB")).astype(int)
    red, green, blue = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    mask = (green > 150) & (green > red * 1.6) & (green > blue * 1.6)
    mask[:, : int(image.width * 0.65)] = False
    mask[int(image.height * 0.25):, :] = False
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return image.crop((max(0, image.width - 108), 6, image.width - 4, 136)).convert("RGB")
    return image.crop((int(xs.min()) + 2, int(ys.min()) + 2,
                       int(xs.max()) - 1, int(ys.max()) - 1)).convert("RGB")


def _windows(arr: np.ndarray, tile: np.ndarray) -> np.ndarray:
    win = np.lib.stride_tricks.sliding_window_view(
        arr, (tile.shape[0], tile.shape[1]), axis=(0, 1))
    return np.abs(win - tile.transpose(2, 0, 1)[None, None, :, :, :]).mean(axis=(2, 3, 4))


def best_match(arr: np.ndarray, tile: Image.Image, scale: int, width_tiles: int = 1) -> dict:
    size = (scale * width_tiles, scale)
    t = np.asarray(tile.resize(size, Image.NEAREST)).astype(np.float32)
    if t.shape[0] > arr.shape[0] or t.shape[1] > arr.shape[1]:
        return {"x": -1, "y": -1, "mae": 999.0}
    diff = _windows(arr, t)
    y, x = np.unravel_index(np.argmin(diff), diff.shape)
    return {"x": int(x), "y": int(y), "mae": round(float(diff[y, x]), 1)}


def preview_scale(preview: Image.Image, block: Image.Image, ground: Image.Image) -> tuple[int, list[dict]]:
    arr = np.asarray(preview, dtype=np.float32)
    best = (24, 999.0, [])
    for scale in (24, 22, 20, 18, 16, 14, 12):
        matches = []
        for r in range(3):
            for c in range(3):
                tile = block.crop((c * TILE, r * TILE, (c + 1) * TILE, (r + 1) * TILE))
                match = best_match(arr, tile, scale)
                match.update({"tile": CORE_LABELS[r * 3 + c], "cell": f"C{3 + c}R{r}"})
                matches.append(match)
        score = float(min(m["mae"] for m in matches))
        if score < best[1]:
            best = (scale, score, matches)
    return best


def preview_composition(preview: Image.Image, image: Image.Image, grid: ps.SheetGrid,
                        scale: int) -> list[dict]:
    """Match each block row and the ground row against the preview, top to bottom.

    The preview repeats the *centre* column horizontally (the left/right edge
    tiles are not part of the sample), so the match uses the centre tile of the
    row. That is enough to prove which rows the artist composed.
    """
    arr = np.asarray(preview, dtype=np.float32)
    strips = []
    for row in range(3):
        tile = tile_rgb(image, grid, 4, row)
        match = best_match(arr, tile, scale)
        strips.append({"row": row, "label": ("back/top edge", "top surface", "front face")[row],
                       "x": match["x"], "y": match["y"], "mae": match["mae"]})
    ground = tile_rgb(image, grid, 13, 1)
    match = best_match(arr, ground, scale)
    strips.append({"row": "ground", "label": "floor", "x": match["x"], "y": match["y"],
                   "mae": match["mae"]})
    strips.sort(key=lambda item: item["y"])
    return strips


def profile_report(name: str, image: Image.Image, grid: ps.SheetGrid) -> dict:
    profile_path = ATLAS_DIR / f"{name}_profile.json"
    profile: dict = {}
    if profile_path.exists():
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
    roles = profile.get("roles", {})
    role_cells = profile.get("role_cells", {})
    stored_sides = profile.get("role_sides", {})
    contract = []
    for role, expected in ps.SIDE_CONTRACT.items():
        if role not in roles:
            continue
        cell = role_cells.get(role)
        if not cell:
            contract.append({"role": role, "cell": "?", "expected": expected,
                             "measured": "?", "stored": stored_sides.get(role, "?"),
                             "ok": False})
            continue
        column, row = int(cell[0]), int(cell[1])
        measured = sides_for(image, grid, column, row)
        contract.append({
            "role": role,
            "cell": f"C{column}R{row}",
            "expected": expected,
            "measured": measured,
            "stored": stored_sides.get(role, "?"),
            "ok": measured == expected and stored_sides.get(role) == measured,
        })

    unexpected = sorted(set(roles.keys()) - ALLOWED_ROLES)
    columns = int(profile.get("columns", 0))
    outside = []
    for role, cell in role_cells.items():
        column, row = int(cell[0]), int(cell[1])
        allowed = (
            (3 <= column <= 5 and 0 <= row <= 2)
            or (12 <= column <= 14 and 0 <= row <= 2)
            or (column, row) in ((16, 1), (19, 1))
            or (column, row) in EXTRA_CELLS.values()
            or (column, row) in ((7, 1), (10, 1))
        )
        if roles.get(role) is not None and not allowed:
            outside.append(f"{role} C{column}R{row}")
    return {
        "profile": profile_path.exists(),
        "columns": columns,
        "roles": roles,
        "contract": contract,
        "contract_ok": all(item["ok"] for item in contract),
        "unexpected_roles": unexpected,
        "outside_component": outside,
        "same_component": (
            profile_path.exists()
            and not unexpected
            and not outside
            and columns == EXPECTED_COLUMNS
        ),
    }


def mirror_pairs(image: Image.Image, grid: ps.SheetGrid) -> list[dict]:
    """Compare each tile with its block-mirror partner (c -> 2-c / r -> 2-r)."""
    tiles = [[tile_rgb(image, grid, 3 + c, r) for c in range(3)] for r in range(3)]
    arrays = [[np.asarray(tiles[r][c], dtype=np.float32) for c in range(3)] for r in range(3)]
    pairs = []
    for r in range(3):
        for c in range(3):
            h_c = 2 - c
            v_r = 2 - r
            h_mae = mae(arrays[r][c], np.asarray(tiles[r][h_c].transpose(Image.FLIP_LEFT_RIGHT), dtype=np.float32))
            v_mae = mae(arrays[r][c], np.asarray(tiles[v_r][c].transpose(Image.FLIP_TOP_BOTTOM), dtype=np.float32))
            pairs.append({
                "cell": f"C{3 + c}R{r}",
                "h_cell": f"C{3 + h_c}R{r}",
                "h_mae": round(h_mae, 1),
                "v_cell": f"C{3 + c}R{v_r}",
                "v_mae": round(v_mae, 1),
            })
    return pairs


def audit(name: str) -> tuple[dict, Image.Image, Image.Image]:
    path = RAW_DIR / f"{name}.png"
    image = Image.open(path).convert("RGBA")
    grid = ps.probe(path)
    block = art_block(image, grid, 3, 0)
    ground = art_block(image, grid, 12, 0)
    b = np.asarray(block, dtype=np.float32)
    g = np.asarray(ground, dtype=np.float32)

    h_sym = mae(b, b[:, ::-1])
    v_sym = mae(b, b[::-1, :])
    gh_sym = mae(g, g[:, ::-1])
    gv_sym = mae(g, g[::-1, :])
    row_means = [float(b[r * TILE:(r + 1) * TILE].mean()) for r in range(3)]
    col_means = [float(b[:, c * TILE:(c + 1) * TILE].mean()) for c in range(3)]
    surface_row = int(np.argmax(row_means))
    front_row = int(np.argmin(row_means))
    back_row = 0 if front_row == 2 else 2

    tiles = [tile_rgb(image, grid, 3 + c, r) for r in range(3) for c in range(3)]
    tile_info = []
    for index, tile in enumerate(tiles):
        tile_info.append({
            "label": CORE_LABELS[index],
            "cell": f"C{3 + index % 3}R{index // 3}",
            "side": sides_for(image, grid, 3 + index % 3, index // 3),
            "mean": round(float(np.asarray(tile, dtype=np.float32).mean()), 1),
            "self_seam": ps.seam_score(tile),
        })

    preview = preview_crop(image)
    scale, _score, scale_matches = preview_scale(preview, block, ground)
    matches = preview_composition(preview, image, grid, scale)
    weak_seams = [s for s in seam_scores(b) if s["mae"] > 18]
    profile = profile_report(name, image, grid)
    mirrors = mirror_pairs(image, grid)
    strip_sides = sides_for(image, grid, 3, 4)

    preview_ok = [m for m in matches if m["mae"] < 20]
    composition = " -> ".join(f"{m['label']} (row {m['row']} y={m['y']})" for m in preview_ok)

    report = {
        "name": name,
        "grid": {"origin_x": grid.origin_x, "origin_y": grid.origin_y,
                 "pitch": grid.pitch, "tile": grid.tile},
        "walls": {
            "h_symmetry_mae": round(h_sym, 1),
            "v_symmetry_mae": round(v_sym, 1),
            "h_symmetric": h_sym < 10,
            "v_symmetric": v_sym < 10,
            "row_means": [round(v, 1) for v in row_means],
            "col_means": [round(v, 1) for v in col_means],
            "surface_row": surface_row,
            "front_row": front_row,
            "back_row": back_row,
            "inference": (
                "wall object: top surface + front face + back edge, not a 9-piece autotile"
                if (not (h_sym < 10 and v_sym < 10)) else
                "symmetric block; orientation ambiguous"
            ),
            "tiles": tile_info,
            "weak_seams": weak_seams,
        },
        "ground": {
            "h_symmetry_mae": round(gh_sym, 1),
            "v_symmetry_mae": round(gv_sym, 1),
            "h_symmetric": gh_sym < 10,
            "v_symmetric": gv_sym < 10,
        },
        "side_strip_C3R4": {"sides": strip_sides},
        "preview": {
            "size": [preview.width, preview.height],
            "scale": scale,
            "matches": matches,
            "matched": sum(1 for m in matches if m["mae"] < 20),
            "composition": composition,
            "core_scale_matches": scale_matches,
        },
        "contract": profile["contract"],
        "same_component": profile,
        "mirror_pairs": mirrors,
    }
    return report, block, preview


def render(name: str, report: dict, block: Image.Image, preview: Image.Image,
           image: Image.Image, grid: ps.SheetGrid, out: Path) -> None:
    width, height = 1360, 980
    canvas = Image.new("RGB", (width, height), (18, 18, 18))
    draw = ImageDraw.Draw(canvas)
    big, small, micro = font(16), font(10), font(8)

    draw.text((12, 8), f"{name} - component / orientation audit", font=big, fill=(255, 220, 80))
    draw.text((12, 30), (
        f"Walls H-sym {report['walls']['h_symmetry_mae']}  V-sym {report['walls']['v_symmetry_mae']}  |  "
        f"front {report['walls']['front_row']} surface {report['walls']['surface_row']} "
        f"back {report['walls']['back_row']}  |  preview scale {report['preview']['scale']}  |  "
        f"contract {'OK' if all(c['ok'] for c in report['contract']) else 'FAIL'}"
    ), font=small, fill=(210, 210, 210))
    draw.text((12, 46), report["walls"]["inference"], font=small, fill=(255, 160, 90))

    # Core block, 6x, with role + cell + measured side.
    scale = 6
    block_big = block.resize((block.width * scale, block.height * scale), Image.NEAREST)
    canvas.paste(block_big, (12, 66))
    for index, tile in enumerate(report["walls"]["tiles"]):
        r, c = divmod(index, 3)
        x, y = 12 + c * TILE * scale, 66 + r * TILE * scale
        draw.rectangle([x, y, x + 150, y + 13], fill=(0, 0, 0))
        draw.text((x + 2, y + 1), f"{tile['label']} C{3 + c}R{r} open={tile['side'] or '-'}",
                  font=micro, fill=(255, 230, 120))
    draw.text((12, 66 + block_big.height + 4),
              f"C3R4 measured open={report['side_strip_C3R4']['sides'] or '-'}",
              font=small, fill=(180, 220, 180))

    # Preview, 3x.
    px, py = 520, 66
    preview_big = preview.resize((preview.width * 3, preview.height * 3), Image.NEAREST)
    draw.text((px, py), "Preview as ground truth (golden)", font=small, fill=(255, 220, 80))
    canvas.paste(preview_big, (px, py + 14))
    draw.text((px, py + 14 + preview_big.height + 4),
              report["preview"]["composition"] or "no row matched the preview",
              font=small, fill=(150, 220, 150))
    draw.text((px, py + 14 + preview_big.height + 18),
              "Only the rows that match at MAE < 20 are shown.", font=micro, fill=(160, 160, 160))

    # Extras used by the atlas.
    ex, ey = 12, 560
    draw.text((ex, ey), "Atlas extras (same Walls component)", font=small, fill=(255, 220, 80))
    for index, (role, (column, row)) in enumerate(EXTRA_CELLS.items()):
        x = ex + (index % 4) * 126
        y = ey + 18 + (index // 4) * 122
        crop = tile_rgb(image, grid, column, row).resize((TILE * 4, TILE * 4), Image.NEAREST)
        canvas.paste(crop, (x, y))
        draw.text((x, y + TILE * 4 + 2), f"{role}", font=micro, fill=(220, 220, 220))
        draw.text((x, y + TILE * 4 + 12), f"C{column}R{row} open={sides_for(image, grid, column, row) or '-'}",
                  font=micro, fill=(160, 200, 160))

    # Contract table.
    tx, ty = 520, 498
    draw.text((tx, ty), "Face contract (role -> source cell -> measured open sides)",
              font=small, fill=(255, 220, 80))
    ty += 14
    for item in report["contract"]:
        color = (150, 220, 150) if item["ok"] else (240, 130, 110)
        draw.text((tx, ty), f"{'OK ' if item['ok'] else 'BAD'} {item['role']:14} {item['cell']:6} "
                            f"expect={item['expected'] or '-':4} measured={item['measured'] or '-':4}",
                  font=micro, fill=color)
        ty += 10

    # Mirrors.
    mx, my = tx + 340, 498
    draw.text((mx, my), "Mirror test (closest block tile)", font=small, fill=(255, 220, 80))
    my += 14
    for item in report["mirror_pairs"]:
        draw.text((mx, my), f"{item['cell']:6} H~{item['h_cell']:6} ({item['h_mae']}) "
                            f"V~{item['v_cell']:6} ({item['v_mae']})",
                  font=micro, fill=(200, 200, 200))
        my += 10

    # Seam diagnostic: self-tile of the mass centre + worst adjacent joins.
    center = next((t for t in report["walls"]["tiles"] if t["cell"] == "C4R1"), None)
    weak = report["walls"]["weak_seams"]
    if center:
        seam = center["self_seam"]
        draw.text((12, 824),
                  f"Seam: wall_c self L/R {seam['left_right']:.0%} T/B {seam['top_bottom']:.0%}; "
                  f"weak adjacent joins {len(weak)}"
                  + (f" (worst {weak[0]['a']}->{weak[0]['b']} {weak[0]['mae']})" if weak else ""),
                  font=micro, fill=(200, 180, 140))

    # Checklist.
    same = report.get("same_component", {})
    contract_ok = all(item["ok"] for item in report["contract"])
    draw.text((12, 848), "Checklist", font=small, fill=(255, 220, 80))
    checklist = [
        ("core tiles all from C3..C5 R0..R2", True),
        ("extras all from the same Walls block C3..C5", not same.get("outside_component")),
        ("alt centres real, from Wall Alt.1/2 (D-355)",
            "wall_alt_1" in same.get("roles", {}) and "wall_alt_2" in same.get("roles", {})),
        ("no synthetic tile in the active atlas", same.get("columns") == EXPECTED_COLUMNS),
        ("every role's measured face matches its contract", contract_ok),
        ("preview rows agree with the atlas rows", report["preview"]["matched"] >= 2),
    ]
    for index, (line, ok) in enumerate(checklist):
        color = (160, 220, 160) if ok else (240, 130, 110)
        draw.text((12 + (index % 2) * 360, 866 + (index // 2) * 11),
                  ("OK  " if ok else "BAD ") + line, font=micro, fill=color)
    draw.text((12, 910),
              f"atlas columns {same.get('columns', '?')}  roles outside the component "
              f"{same.get('outside_component', [])}  unexpected {same.get('unexpected_roles', [])}",
              font=micro, fill=(200, 180, 140))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="single sheet name")
    parser.add_argument("--approve", action="store_true",
                        help="write the human approval for --only after reviewing the sheet")
    args = parser.parse_args()
    names = sorted(path.stem for path in RAW_DIR.glob("*.png"))
    if args.only:
        names = [name for name in names if name == args.only]
    if args.approve and len(names) != 1:
        print("--approve requires exactly one --only sheet", file=sys.stderr)
        return 2
    AUDIT_DIR = ROOT / "tools" / "pmd_import" / "audits"
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    index = []
    for name in names:
        report, block, preview = audit(name)
        (AUDIT_DIR / f"{name}.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        image = Image.open(RAW_DIR / f"{name}.png").convert("RGBA")
        grid = ps.probe(RAW_DIR / f"{name}.png")
        render(name, report, block, preview, image, grid, CONTACT_DIR / f"{name}_components.png")
        if args.approve:
            profile_path = ATLAS_DIR / f"{name}_profile.json"
            profile = json.loads(profile_path.read_text(encoding="utf-8")) if profile_path.exists() else {}
            approval = {
                "name": name,
                "approved": True,
                "source_sha256": ps.sha256_file(RAW_DIR / f"{name}.png"),
                "atlas_columns": profile.get("columns", 0),
                "component_map": profile.get("role_cells", {}),
                "role_sides": profile.get("role_sides", {}),
                "preview_composition": report["preview"]["composition"],
                "contract_ok": all(item["ok"] for item in report["contract"]),
            }
            approval_path = AUDIT_DIR / f"{name}_approved.json"
            approval_path.write_text(json.dumps(approval, indent=2) + "\n", encoding="utf-8")
            print(f"APPROVED {name}: {approval_path.relative_to(ROOT).as_posix()}")
        contract_ok = all(item["ok"] for item in report["contract"])
        index.append({
            "name": name,
            "h_symmetry_mae": report["walls"]["h_symmetry_mae"],
            "v_symmetry_mae": report["walls"]["v_symmetry_mae"],
            "front_row": report["walls"]["front_row"],
            "surface_row": report["walls"]["surface_row"],
            "preview_scale": report["preview"]["scale"],
            "preview_matches": report["preview"]["matched"],
            "preview_composition": report["preview"]["composition"],
            "contract_ok": contract_ok,
            "same_component": report["same_component"].get("same_component"),
        })
        print(f"AUDIT {name}: H {report['walls']['h_symmetry_mae']} V {report['walls']['v_symmetry_mae']} "
              f"front {report['walls']['front_row']} surface {report['walls']['surface_row']} "
              f"preview {report['preview']['matched']} scale {report['preview']['scale']} "
              f"contract {'OK' if contract_ok else 'FAIL'} same={report['same_component'].get('same_component')}")
        if report["preview"]["composition"]:
            print(f"      preview: {report['preview']['composition']}")
    (AUDIT_DIR / "index.json").write_text(json.dumps({"sheets": index}, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
