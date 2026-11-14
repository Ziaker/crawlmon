#!/usr/bin/env python3
"""D-1204/D-235: the Dig Knock-up against every character the room can seat, in 4 party layouts, as a table of numbers.
Layouts: normal (Abra/Pancham/Gible vs Cyclops/Orc), --mirror, --dqt (Cyclops/Orc/Slime on the player side), --dqt-mirror.
For each layout, the player side and then the enemy side attack with Dig (`--move=Dig --attacker=<side> --target=opponent --force=hit`).
`--card-trace` prints the knocked card's base position every frame; per run we check: samples, duration (~1.3 s), k reaches 1,
max frame-to-frame step of the card base <= 3 px (smooth), no SCRIPT ERROR. Usage: python tools/knockup_all_chars.py [--jobs 3]"""
import re, subprocess, sys, argparse, itertools
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = ROOT / "Godot_v4.7.2-stable_win64_console.exe"
LAYOUTS = {"normal": [], "mirror": ["--mirror"], "dqt": ["--dqt"], "dqt-mirror": ["--dqt-mirror"]}
LINE = re.compile(r"\[card-trace\] t=([\d.]+) tag=(\S+) base=\(([-\d.]+),([-\d.]+)\) k=([\d.]+)")


def run(job):
    layout, side = job
    argv = [str(GODOT), "--path", str(ROOT), "res://scenes/debug/vfx_room.tscn", "--", "--move=Dig", f"--attacker={side}",
            "--target=opponent", "--force=hit", "--card-trace", "--quit", *LAYOUTS[layout]]
    try:
        out = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=100, errors="replace").stdout
    except subprocess.TimeoutExpired:
        return layout, side, "TIMEOUT", {}
    rows = [(float(m[1]), m[2], float(m[3]), float(m[4]), float(m[5])) for m in map(LINE.search, out.splitlines()) if m]
    units = re.search(r"cli units: (\[.*?\])", out)
    info = {"units": units.group(1) if units else "?", "n": len(rows)}
    if len(rows) < 5:
        return layout, side, "FAIL no card-trace samples (no hit / no knock-up?)", info
    ts = [r[0] for r in rows]
    # px per 1/60 s: a slow frame (the machine is loaded by parallel runs) must not look like a jump
    steps = [max(abs(rows[i][2] - rows[i - 1][2]), abs(rows[i][3] - rows[i - 1][3])) * (1 / 60) / max(rows[i][0] - rows[i - 1][0], 1 / 240) for i in range(1, len(rows))]
    step = max(steps)
    info.update(who=rows[0][1], dur=ts[-1] - ts[0], kmax=max(r[4] for r in rows), step=step, at_k=rows[steps.index(step) + 1][4])
    bad = []
    if "SCRIPT ERROR" in out: bad.append("script error")
    if info["dur"] < 1.0: bad.append("short flight")
    if info["kmax"] < 0.9: bad.append("k<0.9")
    if step > 3.0: bad.append("not smooth")
    return layout, side, ("FAIL " + ", ".join(bad)) if bad else "PASS", info


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--jobs", type=int, default=2); a = ap.parse_args()
    jobs = list(itertools.product(LAYOUTS, ["player", "enemy"]))
    with ThreadPoolExecutor(a.jobs) as ex:
        res = list(ex.map(run, jobs))
    print(f"{'layout':11} {'attacker':8} {'knocked':9} {'samples':>7} {'dur':>5} {'kmax':>5} {'step':>10}  result")
    fails = 0
    for layout, side, verdict, i in res:
        fails += verdict != "PASS"
        print(f"{layout:11} {side:8} {i.get('who','-'):9} {i.get('n',0):7} {i.get('dur',0):5.2f} {i.get('kmax',0):5.2f} {i.get('step',0):5.1f}@k{i.get('at_k',0):.2f}  {verdict}  {i.get('units','')}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
