#!/usr/bin/env python3
"""Servidor local da matriz de afinidades: arquivos da raiz + API de arte de wiki.

  python tools/matrix_server.py [--port 8791]

Escuta somente em 127.0.0.1 e serve a raiz como o http.server. Rotas:
  GET  /api/wiki/search?wiki=<api.php>&q=<texto>
  POST /api/wiki/save  {"wiki":..., "url":..., "name":...}
Nao contorna bloqueio/CAPTCHA: devolve {"ok": false, "blocked": true, "url": ...}
para o criador salvar a imagem a mao. User-Agent honesto e fixo.
"""
import argparse
import hashlib
import http.client
import http.server
import ipaddress
import json
import os
import re
import socket
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "sugimori" / "dqt_web" / "wiki"
DEFAULT_WIKI = "https://dragon-quest.org/w/api.php"
UA = "CrawlmonArtFetch/1.0 (uso pessoal, projeto de jogo)"
CDN = "wikia.nocookie.net"
MIMES = {"image/png", "image/webp", "image/jpeg"}
EXT = {"png": ".png", "jpg": ".jpg", "webp": ".webp"}
MAX_BYTES, MAX_JSON = 25 << 20, 8 << 20
API_TIMEOUT, DL_TIMEOUT, CHUNK, ATTEMPTS = 15.0, 30.0, 65536, 3
PNG_SIG = b"\x89PNG\r\n\x1a\n"
BAD_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')
EXT_RE = re.compile(r"\.[A-Za-z0-9]{1,5}$")
RESERVED = {"CON", "PRN", "AUX", "NUL"} | {f"COM{i}" for i in range(1, 10)} | {f"LPT{i}" for i in range(1, 10)}
JPEG_SOF = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
NET = (OSError, http.client.HTTPException)


class Failure(Exception):
    def __init__(self, message, status=502, *, retryable=False, blocked=False, url=None):
        super().__init__(message)
        self.message, self.status, self.retryable = message, status, retryable
        self.blocked, self.url = blocked, url


def _looks_html(body, content_type=""):
    if "text/html" in (content_type or "").lower():
        return True
    head = body.lstrip()[:512].lower()
    return head.startswith(b"<") or b"just a moment" in head or b"cf-chl" in head


def detect_kind(data):
    if data.startswith(PNG_SIG):
        return "png"
    if data.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    return None


def image_info(data, kind):
    """Dimensoes e alfa lidos do cabecalho, sem Pillow."""
    if kind == "png":
        if len(data) < 26:
            return None, None, False
        width, height = struct.unpack(">II", data[16:24])
        if data[25] in (4, 6):
            return width, height, True
        pos, alpha = 8, False
        while pos + 8 <= len(data):
            size = struct.unpack(">I", data[pos:pos + 4])[0]
            chunk = data[pos + 4:pos + 8]
            if chunk == b"tRNS":
                alpha = True
            if chunk in (b"tRNS", b"IDAT", b"IEND"):
                break
            pos += 12 + size
        return width, height, alpha
    if kind == "jpg":
        i, size = 2, len(data)
        while i + 9 <= size:
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            if marker in (0x00, 0xD8, 0xD9, 0x01) or 0xD0 <= marker <= 0xD7:
                i += 2
                continue
            segment = struct.unpack(">H", data[i + 2:i + 4])[0]
            if segment < 2:
                break
            if marker in JPEG_SOF:
                height, width = struct.unpack(">HH", data[i + 5:i + 9])
                return width, height, False
            i += 2 + segment
        return None, None, False
    if kind == "webp" and len(data) >= 30:
        chunk = data[12:16]
        if chunk == b"VP8X":
            return (1 + int.from_bytes(data[24:27], "little"),
                    1 + int.from_bytes(data[27:30], "little"), bool(data[20] & 0x10))
        if chunk == b"VP8L":
            bits = int.from_bytes(data[21:25], "little")
            return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1, bool(bits & (1 << 28))
        if chunk == b"VP8 ":
            pos = data.find(b"\x9d\x01\x2a", 20, 64)
            if pos != -1 and pos + 7 <= len(data):
                width = struct.unpack("<H", data[pos + 3:pos + 5])[0] & 0x3FFF
                height = struct.unpack("<H", data[pos + 5:pos + 7])[0] & 0x3FFF
                return width, height, False
    return None, None, False


