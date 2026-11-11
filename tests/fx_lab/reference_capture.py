"""D-1020 tool 6: capture exact frames from a reference video, organized by element and phase.

It accepts a local video or a public URL, a list of PHASE=SECONDS, and writes:
  frames/<phase>_<time>.png
  contact_sheet.png
  manifest.json

For a URL it downloads only the section around the requested timestamps with yt-dlp
and keeps only frames + metadata (the temporary clip is deleted unless --keep-clip).
The tool never touches the game; it is research/reference only.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path
from urllib.parse import urlparse

from PIL import Image, ImageDraw, ImageFont

ELEMENTS = [
    "Neutral", "Fire", "Water", "Electric", "Wind", "Psychic",
    "Light", "Dark", "Nature", "Sound", "Earth", "Mystic",
]
PHASE_RE = re.compile(r"^([A-Za-z0-9_ -]+)=([0-9]+(?:\.[0-9]+)?)$")


class CaptureError(RuntimeError):
    pass


def _bin(name: str, env: str, fallback: str = "") -> str:
    value = os.environ.get(env) or shutil.which(name)
    if value and Path(value).exists():
        return value
    if fallback and Path(fallback).exists():
        return fallback
    raise CaptureError(f"{name} not found (set {env} or put it on PATH).")


def _run(cmd: list[str], timeout: float = 300.0) -> str:
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout
        )
    except subprocess.TimeoutExpired as exc:
        raise CaptureError(f"timeout after {timeout:.0f}s: {' '.join(cmd[:4])} ...") from exc
    out = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0:
        raise CaptureError(f"command failed ({proc.returncode}): {' '.join(cmd[:4])} ...\n{_tail(out)}")
    return out


def _tail(text: str, lines: int = 15) -> str:
    rows = (text or "").rstrip().splitlines()
    return "\n".join(rows[-lines:])


def _slug(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text).strip("_").lower()
    return text or "item"


def _probe(ffprobe: str, path: Path) -> dict:
    out = _run([
        ffprobe, "-v", "error", "-show_entries",
        "format=duration,size:stream=width,height,codec_name", "-of", "json", str(path),
    ], timeout=60.0)
    data = json.loads(out)
    streams = [s for s in data.get("streams", []) if s.get("width") and s.get("height")]
    if not streams:
        raise CaptureError(f"no video stream found in {path}")
    stream = streams[0]
    return {
        "duration": float(data.get("format", {}).get("duration", 0.0)),
        "size": int(data.get("format", {}).get("size", 0)),
        "width": int(stream["width"]),
        "height": int(stream["height"]),
        "codec": stream.get("codec_name", ""),
    }


def _is_url(source: str) -> bool:
    parsed = urlparse(source)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def _ytdlp_meta(ytdlp: str, url: str) -> dict:
    out = _run([ytdlp, "--skip-download", "--no-warnings", "--dump-single-json", url], timeout=120.0)
    data = json.loads(out)
    return {
        "title": data.get("title") or url,
        "duration": float(data.get("duration") or 0.0),
        "uploader": data.get("uploader") or "",
        "webpage_url": data.get("webpage_url") or url,
    }


def _download_section(ytdlp: str, url: str, start: float, end: float, dest: Path, max_height: int) -> Path:
    # Combined format: no audio is needed for reference frames.
    fmt = f"b[height<={max_height}]/bv*[height<={max_height}]"
    pattern = str(dest.with_suffix(".%(ext)s"))
    _run([
        ytdlp, "-f", fmt, "--no-warnings", "--no-progress",
        "--download-sections", f"*{start:.3f}-{end:.3f}",
        "-o", pattern, url,
    ], timeout=300.0)
    candidates = sorted(dest.parent.glob(dest.stem + ".*"), key=lambda p: p.stat().st_size, reverse=True)
    candidates = [p for p in candidates if p.suffix.lower() in (".mp4", ".webm", ".mkv", ".mov")]
    if not candidates:
        raise CaptureError(f"yt-dlp did not produce a video file in {dest.parent}")
    return candidates[0]


def _parse_at(values: list[str]) -> list[tuple[str, float]]:
    phases: list[tuple[str, float]] = []
    for raw in values:
        m = PHASE_RE.match(raw.strip())
        if not m:
            raise CaptureError(f"--at must be PHASE=SECONDS, got: {raw!r}")
        phase = m.group(1).strip().upper().replace(" ", "_")
        t = float(m.group(2))
        if t < 0:
            raise CaptureError(f"negative time in --at: {raw!r}")
        phases.append((phase, t))
    if not phases:
        raise CaptureError("provide at least one --at PHASE=SECONDS")
    phases.sort(key=lambda p: p[1])
    return phases


def _font(size: int, bold: bool = False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except Exception:
        return ImageFont.load_default()


def _thumb(path: Path, size=(320, 180)) -> Image.Image:
    im = Image.open(path).convert("RGB")
    im.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", size, (8, 10, 16))
    canvas.paste(im, ((size[0] - im.width) // 2, (size[1] - im.height) // 2))
    return canvas


def _contact_sheet(rows: list[dict], out_path: Path, title: str) -> None:
    cols = min(4, max(1, len(rows)))
    cell_w, cell_h, cap_h = 320, 180, 40
    lines = (len(rows) + cols - 1) // cols
    header = 56
    sheet = Image.new("RGB", (cols * cell_w, header + lines * (cell_h + cap_h)), (8, 10, 16))
    d = ImageDraw.Draw(sheet)
    d.text((10, 10), title, font=_font(20, True), fill=(240, 244, 250))
    for i, row in enumerate(rows):
        x = (i % cols) * cell_w
        y = header + (i // cols) * (cell_h + cap_h)
        sheet.paste(_thumb(Path(row["frame"])), (x, y))
        d.rectangle([x, y, x + cell_w - 1, y + cell_h - 1], outline=(40, 50, 66))
        d.text((x + 4, y + cell_h + 2), f"{row['phase']}  t={row['time']:.3f}s", font=_font(14, True), fill=(255, 200, 90))
        d.text((x + 4, y + cell_h + 20), f"local={row['local_time']:.3f}s", font=_font(12), fill=(154, 166, 184))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def main() -> int:
    ap = argparse.ArgumentParser(description="Capture exact reference frames by element and phase.")
    ap.add_argument("--source", required=True, help="local video path or public URL")
    ap.add_argument("--element", required=True, choices=ELEMENTS)
    ap.add_argument("--effect", required=True, help="effect/move name used in the output path")
    ap.add_argument("--at", action="append", default=[], metavar="PHASE=SECONDS",
                    help="repeatable, e.g. --at WINDUP=0.5 --at IMPACT=1.2")
    ap.add_argument("--out", default="", help="output dir; default docs/vfx/referencias/capturas/<element>/<effect>")
    ap.add_argument("--title", default="", help="override the source title")
    ap.add_argument("--max-height", type=int, default=720)
    ap.add_argument("--crop", default="", help="x,y,w,h before scaling")
    ap.add_argument("--keep-clip", action="store_true", help="keep the downloaded/local clip in the output dir")
    a = ap.parse_args()

    try:
        phases = _parse_at(a.at)
        ffmpeg = _bin("ffmpeg", "FFMPEG")
        ffprobe = _bin("ffprobe", "FFPROBE")
        ytdlp = _bin("yt-dlp", "YTDLP") if _is_url(a.source) else ""

        out_dir = Path(a.out) if a.out else Path("docs/vfx/referencias/capturas") / _slug(a.element) / _slug(a.effect)
        out_dir = out_dir.expanduser()
        frames_dir = out_dir / "frames"
        frames_dir.mkdir(parents=True, exist_ok=True)
        for old in frames_dir.glob("*.png"):
            old.unlink()

        tmp = Path(tempfile.mkdtemp(prefix="refcap_"))
        clip: Path
        clip_start = 0.0
        source_meta = {}
        try:
            if _is_url(a.source):
                source_meta = _ytdlp_meta(ytdlp, a.source)
                duration = float(source_meta["duration"])
                if duration <= 0:
                    raise CaptureError("source duration is unknown; cannot validate timestamps")
                for phase, t in phases:
                    if t > duration:
                        raise CaptureError(f"{phase}={t}s is beyond the source duration ({duration:.1f}s)")
                clip_start = max(0.0, min(t for _, t in phases) - 2.0)
                clip_end = min(duration, max(t for _, t in phases) + 2.0)
                if clip_end <= clip_start:
                    raise CaptureError("empty download section")
                clip = _download_section(ytdlp, a.source, clip_start, clip_end, tmp / "clip", a.max_height)
            else:
                clip = Path(a.source).expanduser()
                if not clip.exists():
                    raise CaptureError(f"local video not found: {clip}")
                source_meta = {"title": clip.name, "duration": 0.0, "uploader": "", "webpage_url": str(clip)}
                clip_start = 0.0

            info = _probe(ffprobe, clip)
            source_duration = float(source_meta.get("duration") or info["duration"])
            for phase, t in phases:
                if t > source_duration + 0.001:
                    raise CaptureError(f"{phase}={t}s is beyond the clip duration ({source_duration:.1f}s)")
            # The downloaded section is expected to start at 0; local videos start at 0.
            # If the section includes a small pre-roll, record it and let the manifest show it.
            # At clip_start == 0 there cannot be a head pre-roll: any extra duration is the tail.
            section_len = info["duration"]
            expected_len = (clip_end - clip_start) if _is_url(a.source) else source_duration
            if clip_start <= 0.001:
                preroll = 0.0
                local_base = 0.0
            else:
                preroll = max(0.0, section_len - expected_len)
                local_base = clip_start - preroll

            vf = []
            if a.crop:
                parts = [p.strip() for p in a.crop.split(",")]
                if len(parts) != 4 or not all(p.lstrip("-").isdigit() for p in parts):
                    raise CaptureError("--crop must be x,y,w,h with integers")
                x, y, w, h = (int(p) for p in parts)
                if w <= 0 or h <= 0:
                    raise CaptureError("--crop width/height must be positive")
                vf.append(f"crop={w}:{h}:{x}:{y}")
                out_h = h
            else:
                out_h = info["height"]
            if out_h > a.max_height:
                vf.append(f"scale=-2:{a.max_height}")
            vf_arg = ["-vf", ",".join(vf)] if vf else []

            rows = []
            for i, (phase, t) in enumerate(phases):
                local_t = t - local_base
                if local_t < 0 or local_t > info["duration"] + 0.001:
                    raise CaptureError(
                        f"{phase}={t}s maps to local {local_t:.3f}s, outside the clip "
                        f"(0..{info['duration']:.3f}s)"
                    )
                frame = frames_dir / f"{i:02d}_{_slug(phase)}_{t:.3f}.png"
                # Accurate seek: decode from the start of the short clip.
                _run([
                    ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(clip), *vf_arg, "-ss", f"{local_t:.6f}",
                    "-frames:v", "1", "-q:v", "2", str(frame),
                ], timeout=120.0)
                if not frame.exists() or frame.stat().st_size == 0:
                    raise CaptureError(f"ffmpeg produced no frame for {phase} at {t}s")
                rows.append({
                    "phase": phase,
                    "time": t,
                    "local_time": round(local_t, 6),
                    "frame": str(frame),
                    "sha256": hashlib.sha256(frame.read_bytes()).hexdigest()[:16],
                })

            title = a.title or source_meta.get("title") or a.effect
            contact = out_dir / "contact_sheet.png"
            _contact_sheet(rows, contact, f"{title}  |  {a.element}  |  {a.effect}")
            # The real frame size after crop/scale, not the source resolution.
            first_size = Image.open(Path(rows[0]["frame"])).size if rows else (info["width"], info["height"])
            output_resolution = {"width": int(first_size[0]), "height": int(first_size[1])}
            manifest = {
                "tool": "reference_capture.py",
                "date": "2026-11-09",
                "source": a.source,
                "source_title": title,
                "source_uploader": source_meta.get("uploader", ""),
                "source_duration": source_duration,
                "clip_start": round(clip_start, 3),
                "clip_end": round(clip_end, 3) if _is_url(a.source) else round(source_duration, 3),
                "clip_preroll": round(preroll, 3),
                "element": a.element,
                "effect": a.effect,
                "source_resolution": {"width": info["width"], "height": info["height"]},
                "output_resolution": output_resolution,
                # Backward-compatible alias: now it describes the frames, not the source.
                "resolution": output_resolution,
                "max_height": a.max_height,
                "crop": a.crop,
                "phases": rows,
                "contact_sheet": str(contact),
            }
            (out_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            if a.keep_clip:
                kept = out_dir / ("source_clip" + clip.suffix)
                shutil.copyfile(clip, kept)
                manifest["kept_clip"] = str(kept)
                (out_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"frames: {len(rows)}")
            print(f"contact: {contact}")
            print(f"manifest: {out_dir / 'manifest.json'}")
            return 0
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    except CaptureError as exc:
        print(f"[ERRO] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
