"""Compose the HTML x Godot A/B video (normal, side A, 20 fps)."""
from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "test_captures" / "ab_video"
OUT = SRC / "frames"
OUT.mkdir(parents=True, exist_ok=True)

TIMES = [i * 0.05 for i in range(38)]
W, H = 1280, 720
BAR = 30
FONT_PATH = r"C:\Windows\Fonts\arialbd.ttf"
try:
    FONT = ImageFont.truetype(FONT_PATH, 22)
except OSError:
    FONT = ImageFont.load_default()


def tname(t: float) -> str:
    return f"{t:04.2f}"


def main() -> int:
    for idx, t in enumerate(TIMES):
        h = Image.open(SRC / "html" / f"html_normal_a_t{tname(t)}.png").convert("RGB")
        g = Image.open(SRC / "godot" / f"godot_normal_a_t{tname(t)}.png").convert("RGB")
        frame = Image.new("RGB", (W, (H + BAR) * 2 + 8), (6, 10, 16))
        d = ImageDraw.Draw(frame)
        d.text((10, 4), f"HTML Card C  t={tname(t)}s", font=FONT, fill=(255, 225, 120))
        frame.paste(h, (0, BAR))
        y = BAR + H + 8
        d.text((10, y - BAR + 4), f"GODOT 4.7 literal  t={tname(t)}s", font=FONT, fill=(120, 220, 255))
        frame.paste(g, (0, y))
        frame.save(OUT / f"{idx:04d}.png")
    video = SRC / "javelin_html_vs_godot.mp4"
    cmd = [
        "ffmpeg", "-y", "-framerate", "20", "-i", str(OUT / "%04d.png"),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(video),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    print((proc.stdout or "")[-400:])
    print((proc.stderr or "")[-400:])
    print(video)
    return 0 if proc.returncode == 0 else proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
