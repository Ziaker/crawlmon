"""Static server for the VFX library with no-store headers.

The default `python -m http.server` lets the browser cache ES modules, which
hides edits during iteration. Run from the project root:

    python prototypes/vfx_library/serve_nocache.py .

Then open http://127.0.0.1:8126/prototypes/vfx_library/index.html
"""
from __future__ import annotations

import functools
import http.server
import os
import socketserver
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, *args) -> None:  # noqa: D401
        pass


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(os.environ.get("PORT", "8126"))
    handler = functools.partial(Handler, directory=root)
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", port), handler) as httpd:
        print(f"serving {root} on http://127.0.0.1:{port}")
        httpd.serve_forever()
