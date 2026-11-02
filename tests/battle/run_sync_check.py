"""Headless regression check for the battle: rules and drawing must stay in step.

Runs a few seeded AI-vs-AI battles (the leader plays itself with --drive) with the flight
recorder on, then fails if the trace shows any of the hard anomalies: damage applied while
the attacker or projectile is not at its target (rules positions), the attack clip off its
contact frame, a body teleporting, a dead body still attacking, or any script error.

    python tests/battle/run_sync_check.py [seed ...]

Needs the Godot console build next to project.godot (or set GODOT=path). Takes about a
minute per seed.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
TRACE = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Crawlmon", "battle_trace.jsonl")
HARD = {"MELEE_HIT_FAR", "PROJ_HIT_FAR", "ANIM_DRIFT", "TELEPORT", "TOO_FAST", "DEAD_ATTACKING", "REAPPEAR_FAR", "SCALE_POP"}


def run(seed):
    proc = subprocess.run(
        [GODOT, "--headless", "--fixed-fps", "60", "--path", ROOT, "res://scenes/battle.tscn",
         "--quit-after", "9000", "--", "--trace", "--drive", "--seed=%d" % seed],
        capture_output=True, text=True, timeout=600)
    errors = [l for l in (proc.stdout + proc.stderr).splitlines() if "ERROR" in l]
    anomalies = {}
    hits = 0
    with open(TRACE, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            if row.get("ev") == "ANOMALY":
                kind = row["data"]["kind"]
                anomalies[kind] = anomalies.get(kind, 0) + 1
            elif row.get("ev") == "hit":
                hits += 1
    return errors, anomalies, hits


def unit_test():
    proc = subprocess.run([GODOT, "--headless", "--path", ROOT, "--script", "res://tests/battle/test_attack_motion.gd"],
                          capture_output=True, text=True, timeout=300)
    ok = "BATTLE_MOTION_TEST_PASS" in proc.stdout
    print("rules (test_attack_motion.gd): %s" % ("ok" if ok else "FAIL"))
    if not ok:
        print((proc.stdout + proc.stderr)[-1500:])
    return ok


def main():
    failed = not unit_test()
    seeds = [int(a) for a in sys.argv[1:]] or [1, 2, 3, 4]
    for seed in seeds:
        errors, anomalies, hits = run(seed)
        bad = {k: v for k, v in anomalies.items() if k in HARD}
        status = "FAIL" if (errors or bad) else "ok"
        print("seed %d: %s  hits=%d  hard=%s  errors=%d" % (seed, status, hits, bad or "-", len(errors)))
        for e in errors[:5]:
            print("   ", e)
        failed = failed or status == "FAIL"
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
