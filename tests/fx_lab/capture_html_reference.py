"""Capture exact frames from the HTML Card C prototype with headless Chromium.

Usage:
  python tests/fx_lab/capture_html_reference.py --out test_captures/html_ab \
      --times 0.30,0.60,0.74,0.75,0.90,1.00,1.05,1.13,1.20,1.35,1.60,1.85 \
      --views normal,mirrored --sides a

The page is isolated to the Card C viewport (full window), so the PNG is only the
Three.js scene with the exact camera/FOV/aspect used by the prototype. The JSON
sidecar records the viewport size, phase text and the exact time.
"""
from __future__ import annotations

import argparse
import functools
import http.server
import json
import os
import sys
import threading
from pathlib import Path

from playwright.sync_api import sync_playwright

DEFAULT_ROOT = r"C:\Users\zerke\Downloads"
DEFAULT_PAGE = "javelin_throw_3d_vfx_prototype.html"

ISOLATE_CSS = """
header, footer { display: none !important; }
html, body { margin: 0 !important; padding: 0 !important; width: 100vw !important; height: 100vh !important; overflow: hidden !important; background: #0b131b !important; }
main { display: block !important; padding: 0 !important; margin: 0 !important; max-width: none !important; width: 100vw !important; height: 100vh !important; }
main > section { display: none !important; }
main > section:nth-child(3) {
  display: flex !important; width: 100vw !important; height: 100vh !important;
  border: none !important; border-radius: 0 !important; box-shadow: none !important;
  background: transparent !important; overflow: visible !important;
}
main > section:nth-child(3) > div:not(#viewport-C) { display: none !important; }
#viewport-C {
  display: block !important; position: fixed !important; inset: 0 !important;
  width: 100vw !important; height: 100vh !important; min-height: 0 !important;
  background: transparent !important; cursor: default !important;
}
#viewport-C > * { display: none !important; }
#webgl-canvas { display: block !important; }
"""


def set_time(page, t: float) -> None:
    page.evaluate(
        """(t) => {
            const slider = document.getElementById('slider-timeline');
            slider.value = String(t);
            slider.dispatchEvent(new Event('input', { bubbles: true }));
        }""",
        t,
    )
    page.wait_for_function(
        """(t) => {
            const el = document.getElementById('time-readout');
            return el && el.textContent.trim().startsWith(t.toFixed(2));
        }""",
        arg=t,
        timeout=10000,
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="")
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--out", default="test_captures/html_ab")
    ap.add_argument("--times", default="0.30,0.60,0.74,0.75,0.90,1.00,1.05,1.13,1.20,1.35,1.60,1.85")
    ap.add_argument("--views", default="normal,mirrored")
    ap.add_argument("--sides", default="a")
    ap.add_argument("--width", type=int, default=1280)
    ap.add_argument("--height", type=int, default=720)
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    times = [float(x) for x in args.times.split(",") if x.strip()]
    views = [x.strip() for x in args.views.split(",") if x.strip()]
    sides = [x.strip().lower() for x in args.sides.split(",") if x.strip()]

    server = None
    url = args.url
    if not url:
        root = Path(args.root)
        handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        port = server.server_address[1]
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        url = f"http://127.0.0.1:{port}/{DEFAULT_PAGE}"
        print("serving", root, "at", url)

    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            headless=True,
            args=[
                "--use-angle=swiftshader",
                "--enable-webgl",
                "--ignore-gpu-blocklist",
                "--disable-web-security",
            ],
        )
        page = browser.new_page(viewport={"width": args.width, "height": args.height}, device_scale_factor=1)
        page.goto(url, wait_until="networkidle")
        page.wait_for_function("() => !!document.getElementById('viewport-C')", timeout=20000)
        page.add_style_tag(content=ISOLATE_CSS)
        page.wait_for_timeout(300)

        # Guard against a blank canvas / module failure.
        info = page.evaluate(
            """() => {
                const canvas = document.getElementById('webgl-canvas');
                const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
                return {
                    webgl: !!gl,
                    canvas: { w: canvas.width, h: canvas.height, cw: canvas.clientWidth, ch: canvas.clientHeight },
                    rect: document.getElementById('viewport-C').getBoundingClientRect().toJSON(),
                    dpr: window.devicePixelRatio
                };
            }"""
        )
        print("page:", json.dumps(info))
        if not info["webgl"]:
            print("WebGL is not available", file=sys.stderr)
            return 2

        manifest = []
        for side in sides:
            if side not in ("a", "b"):
                raise SystemExit(f"unknown side {side}")
            page.evaluate("(id) => document.getElementById(id).click()", f"btn-side-{side}")
            for view in views:
                view_id = {"normal": "normal", "mirrored": "espelhada", "oblique": "obliqua"}.get(view, view)
                page.evaluate("(id) => document.getElementById(id).click()", f"btn-view-{view_id}")
                for t in times:
                    set_time(page, t)
                    page.wait_for_timeout(120)
                    name = f"html_{view}_{side}_t{t:04.2f}.png"
                    path = out / name
                    page.screenshot(path=str(path), full_page=False)
                    meta = page.evaluate(
                        """() => ({
                            t: document.getElementById('time-readout').textContent,
                            phase: document.getElementById('global-phase-badge').textContent,
                            substatus: document.getElementById('substatus-C').textContent,
                            rect: document.getElementById('viewport-C').getBoundingClientRect().toJSON()
                        })"""
                    )
                    manifest.append({"file": name, "view": view, "side": side, "t": t, **meta})
                    print(name, meta["t"], meta["phase"])
        (out / "html_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        browser.close()
    if server is not None:
        server.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
