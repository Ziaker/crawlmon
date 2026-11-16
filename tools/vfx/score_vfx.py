"""D-1220: Unified VFX & Motion Scorecard for Crawlmon Moves.

Runs vfx_room.tscn headless in Normal + Mirrored views, parses SUMMARY_JSON and
[TRACE_JSONL] vfx_frame kinematic events, validates universal + archetype motion
invariants (plus optional tests/vfx/specs/<slug>.json), and plots a 2-panel
speed/alpha + overlaid Normal-vs-Mirrored trajectory PNG.

Usage:
  python tools/vfx/score_vfx.py --move="Fire Bullet"
  python tools/vfx/score_vfx.py --move="Karate Chop" --archetype=melee_strike
"""
import argparse
import concurrent.futures
import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
SPECS_DIR = os.path.join(ROOT, "tests", "vfx", "specs")
REGRESSIONS_PATH = os.path.join(ROOT, "tests", "vfx", "regressions.json")
SHOTS_DIR = os.path.join(ROOT, "tests", "battle", "_shots")


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.strip().lower()).strip("_")


def run_view(move: str, mirror: bool, timeout_s: int) -> dict:
    cmd = [
        GODOT, "--headless", "--path", ROOT, "res://scenes/debug/vfx_room.tscn", "--",
        f"--move={move}", "--vfx-trace", "--summary-json", "--quit",
    ]
    if mirror:
        cmd.append("--mirror")
    t0 = time.time()
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    elapsed = time.time() - t0
    summary = {}
    frames = []
    hits = []
    for line in proc.stdout.splitlines():
        if line.startswith("[vfx_room] SUMMARY_JSON: "):
            try:
                summary = json.loads(line.split("SUMMARY_JSON: ", 1)[1])
            except json.JSONDecodeError:
                pass
        elif line.startswith("[TRACE_JSONL] "):
            try:
                obj = json.loads(line[14:])
            except json.JSONDecodeError:
                continue
            ev = obj.get("ev")
            if ev == "vfx_frame":
                row = dict(obj.get("data", {}))
                row["t"] = obj.get("t", 0.0)
                frames.append(row)
            elif ev == "hit":
                hits.append(obj.get("t", 0.0))
    return {
        "mirror": mirror,
        "returncode": proc.returncode,
        "elapsed": elapsed,
        "summary": summary,
        "frames": frames,
        "hits": hits,
    }


def infer_archetype(move: str, summary: dict, spec: dict) -> str:
    if spec.get("archetype"):
        return spec["archetype"]
    ficha = summary.get("ficha_fases", {})
    blob = (move + " " + " ".join(str(v) for v in ficha.values())).lower()
    if any(k in blob for k in ("buff", "debuff", "aura", "heal", "guard", "escudo", "selo")):
        return "status_aura"
    if any(k in blob for k in ("onda", "wave", "surge", "aoe", "todos")):
        return "aoe_wave"
    if any(k in blob for k in ("projétil", "projetil", "bullet", "beam", "bolt", "javelin", "bubble", "voo")):
        return "projectile_travel"
    return "melee_strike"


NOISE_NODE_PREFIXES = ("evadeflash", "@label3d", "dmgpopup", "floatingtext")


def is_vfx_node(name: str) -> bool:
    low = str(name).lower()
    return not any(low.startswith(p) for p in NOISE_NODE_PREFIXES)


def group_by_node(frames: list) -> dict:
    by_node = {}
    for r in frames:
        n = r.get("node", "?")
        if is_vfx_node(n):
            by_node.setdefault(n, []).append(r)
    return by_node


def primary_track(frames: list, archetype: str) -> tuple:
    by_node = group_by_node(frames)
    if not by_node:
        return "", []
    if archetype == "projectile_travel":
        # Prefer moving mesh/node with >= 4 frames and real progress span over static impact emitters
        moving = {
            k: v for k, v in by_node.items()
            if len(v) >= 4 and (max(r["progress"] for r in v) - min(r["progress"] for r in v)) > 0.05
        }
        pool = moving or by_node
        def _proj_key(kv):
            name, rows = kv
            span = max(r["progress"] for r in rows) - min(r["progress"] for r in rows)
            is_mesh = 1 if ("Particle" not in str(rows[0].get("kind", "")) and "CPUParticles" not in name) else 0
            return (is_mesh, span, len(rows))
        return max(pool.items(), key=_proj_key)
    def _melee_key(kv):
        name, rows = kv
        peak = max((r.get("speed", 0.0) for r in rows), default=0.0)
        is_hand = 1 if ("hand" in name.lower() or "blade" in name.lower() or "slash" in name.lower()) else 0
        return (is_hand, peak, len(rows))
    return max(by_node.items(), key=_melee_key)


