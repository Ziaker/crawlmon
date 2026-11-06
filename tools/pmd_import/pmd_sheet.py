"""Measure and validate a PMD dungeon-tiles sheet before importing it.

The Sky sheets are a 25 px grid: a 1 px cyan line, then a 24x24 art cell.
This module finds that grid from the pixels instead of hardcoding it, so a
sheet with a different width or a different right-hand palette cannot shift
the tiles silently.

Pure Python + Pillow; no game code depends on it.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

PIPELINE_VERSION = "2.5.0"
CYAN = (128, 255, 255, 255)
TEAL = (0, 128, 128, 255)

# The first 24 columns are shared by all 16 Sky sheets:
# Legend 0..2, Walls 3..5, Wall Alt. 1 6..8, Wall Alt. 2 9..11,
# Ground 12..14, Ground Alt. 1 15..17, Ground Alt. 2 18..20.
# After that the sheets diverge (Water / Unused Ground / palettes).
COMMON_COLUMNS = 24
WALL_CORE = (3, 0)
GROUND_CORE = (12, 0)
CORE_ROLES = (
    "tl", "t", "tr",
    "l", "c", "r",
    "bl", "b", "br",
)


@dataclass(frozen=True)
class SheetGrid:
    width: int
    height: int
    origin_x: int
    origin_y: int
    pitch: int
    tile: int
    line_columns: int
    line_rows: int

    @property
    def columns(self) -> int:
        """Columns that share the same category layout across all sheets."""
        return min(COMMON_COLUMNS, self.line_columns)

    def cell_box(self, column: int, row: int) -> tuple[int, int, int, int]:
        x = self.origin_x + column * self.pitch
        y = self.origin_y + row * self.pitch
        return (x, y, x + self.tile, y + self.tile)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _is_cyan(pixel: tuple[int, int, int, int]) -> bool:
    return pixel == CYAN


def _is_sheet_background(pixel: tuple[int, int, int, int]) -> bool:
    if pixel[3] == 0:
        return True
    return pixel == CYAN or pixel == TEAL


def probe(path: Path) -> SheetGrid:
    """Find the cyan grid lines and return the real origin, pitch and tile."""
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    width, height = image.size

    line_columns = [
        x for x in range(width)
        if sum(1 for y in range(140, height) if _is_cyan(pixels[x, y])) > 30
    ]
    line_rows = [
        y for y in range(120, height)
        if sum(1 for x in range(width) if _is_cyan(pixels[x, y])) > 60
    ]
    if len(line_columns) < 2 or len(line_rows) < 2:
        raise ValueError(f"{path.name}: cyan grid not found")

    # The tile grid is the initial 25 px run. A few sheets put an extra
    # palette/note block on the right with a gap before it; that right-hand
    # block is not part of the dungeon grid and must not shift the common
    # columns.
    regular_columns = [line_columns[0]]
    for a, b in zip(line_columns, line_columns[1:]):
        if b - a != 25:
            break
        regular_columns.append(b)
    line_columns = regular_columns

    row_steps = {b - a for a, b in zip(line_rows, line_rows[1:])}
    if len(line_columns) < 2 or row_steps != {25}:
        raise ValueError(
            f"{path.name}: expected a 25 px row pitch, got {sorted(row_steps)}"
        )

    return SheetGrid(
        width=width,
        height=height,
        origin_x=line_columns[0] + 1,
        origin_y=line_rows[0] + 1,
        pitch=25,
        tile=24,
        line_columns=len(line_columns),
        line_rows=len(line_rows),
    )


def art_fraction(image: Image.Image, grid: SheetGrid, column: int, row: int) -> float:
    """Fraction of a cell that is not sheet background (teal/cyan/transparent)."""
    cell = image.crop(grid.cell_box(column, row)).convert("RGBA")
    pixels = cell.load()
    total = cell.width * cell.height
    art = 0
    for y in range(cell.height):
        for x in range(cell.width):
            if not _is_sheet_background(pixels[x, y]):
                art += 1
    return art / total


def category_ranges(grid: SheetGrid) -> dict[str, list[int]]:
    """Known label ranges, derived from the sheet width.

    The sheets have two layouts after Ground Alt. 2:
      24 physical columns: Water 21..23, then the water palette;
      27+ physical columns: Unused Ground 21..23, Water 24..26.
    """
    ranges = {
        "legend": [0, 2],
        "walls": [3, 5],
        "wall_alt_1": [6, 8],
        "wall_alt_2": [9, 11],
        "ground": [12, 14],
        "ground_alt_1": [15, 17],
        "ground_alt_2": [18, 20],
    }
    if grid.line_columns >= 27:
        ranges["unused_ground"] = [21, 23]
        ranges["water"] = [24, 26]
    else:
        # 24-column sheets put Water at 21..23 and the palette to the right,
        # outside the regular grid. Do not invent a 25 px column for it.
        ranges["water"] = [21, 23]
    return ranges


def detect_core(
    image: Image.Image, grid: SheetGrid, base_column: int, base_row: int
) -> list[list[dict]]:
    """Return the 3x3 core with its role, cell and art fraction."""
    core = []
    for row in range(3):
        line = []
        for column in range(3):
            c = base_column + column
            r = base_row + row
            line.append({
                "role": CORE_ROLES[row * 3 + column],
                "column": c,
                "row": r,
                "art": round(art_fraction(image, grid, c, r), 3),
            })
        core.append(line)
    return core


def detect_extras(
    image: Image.Image, grid: SheetGrid, base_column: int, base_row: int
) -> list[dict]:
    """Art cells below the 3x3 core (shape pieces, recorded for reference)."""
    extras = []
    for row in range(base_row + 3, min(base_row + 14, grid.line_rows)):
        for column in range(base_column, base_column + 3):
            art = art_fraction(image, grid, column, row)
            if art > 0.5:
                extras.append({
                    "column": column,
                    "row": row,
                    "art": round(art, 3),
                })
    return extras


def tile_image(image: Image.Image, grid: SheetGrid, column: int, row: int, size: int) -> Image.Image:
    """Crop the full 24x24 art cell and scale with nearest neighbour."""
    cell = image.crop(grid.cell_box(column, row)).convert("RGBA")
    return cell.resize((size, size), Image.NEAREST)


def tile_has_no_grid(image: Image.Image) -> bool:
    """True when the tile contains no cyan line and no teal sheet background."""
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if _is_sheet_background(pixels[x, y]):
                return False
    return True


def seam_score(tile: Image.Image) -> dict[str, float]:
    """How much a repeated tile matches itself on each edge (diagnostic only)."""
    pixels = tile.load()
    width, height = tile.size
    left_right = sum(
        1 for y in range(height) if pixels[0, y] == pixels[width - 1, y]
    ) / height
    top_bottom = sum(
        1 for x in range(width) if pixels[x, 0] == pixels[x, height - 1]
    ) / width
    return {
        "left_right": round(left_right, 3),
        "top_bottom": round(top_bottom, 3),
    }
