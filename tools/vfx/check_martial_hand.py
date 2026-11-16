"""D-1218: numeric conformance test of the Karate Chop hand against the creator's words (D-1209).

Usage: python tools/vfx/check_martial_hand.py [scenario ...]   (default: karate_holo karate_holo_esp)
Runs the debug room headless with --stdout-trace, reads the `martial_hand` events and asserts the
choreography. Writes a speed/height graph to tests/battle/_shots/martial_hand_<scenario>.png (PIL).
Exit code 1 if any assertion fails.
"""
import json
import math
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
PRELUDE = 0.20  # creator: "TUDO ISSO EM .20 SEGUNDOS DO PRELUDE"
FADE = 0.85     # creator: "sumindo lentamente ... .85 segundos"
FLOOR = 0.2


def run(scn):
    out = subprocess.run([GODOT, "--headless", "--path", ROOT, "res://scenes/debug/vfx_room.tscn", "--",
                          "--scenario=" + scn, "--stdout-trace", "--quit"],
                         capture_output=True, text=True, timeout=100).stdout
    rows = []
    for line in out.splitlines():
        if line.startswith("[TRACE_JSONL] ") and '"martial_hand"' in line:
            o = json.loads(line[14:])
            d = o["data"]
            d["t"] = o["t"]
            rows.append(d)
    return rows


def span(rows, stage):
    r = [x["t"] for x in rows if x["stage"] == stage]
    return (r[0], r[-1]) if r else (None, None)


def check(scn, rows):
    res = []

    def ok(name, cond, detail=""):
        res.append((name, bool(cond), detail))

    ok("hand telemetry exists", len(rows) > 50, "%d rows" % len(rows))
    if len(rows) <= 50:
        return res
    after = [r for r in rows if r["stage"] not in ("windup", "fade")]
    ok("never hidden after wind-up (form>=0.99, fade>0.02)", all(r["form"] >= 0.99 and r["fade"] > 0.02 for r in after))
    ok("never below floor (y>=%.2f)" % FLOOR, all(r["pos"][1] >= FLOOR for r in rows), "min y %.2f" % min(r["pos"][1] for r in rows))
    ok("no teleport (speed<60 m/s outside run)", all(r["speed"] < 60 for r in rows if r["stage"] != "run"),
       "max %.1f" % max(r["speed"] for r in rows if r["stage"] != "run"))
    j0, j1 = span(rows, "jump")
    c0, c1 = span(rows, "cut")
    p0, p1 = span(rows, "post")
    f0, f1 = span(rows, "fade")
    ok("stages in order run->jump->cut->post->fade", None not in (j0, c0, p0, f0) and j0 < c0 < p0 < f0)
    if None in (j0, c0, p0, f0):
        return res
    ok("prelude lasts %.2f s +-0.04" % PRELUDE, abs((c0 - j0) - PRELUDE) <= 0.04, "%.3f s" % (c0 - j0))
    cut = [r for r in rows if r["stage"] == "cut"]
    ok("cut window 0.16 s +-0.04", abs((p0 - c0) - 0.16) <= 0.04, "%.3f s" % (p0 - c0))
    peak = max(rows, key=lambda r: r["speed"] if r["stage"] in ("jump", "cut", "post") else -1)
    ok("speed peak inside the cut", peak["stage"] == "cut", "peak %.1f m/s in %s" % (peak["speed"], peak["stage"]))
    ok("no stall in the cut (speed>0.05 on all rows)", all(r["speed"] > 0.05 for r in cut[1:]))
    post = [r for r in rows if r["stage"] in ("post", "fade")]
    ok("friction after the cut (post speed < 15% of peak)", max(r["speed"] for r in post[3:]) < 0.15 * peak["speed"],
       "post max %.1f" % max(r["speed"] for r in post[3:]))
    ok("fade stays 1.0 until landing", all(r["fade"] >= 0.999 for r in rows if r["stage"] == "post"))
    ok("fade lasts %.2f s +-0.1 then ends" % FADE, abs((f1 - f0) - FADE) <= 0.1, "%.3f s" % (f1 - f0))
    jump = [r for r in rows if r["stage"] == "jump"]
    ok("grows to ~x1.35 in the prelude", jump[-1]["scale"][0] / max(jump[0]["scale"][0], 1e-6) >= 1.2,
       "x%.2f" % (jump[-1]["scale"][0] / max(jump[0]["scale"][0], 1e-6)))
    ok("prelude does not drop the hand below the target centre", min(r["pos"][1] for r in jump) >= cut[0]["geo"]["c"][1] - 0.01,
       "min y %.2f vs centre %.2f" % (min(r["pos"][1] for r in jump), cut[0]["geo"]["c"][1]))
    d = cut[0].get("geo", {}).get("dir")
    if d:
        a, b = cut[0]["pos"], cut[-1]["pos"]
        v = [b[0] - a[0], b[1] - a[1], b[2] - a[2]]
        along = abs(v[0] * d[0] + v[2] * d[2])
        total = math.sqrt(sum(x * x for x in v)) or 1e-6
        ok("cut is a visible diagonal (axis share < 50%)", along / total < 0.5, "axis share %.2f" % (along / total))
    return res


def graph(scn, rows):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    W, H = 900, 360
    im = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(im)
    t0, t1 = rows[0]["t"], rows[-1]["t"]
    vmax = max(max(r["speed"] for r in rows if r["stage"] != "run"), 1.0)
    colors = {"windup": "gray", "run": "blue", "jump": "orange", "cut": "red", "post": "green", "fade": "purple"}
    for i in range(1, len(rows)):
        a, b = rows[i - 1], rows[i]
        x = lambda r: (r["t"] - t0) / (t1 - t0) * (W - 20) + 10
        y = lambda v: H - 10 - min(v, vmax) / vmax * (H - 20)
        dr.line([x(a), y(a["speed"]), x(b), y(b["speed"])], fill=colors.get(b["stage"], "black"), width=2)
        dr.line([x(a), H - 10 - a["fade"] * 40, x(b), H - 10 - b["fade"] * 40], fill="black")
    dr.text((12, 4), "%s: hand speed (m/s, max %.0f), black=fade; gray wind-up blue run orange prelude red cut green post purple fade" % (scn, vmax), fill="black")
    out = os.path.join(ROOT, "tests", "battle", "_shots")
    os.makedirs(out, exist_ok=True)
    im.save(os.path.join(out, "martial_hand_%s.png" % scn))


def main():
    scns = sys.argv[1:] or ["karate_holo", "karate_holo_esp"]
    bad = 0
    for scn in scns:
        rows = run(scn)
        print("== %s" % scn)
        for name, passed, detail in check(scn, rows):
            print("  [%s] %s %s" % ("OK" if passed else "FAIL", name, detail))
            bad += 0 if passed else 1
        if rows:
            graph(scn, rows)
    print("MARTIAL_HAND_CHECK_%s" % ("PASS" if bad == 0 else "FAIL(%d)" % bad))
    sys.exit(1 if bad else 0)


main()