def run_visual_silhouette(move: str, timeout_s: int) -> dict:
    try:
        from PIL import Image
    except ImportError:
        return {"ok": False, "reason": "PIL missing"}
    os.makedirs(SHOTS_DIR, exist_ok=True)
    slug = slugify(move)
    p_blk = os.path.join(SHOTS_DIR, f"vis_{slug}_black.png")
    p_wht = os.path.join(SHOTS_DIR, f"vis_{slug}_white.png")
    for bg, path in (("black", p_blk), ("white", p_wht)):
        cmd = [
            GODOT, "--path", ROOT, "res://scenes/debug/vfx_room.tscn", "--",
            f"--move={move}", "--no-panel", f"--bg={bg}", "--pause-at=impact", f"--shot={path}", "--quit",
        ]
        subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    if not (os.path.isfile(p_blk) and os.path.isfile(p_wht)):
        return {"ok": False, "reason": "shot capture failed"}
    ib = Image.open(p_blk).convert("RGB")
    iw = Image.open(p_wht).convert("RGB")
    pb, pw = ib.load(), iw.load()
    w, h = ib.size
    sil = Image.new("RGB", (w, h), (0, 0, 0))
    ps = sil.load()
    vis_b = vis_w = vis_both = 0
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            rb, gb, bb = pb[x, y]
            rw, gw, bw = pw[x, y]
            on_b = max(rb, gb, bb) > 18
            on_w = min(rw, gw, bw) < 235
            if on_b:
                vis_b += 1
            if on_w:
                vis_w += 1
            if on_b and on_w:
                vis_both += 1
                ps[x, y] = (255, 255, 255)
            elif on_b:
                ps[x, y] = (0, 220, 255)
            elif on_w:
                ps[x, y] = (255, 140, 0)
    total = max((w // 2) * (h // 2), 1)
    sil_path = os.path.join(SHOTS_DIR, f"silhouette_{slug}.png")
    sil.save(sil_path)
    return {
        "ok": True,
        "cov_black_pct": round(100.0 * vis_b / total, 2),
        "cov_white_pct": round(100.0 * vis_w / total, 2),
        "cov_both_pct": round(100.0 * vis_both / total, 2),
        "silhouette_path": sil_path,
    }


def eval_view(view: dict, archetype: str, spec: dict) -> tuple:
    s = view["summary"]
    frames = view["frames"]
    checks = []

    def add(name: str, ok: bool, detail: str) -> None:
        checks.append((name, bool(ok), detail))

    spawns = s.get("vfx_spawns", [])
    add("spawns", len(spawns) > 0, f"count={len(spawns)}")

    phases = s.get("phases_reached", [])
    req_phases = spec.get("require_phases", ["impact"] if archetype != "status_aura" else [])
    missing_ph = [p for p in req_phases if p not in phases]
    add("phases", len(missing_ph) == 0, f"reached={phases}" if not missing_ph else f"missing={missing_ph}")

    pops = s.get("envelope_pops", [])
    add("no_pops", len(pops) <= int(spec.get("max_pops", 0)), f"pops={len(pops)} {pops[:2]}")

    leaks = int(s.get("leaks_detected", 0))
    max_leaks = int(spec.get("max_leaks", 0))
    add("leaks", leaks <= max_leaks, f"leaks={leaks} (max={max_leaks})")

    vis_frames = [r for r in frames if is_vfx_node(r.get("node", "")) and r.get("visible") and r.get("alpha", 0.0) > 0.05]
    max_px = max((max(r.get("screen_px", [0.0, 0.0])) for r in vis_frames), default=0.0)
    min_px = float(spec.get("min_screen_px", 20.0))
    add("screen_readability", max_px >= min_px, f"max_px={max_px:.1f} (min={min_px:.1f})")

    underground = [r for r in vis_frames if r.get("height_y", 0.0) < -0.15]
    add("no_underground", len(underground) == 0, f"violations={len(underground)}")

    forbid = [f.lower() for f in spec.get("forbid_nodes", [])]
    if forbid:
        bad_nodes = [n for n in spawns if any(f in str(n).lower() for f in forbid)]
        add("forbidden_nodes", len(bad_nodes) == 0, f"found={bad_nodes}")

    node_name, track = primary_track(frames, archetype)
    if track:
        speeds = [r.get("speed", 0.0) for r in track]
        peak_row = max(track, key=lambda r: r.get("speed", 0.0))
        if archetype == "projectile_travel":
            max_prog = max(r["progress"] for r in track)
            min_dist = min(r["dist_to_target"] for r in track)
            add("proj_reaches_target", max_prog >= 0.70 or min_dist <= 2.5,
                f"node={node_name} max_prog={max_prog:.2f} min_dist={min_dist:.2f}m")
            progs = [r["progress"] for r in track]
            back_jumps = [progs[i] - progs[i - 1] for i in range(1, len(progs)) if progs[i] - progs[i - 1] < -0.20]
            add("proj_no_back_teleport", len(back_jumps) == 0, f"jumps={len(back_jumps)}")
            travel_rows = [r for r in track if r.get("stage") in ("travel", "strike")]
            stalls, cur = 0, 0
            for r in travel_rows:
                cur = cur + 1 if r.get("speed", 0.0) < 0.5 else 0
                stalls = max(stalls, cur)
            add("proj_no_mid_stall", stalls <= 4, f"max_stall_frames={stalls}")
        elif archetype == "melee_strike":
            peak_spd = peak_row.get("speed", 0.0)
            add("melee_peak_speed", peak_spd >= 2.0, f"node={node_name} peak={peak_spd:.1f}m/s")
            cd = peak_row.get("contact_delta_s")
            if cd is not None:
                add("melee_contact_sync", abs(float(cd)) <= 0.25, f"contact_delta={float(cd):+.3f}s")
        elif archetype == "aoe_wave":
            wave_vis = [r for r in vis_frames if r.get("stage") in ("travel", "strike", "impact")]
            add("aoe_wave_active", len(wave_vis) > 0, f"active_frames={len(wave_vis)}")
        elif archetype == "status_aura":
            # Anchored either at target (progress~1, dist<=4.5) or at caster/self-buff (abs(progress)<=0.15)
            far = [r for r in vis_frames if r.get("dist_to_target", 0.0) > 4.5 and abs(r.get("progress", 0.0)) > 0.15]
            add("status_anchored", len(far) == 0, f"unanchored_frames={len(far)}")

        # D-1222: Move = 3D, never 2D (require 3D rotation or multi-axis 3D curve unless spec allows 2D)
        if archetype in ("melee_strike", "projectile_travel") and not spec.get("allow_2d", False):
            max_ang = max((r.get("ang_speed", 0.0) for r in track), default=0.0)
            lat_vals = [r.get("lateral_offset", 0.0) for r in track]
            y_vals = [r.get("height_y", 0.0) for r in track]
            lat_span = (max(lat_vals) - min(lat_vals)) if lat_vals else 0.0
            y_span = (max(y_vals) - min(y_vals)) if y_vals else 0.0
            is_3d = (max_ang >= 15.0) or (lat_span >= 0.15 and y_span >= 0.10)
            add("d1222_3d_motion", is_3d,
                f"max_ang={max_ang:.1f}deg/s lat_span={lat_span:.2f}m y_span={y_span:.2f}m")

    return checks, {"node": node_name, "track": track, "max_px": max_px}


def save_graph(move: str, norm: dict, mirr: dict, norm_meta: dict, mirr_meta: dict) -> str:
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return ""
    W, H = 960, 700
    im = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(im)
    dr.line([10, 230, W - 10, 230], fill="#cccccc", width=1)
    dr.line([10, 465, W - 10, 465], fill="#cccccc", width=1)
    dr.text((14, 8), f"VFX 3D Scorecard: {move} | Blue=Normal ({norm_meta['node']})  Orange=Mirrored ({mirr_meta['node']})", fill="black")

    def plot_top(track: list, color: str) -> None:
        if len(track) < 2:
            return
        t0, t1 = track[0]["t"], max(track[-1]["t"], track[0]["t"] + 0.01)
        vmax = max(max(r.get("speed", 0.0) for r in track), 1.0)
        for i in range(1, len(track)):
            a, b = track[i - 1], track[i]
            x0 = 20 + (a["t"] - t0) / (t1 - t0) * (W - 40)
            x1 = 20 + (b["t"] - t0) / (t1 - t0) * (W - 40)
            y0 = 218 - min(a.get("speed", 0.0), vmax) / vmax * 180
            y1 = 218 - min(b.get("speed", 0.0), vmax) / vmax * 180
            dr.line([x0, y0, x1, y1], fill=color, width=2)

    plot_top(norm_meta["track"], "#1e66f5")
    plot_top(mirr_meta["track"], "#fe640b")

    all_pts = norm_meta["track"] + mirr_meta["track"]
    dr.text((14, 238), "3D Side View: X = progress (0..1)  Y = height_y (m)", fill="black")
    ymin = min((r.get("height_y", 0.0) for r in all_pts), default=0.0)
    ymax = max((r.get("height_y", 2.0) for r in all_pts), default=2.0)
    if ymax - ymin < 0.5:
        ymax = ymin + 0.5

    def plot_xy(track: list, key: str, lo: float, hi: float, bottom_y: int, span_h: int, color: str) -> None:
        if len(track) < 2:
            return
        for i in range(1, len(track)):
            a, b = track[i - 1], track[i]
            x0 = 20 + max(-0.2, min(1.3, a["progress"])) / 1.5 * (W - 40)
            x1 = 20 + max(-0.2, min(1.3, b["progress"])) / 1.5 * (W - 40)
            y0 = bottom_y - (a.get(key, 0.0) - lo) / (hi - lo) * span_h
            y1 = bottom_y - (b.get(key, 0.0) - lo) / (hi - lo) * span_h
            dr.line([x0, y0, x1, y1], fill=color, width=2)

    plot_xy(norm_meta["track"], "height_y", ymin, ymax, 452, 185, "#1e66f5")
    plot_xy(mirr_meta["track"], "height_y", ymin, ymax, 452, 185, "#fe640b")

    dr.text((14, 473), "3D Top-Down View (D-1222): X = progress (0..1)  Y = lateral_offset (m)", fill="black")
    lmin = min((r.get("lateral_offset", 0.0) for r in all_pts), default=-1.0)
    lmax = max((r.get("lateral_offset", 1.0) for r in all_pts), default=1.0)
    l_abs = max(abs(lmin), abs(lmax), 0.5)
    plot_xy(norm_meta["track"], "lateral_offset", -l_abs, l_abs, H - 18, 185, "#1e66f5")
    plot_xy(mirr_meta["track"], "lateral_offset", -l_abs, l_abs, H - 18, 185, "#fe640b")

    os.makedirs(SHOTS_DIR, exist_ok=True)
    out_path = os.path.join(SHOTS_DIR, f"score_{slugify(move)}.png")
    im.save(out_path)
    return out_path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--move", required=True)
    ap.add_argument("--archetype", default="auto")
    ap.add_argument("--spec", default="")
    ap.add_argument("--no-graph", action="store_true")
    ap.add_argument("--visual", action="store_true", help="Also run windowed black/white silhouette contrast pass")
    ap.add_argument("--timeout", type=int, default=60)
    args = ap.parse_args()

    spec = {}
    spec_path = args.spec or os.path.join(SPECS_DIR, f"{slugify(args.move)}.json")
    if os.path.isfile(spec_path):
        with open(spec_path, "r", encoding="utf-8") as fh:
            spec = json.load(fh)

    t0 = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
        f_norm = ex.submit(run_view, args.move, False, args.timeout)
        f_mirr = ex.submit(run_view, args.move, True, args.timeout)
        norm = f_norm.result()
        mirr = f_mirr.result()

    archetype = infer_archetype(args.move, norm["summary"], spec) if args.archetype == "auto" else args.archetype
    norm_checks, norm_meta = eval_view(norm, archetype, spec)
    mirr_checks, mirr_meta = eval_view(mirr, archetype, spec)

    px_a, px_b = norm_meta["max_px"], mirr_meta["max_px"]
    sym_ratio = (min(px_a, px_b) / max(px_a, px_b)) if max(px_a, px_b) > 0 else 1.0
    sym_ok = sym_ratio >= float(spec.get("min_mirror_px_ratio", 0.25))
    all_checks = [("normal." + n, ok, d) for n, ok, d in norm_checks] + \
                 [("mirror." + n, ok, d) for n, ok, d in mirr_checks] + \
                 [("d235.screen_symmetry", sym_ok, f"ratio={sym_ratio:.2f} (norm={px_a:.1f}px, mirr={px_b:.1f}px)")]

    passed = sum(1 for _, ok, _ in all_checks if ok)
    total = len(all_checks)
    score = int(round(100.0 * passed / max(total, 1)))

    print(f"== VFX SCORECARD: {args.move} (archetype={archetype}) ==")
    for name, ok, detail in all_checks:
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")

    if not args.no_graph and (norm_meta["track"] or mirr_meta["track"]):
        gpath = save_graph(args.move, norm, mirr, norm_meta, mirr_meta)
        if gpath:
            print(f"  [GRAPH] {gpath}")

    if args.visual:
        vis = run_visual_silhouette(args.move, args.timeout)
        if vis.get("ok"):
            print(f"  [SILHOUETTE] black={vis['cov_black_pct']}% white={vis['cov_white_pct']}% both={vis['cov_both_pct']}% -> {vis['silhouette_path']}")
        else:
            print(f"  [SILHOUETTE] skipped: {vis.get('reason')}")

    dt = time.time() - t0
    verdict = "PASS" if passed == total else "FAIL"
    print(f"VFX_SCORECARD: {verdict} score={score}/100 ({passed}/{total}) in {dt:.2f}s")
    sys.exit(0 if verdict == "PASS" else 1)


if __name__ == "__main__":
    main()
