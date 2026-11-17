"""D-1204: matriz do ataque no jogo REAL (lab sem nada congelado), em paralelo, ~20 s.

    python tests/overworld/run_attack_real_matrix.py

Cada linha: atacante, alvo, distância centro a centro, quanto esperou antes do Z (0,2 s: o
inimigo ainda arma; 1,0 s: o inimigo já está avançando), fase do inimigo ao apertar Z, se o
alvo foi adquirido, vantagem resultante, quem reagiu, distância de borda no impacto e se o
texto HIT ficou visível.
"""
import itertools
import json
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
PHASES = {0: "NONE", 1: "TELEGRAPH", 2: "DASH", 3: "PRE_DASH", 4: "ENDLAG"}


def run(case):
    sp, tg, dist, wait = case
    cmd = [GODOT, "--headless", "--fixed-fps", "60", "--path", ROOT, "--script",
           "res://tests/overworld/attack_real_scenario.gd", "--",
           f"--sp={sp}", f"--tg={tg}", f"--dist={dist}", f"--wait={wait}"]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=120).stdout
    start = re.search(r"REAL_START: (\{.*\})", out)
    imp = re.search(r"REAL_IMPACT: (\{.*\})", out)
    vis = '"hit_visible":true' in out
    return case, json.loads(start.group(1)) if start else None, json.loads(imp.group(1)) if imp else None, vis


def main():
    cases = list(itertools.product(["abra", "dqt_orc"], ["dqt_cyclops", "dqt_orc"], ["3.0", "5.0"], ["0.2", "1.0"]))
    with ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(run, cases))
    for (sp, tg, dist, wait), start, imp, vis in results:
        s = f"edge={start['edge_gap']:.2f} acq={start['acquired']} enemy={start['enemy_phase']}" if start else "SEM START"
        i = (f"adv={imp['advantage']} victims={imp['contacts']} edge@impact={imp['edge_at_impact']}" if imp else "sem impacto")
        print(f"{sp:8} -> {tg:12} d={dist} wait={wait} | {s} | {i} | HIT visível={vis}")


if __name__ == "__main__":
    sys.exit(main())
