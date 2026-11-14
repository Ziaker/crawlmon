"""
Folha de contato rotulada de um cenário da sala de debug em vários instantes (D-1204). Uso:
  python tools/room_seq.py <cenario> --phase impact --delays 0,0.15,0.3 --out sheet.png [--crop x0,y0,x1,y1] [--cols 3] [--scale 0.5] [-- flags da sala...]

Roda até 3 Godot em paralelo (100 s cada), recorta/escala cada foto e monta uma grade com o
atraso em amarelo; execução que falha vira um tile vermelho "FAIL t=...".
"""
import argparse
import math
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
SCENE = "res://scenes/debug/vfx_room.tscn"
TIMEOUT = 100
GAP = 8
LABEL_BG = (0, 0, 0)
LABEL_FG = (255, 220, 0)
FAIL_BG = (150, 20, 20)


def run_shot(scenario, phase, delay, png, extra):
    argv = [EXE, "--path", ".", SCENE, "--",
            "--scenario=%s" % scenario, "--pause-at=%s" % phase,
            "--pause-delay=%g" % delay, "--shot=%s" % png, "--quit"] + list(extra)
    try:
        proc = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return delay, png, "timeout de %ds" % TIMEOUT, ""
    if proc.returncode != 0:
        return delay, png, "exit %d" % proc.returncode, proc.stderr
    if not os.path.isfile(png):
        return delay, png, "png ausente", proc.stderr
    return delay, png, None, proc.stderr


def make_tile(delay, png, err, crop, scale, size):
    if err:
        img = Image.new("RGB", size, FAIL_BG)
        text, color = "FAIL t=%gs" % delay, (255, 255, 255)
    else:
        try:
            src = Image.open(png).convert("RGB")
        except OSError as exc:
            return make_tile(delay, png, "imagem ilegível: %s" % exc, crop, scale, size)
        img = src.crop(crop)
        img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))),
                         Image.LANCZOS)
        text, color = "t=%gs" % delay, LABEL_FG
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 6 * len(text) + 6, 14], fill=LABEL_BG)
    draw.text((3, 1), text, fill=color)
    return img


def build_sheet(tiles, cols, tile):
    rows = math.ceil(len(tiles) / float(cols))
    w = cols * tile[0] + (cols + 1) * GAP
    h = rows * tile[1] + (rows + 1) * GAP
    sheet = Image.new("RGB", (w, h), (24, 24, 24))
    for i, img in enumerate(tiles):
        sheet.paste(img, (GAP + (i % cols) * (tile[0] + GAP), GAP + (i // cols) * (tile[1] + GAP)))
    return sheet


def main(argv):
    extra = []
    if "--" in argv:
        k = argv.index("--")
        argv, extra = argv[:k], argv[k + 1:]
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scenario")
    ap.add_argument("--phase", required=True)
    ap.add_argument("--delays", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--crop", default="0,0,700,420")
    ap.add_argument("--cols", type=int, default=3)
    ap.add_argument("--scale", type=float, default=0.5)
    args = ap.parse_args(argv)

    crop = tuple(int(v) for v in args.crop.split(","))
    if len(crop) != 4:
        ap.error("--crop precisa de x0,y0,x1,y1")
    delays = [float(v) for v in args.delays.split(",") if v.strip()]
    tile = (max(1, int((crop[2] - crop[0]) * args.scale)),
            max(1, int((crop[3] - crop[1]) * args.scale)))

    tmp = tempfile.mkdtemp(prefix="room_seq_")
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(run_shot, args.scenario, args.phase, d,
                               os.path.join(tmp, "%02d.png" % i), extra)
                   for i, d in enumerate(delays)]
        results = [f.result() for f in futures]

    tiles, failed = [], []
    for delay, png, err, stderr in results:
        if err:
            failed.append((delay, err, stderr))
        tiles.append(make_tile(delay, png, err, crop, args.scale, tile))

    sheet = build_sheet(tiles, max(1, args.cols), tile)
    out = os.path.abspath(args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print("SHEET: %s" % out)
    print("SIZE: %dx%d" % sheet.size)
    print("FAILED RUNS: %d" % len(failed))
    for delay, err, stderr in failed:
        print("  FAIL t=%gs: %s" % (delay, err))
        for line in [l for l in (stderr or "").splitlines() if l.strip()][-5:]:
            print("    | %s" % line)
    return 0


if __name__ == "__main__":
    os.chdir(ROOT)
    sys.exit(main(sys.argv[1:]))
