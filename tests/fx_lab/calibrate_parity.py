"""Sweep Godot parity lighting presets against the HTML Card C frames.

The HTML uses Three.js/ACES; Godot uses ACES with different light units. This
script finds the closest Godot light/exposure/background combination for the
literal port, using fixed sample points in the same 1280x720 frame.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "Godot_v4.7.2-stable_win64_console.exe"
OUT = ROOT / "test_captures" / "html_parity_cal"
HTML = ROOT / "test_captures" / "html_ab"

# Scene-only samples (avoid VFX pixels so lighting is compared, not the effect).
POINTS = {
    "bg": (10, 10),
    "floor_lit": (700, 500),
    "floor_shadow": (400, 450),
    "actor_torso": (450, 550),
    "target_accent": (600, 300),
    "pillar": (800, 300),
}

PRESETS = [
    ("a", 0.04, 0.80, 0.05, "#18202A", 1.18),
    ("b", 0.06, 1.00, 0.06, "#18202A", 1.18),
    ("c", 0.08, 1.20, 0.08, "#18202A", 1.18),
    ("d", 0.10, 1.40, 0.10, "#18202A", 1.18),
    ("e", 0.05, 0.80, 0.05, "#141C26", 1.18),
    ("f", 0.07, 1.00, 0.07, "#141C26", 1.18),
]


def run_godot(tag: str, amb: float, key: float, rim: float, bg: str, exp: float) -> None:
    out = OUT / tag
    out.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(GODOT),
        "--path", str(ROOT),
        "--resolution", "1280x720",
        "--rendering-method", "gl_compatibility",
        "res://scenes/debug/javelin_html_parity_lab.tscn",
        "--",
        "--parity-capture",
        "--parity-view=normal",
        "--parity-side=a",
        "--parity-times=0.60,1.13",
        "--parity-out=res://" + str(out.relative_to(ROOT)).replace("\\", "/"),
        f"--parity-ambient={amb}",
        f"--parity-key={key}",
        f"--parity-rim={rim}",
        f"--parity-bg={bg}",
        f"--parity-exposure={exp}",
    ]
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=180)
    if proc.returncode not in (0, 1):
        print(proc.stdout)
        print(proc.stderr)
        raise SystemExit(f"godot failed for {tag}: {proc.returncode}")


def score(tag: str) -> dict:
    h = Image.open(HTML / "html_normal_a_t0.60.png").convert("RGB")
    g = Image.open(OUT / tag / "godot_normal_a_t0.60.png").convert("RGB")
    rows = {}
    total = 0.0
    for name, p in POINTS.items():
        hc = h.getpixel(p)
        gc = g.getpixel(p)
        d = sum(abs(a - b) for a, b in zip(hc, gc)) / 3.0
        rows[name] = {"html": hc, "godot": gc, "d": round(d, 1)}
        total += d
    rows["_mean"] = round(total / len(POINTS), 2)
    return rows


def main() -> int:
    results = {}
    for tag, amb, key, rim, bg, exp in PRESETS:
        print(f"== {tag}: amb={amb} key={key} rim={rim} bg={bg} exp={exp}")
        run_godot(tag, amb, key, rim, bg, exp)
        results[tag] = score(tag)
        print(json.dumps(results[tag], indent=1))
    (OUT / "calibration.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    best = min(results.items(), key=lambda kv: kv[1]["_mean"])
    print(f"BEST: {best[0]} mean={best[1]['_mean']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