def sanitize_stem(raw):
    if not isinstance(raw, str) or not raw.strip():
        raise Failure("nome invalido", 400)
    name = raw.strip()
    if "/" in name or "\\" in name or ".." in name:
        raise Failure("nome invalido: sem separadores nem '..'", 400)
    name = re.sub(r"[\s_]+", "_", BAD_CHARS.sub("_", EXT_RE.sub("", name))).strip(" ._")
    if not name or name.split(".")[0].upper() in RESERVED:
        raise Failure("nome reservado ou vazio no Windows", 400)
    return name[:120]


def _wiki_arg(value):
    wiki = value.strip() if isinstance(value, str) else ""
    return wiki or DEFAULT_WIKI


def check_url(url, base_host=None, allow_cdn=False):
    parts = urllib.parse.urlsplit(url)
    if parts.scheme != "https":
        raise Failure("apenas https e aceito", 400)
    host = (parts.hostname or "").lower().rstrip(".")
    if not host:
        raise Failure("URL sem host", 400)
    if base_host:
        same = host == base_host or host.endswith("." + base_host)
        cdn = allow_cdn and (host == CDN or host.endswith("." + CDN))
        if not (same or cdn):
            raise Failure(f"host nao permitido para esta wiki: {host}", 403)
    try:
        infos = socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise Failure(f"nao foi possivel resolver {host}: {exc}", 502) from None
    for info in infos:
        try:
            ip = ipaddress.ip_address(info[4][0].split("%", 1)[0])
        except ValueError:
            raise Failure(f"endereco invalido para {host}", 502) from None
        if (ip.is_private or ip.is_loopback or ip.is_link_local
                or ip.is_reserved or ip.is_multicast or ip.is_unspecified):
            raise Failure(f"host nao permitido (rede privada): {host}", 403)
    return host


class _Redirect(urllib.request.HTTPRedirectHandler):
    """Revalida cada URL de redirecionamento (https, dominio e IP publico)."""

    def __init__(self, checker):
        super().__init__()
        self._checker = checker

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        self._checker(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def _open(url, checker, timeout):
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    return urllib.request.build_opener(_Redirect(checker)).open(request, timeout=timeout)


def _failure(exc, url):
    if isinstance(exc, urllib.error.HTTPError):
        try:
            body = exc.read(65536)
        except Exception:
            body = b""
        headers = exc.headers or {}
        content_type = headers.get("Content-Type", "") or ""
        try:
            exc.close()
        except Exception:
            pass
        if exc.code == 403 and headers.get("cf-mitigated"):
            return Failure("a wiki bloqueou o acesso (Cloudflare)", 403, blocked=True, url=url)
        if _looks_html(body, content_type):
            return Failure("a wiki devolveu HTML/desafio em vez da imagem", 403,
                           blocked=True, url=url)
        retry = exc.code == 429 or 500 <= exc.code < 600
        return Failure(f"HTTP {exc.code} de {url}", 502, retryable=retry)
    reason = getattr(exc, "reason", exc)
    if isinstance(reason, (socket.timeout, TimeoutError)) or "timed out" in str(reason).lower():
        return Failure(f"timeout ao acessar {url}", 502, retryable=True)
    return Failure(f"falha de rede em {url}: {reason}", 502)


def _retry(fn):
    """So 429, 5xx e timeout valem nova tentativa; no maximo 3 tentativas."""
    for attempt in range(ATTEMPTS):
        try:
            return fn()
        except Failure as exc:
            if not exc.retryable or attempt + 1 >= ATTEMPTS:
                raise
            time.sleep(min(0.5 * (2 ** attempt), 5.0))


def _api_json(wiki, params, base_host, allow_cdn):
    parts = urllib.parse.urlsplit(wiki)
    query = dict(urllib.parse.parse_qsl(parts.query, keep_blank_values=True))
    query.update(params)
    query.setdefault("format", "json")
    url = urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, parts.path or "/w/api.php", urllib.parse.urlencode(query), "")
    )

    def attempt():
        try:
            resp = _open(url, lambda u: check_url(u, base_host, allow_cdn), API_TIMEOUT)
        except urllib.error.HTTPError as exc:
            raise _failure(exc, url) from None
        except NET as exc:
            raise _failure(exc, url) from None
        try:
            content_type = resp.headers.get("Content-Type", "")
            raw = resp.read(MAX_JSON + 1)
        except NET as exc:
            raise _failure(exc, url) from None
        finally:
            resp.close()
        if len(raw) > MAX_JSON:
            raise Failure("resposta da API grande demais", 502)
        if _looks_html(raw[:4096], content_type) and not raw.lstrip().startswith(b"{"):
            raise Failure("API devolveu HTML/desafio anti-robo", 403, blocked=True, url=url)
        try:
            data = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            raise Failure("JSON invalido da API", 502) from None
        if not isinstance(data, dict):
            raise Failure("JSON da API nao e um objeto", 502)
        if data.get("error"):
            err = data["error"]
            info = err.get("info") if isinstance(err, dict) else str(err)
            raise Failure(f"erro da API: {info}", 502)
        return data

    return _retry(attempt)


