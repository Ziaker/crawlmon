"""Tiny CORS receiver for canvas captures from the VFX library page.

Run: python capture_server.py
The page POSTs a PNG data URL to http://127.0.0.1:8124/shot?name=foo and this
writes captures/foo.png next to this script. Local only, no external access.
"""
from __future__ import annotations

import base64
import pathlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = pathlib.Path(__file__).resolve().parent
OUT = ROOT / "captures"
OUT.mkdir(exist_ok=True)


class Handler(BaseHTTPRequestHandler):
    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802
        if not self.path.startswith("/shot"):
            self.send_response(404)
            self._cors()
            self.end_headers()
            return
        name = "latest"
        if "?name=" in self.path:
            name = self.path.split("?name=", 1)[1].split("&", 1)[0]
            name = "".join(ch for ch in name if ch.isalnum() or ch in "-_") or "latest"
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length).decode("utf-8", "replace")
        if "," in raw:
            raw = raw.split(",", 1)[1]
        try:
            data = base64.b64decode(raw)
        except Exception as exc:  # noqa: BLE001
            self.send_response(400)
            self._cors()
            self.end_headers()
            self.wfile.write(str(exc).encode())
            return
        (OUT / f"{name}.png").write_bytes(data)
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"ok")


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8124), Handler)
    print("capture server on http://127.0.0.1:8124/shot")
    server.serve_forever()
