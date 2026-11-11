"""Build A/B sheets from HTML Card C and the Godot literal parity lab."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
HTML = ROOT / "test_captures" / "html_ab"
GODOT = ROOT / "test_captures" / "html_parity"
OUT = ROOT / "test_captures" / "html_ab_sheets"
OUT.mkdir(parents=True, exist_ok=True)

TIMES = [0.30, 0.60, 0.74, 0.75, 0.90, 1.00, 1.05, 1.13, 1.20, 1.35, 1.60, 1.85]
KEY_TIMES = [0.75, 0.90, 1.13]
SIDES = {"a": "A: Alpha ataca Beta", "b": "B: Beta ataca Alpha"}
VIEWS = {"normal": "Normal", "mirrored": "Espelhada"}


def tname(t: float) -> str:
    return f"{t:04.2f}"


def load(directory: Path, prefix: str, view: str, side: str, t: float) -> Image.Image:
    path = directory / f"{prefix}_{view}_{side}_t{tname(t)}.png"
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGB")


def grid(view: str, side: str) -> None:
    cw, ch = 320, 180
    header = 46
    label = 18
    out = Image.new("RGB", (cw * len(TIMES), header + (ch + label) * 2 + 8), (8, 12, 18))
    d = ImageDraw.Draw(out)
    d.text((10, 8), f"Javelin Throw - HTML Card C x Godot literal - {VIEWS[view]} - {SIDES[side]}",
           fill=(255, 245, 210))
    d.text((10, 26), "topo: HTML Three.js (frame exato) | base: Godot 4.7 gl_compatibility (mesma cena/câmera/tempo)",
           fill=(160, 190, 210))
    for i, t in enumerate(TIMES):
        x = i * cw
        y = header
        out.paste(load(HTML, "html", view, side, t).resize((cw, ch)), (x, y))
        d.text((x + 4, y + 2), f"HTML t={tname(t)}", fill=(255, 225, 120))
        y2 = y + ch
        out.paste(load(GODOT, "godot", view, side, t).resize((cw, ch)), (x, y2))
        d.text((x + 4, y2 + 2), f"GODOT t={tname(t)}", fill=(120, 220, 255))
    path = OUT / f"ab_grid_{view}_{side}.png"
    out.save(path)
    print(path)


def key_sheet(view: str, side: str) -> None:
    cw, ch = 640, 360
    header = 54
    label = 20
    out = Image.new("RGB", (cw * len(KEY_TIMES), header + (ch + label) * 2 + 10), (8, 12, 18))
    d = ImageDraw.Draw(out)
    d.text((10, 8), f"Javelin Throw - momentos-chave - {VIEWS[view]} - {SIDES[side]}",
           fill=(255, 245, 210))
    d.text((10, 28), "HTML (topo) x Godot literal (base), mesmo instante e mesmo enquadramento",
           fill=(160, 190, 210))
    for i, t in enumerate(KEY_TIMES):
        x = i * cw
        y = header
        out.paste(load(HTML, "html", view, side, t).resize((cw, ch)), (x, y))
        d.text((x + 6, y + 4), f"HTML t={tname(t)}", fill=(255, 225, 120))
        y2 = y + ch
        out.paste(load(GODOT, "godot", view, side, t).resize((cw, ch)), (x, y2))
        d.text((x + 6, y2 + 4), f"GODOT t={tname(t)}", fill=(120, 220, 255))
    path = OUT / f"ab_key_{view}_{side}.png"
    out.save(path)
    print(path)


def diff(view: str, side: str, t: float) -> None:
    h = load(HTML, "html", view, side, t)
    g = load(GODOT, "godot", view, side, t)
    out = Image.new("RGB", (h.width, h.height * 2 + 30), (8, 12, 18))
    d = ImageDraw.Draw(out)
    d.text((8, 4), f"HTML x GODOT t={tname(t)} - {VIEWS[view]} - {SIDES[side]}", fill=(255, 245, 210))
    out.paste(h, (0, 24))
    out.paste(g, (0, 24 + h.height + 6))
    path = OUT / f"ab_stack_{view}_{side}_t{tname(t)}.png"
    out.save(path)
    print(path)


def main() -> int:
    for view in VIEWS:
        for side in SIDES:
            grid(view, side)
    for view in VIEWS:
        key_sheet(view, "a")
        key_sheet(view, "b")
        diff(view, "a", 1.13)
        diff(view, "a", 0.90)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