def wiki_search(raw_wiki, query):
    text = (query or "").strip()
    if not text:
        raise Failure("informe o texto da busca (q)", 400)
    wiki = _wiki_arg(raw_wiki)
    base = check_url(wiki)
    allow_cdn = base.endswith(".fandom.com")
    data = _api_json(wiki, {"action": "query", "list": "search", "srsearch": text,
                            "srnamespace": "6", "srlimit": "20"}, base, allow_cdn)
    hits = [hit["title"] for hit in ((data.get("query") or {}).get("search") or [])
            if isinstance(hit, dict) and hit.get("title")]
    # A pagina do proprio monstro lista as artes dele (ex.: "DQVIII Cyclops.png"): essas vem primeiro.
    try:
        page = _api_json(wiki, {"action": "query", "titles": text, "prop": "images",
                                "imlimit": "50", "redirects": "1"}, base, allow_cdn)
        own = [img["title"] for pg in ((page.get("query") or {}).get("pages") or {}).values()
               if isinstance(pg, dict) for img in (pg.get("images") or [])
               if isinstance(img, dict) and img.get("title")]
    except Failure:
        own = []
    hits = (own + [h for h in hits if h not in own])[:50]
    if not hits:
        return {"ok": True, "wiki": wiki, "results": []}
    info = _api_json(wiki, {"action": "query", "prop": "imageinfo", "iiprop": "url|size|mime",
                            "iiurlwidth": "240", "titles": "|".join(hits)}, base, allow_cdn)
    block = info.get("query") or {}
    aliases = {item.get("from", "").casefold(): item.get("to", "")
               for item in block.get("normalized") or [] if isinstance(item, dict)}
    pages = {str(page.get("title", "")).casefold(): page
             for page in (block.get("pages") or {}).values() if isinstance(page, dict)}
    results = []
    for title in hits:
        page = pages.get(aliases.get(title.casefold(), title).casefold()) or {}
        infos = page.get("imageinfo") or []
        if not infos or not isinstance(infos[0], dict):
            continue
        item = infos[0]
        mime = str(item.get("mime") or "").lower()
        if mime not in MIMES or not item.get("url"):
            continue
        results.append({"title": page.get("title") or title, "url": item["url"],
                        "thumb": item.get("thumburl") or item["url"],
                        "width": item.get("width"), "height": item.get("height"),
                        "mime": mime, "size": item.get("size")})
    # Primeiro os arquivos com o nome buscado no titulo; dentro deles, as maiores (artes oficiais
    # costumam ser maiores que sprites e icones).
    needle = text.casefold()
    results.sort(key=lambda r: (needle not in str(r["title"]).casefold(),
                                -((r.get("width") or 0) * (r.get("height") or 0))))
    return {"ok": True, "wiki": wiki, "results": results}


def _download(url, part, base_host, allow_cdn):
    def attempt():
        try:
            resp = _open(url, lambda u: check_url(u, base_host, allow_cdn), DL_TIMEOUT)
        except urllib.error.HTTPError as exc:
            raise _failure(exc, url) from None
        except NET as exc:
            raise _failure(exc, url) from None
        total = 0
        try:
            content_type = resp.headers.get("Content-Type", "")
            with open(part, "wb") as handle:
                while True:
                    try:
                        chunk = resp.read(CHUNK)
                    except NET as exc:
                        raise _failure(exc, url) from None
                    if not chunk:
                        break
                    if total == 0 and not detect_kind(chunk[:16]) \
                            and _looks_html(chunk[:4096], content_type):
                        raise Failure("a wiki devolveu HTML/desafio em vez da imagem",
                                      403, blocked=True, url=url)
                    total += len(chunk)
                    if total > MAX_BYTES:
                        raise Failure("imagem maior que 25 MB", 413)
                    handle.write(chunk)
        finally:
            resp.close()
        if not total:
            raise Failure(f"resposta vazia de {url}", 502)

    _retry(attempt)


