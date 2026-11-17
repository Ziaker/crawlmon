#!/usr/bin/env python3
"""Olhos em combate (D-1268, D-1271, D-1272, D-235): piscar, fechar, BLIND e hit nas duas vistas.

Roda `--scenario=olhos_debug` (sala de VFX, headless, ~10 s) com `--eyes-trace --stdout-trace` e confere os
eventos `eyes`, `eyes_blink` e `eyes_lid` (docs/TELEMETRIA.md, seção Olhos). Vista normal: Pikachu(A1), Eevee(A2)
aliados; Charmander(E1), Squirtle(E2) inimigos. Vista espelhada (`--mirror`): os times trocam de lado.
Uso: python tests/battle/check_eyes_combat.py
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")

VIEWS = {
    "normal": (["--units=pikachu,eevee/charmander,squirtle"], ("Pikachu", "Eevee", "Charmander", "Squirtle")),
    "espelhada": (["--mirror", "--units=charmander,squirtle/pikachu,eevee"], ("Charmander", "Squirtle", "Pikachu", "Eevee")),
}


def run(extra):
    cmd = [GODOT, "--headless", "--path", ROOT, "scenes/debug/vfx_room.tscn", "--", "--scenario=olhos_debug",
           "--eyes-trace", "--stdout-trace", "--quit"] + extra
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=120).stdout
    evs = []
    for ln in out.splitlines():
        if ln.startswith("[TRACE_JSONL] "):
            evs.append(json.loads(ln[len("[TRACE_JSONL] "):]))
    return evs


def check(view, extra, names):
    a1, a2, e1, e2 = names
    evs = run(extra)
    fails = []
    eyes = [e for e in evs if e["ev"] == "eyes"]
    lid = [e for e in evs if e["ev"] == "eyes_lid"]
    blink = [e for e in evs if e["ev"] == "eyes_blink"]

    def edges(actor, **kv):
        return [e for e in eyes if e["data"]["actor"] == actor and all(e["data"][k] == v for k, v in kv.items())]

    def lid_of(actor, t0, t1):
        # eyes_lid só sai quando k muda: vale o último valor antes de t0 (degrau) mais os da janela.
        mine = [e for e in lid if e["data"]["actor"] == actor]
        before = [e["data"]["k"] for e in mine if e["t"] < t0][-1:]
        return before + [e["data"]["k"] for e in mine if t0 <= e["t"] <= t1]

    for n in names:
        if not [e for e in blink if e["data"]["actor"] == n]:
            fails.append("%s nunca piscou (eyes_blink)" % n)
    # A1: fechar forçado -> closed true, depois false, pálpebra chega a 1.0 e segura
    c = edges(a1, closed=True, blind=False, hit=False)
    o = [e for e in edges(a1, closed=False) if c and e["t"] > c[0]["t"]]
    if not c or not o:
        fails.append("%s: sem par fechar/abrir forçado" % a1)
    else:
        held = lid_of(a1, c[0]["t"] + 0.3, o[0]["t"])
        if not held or min(held) < 0.99:
            fails.append("%s: pálpebra não chegou a 1.0 enquanto fechada (%s)" % (a1, held[:5]))
        if o[0]["t"] - c[0]["t"] < 1.2:
            fails.append("%s: fechou por só %.2f s (esperado ~1.4 s)" % (a1, o[0]["t"] - c[0]["t"]))
    # A2: hit forçado -> fecha ~0,5 s
    h = edges(a2, closed=True, hit=True)
    if not h:
        fails.append("%s: sem fechamento por hit" % a2)
    else:
        o2 = [e for e in edges(a2, closed=False) if e["t"] > h[0]["t"]]
        dur = o2[0]["t"] - h[0]["t"] if o2 else -1
        if not (0.40 <= dur <= 0.70):
            fails.append("%s: hit manteve fechado %.2f s (esperado ~0,5)" % (a2, dur))
    # E2: blind -> closed true blind true, depois false, pálpebra 1.0 durante
    b = edges(e2, closed=True, blind=True)
    if not b:
        fails.append("%s: BLIND não fechou" % e2)
    else:
        o3 = [e for e in edges(e2, closed=False) if e["t"] > b[0]["t"]]
        if not o3:
            fails.append("%s: BLIND nunca reabriu" % e2)
        else:
            held = lid_of(e2, b[0]["t"] + 0.4, o3[0]["t"])
            if not held or max(held) < 0.99:
                fails.append("%s: BLIND sem pálpebra 1.0 (%s)" % (e2, held[:5]))
            # nenhuma abertura enquanto cego (blind=true com closed=false)
            if [e for e in eyes if e["data"]["actor"] == e2 and e["data"]["blind"] and not e["data"]["closed"]]:
                fails.append("%s: abriu enquanto cego" % e2)
    print("[%s] eventos eyes=%d eyes_blink=%d eyes_lid=%d -> %s" % (view, len(eyes), len(blink), len(lid), "FALHA" if fails else "OK"))
    for f in fails:
        print("   -", f)
    return not fails


def main():
    ok = True
    for view, (extra, names) in VIEWS.items():
        ok = check(view, extra, names) and ok
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
