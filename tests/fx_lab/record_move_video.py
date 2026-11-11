"""D-308/D-1020: robust recorder for a Move in the REAL battle (VFX room).

It records ONE video with the two views that exist in the game:
  normal   = the player's side attacks, target far from the camera
  mirrored = the enemy's side attacks, target near the camera

The old version is kept as the CLI entry point, but it now:
  - runs a fail-fast preflight (default 1 s) before recording;
  - chooses the target by side (`--target=opponent`), never by a fixed index;
  - reads `[vfx_room]` and fails with the refusal line if the combat rejects the shot;
  - uses the real MP by default (the room's old MP fill hides the DQT/Slime 0 MP issue);
  - keeps the room log and builds a labeled phase sheet from the `FASE ...` lines;
  - fails in seconds instead of waiting 600 s.

Usage:
    python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4
    python tests/fx_lab/record_move_video.py "Fire Bullet" out.mp4 --clean --cam=1
    python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --stun=always
    python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --dqt-mirror
    python tests/fx_lab/record_move_video.py "Tidal Surge" out.mp4 --dqt-mirror --attacker=Slime --mirror-attacker=Slime

The recorder only observes the VFX room; it never changes damage, range, timing,
accuracy or any combat rule. D-235: roles/sides, never character-specific logic.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageFont
except Exception:  # pragma: no cover - only used for the phase sheet
    Image = None

ROOT = Path(__file__).resolve().parents[2]
GODOT = next(ROOT.glob("Godot_v*_console.exe"), None)

SCENE = "res://scenes/debug/vfx_room.tscn"
PHASE_RE = re.compile(r"t=\s*([0-9.]+)\s+(?:FASE\s+([A-Z_]+)|IMPACTO)\b")
FRAME_TIME_RE = re.compile(r"_t([0-9.]+)\.png$")
PREFLIGHT_RE = re.compile(r"\[vfx_room\]\s+preflight\s+result=(\w+)(.*)")


class RecorderError(RuntimeError):
    pass


def _tail(text: str, lines: int = 18) -> str:
    rows = (text or "").rstrip().splitlines()
    return "\n".join(rows[-lines:])


def _godot() -> str:
    if GODOT is None or not Path(GODOT).exists():
        raise RecorderError(
            "Godot console executable not found in the project root "
            "(expected Godot_v*_console.exe)."
        )
    return str(GODOT)


def _ffmpeg() -> str:
    candidate = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if candidate and Path(candidate).exists():
        return candidate
    fallback = Path("C:/Users/zerke/go/bin/ffmpeg.exe")
    if fallback.exists():
        return str(fallback)
    raise RecorderError("ffmpeg not found (set FFMPEG or put ffmpeg on PATH).")


def _run_godot(extra: list[str], fps: int, resolution: str, timeout: float) -> str:
    args = [
        _godot(),
        "--path", str(ROOT),
        SCENE,
        "--fixed-fps", str(fps),
        "--resolution", resolution,
        "--",
        *extra,
    ]
    try:
        proc = subprocess.run(
            args,
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise RecorderError(
            f"Godot timed out after {timeout:.0f}s; the room did not finish. "
            f"Args: {' '.join(extra)}"
        ) from exc
    output = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0:
        raise RecorderError(
            f"Godot exited with {proc.returncode}.\n{_tail(output)}"
        )
    return output


def _common_args(a: argparse.Namespace, view: str) -> list[str]:
    if view == "normal":
        attacker = a.attacker
        target = a.target
    else:
        attacker = a.mirror_attacker if a.mirror_attacker else a.attacker
        target = a.mirror_target if a.mirror_target else a.target
    args = [
        f"--move={a.move}",
        f"--attacker={attacker}",
        f"--target={target}",
        f"--force={a.force}",
        f"--hp={a.hp:g}",
    ]
    # D-1020: expose the real refusal instead of the room's old MP fill.
    if not a.fill_mp:
        args.append("--real-mp")
    if a.clean:
        args.append("--clean")
    if a.cam:
        args.append(f"--cam={a.cam}")
    if a.stun:
        args.append(f"--stun={a.stun}")
    if a.scenario:
        args.append(f"--scenario={a.scenario}")
    if a.dqt or a.dqt_mirror:
        # D-1031: `--dqt-mirror` records the pair: the DQT trio on the player's
        # side in the normal view and on the enemy side in the mirrored view.
        # `--dqt` alone is rejected in main() because it cannot form the pair.
        args.append("--dqt" if view == "normal" else "--dqt-mirror")
    # `--mirror` is the normal mirrored party. `--dqt-mirror` already changes
    # the party in BattleScene and must not be overridden by `--mirror`.
    if view == "mirrored" and not a.dqt_mirror:
        args.append("--mirror")
    return args


def _preflight(a: argparse.Namespace, view: str) -> tuple[str, str]:
    if a.scenario:
        # D-1035: do not skip the 1 s check silently. A ready-made scenario is
        # accepted only when the caller explicitly accepts recording without it.
        if not a.skip_preflight:
            raise RecorderError(
                "--scenario runs a ready-made scenario and cannot be preflighted; "
                "pass --skip-preflight explicitly if you accept recording it without the 1 s check."
            )
        return "skipped", "scenario mode: preflight skipped explicitly"
    args = _common_args(a, view) + [f"--preflight={a.preflight:g}", "--quit"]
    output = _run_godot(args, a.fps, a.resolution, timeout=20.0)
    m = PREFLIGHT_RE.search(output)
    if not m:
        raise RecorderError(
            "preflight did not print [vfx_room] preflight result=... "
            f"(move={a.move}, view={view}).\n{_tail(output)}"
        )
    result = m.group(1)
    line = m.group(0).strip()
    if result != "ok":
        raise RecorderError(
            f"combat refused the shot ({view}): {line}\n{_tail(output)}"
        )
    return result, line


def _record(a: argparse.Namespace, view: str, out_dir: Path) -> tuple[list[Path], str]:
    args = _common_args(a, view) + [
        f"--record={a.seconds:g}",
        f"--step={1.0 / max(1, a.fps):.7f}",
        f"--out={out_dir}",
        f"--log={out_dir / 'log.txt'}",
        "--quit",
    ]
    # Saving 30 PNGs per second is the slow part; the preflight already proved the shot is accepted.
    # Keep a generous cap so a normal 4.5 s take finishes, but still far below the old 600 s hang.
    timeout = max(180.0, a.seconds * 20.0 + 30.0)
    output = _run_godot(args, a.fps, a.resolution, timeout=timeout)
    frames = sorted(out_dir.glob("f_*.png"), key=lambda p: p.name)
    if not frames:
        raise RecorderError(
            f"no frames recorded for {view} (move={a.move}).\n{_tail(output)}"
        )
    (out_dir / "godot_stdout.txt").write_text(output, encoding="utf-8")
    log = out_dir / "log.txt"
    return frames, log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""


def _frame_time(path: Path) -> float:
    m = FRAME_TIME_RE.search(path.name)
    return float(m.group(1)) if m else 0.0


PHASE_RANK = {
    "WINDUP": 0, "RELEASE": 1, "STRIKE": 2, "TRAVEL": 3,
    "IMPACT": 4, "RETURN": 5,
}


def _phases(log: str) -> list[tuple[str, float]]:
    found: list[tuple[str, float]] = []
    seen: set[str] = set()

    def add(name: str, t: float) -> None:
        name = name.upper()
        if name == "DONE":  # logic end marker, not a visual phase
            return
        if name not in seen:
            seen.add(name)
            found.append((name, t))

    for m in PHASE_RE.finditer(log):
        add(m.group(2) or "IMPACT", float(m.group(1)))
    # The room logs the charge as "CARGA ..." and the hit as "IMPACTO";
    # map those to the visual phase names even when FASE lines also exist.
    for pattern, name in [
        (r"t=\s*([0-9.]+)\s+CARGA come", "WINDUP"),
        (r"t=\s*([0-9.]+)\s+CARGA termina", "RELEASE"),
        (r"t=\s*([0-9.]+)\s+IMPACTO", "IMPACT"),
    ]:
        m = re.search(pattern, log)
        if m:
            add(name, float(m.group(1)))
    # Release and STRIKE share the same instant; keep the visual order.
    found.sort(key=lambda row: (row[1], PHASE_RANK.get(row[0], 99)))
    return found


def _font(size: int, bold: bool = False):
    if Image is None:
        return None
    name = "arialbd.ttf" if bold else "arial.ttf"
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except Exception:
        return ImageFont.load_default()


def _thumb(path: Path, size=(320, 180)):
    im = Image.open(path).convert("RGB")
    im.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", size, (8, 10, 16))
    canvas.paste(im, ((size[0] - im.width) // 2, (size[1] - im.height) // 2))
    return canvas


def _phase_sheet(
    view: str,
    a: argparse.Namespace,
    phases: list[tuple[str, float]],
    frames: list[Path],
    out_path: Path,
) -> None:
    if Image is None:
        print("[aviso] Pillow ausente: folha de fases não gerada.")
        return
    if not frames:
        return
    if not phases:
        # Fallback: five evenly spaced frames, clearly marked as samples.
        picks = [frames[round(i * (len(frames) - 1) / 4)] for i in range(5)]
        phases = [(f"SAMPLE {i + 1}", _frame_time(p)) for i, p in enumerate(picks)]
    else:
        picks = [min(frames, key=lambda p: abs(_frame_time(p) - t)) for _, t in phases]

    cols = len(phases)
    cell_w, cell_h = 320, 180
    head_h, cap_h = 46, 34
    sheet = Image.new("RGB", (cols * cell_w, head_h + cell_h + cap_h), (8, 10, 16))
    d = ImageDraw.Draw(sheet)
    f_head = _font(19, True)
    f_small = _font(13)
    title = f"{a.move} — {view} — phase sheet"
    d.text((8, 8), title, font=f_head, fill=(240, 244, 250))
    for i, ((name, t), path) in enumerate(zip(phases, picks)):
        x = i * cell_w
        sheet.paste(_thumb(path), (x, head_h))
        d.rectangle([x, head_h, x + cell_w - 1, head_h + cell_h - 1], outline=(40, 50, 66))
        d.text((x + 5, head_h + cell_h + 3), f"{name}  t={t:.3f}s", font=f_small, fill=(255, 200, 90))
        d.text((x + 5, head_h + cell_h + 18), f"frame t={_frame_time(path):.3f}s", font=f_small, fill=(154, 166, 184))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def _stack_sheets(normal: Path, mirrored: Path, out_path: Path) -> None:
    if Image is None or not normal.exists() or not mirrored.exists():
        return
    a = Image.open(normal).convert("RGB")
    b = Image.open(mirrored).convert("RGB")
    w = max(a.width, b.width)
    out = Image.new("RGB", (w, a.height + b.height + 10), (8, 10, 16))
    out.paste(a, (0, 0))
    out.paste(b, (0, a.height + 10))
    out.save(out_path)


def _video(a: argparse.Namespace, normal: list[Path], mirrored: list[Path], out_path: Path, tmp: Path) -> None:
    seqs = []
    for name, frames in (("normal", normal), ("mirrored", mirrored)):
        seq = tmp / f"seq_{name}"
        seq.mkdir(parents=True, exist_ok=True)
        for i, f in enumerate(frames):
            shutil.copyfile(f, seq / f"f_{i:04d}.png")
        seqs.append(seq / "f_%04d.png")
    font = "C\\:/Windows/Fonts/arialbd.ttf"
    flt = (
        "[0:v]drawtext=fontfile='%s':text='NORMAL (player side attacks)':x=16:y=12:"
        "fontsize=30:fontcolor=white:box=1:boxcolor=black@0.55[t];"
        "[1:v]drawtext=fontfile='%s':text='MIRRORED (enemy side attacks)':x=16:y=12:"
        "fontsize=30:fontcolor=white:box=1:boxcolor=black@0.55[b];"
        "[t][b]vstack=inputs=2,format=yuv420p"
    ) % (font, font)
    cmd = [
        _ffmpeg(), "-y",
        "-framerate", str(a.fps), "-i", str(seqs[0]),
        "-framerate", str(a.fps), "-i", str(seqs[1]),
        "-filter_complex", flt,
        "-c:v", "libx264", "-crf", "20", "-shortest",
        str(out_path),
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
    except subprocess.TimeoutExpired as exc:
        raise RecorderError("ffmpeg timed out while stacking the two views.") from exc
    if proc.returncode != 0:
        raise RecorderError(f"ffmpeg failed:\n{_tail((proc.stdout or '') + (proc.stderr or ''))}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Record a Move in the real VFX room (normal + mirrored).")
    ap.add_argument("move")
    ap.add_argument("out")
    ap.add_argument("--seconds", type=float, default=4.5)
    ap.add_argument("--attacker", default="player", help="player|enemy|name (D-235: prefer a side)")
    ap.add_argument("--target", default="opponent", help="opponent|name (never an index)")
    ap.add_argument("--mirror-attacker", default="enemy", help="player|enemy|name for the mirrored view")
    ap.add_argument("--mirror-target", default="opponent", help="opponent|name for the mirrored view")
    ap.add_argument("--hp", type=float, default=100.0)
    ap.add_argument("--force", default="hit", choices=["hit", "dodge", "crit", "weak", "random"])
    ap.add_argument("--clean", action="store_true", help="D-965: no HUD, no arena props")
    ap.add_argument("--cam", default="", help="VFX room camera mode (0-4)")
    ap.add_argument("--stun", default="", choices=["", "always", "never"])
    ap.add_argument("--scenario", default="", help="VFX room scenario id; requires --skip-preflight (D-1035)")
    ap.add_argument("--dqt", action="store_true", help="DQT party on the player's side (BattleScene); alone it is rejected")
    ap.add_argument("--dqt-mirror", action="store_true", help="D-1031 pair: DQT on the player's side (normal) and on the enemy side (mirrored)")
    ap.add_argument("--fill-mp", action="store_true", help="old debug behavior: fill MP before firing")
    ap.add_argument("--preflight", type=float, default=1.0, help="seconds of fail-fast check before recording")
    ap.add_argument("--skip-preflight", action="store_true")
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--resolution", default="1280x720")
    ap.add_argument("--keep-temp", action="store_true")
    a = ap.parse_args()
    if a.dqt and not a.dqt_mirror:
        print(
            "[ERRO] --dqt sozinho não forma o par normal+espelhado. Use --dqt-mirror, "
            "que grava o trio DQT no lado do jogador na vista normal e no lado inimigo "
            "na vista espelhada (D-1031).",
            file=sys.stderr,
        )
        return 2

    out_path = Path(a.out).expanduser()
    if out_path.suffix.lower() != ".mp4":
        out_path = out_path.with_suffix(".mp4")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    tmp = Path(tempfile.mkdtemp(prefix="vfxrec_"))
    views: dict[str, dict] = {}
    try:
        for view in ("normal", "mirrored"):
            view_dir = tmp / view
            view_dir.mkdir(parents=True, exist_ok=True)
            preflight = ("skipped", "flag") if a.skip_preflight else _preflight(a, view)
            print(f"[{view}] preflight: {preflight[0]}")
            frames, log = _record(a, view, view_dir)
            phases = _phases(log)
            warnings: list[str] = []
            if not phases:
                warnings.append("nenhuma linha FASE/IMPACTO no log; folha usa amostras")
            elif not any(name == "IMPACT" for name, _ in phases):
                warnings.append("IMPACTO não apareceu; --seconds pode ser curto")
            phase_sheet = out_path.with_name(out_path.stem + f"_{view}_phases.png")
            _phase_sheet(view, a, phases, frames, phase_sheet)
            for warning in warnings:
                print(f"[{view}] aviso: {warning}")
            all_sheet = out_path.with_name(out_path.stem + f"_{view}_all.png")
            src_sheet = view_dir / "sheet.png"
            if src_sheet.exists():
                shutil.copyfile(src_sheet, all_sheet)
            log_out = out_path.with_name(out_path.stem + f"_{view}_log.txt")
            views[view] = {
                "frames": len(frames),
                "phases": phases,
                "warnings": warnings,
                "preflight": preflight[1],
                "log": str(log_out),
                "phase_sheet": str(phase_sheet),
                "all_frames_sheet": str(all_sheet) if all_sheet.exists() else "",
            }
            print(f"[{view}] {len(frames)} quadros, fases: {', '.join(n for n, _ in phases) or 'sem FASE'}")
        _video(a, sorted((tmp / 'normal').glob('f_*.png')), sorted((tmp / 'mirrored').glob('f_*.png')), out_path, tmp)
        _stack_sheets(
            out_path.with_name(out_path.stem + "_normal_phases.png"),
            out_path.with_name(out_path.stem + "_mirrored_phases.png"),
            out_path.with_name(out_path.stem + "_phases.png"),
        )
        manifest = {
            "tool": "record_move_video.py",
            "date": "2026-11-09",
            "move": a.move,
            "output": str(out_path),
            "options": vars(a),
            "views": views,
        }
        (out_path.with_name(out_path.stem + "_manifest.json")).write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        # Preserve the room's per-view log even when the temp dir is removed.
        for view in ("normal", "mirrored"):
            src = tmp / view / "log.txt"
            if src.exists():
                shutil.copyfile(src, out_path.with_name(out_path.stem + f"_{view}_log.txt"))
        print(f"video: {out_path}")
        print(f"phases: {out_path.with_name(out_path.stem + '_phases.png')}")
        print(f"manifest: {out_path.with_name(out_path.stem + '_manifest.json')}")
        return 0
    except RecorderError as exc:
        print(f"[ERRO] {exc}", file=sys.stderr)
        return 1
    finally:
        if a.keep_temp:
            print(f"temp: {tmp}")
        else:
            shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