def wiki_save(payload):
    if not isinstance(payload, dict):
        raise Failure("corpo JSON invalido", 400)
    wiki = _wiki_arg(payload.get("wiki"))
    base = check_url(wiki)
    allow_cdn = base.endswith(".fandom.com")
    url = payload.get("url")
    if not isinstance(url, str) or not url.strip():
        raise Failure("informe a url da imagem", 400)
    url = url.strip()
    check_url(url, base, allow_cdn)
    stem = sanitize_stem(payload.get("name"))
    DEST.mkdir(parents=True, exist_ok=True)
    part = DEST / (stem + ".part")
    try:
        _download(url, part, base, allow_cdn)
        data = part.read_bytes()
    except Exception:
        part.unlink(missing_ok=True)
        raise
    kind = detect_kind(data)
    if kind is None:
        part.unlink(missing_ok=True)
        raise Failure("conteudo nao e PNG/WebP/JPEG", 415)
    width, height, has_alpha = image_info(data, kind)
    digest = hashlib.sha256(data).hexdigest()
    final, index = DEST / (stem + EXT[kind]), 2
    while final.exists():
        if final.is_file() and hashlib.sha256(final.read_bytes()).hexdigest() == digest:
            break
        final, index = DEST / f"{stem}_{index}{EXT[kind]}", index + 1
    else:
        os.replace(part, final)
    if part.exists():
        part.unlink()
    rel = final.relative_to(ROOT).as_posix()
    return {"ok": True, "path": rel, "res_path": "res://" + rel, "width": width,
            "height": height, "bytes": final.stat().st_size, "has_alpha": has_alpha}


class Handler(http.server.SimpleHTTPRequestHandler):
    server_version = "MatrixServer/1.0"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def list_directory(self, path):
        self.send_error(403, "listagem de diretorios desativada")

    def _inside(self):
        try:
            Path(self.translate_path(self.path)).resolve().relative_to(ROOT)
            return True
        except (ValueError, OSError, RuntimeError):
            return False

    def do_GET(self):
        try:
            if not self.path.startswith("/api/"):
                if not self._inside():
                    return self.send_error(404)
                return super().do_GET()
            parts = urllib.parse.urlsplit(self.path)
            if parts.path != "/api/wiki/search":
                self._log("GET", parts.path, 404)
                return self._json(404, {"ok": False, "error": "rota desconhecida"})
            qs = urllib.parse.parse_qs(parts.query)
            try:
                out = wiki_search((qs.get("wiki") or [""])[0], (qs.get("q") or [""])[0])
            except Failure as exc:
                return self._error(exc)
            self._log("GET", parts.path, 200)
            self._json(200, out)
        except Exception as exc:
            self._fail(exc)

    def do_POST(self):
        try:
            if not self.path.startswith("/api/"):
                return self.send_error(405)
            parts = urllib.parse.urlsplit(self.path)
            if parts.path != "/api/wiki/save":
                self._log("POST", parts.path, 404)
                return self._json(404, {"ok": False, "error": "rota desconhecida"})
            try:
                size = int(self.headers.get("Content-Length") or 0)
            except ValueError:
                size = 0
            if not 0 < size <= 1 << 20:
                self._log("POST", parts.path, 400)
                return self._json(400, {"ok": False, "error": "corpo JSON ausente ou grande demais"})
            try:
                out = wiki_save(json.loads(self.rfile.read(size).decode("utf-8")))
            except (UnicodeDecodeError, ValueError):
                self._log("POST", parts.path, 400)
                return self._json(400, {"ok": False, "error": "JSON invalido"})
            except Failure as exc:
                return self._error(exc)
            self._log("POST", parts.path, 200)
            self._json(200, out)
        except Exception as exc:
            self._fail(exc)

    def _error(self, exc):
        body = {"ok": False, "error": exc.message}
        if exc.blocked:
            body.update(blocked=True, url=exc.url)
        self._log(self.command, urllib.parse.urlsplit(self.path).path, exc.status)
        self._json(exc.status, body)

    def _fail(self, exc):
        if isinstance(exc, Failure):
            return self._error(exc)
        self.log_error("erro inesperado: %r", exc)
        if self.path.startswith("/api/"):
            return self._json(500, {"ok": False, "error": "erro interno"})
        self.send_error(500)

    def _json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        try:
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass


    def _log(self, method, path, status):
        sys.stderr.write("[matrix_server] API %s %s -> %s\n" % (method, path, status))

    def log_message(self, fmt, *args):
        if self.path.startswith("/api/"):
            sys.stderr.write("[matrix_server] %s\n" % (fmt % args))


def main():
    parser = argparse.ArgumentParser(description="Servidor local da matriz de afinidades")
    parser.add_argument("--port", type=int, default=8791)
    args = parser.parse_args()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Matriz: http://localhost:{args.port}/prototypes/affinity_matrix.html  (Ctrl+C encerra)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nencerrado")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
