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
AUDIT_DIR = ROOT / "tools" / "pmd_import" / "audits"
CONTACT_DIR = ROOT / "docs" / "referencias" / "tilesets"
ACTIVE = "temporal_tower"
ATLAS_TILE = 48

BASE_ROLES: dict[str, int] = {}
for index, role in enumerate(ps.CORE_ROLES):
    BASE_ROLES[f"wall_{role}"] = index
for index, role in enumerate(ps.CORE_ROLES):
    BASE_ROLES[f"ground_{role}"] = 9 + index

# The face contract lives in pmd_sheet so the builder and the audit use the
# same one.
SIDE_CONTRACT = ps.SIDE_CONTRACT


def _font(size: int) -> ImageFont.ImageFont:
    for name in ("arial.ttf", "C:/Windows/Fonts/arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


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

    # Real extra wall pieces below the 3x3 core (D-354). Each one is chosen by
    # the side signature measured from its own pixels, never by grid position:
    #   C3R4 EW strip, C4R3 NS strip, C4R4 island, C4R6/8/3R7/5R7 tips,
    #   C4R7 cross. The 3x3 core is the wall mass; these are its shapes.
    wall_extras = [
        ("wall_strip_v", "Wall strip V", (3, 4)),
        ("wall_strip_h", "Wall strip H", (4, 3)),
        ("wall_island", "Wall island", (4, 4)),
        ("wall_tip_n", "Wall tip N", (4, 6)),
        ("wall_tip_s", "Wall tip S", (4, 8)),
        ("wall_tip_w", "Wall tip W", (3, 7)),
        ("wall_tip_e", "Wall tip E", (5, 7)),
        ("wall_cross", "Wall cross", (4, 7)),
    ]
    for role, category, (column, row) in wall_extras:
        if ps.art_fraction(image, grid, column, row) < 0.5:
            continue
        roles[role] = len(cells)
        cells.append({
            "category": category,
            "role": role,
            "column": column,
            "row": row,
        })

    # Wall Alt. 1/2 centres (D-355): real cells, used only as a rare interior
    # variation of the wall mass, never on edges/corners.
    for role, (column, row) in [("wall_alt_1", (7, 1)), ("wall_alt_2", (10, 1))]:
        if ps.art_fraction(image, grid, column, row) < 0.5:
            continue
        roles[role] = len(cells)
        cells.append({
            "category": "Wall Alt centre",
            "role": role,
            "column": column,
            "row": row,
        })

    columns = len(cells)
    errors: list[str] = []
    warnings: list[str] = []
    duplicates: list[list[int]] = []
    # Measure the face of every wall role from the source pixels. The game
    # selects by this signature, and a mismatch stops the build.
    role_sides: dict[str, str] = {}
    role_cells: dict[str, list[int]] = {}
    contract_ok = True
    for cell in cells:
        role_name = str(cell["role"])
        if cell.get("category") == "Walls":
            role_name = f"wall_{role_name}"
        if not role_name.startswith("wall_"):
            continue
        source_tile = image.crop(
            grid.cell_box(int(cell["column"]), int(cell["row"]))
        ).convert("RGB")
        sides = ps.open_sides(source_tile)
        role_sides[role_name] = sides
        role_cells[role_name] = [int(cell["column"]), int(cell["row"])]
        expected = SIDE_CONTRACT.get(role_name)
        if expected is not None and sides != expected:
            contract_ok = False
            message = (
                f"{name}: role {role_name} measures open={sides or '-'} "
                f"but the contract expects {expected or '-'}"
            )
            if name == ACTIVE:
                errors.append(message)
            else:
                warnings.append(message + " (not the active sheet)")

    if name == ACTIVE:
        approval_path = AUDIT_DIR / f"{name}_approved.json"
        if not approval_path.exists():
            warnings.append(
                f"{name}: no human component approval yet; run audit_components.py "
                f"--only {name} --approve after reviewing the component sheet"
            )
        else:
            approval = json.loads(approval_path.read_text(encoding="utf-8"))
            if approval.get("source_sha256") != ps.sha256_file(source_path):
                warnings.append(f"{name}: component approval is stale (source changed)")
            elif approval.get("atlas_columns") != columns \
                    or approval.get("component_map") != role_cells:
                warnings.append(
                    f"{name}: component approval is stale (atlas/roles changed); "
                    f"review the component sheet and run --approve again"
                )

    atlas = Image.new("RGBA", (columns * ATLAS_TILE, ATLAS_TILE), (0, 0, 0, 0))
    tile_hashes: list[str] = []
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
        "role_sides": role_sides,
        "role_cells": role_cells,
        "side_contract_ok": contract_ok,
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
        "role_sides": role_sides,
        "role_cells": role_cells,
        "side_contract_ok": contract_ok,
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
        "ground_alt_1", "ground_alt_2",
        "wall_strip_v", "wall_strip_h", "wall_island",
        "wall_tip_n", "wall_tip_s", "wall_tip_w", "wall_tip_e", "wall_cross",
        "wall_alt_1", "wall_alt_2",
    ):
        if role not in profile["roles"]:
            continue
        index = int(profile["roles"][role])
        if index < len(BASE_ROLES) or index >= columns:
            problems.append(f"{name}: role {role} has invalid index {index}")
    # Face contract: re-measure each wall role's source cell (D-354). The
    # strict contract is the active sheet's gate; the other sheets record
    # their own sides and are reviewed when they become active.
    if name == ACTIVE:
        source_image = Image.open(source_path).convert("RGBA")
        role_sides = profile.get("role_sides", {})
        role_cells = profile.get("role_cells", {})
        for role, expected in SIDE_CONTRACT.items():
            index = profile["roles"].get(role)
            if index is None:
                continue
            if role not in role_sides or role not in role_cells:
                problems.append(f"{name}: role {role} has no measured side signature")
                continue
            column, row = int(role_cells[role][0]), int(role_cells[role][1])
            measured = ps.open_sides(source_image.crop(grid.cell_box(column, row)))
            if measured != expected:
                problems.append(
                    f"{name}: role {role} measures open={measured or '-'} "
                    f"but the contract expects {expected or '-'}"
                )
            if role_sides[role] != measured:
                problems.append(
                    f"{name}: role {role} stored open={role_sides[role] or '-'} "
                    f"but the source now measures {measured or '-'}"
                )
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
