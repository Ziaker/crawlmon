"""Runs the Nature -> Hub transition (D-1237) and prints the data lines.

Usage: python prototypes/nature_hub_transition/run_nht.py [leader=abra] [load_min_ms=1300]
Shots: prototypes/nature_hub_transition/shots/nht_<variant>_<STATE>.png + sheet_<variant>.jpg
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "prototypes" / "nature_hub_transition" / "shots"
STATES = ["EXIT", "LOADING_LOOP", "REVEAL", "FALL", "LAND", "CONTROL"]


def run(variant: str, leader: str, load_min: str) -> bool:
    args = [
        str(ROOT / "Godot_v4.7.2-stable_win64_console.exe"), "--path", str(ROOT),
        "scenes/pre_game.tscn", "--resolution", "1280x720", "--",
        "--nht-auto", "--nature=brave", "--nht-summary", "--nht-quit",
        f"--nht-load-min={load_min}", f"--species={leader}", f"--player={leader}", f"--leader={leader}",
        "--nht-shots=res://prototypes/nature_hub_transition/shots",
    ]
    out = subprocess.run(args, capture_output=True, text=True, timeout=55, errors="replace")
    text = out.stdout + out.stderr
    ok = False
    for line in text.splitlines():
        if line.startswith(("NHT_SUMMARY", "NHT_HUB", "NHT_ERROR", "NHT_WARN")) or "SCRIPT ERROR" in line or "Parse Error" in line:
            print(variant, line[:400])
            ok = ok or ('"ok":true' in line)
    try:
        from PIL import Image
        sheet = Image.new("RGB", (480 * 3, 270 * 2))
        for i, s in enumerate(STATES):
            im = Image.open(SHOTS / f"nht_{variant}_{s}.png").convert("RGB").resize((480, 270))
            sheet.paste(im, ((i % 3) * 480, (i // 3) * 270))
        sheet.save(SHOTS / f"sheet_{variant}.jpg", quality=80)
    except Exception as exc:  # shots are optional
        print(variant, "sheet skipped:", exc)
    return ok


if __name__ == "__main__":
    leader = sys.argv[1] if len(sys.argv) > 1 else "abra"
    load_min = sys.argv[2] if len(sys.argv) > 2 else "1300"
    SHOTS.mkdir(parents=True, exist_ok=True)
    sys.exit(0 if run("c", leader, load_min) else 1)
