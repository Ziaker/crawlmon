"""D-308: records a Move in the REAL battle (VFX room) from both points of view that exist in the game and puts
them in ONE video, each at full resolution: normal (the player's side attacks, the target is far) on top and
mirrored (the enemy's side attacks, the target is near the camera) below.

    python tests/fx_lab/record_move_video.py "Flame Stream" out.mp4 [--seconds 4.5] [--attacker Abra] [--target Gible]
        [--hp 100] [--mirror-attacker NAME] [--mirror-target NAME]

`--hp` lowers every unit's HP before the shot (a status heal such as Media then shows its real +HP).
`--mirror-attacker` lets the mirrored side use another caster (Media: Gible is the lone ally on that side).

Needs the Godot console exe in the project folder and ffmpeg on PATH (or FFMPEG env var). Windowed run (headless draws nothing).
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = next(ROOT.glob("Godot_v*_console.exe"), None)


def record(move: str, mirror: bool, seconds: float, attacker: str, target: str, hp: float, out_dir: Path) -> list:
    args = [str(GODOT), "--path", str(ROOT), "res://scenes/debug/vfx_room.tscn", "--fixed-fps", "30", "--resolution", "1280x720", "--",
            f"--move={move}", f"--attacker={attacker}", f"--target={target}", "--force=hit", f"--record={seconds}", "--step=0.0333333",
            f"--hp={hp:g}", f"--out={out_dir}", "--quit"]
    if mirror:
        args.insert(args.index("--quit"), "--mirror")
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=600)
    return sorted(out_dir.glob("f_*.png"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("move")
    ap.add_argument("out")
    ap.add_argument("--seconds", type=float, default=4.5)
    ap.add_argument("--attacker", default="Abra")
    ap.add_argument("--target", default="Gible")
    ap.add_argument("--hp", type=float, default=100.0)
    ap.add_argument("--mirror-attacker", default="")
    ap.add_argument("--mirror-target", default="")
    a = ap.parse_args()
    ffmpeg = os.environ.get("FFMPEG") or shutil.which("ffmpeg") or "C:/Users/zerke/go/bin/ffmpeg.exe"
    tmp = Path(tempfile.mkdtemp(prefix="movevideo_"))
    seqs = {}
    for name, mirror in (("normal", False), ("espelhado", True)):
        d = tmp / name
        d.mkdir()
        att = a.mirror_attacker if mirror and a.mirror_attacker else a.attacker
        tgt = a.mirror_target if mirror and a.mirror_target else a.target
        frames = record(a.move, mirror, a.seconds, att, tgt, a.hp, d)
        seq = tmp / f"seq_{name}"
        seq.mkdir()
        for i, f in enumerate(frames):
            shutil.copy(f, seq / f"f_{i:04d}.png")
        seqs[name] = (seq, len(frames))
        print(name, len(frames), "quadros")
    font = "C\\:/Windows/Fonts/arialbd.ttf"
    flt = ("[0:v]drawtext=fontfile='%s':text='NORMAL (jogador ataca)':x=16:y=12:fontsize=30:fontcolor=white:box=1:boxcolor=black@0.55[t];"
           "[1:v]drawtext=fontfile='%s':text='ESPELHADO (inimigo ataca)':x=16:y=12:fontsize=30:fontcolor=white:box=1:boxcolor=black@0.55[b];"
           "[t][b]vstack=inputs=2,format=yuv420p") % (font, font)
    cmd = [ffmpeg, "-y", "-framerate", "30", "-i", str(seqs["normal"][0] / "f_%04d.png"), "-framerate", "30", "-i", str(seqs["espelhado"][0] / "f_%04d.png"),
           "-filter_complex", flt, "-c:v", "libx264", "-crf", "20", "-shortest", a.out]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.rmtree(tmp, ignore_errors=True)
    print("video:", a.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
