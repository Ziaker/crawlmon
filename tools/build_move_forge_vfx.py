#!/usr/bin/env python3
"""Grava o VFX real de cada Move na sala de debug e gera tiras de quadros para o Move Forge (D-1206).

  python tools/build_move_forge_vfx.py            # todos os Moves que ainda não têm tira
  python tools/build_move_forge_vfx.py --force    # regrava tudo
  python tools/build_move_forge_vfx.py tackle fire_bullet   # só estes ids

Para cada Move: roda scenes/debug/vfx_room.tscn com --move=<nome> --clean --record, junta os quadros
numa tira JPEG em prototypes/move_forge/vfx/<id>.jpg e escreve prototypes/move_forge/vfx_previews.js.
Precisa de Pillow e de rodar antes tools/build_move_forge_data.py.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT") or str(ROOT / "Godot_v4.7.2-stable_win64_console.exe")
FORGE = ROOT / "prototypes" / "move_forge"
OUT = FORGE / "vfx"
FRAME_W, FRAME_H, COLS, STEP = 320, 180, 8, 0.1


def load_moves():
    text = (FORGE / "move_forge_data.js").read_text(encoding="utf-8")
    return json.loads(text[text.index("{"):text.rindex("}") + 1])["moves"]


def record(move, mirror=False):
    windup = move["windup"] if move["windup"] >= 0 else 1.5
    seconds = round(min(5.0, windup + 2.4), 1)
    tmp = Path(tempfile.mkdtemp(prefix="forge_vfx_"))
    cmd = [GODOT, "--path", str(ROOT), "scenes/debug/vfx_room.tscn", "--", f"--move={move['name']}", "--clean",
           f"--record={seconds}", f"--step={STEP}", f"--out={tmp}", "--quit"]
    if mirror:
        cmd.insert(-1, "--mirror")
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"  tempo esgotado: {move['id']}", file=sys.stderr)
    frames = sorted(tmp.glob("f_*.png"))
    images = [Image.open(f).convert("RGB").resize((FRAME_W, FRAME_H), Image.LANCZOS) for f in frames]
    shutil.rmtree(tmp, ignore_errors=True)
    return images, seconds


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("ids", nargs="*")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    index_path = FORGE / "vfx_previews.js"
    index = {}
    if index_path.exists():
        text = index_path.read_text(encoding="utf-8")
        index = json.loads(text[text.index("{"):text.rindex("}") + 1])
    for move in load_moves():
        mid = move["id"]
        if args.ids and mid not in args.ids:
            continue
        if not args.force and not args.ids and mid in index and (OUT / f"{mid}.jpg").exists():
            continue
        images, seconds = record(move)
        if len(images) < 4:
            print(f"  sem quadros: {mid}", file=sys.stderr)
            continue
        rows = (len(images) + COLS - 1) // COLS
        sheet = Image.new("RGB", (COLS * FRAME_W, rows * FRAME_H))
        for i, image in enumerate(images):
            sheet.paste(image, ((i % COLS) * FRAME_W, (i // COLS) * FRAME_H))
        sheet.save(OUT / f"{mid}.jpg", quality=72, optimize=True)
        index[mid] = {"name": move["name"], "family": move.get("vfx_family", ""), "frames": len(images), "cols": COLS,
                      "w": FRAME_W, "h": FRAME_H, "fps": round(1 / STEP), "seconds": seconds, "element": move["element"]}
        index_path.write_text("window.MOVE_FORGE_VFX = " + json.dumps(index, ensure_ascii=False, indent=1) + ";\n", encoding="utf-8")
        print(f"{mid}: {len(images)} quadros")
    print(f"total: {len(index)} Moves com tira")
    return 0


if __name__ == "__main__":
    sys.exit(main())
