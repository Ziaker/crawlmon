"""Occluder brightness regression (D-356).

Measures the centre of the room in the 10 seed captures and compares it with
the approved baseline. A face-aware occluder must not darken the floor; the
wall mass may get darker, but the playable centre must stay readable.

Usage:
  Godot ... --path . scratch/capture_exploration_seeds.tscn
  python tools/pmd_import/check_occluder_brightness.py
  python tools/pmd_import/check_occluder_brightness.py --baseline
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SEEDS = [1, 2, 3, 7, 42, 777, 2026, 12345, 54321, 99999]
CAPTURE = ROOT / "scratch" / "exploration_seed_{seed}.png"
BASELINE = ROOT / "scratch" / "occluder_baseline.json"


def centre_mean(path: Path) -> float:
    image = Image.open(path).convert("L")
    arr = np.asarray(image, dtype=float)
    height, width = arr.shape
    return float(arr[int(height * 0.30):int(height * 0.70),
                     int(width * 0.25):int(width * 0.75)].mean())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", action="store_true",
                        help="write the current values as the approved baseline")
    args = parser.parse_args()

    values = {}
    missing = []
    for seed in SEEDS:
        path = Path(str(CAPTURE).format(seed=seed))
        if not path.exists():
            missing.append(path.name)
            continue
        values[str(seed)] = round(centre_mean(path), 1)
    if missing:
        print(f"missing captures: {missing}")
        return 2

    if args.baseline:
        BASELINE.write_text(json.dumps({"seeds": values}, indent=2) + "\n", encoding="utf-8")
        print(f"baseline written: {BASELINE.relative_to(ROOT).as_posix()}")
        print(json.dumps(values, indent=1))
        return 0

    if not BASELINE.exists():
        print(f"missing baseline: {BASELINE}")
        return 2
    baseline = json.loads(BASELINE.read_text(encoding="utf-8")).get("seeds", {})
    failed = []
    for seed, current in values.items():
        reference = float(baseline.get(seed, current))
        delta = (current - reference) / reference if reference else 0.0
        status = "OK" if abs(delta) <= 0.12 else "FAIL"
        print(f"seed {seed:>5}: current {current:5.1f}  baseline {reference:5.1f}  "
              f"delta {delta * 100:+5.1f}%  {status}")
        if abs(delta) > 0.12:
            failed.append(seed)
    print("occluder brightness:", "OK" if not failed else f"FAIL {failed}")
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
