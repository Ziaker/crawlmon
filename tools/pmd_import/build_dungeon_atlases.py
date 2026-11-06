"""Build the Sky dungeon atlases with measurement, manifests and validation.

Pipeline (D-345):
  1. probe the sheet (cyan lines -> origin, pitch, tile);
  2. validate the 3x3 cores and detect the extra autotile pieces;
  3. crop the full 24x24 art cell, scale 2x with nearest;
  4. build the 18-tile core atlas plus Ground Alt. 1/2, profile and manifest;
  5. write a labeled contact sheet and a labeled atlas;
  6. validate dimensions, empty/duplicate tiles, cyan/teal pixels and report
     seam scores (diagnostic only: the 3x3 blocks are border sets).

Usage, from the repository root:
    python tools/pmd_import/build_dungeon_atlases.py
    python tools/pmd_import/build_dungeon_atlases.py --check
    python tools/pmd_import/build_dungeon_atlases.py --only temporal_tower
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

import pmd_sheet as ps

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "assets" / "pmd" / "dungeons" / "sky" / "raw"
ATLAS_DIR = ROOT / "assets" / "pmd" / "dungeons" / "sky" / "atlas"
MANIFEST_DIR = ROOT / "tools" / "pmd_import" / "manifests"
CONTACT_DIR = ROOT / "docs" / "referencias" / "tilesets"
ACTIVE = "temporal_tower"
ATLAS_TILE = 48

BASE_ROLES: dict[str, int] = {}
for index, role in enumerate(ps.CORE_ROLES):
    BASE_ROLES[f"wall_{role}"] = index
for index, role in enumerate(ps.CORE_ROLES):
    BASE_ROLES[f"ground_{role}"] = 9 + index


def _font(size: int) -> ImageFont.ImageFont:
    for name in ("arial.ttf", "C:/Windows/Fonts/arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _corner_image(
    image: Image.Image,
    grid: ps.SheetGrid,
    base: tuple[int, int],
    patch: tuple[int, int],
    corner: str,
) -> Image.Image:
    """Base 24x24 tile plus the 8x8 corner patch from another core tile."""
    def raw(column: int, row: int) -> Image.Image:
        return image.crop(grid.cell_box(column, row)).convert("RGBA")

    tile = raw(*base)
    source = raw(*patch)
    box = {
        "tl": (0, 0, 8, 8),
        "tr": (16, 0, 24, 8),
        "bl": (0, 16, 8, 24),
        "br": (16, 16, 24, 24),
    }[corner]
    tile.paste(source.crop(box), box)
    return tile.resize((ATLAS_TILE, ATLAS_TILE), Image.NEAREST)


def _strip_image(image: Image.Image, grid: ps.SheetGrid, horizontal: bool) -> Image.Image:
    """Synthesize a clean two-border strip from the 3x3 wall pieces.

    The sheet's frame pieces have joints when repeated. This composes the
    border rows/columns of wall_t/wall_b/wall_l/wall_r over wall_c, giving a
    seamless strip with borders on both sides and no vertical/horizontal seam.
    """
    def raw(column: int, row: int) -> Image.Image:
        return image.crop(grid.cell_box(column, row)).convert("RGBA")

    base = raw(4, 1)
    border = 6
    if horizontal:
        base.paste(raw(4, 0).crop((0, 0, 24, border)), (0, 0))
        base.paste(raw(4, 2).crop((0, 24 - border, 24, 24)), (0, 24 - border))
    else:
        base.paste(raw(3, 1).crop((0, 0, border, 24)), (0, 0))
        base.paste(raw(5, 1).crop((24 - border, 0, 24, 24)), (24 - border, 0))
    return base.resize((ATLAS_TILE, ATLAS_TILE), Image.NEAREST)


def _make_contact_sheet(
    name: str,
    image: Image.Image,
    grid: ps.SheetGrid,
    cells: list[dict],
    out_path: Path,
) -> None:
    """One labeled card per atlas tile, plus the sheet header."""
    zoom = 4
    tile = grid.tile * zoom
    label_h = 26
    cols = 3
    rows = (len(cells) + cols - 1) // cols
    margin = 10
    header = 44
    width = margin * 2 + cols * tile
    height = header + margin + rows * (tile + label_h) + margin
    canvas = Image.new("RGB", (width, height), (18, 18, 18))
    draw = ImageDraw.Draw(canvas)
    font = _font(11)
    small = _font(9)
    draw.text((margin, 6), f"{name}  |  pipeline {ps.PIPELINE_VERSION}", font=font, fill=(255, 220, 80))
    draw.text(
        (margin, 22),
        f"grid {grid.origin_x},{grid.origin_y}  pitch {grid.pitch}  tile {grid.tile}  "
        f"columns {grid.columns}/{grid.line_columns}  source {ps.sha256_file(RAW_DIR / f'{name}.png')[:12]}",
        font=small,
        fill=(190, 190, 190),
    )
    for index, cell in enumerate(cells):
        x = margin + (index % cols) * tile
        y = header + margin + (index // cols) * (tile + label_h)
        draw.text((x + 2, y + 2), f"#{index:02d} {cell['category']} {cell['role'].upper()}", font=small, fill=(220, 220, 220))
        source_text = "sintético" if cell.get("source") == "synthetic" else f"C{cell['column']} R{cell['row']}"
        draw.text((x + 2, y + 13), source_text, font=small, fill=(160, 160, 160))
        if cell.get("source") == "synthetic":
            crop = cell["image"].resize((tile, tile), Image.NEAREST)
        else:
            crop = ps.tile_image(image, grid, cell["column"], cell["row"], tile)
        canvas.paste(crop.convert("RGB"), (x, y + label_h))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path)


def _make_labeled_atlas(
    name: str, atlas: Image.Image, out_path: Path, columns: int, roles: dict[str, int]
) -> None:
    zoom = 2
    tile = ATLAS_TILE * zoom
    label_h = 16
    margin = 8
    width = margin * 2 + columns * tile
    height = label_h + margin * 2 + tile
    canvas = Image.new("RGB", (width, height), (18, 18, 18))
    draw = ImageDraw.Draw(canvas)
    font = _font(9)
    for index in range(columns):
        x = margin + index * tile
        role = next((key for key, value in roles.items() if value == index), str(index))
        draw.text((x + 2, 2), f"{index:02d} {role}", font=font, fill=(220, 220, 220))
        crop = atlas.crop((index * ATLAS_TILE, 0, (index + 1) * ATLAS_TILE, ATLAS_TILE))
        canvas.paste(crop.convert("RGB").resize((tile, tile), Image.NEAREST), (x, label_h))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path)


def _make_labels_sheet(image: Image.Image, out_path: Path) -> None:
    strip = image.crop((0, 140, image.width, 162))
    strip = strip.resize((strip.width * 2, strip.height * 2), Image.NEAREST)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out_path)


def _make_preview(image: Image.Image, out_path: Path) -> None:
    crop = image.crop((max(0, image.width - 116), 4, image.width - 4, 132))
    crop = crop.resize((crop.width * 4, crop.height * 4), Image.NEAREST)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    crop.save(out_path)


def build_one(name: str) -> dict:
    source_path = RAW_DIR / f"{name}.png"
    if not source_path.exists():
        raise FileNotFoundError(source_path)
    image = Image.open(source_path).convert("RGBA")
    grid = ps.probe(source_path)
    if grid.columns < 21:
        raise ValueError(f"{name}: only {grid.columns} shared columns")

    walls = ps.detect_core(image, grid, *ps.WALL_CORE)
    ground = ps.detect_core(image, grid, *ps.GROUND_CORE)
    for label, core in (("Walls", walls), ("Ground", ground)):
        for line in core:
            for cell in line:
                if cell["art"] < 0.9:
                    raise ValueError(
                        f"{name}: {label} core cell C{cell['column']} R{cell['row']} "
                        f"is not art ({cell['art']:.0%})"
                    )

    cells: list[dict] = []
    roles: dict[str, int] = dict(BASE_ROLES)
    for line in walls:
        for cell in line:
            cells.append({
                "category": "Walls",
                "role": cell["role"],
                "column": cell["column"],
                "row": cell["row"],
            })
    for line in ground:
        for cell in line:
            cells.append({
                "category": "Ground",
                "role": cell["role"],
                "column": cell["column"],
                "row": cell["row"],
            })

    # Ground variants for the organic floor (D-347): Ground Alt. 1 (C16 R1)
    # and Ground Alt. 2 (C19 R1). Only added where the sheet has art.
    for alt_index, (column, row) in enumerate([(16, 1), (19, 1)], start=1):
        if ps.art_fraction(image, grid, column, row) < 0.5:
            continue
        role = f"ground_alt_{alt_index}"
        roles[role] = len(cells)
        cells.append({
            "category": "Ground Alt",
            "role": role,
            "column": column,
            "row": row,
        })

    # Clean two-border strips synthesized from the 3x3 wall pieces (D-348).
    # The sheet's frame bars have joints; these are continuous.
    for role, horizontal in [("wall_strip_h", True), ("wall_strip_v", False)]:
        roles[role] = len(cells)
        cells.append({
            "category": "Wall strip",
            "role": role,
            "column": -1,
            "row": -1,
            "source": "synthetic",
            "image": _strip_image(image, grid, horizontal),
        })

    # Inner corners: the 3x3 only has outer corners. Base outer-corner tile +
    # the diagonal corner patch from the matching corner (D-348).
    inner_corners = [
        ("wall_inner_br", (3, 0), (5, 2), "br"),
        ("wall_inner_bl", (5, 0), (3, 2), "bl"),
        ("wall_inner_tr", (3, 2), (5, 0), "tr"),
        ("wall_inner_tl", (5, 2), (3, 0), "tl"),
        ("ground_inner_tl", (13, 1), (12, 0), "tl"),
        ("ground_inner_tr", (13, 1), (14, 0), "tr"),
        ("ground_inner_bl", (13, 1), (12, 2), "bl"),
        ("ground_inner_br", (13, 1), (14, 2), "br"),
    ]
    for role, base, patch, corner in inner_corners:
        roles[role] = len(cells)
        cells.append({
            "category": "Inner corner",
            "role": role,
            "column": -1,
            "row": -1,
            "source": "synthetic",
            "image": _corner_image(image, grid, base, patch, corner),
        })

    columns = len(cells)
    atlas = Image.new("RGBA", (columns * ATLAS_TILE, ATLAS_TILE), (0, 0, 0, 0))
    tile_hashes: list[str] = []
    errors: list[str] = []
    warnings: list[str] = []
    duplicates: list[list[int]] = []
    seen: dict[str, int] = {}
    for index, cell in enumerate(cells):
        if cell.get("source") == "synthetic":
            tile = cell["image"]
        else:
            tile = ps.tile_image(image, grid, cell["column"], cell["row"], ATLAS_TILE)
        if not ps.tile_has_no_grid(tile):
            errors.append(f"{name}: tile {index} still contains cyan/teal pixels")
        digest = ps.sha256_bytes(tile.tobytes())
        if digest in seen:
            duplicates.append([seen[digest], index])
        else:
            seen[digest] = index
        tile_hashes.append(digest)
        atlas.paste(tile, (index * ATLAS_TILE, 0))
    if duplicates:
        # Identical edge tiles are legitimate in uniform art (for example a
        # ground block with no bottom border). Report, do not fail.
        warnings.append(f"{name}: repeated atlas tiles {duplicates}")

    center_scores = {
        "wall_c": ps.seam_score(atlas.crop((roles["wall_c"] * ATLAS_TILE, 0, (roles["wall_c"] + 1) * ATLAS_TILE, ATLAS_TILE))),
        "ground_c": ps.seam_score(atlas.crop((roles["ground_c"] * ATLAS_TILE, 0, (roles["ground_c"] + 1) * ATLAS_TILE, ATLAS_TILE))),
    }
    for tile_name, score in center_scores.items():
        if score["left_right"] < 0.9 or score["top_bottom"] < 0.9:
            warnings.append(
                f"{name}: {tile_name} does not self-tile perfectly "
                f"(L/R {score['left_right']:.0%}, T/B {score['top_bottom']:.0%}); "
                "the 3x3 block is a border set, so this is diagnostic"
            )

    atlas_path = ATLAS_DIR / f"{name}_atlas.png"
    atlas_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_path)

    profile_path = ATLAS_DIR / f"{name}_profile.json"
    profile = {
        "name": name,
        "pipeline_version": ps.PIPELINE_VERSION,
        "atlas": f"res://{_rel(atlas_path)}",
        "tile_size": ATLAS_TILE,
        "columns": columns,
        "rows": 1,
        "roles": roles,
    }
    profile_path.write_text(json.dumps(profile, indent=2) + "\n", encoding="utf-8")

    contact_path = CONTACT_DIR / f"{name}_contact.png"
    labels_path = CONTACT_DIR / f"{name}_labels.png"
    preview_path = CONTACT_DIR / f"{name}_preview.png"
    labeled_atlas_path = CONTACT_DIR / f"{name}_atlas_labeled.png"
    _make_contact_sheet(name, image, grid, cells, contact_path)
    _make_labeled_atlas(name, atlas, labeled_atlas_path, columns, roles)
    _make_labels_sheet(image, labels_path)
    _make_preview(image, preview_path)

    manifest = {
        "pipeline_version": ps.PIPELINE_VERSION,
        "name": name,
        "source": _rel(source_path),
        "source_sha256": ps.sha256_file(source_path),
        "grid": {
            "width": grid.width,
            "height": grid.height,
            "origin_x": grid.origin_x,
            "origin_y": grid.origin_y,
            "pitch": grid.pitch,
            "tile": grid.tile,
            "shared_columns": grid.columns,
            "physical_columns": grid.line_columns,
            "rows": grid.line_rows,
        },
        "categories": ps.category_ranges(grid),
        "autotile": {
            "walls": {
                "base": {"column": ps.WALL_CORE[0], "row": ps.WALL_CORE[1]},
                "core": walls,
                "extras": ps.detect_extras(image, grid, *ps.WALL_CORE),
            },
            "ground": {
                "base": {"column": ps.GROUND_CORE[0], "row": ps.GROUND_CORE[1]},
                "core": ground,
                "extras": ps.detect_extras(image, grid, *ps.GROUND_CORE),
            },
        },
        "atlas": {
            "path": _rel(atlas_path),
            "sha256": ps.sha256_file(atlas_path),
            "tile_size": ATLAS_TILE,
            "columns": columns,
            "rows": 1,
        },
        "roles": roles,
        "profile": _rel(profile_path),
        "contact_sheet": _rel(contact_path),
        "labeled_atlas": _rel(labeled_atlas_path),
        "labels": _rel(labels_path),
        "preview": _rel(preview_path),
        "validation": {
            "tiles": len(cells),
            "unique_tiles": len(set(tile_hashes)),
            "duplicates": duplicates,
            "seam": center_scores,
            "warnings": warnings,
        },
    }
    MANIFEST_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path = MANIFEST_DIR / f"{name}.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    if errors:
        raise ValueError("; ".join(errors))
    return manifest


def check_one(name: str) -> list[str]:
    source_path = RAW_DIR / f"{name}.png"
    atlas_path = ATLAS_DIR / f"{name}_atlas.png"
    profile_path = ATLAS_DIR / f"{name}_profile.json"
    manifest_path = MANIFEST_DIR / f"{name}.json"
    problems = []
    for path in (source_path, atlas_path, profile_path, manifest_path):
        if not path.exists():
            problems.append(f"{name}: missing {_rel(path)}")
    if problems:
        return problems

    grid = ps.probe(source_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    if manifest["source_sha256"] != ps.sha256_file(source_path):
        problems.append(f"{name}: source hash changed")
    if manifest["grid"]["origin_x"] != grid.origin_x or manifest["grid"]["pitch"] != grid.pitch:
        problems.append(f"{name}: probe grid changed")
    if manifest["atlas"]["sha256"] != ps.sha256_file(atlas_path):
        problems.append(f"{name}: atlas hash changed")
    for role, index in BASE_ROLES.items():
        if profile["roles"].get(role) != index:
            problems.append(f"{name}: core role {role} does not match the pipeline")
        if manifest["roles"].get(role) != index:
            problems.append(f"{name}: manifest core role {role} does not match")
    columns = int(profile["columns"])
    role_indices = list(profile["roles"].values())
    if len(set(role_indices)) != len(role_indices):
        problems.append(f"{name}: duplicate role indices")
    for role in (
        "ground_alt_1", "ground_alt_2", "wall_strip_h", "wall_strip_v",
        "wall_inner_br", "wall_inner_bl", "wall_inner_tr", "wall_inner_tl",
        "ground_inner_tl", "ground_inner_tr", "ground_inner_bl", "ground_inner_br",
    ):
        if role not in profile["roles"]:
            continue
        index = int(profile["roles"][role])
        if index < len(BASE_ROLES) or index >= columns:
            problems.append(f"{name}: role {role} has invalid index {index}")
    for key in ("contact_sheet", "labeled_atlas", "labels", "preview"):
        artifact = ROOT / manifest[key]
        if not artifact.exists():
            problems.append(f"{name}: missing {key} {_rel(artifact)}")
    columns = int(profile["columns"])
    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.size != (columns * ATLAS_TILE, ATLAS_TILE):
        problems.append(f"{name}: atlas size {atlas.size} is wrong")
    else:
        for index in range(columns):
            tile = atlas.crop((index * ATLAS_TILE, 0, (index + 1) * ATLAS_TILE, ATLAS_TILE))
            if not ps.tile_has_no_grid(tile):
                problems.append(f"{name}: tile {index} contains cyan/teal")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="build/check a single sheet name")
    parser.add_argument("--check", action="store_true", help="validate existing outputs")
    args = parser.parse_args()

    names = sorted(path.stem for path in RAW_DIR.glob("*.png"))
    if args.only:
        names = [name for name in names if name == args.only]
        if not names:
            print(f"unknown sheet: {args.only}", file=sys.stderr)
            return 2

    problems: list[str] = []
    if args.check:
        for name in names:
            problems.extend(check_one(name))
    else:
        for name in names:
            try:
                manifest = build_one(name)
                warnings = manifest["validation"]["warnings"]
                print(f"OK {name}: {manifest['grid']['origin_x']},{manifest['grid']['origin_y']} "
                      f"pitch {manifest['grid']['pitch']} columns {manifest['grid']['shared_columns']}/"
                      f"{manifest['grid']['physical_columns']} tiles {manifest['validation']['tiles']}")
                for warning in warnings:
                    print(f"  WARN {warning}")
            except Exception as exc:  # keep going so one sheet cannot hide the others
                problems.append(f"{name}: {exc}")
                print(f"FAIL {name}: {exc}", file=sys.stderr)

        if not args.only:
            pool_path = ATLAS_DIR / "biome_pool.json"
            pool = {
                "pipeline_version": ps.PIPELINE_VERSION,
                "floors_per_biome": 5,
                "fallback": ACTIVE,
                "profiles": [
                    {
                        "name": name,
                        "profile": f"res://{_rel(ATLAS_DIR / f'{name}_profile.json')}",
                    }
                    for name in names
                ],
            }
            pool_path.write_text(json.dumps(pool, indent=2) + "\n", encoding="utf-8")
            print(f"biome pool: {_rel(pool_path)}")

            index_path = MANIFEST_DIR / "index.json"
            index = {
                "pipeline_version": ps.PIPELINE_VERSION,
                "active": ACTIVE,
                "active_atlas": f"res://{_rel(ATLAS_DIR / f'{ACTIVE}_atlas.png')}",
                "active_profile": f"res://{_rel(ATLAS_DIR / f'{ACTIVE}_profile.json')}",
                "sheets": [
                    {
                        "name": name,
                        "manifest": f"{name}.json",
                        "atlas": f"res://{_rel(ATLAS_DIR / f'{name}_atlas.png')}",
                        "profile": f"res://{_rel(ATLAS_DIR / f'{name}_profile.json')}",
                    }
                    for name in names
                ],
            }
            index_path.parent.mkdir(parents=True, exist_ok=True)
            index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
            print(f"index: {_rel(index_path)}")

    if problems:
        print("\nPROBLEMS:", file=sys.stderr)
        for problem in problems:
            print(f"- {problem}", file=sys.stderr)
        return 1
    print("validation: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
