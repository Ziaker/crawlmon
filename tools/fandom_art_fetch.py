#!/usr/bin/env python3
"""Baixa em lote a arte 2D oficial ("<Nome>_Artwork.png") da Dragon Quest Wiki.

Destino: sugimori/dqt_web/fandom/ (relativo a raiz do repo, calculado a partir
de __file__). Fonte: API MediaWiki de https://dragonquest.fandom.com
(prop=pageimages, com fallback para prop=images). O script nao contorna
bloqueio, CAPTCHA ou desafio anti-robo: usa um User-Agent honesto e, quando o
CDN devolve desafio, reporta BLOQUEADO com a URL para salvar manualmente.

Uso:
  python tools/fandom_art_fetch.py [--dry-run] [--force] [--delay N] [--max-mb N] [titulos...]

Exemplos:
  python tools/fandom_art_fetch.py
  python tools/fandom_art_fetch.py --dry-run Slime "King Slime"
  python tools/fandom_art_fetch.py --force --delay 2

Saida: arquivos validados na pasta de destino, manifest.json, fandom_art_fetch.log
e um relatorio final (OK / PULADO / BLOQUEADO / FALHOU / AMBIGUO / CORROMPIDO).
Codigo de saida != 0 quando algum item fica BLOQUEADO, FALHOU, AMBIGUO ou CORROMPIDO.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import http.client
import json
import logging
import os
import random
import re
import shutil
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "sugimori" / "dqt_web" / "fandom"
MANIFEST_PATH = DEST / "manifest.json"
MANIFEST_TMP = DEST / "manifest.json.tmp"
LOG_PATH = DEST / "fandom_art_fetch.log"

API_URL = "https://dragonquest.fandom.com/api.php"
WIKI_URL = "https://dragonquest.fandom.com/wiki/"
USER_AGENT = "CrawlmonArtFetch/1.0 (uso pessoal, projeto de jogo)"

DEFAULT_TITLES = ("Slime", "Orc", "Cyclops")
DEFAULT_MAX_MB = 25.0

CHUNK = 64 * 1024
MAX_JSON_BYTES = 8 * 1024 * 1024
MAX_ERROR_BODY = 256 * 1024
RETRY_BASE = 1.0
MAX_RETRY_WAIT = 30.0
MAX_RETRY_AFTER = 60.0
MIN_FREE_MARGIN = 2 * 1024 * 1024

PNG_SIG = b"\x89PNG\r\n\x1a\n"
EXT_BY_KIND = {"png": ".png", "jpg": ".jpg", "webp": ".webp"}
KNOWN_EXTS = (".png", ".jpg", ".webp")

ARTWORK_RE = re.compile(r"_artwork\.(?:png|jpe?g|webp)$", re.IGNORECASE)
BAD_CHARS_RE = re.compile(r'[<>:"/\\|?*\x00-\x1f]')

JPEG_SOF_MARKERS = {
    0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
    0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF,
}

RESERVED_WINDOWS = {
    "CON", "PRN", "AUX", "NUL",
    *{f"COM{i}" for i in range(1, 10)},
    *{f"LPT{i}" for i in range(1, 10)},
}

STATUSES = ("OK", "PULADO", "BLOQUEADO", "FALHOU", "AMBIGUO", "CORROMPIDO", "DRY")
FAILED_STATUSES = ("BLOQUEADO", "FALHOU", "AMBIGUO", "CORROMPIDO")
QUIET_STATUSES = ("OK", "PULADO", "DRY")

log = logging.getLogger("fandom_art_fetch")


class FetchError(Exception):
    """Falha esperada em um item; nao derruba os outros itens do lote."""


class BlockedError(FetchError):
    """Bloqueio/CAPTCHA/desafio anti-robo detectado (nao se tenta contornar)."""


class ApiError(FetchError):
    """Resposta invalida ou com campo de erro da API MediaWiki."""


class SizeError(FetchError):
    """Arquivo acima do limite --max-mb (nao adianta repetir)."""


class AmbiguousError(FetchError):
    """Mais de um arquivo plausivel; o script nao escolhe sozinho."""

    def __init__(self, message: str, candidates: list[str]) -> None:
        super().__init__(message)
        self.candidates = candidates


class RetryableTransfer(Exception):
    """Falha transitoria (rede, 5xx, 429, corpo truncado): vale tentar de novo."""

    def __init__(self, message: str, retry_after: float | None = None) -> None:
        super().__init__(message)
        self.retry_after = retry_after


# --------------------------------------------------------------------- util


def utc_now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def normalize_title(raw: str) -> str:
    """Espacos/underscore e primeira letra maiuscula, como a MediaWiki aceita."""
    title = re.sub(r"\s+", " ", raw.replace("_", " ")).strip()
    return title[:1].upper() + title[1:] if title else title


def title_key(raw: str) -> str:
    return re.sub(r"\s+", " ", raw.replace("_", " ")).strip().casefold()


def manual_wiki_url(title: str) -> str:
    return WIKI_URL + urllib.parse.quote(title.replace(" ", "_"))


def safe_stem(title: str) -> str:
    """Nome-base seguro para Windows, sem separadores e sem path traversal."""
    stem = title.replace(" ", "_")
    stem = BAD_CHARS_RE.sub("_", stem)
    stem = re.sub(r"_{2,}", "_", stem).strip(" .")
    if not stem:
        stem = "artwork"
    if stem.upper() in RESERVED_WINDOWS:
        stem = "_" + stem
    return stem + "_Artwork"


def existing_file(stem: str) -> Path | None:
    for ext in KNOWN_EXTS:
        candidate = DEST / (stem + ext)
        if candidate.is_file():
            return candidate
    return None


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(CHUNK), b""):
            digest.update(block)
    return digest.hexdigest()


def _unlink(path: Path) -> None:
    try:
        path.unlink()
    except FileNotFoundError:
        pass
    except OSError as exc:
        log.warning("nao foi possivel remover %s: %s", path, exc)


def ensure_inside(path: Path) -> None:
    try:
        path.resolve().relative_to(DEST.resolve())
    except ValueError:
        raise FetchError(f"caminho fora da pasta de destino: {path}") from None


def is_artwork_file(file_title: str) -> bool:
    return bool(ARTWORK_RE.search(file_title.replace(" ", "_")))


def detect_image_type(data: bytes) -> str | None:
    if data.startswith(PNG_SIG):
        return "png"
    if data.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    return None


def looks_like_challenge(data: bytes, content_type: str = "") -> bool:
    """Detecta pagina de desafio Cloudflare / HTML sem tentar contorna-la."""
    head = data[:MAX_ERROR_BODY].decode("utf-8", "replace").lower()
    for marker in ("just a moment", "cf-chl", "cf-browser-verification"):
        if marker in head:
            return True
    if detect_image_type(data):
        return False
    if "text/html" in (content_type or "").lower():
        return True
    snippet = data.lstrip()[:512].lower()
    return snippet.startswith((b"<!doctype html", b"<html"))


def png_has_transparency(data: bytes) -> bool:
    if len(data) < 26:
        return False
    if data[25] in (4, 6):
        return True
    pos = 8
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        if chunk_type == b"tRNS":
            return True
        if chunk_type in (b"IDAT", b"IEND"):
            break
        pos += 12 + length
    return False


def jpeg_size(data: bytes) -> tuple[int | None, int | None]:
    i = 2
    size = len(data)
    while i + 9 <= size:
        if data[i] != 0xFF:
            i += 1
            continue
        marker = data[i + 1]
        if marker in (0xD8, 0xD9, 0x01) or 0xD0 <= marker <= 0xD7:
            i += 2
            continue
        if i + 4 > size:
            break
        length = struct.unpack(">H", data[i + 2:i + 4])[0]
        if length < 2:
            break
        if marker in JPEG_SOF_MARKERS:
            height, width = struct.unpack(">HH", data[i + 5:i + 9])
            return width, height
        i += 2 + length
    return None, None


def webp_size(data: bytes) -> tuple[int | None, int | None]:
    if len(data) < 30:
        return None, None
    chunk = data[12:16]
    if chunk == b"VP8X":
        width = 1 + int.from_bytes(data[24:27], "little")
        height = 1 + int.from_bytes(data[27:30], "little")
        return width, height
    if chunk == b"VP8 ":
        pos = data.find(b"\x9d\x01\x2a", 20, 64)
        if pos != -1 and pos + 7 <= len(data):
            width = struct.unpack("<H", data[pos + 3:pos + 5])[0] & 0x3FFF
            height = struct.unpack("<H", data[pos + 5:pos + 7])[0] & 0x3FFF
            return width, height
    if chunk == b"VP8L" and len(data) >= 25:
        bits = int.from_bytes(data[21:25], "little")
        return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
    return None, None


def webp_has_alpha(data: bytes) -> bool | None:
    if len(data) < 30:
        return None
    chunk = data[12:16]
    if chunk == b"VP8X":
        return bool(data[20] & 0x10)
    if chunk == b"VP8L":
        return bool(int.from_bytes(data[21:25], "little") & (1 << 28))
    if chunk == b"VP8 ":
        return False
    return None


def inspect_image(path: Path, api_width=None, api_height=None) -> dict:
    """Valida assinatura, le dimensoes sem Pillow e avisa sobre transparencia."""
    data = path.read_bytes()
    kind = detect_image_type(data)
    if kind is None:
        raise FetchError("arquivo baixado nao tem assinatura PNG/JPEG/WebP")

    width = height = None
    transparent = None
    warnings: list[str] = []

    if kind == "png":
        if len(data) < 24:
            raise FetchError("PNG truncado (IHDR ausente)")
        width, height = struct.unpack(">II", data[16:24])
        transparent = png_has_transparency(data)
        if not transparent:
            warnings.append("PNG sem transparencia (sem canal alfa nem tRNS)")
    elif kind == "jpg":
        width, height = jpeg_size(data)
        transparent = False
        warnings.append("JPEG nao suporta transparencia")
        if width is None:
            warnings.append("dimensoes JPEG nao verificadas")
    else:
        width, height = webp_size(data)
        transparent = webp_has_alpha(data)
        if width is None:
            warnings.append("dimensoes WebP nao verificadas")
        if transparent is None:
            warnings.append("transparencia WebP nao verificada")
        elif not transparent:
            warnings.append("WebP sem transparencia")

    if api_width and api_height and width and height:
        try:
            if int(api_width) != width or int(api_height) != height:
                warnings.append(
                    f"dimensoes da API {api_width}x{api_height} diferentes da imagem "
                    f"{width}x{height}"
                )
        except (TypeError, ValueError):
            pass

    return {
        "kind": kind,
        "width": width,
        "height": height,
        "transparent": transparent,
        "warnings": warnings,
    }


# ----------------------------------------------------------------- manifest


def load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        return {"version": 1, "entries": {}}
    try:
        data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        log.warning("manifesto ilegivel (%s); comecando um novo", exc)
        return {"version": 1, "entries": {}}
    if not isinstance(data, dict) or not isinstance(data.get("entries"), dict):
        log.warning("manifesto em formato inesperado; comecando um novo")
        return {"version": 1, "entries": {}}
    data.setdefault("version", 1)
    return data


def setup_logging(dry_run: bool) -> None:
    log.handlers.clear()
    log.setLevel(logging.INFO)
    log.propagate = False
    fmt = logging.Formatter(
        "%(asctime)s %(levelname)-7s %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )
    stream = logging.StreamHandler(sys.stdout)
    stream.setFormatter(fmt)
    log.addHandler(stream)
    if not dry_run:
        file_handler = logging.FileHandler(LOG_PATH, mode="a", encoding="utf-8")
        file_handler.setFormatter(fmt)
        log.addHandler(file_handler)


def utf8_console() -> None:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            try:
                stream.reconfigure(encoding="utf-8", errors="replace")
            except (OSError, ValueError):
                pass


# ------------------------------------------------------------------ fetcher


class Fetcher:
    def __init__(self, args: argparse.Namespace) -> None:
        self.dry_run = bool(args.dry_run)
        self.force = bool(args.force)
        self.delay = max(0.0, float(args.delay))
        self.retries = max(0, int(args.retries))
        self.timeout = max(1.0, float(args.timeout))
        self.max_bytes = int(max(0.1, float(args.max_mb)) * 1024 * 1024)

        self.manifest: dict = {"version": 1, "entries": {}}
        self.results: list[dict] = []
        self._last_request = 0.0
        self._current_url: str | None = None

        if not self.dry_run:
            DEST.mkdir(parents=True, exist_ok=True)
        setup_logging(self.dry_run)
        if not self.dry_run:
            self.manifest = load_manifest()
            self.cleanup_parts()

    # -------------------------------------------------------------- rede

    def _throttle(self) -> None:
        if self.delay > 0:
            wait = self.delay - (time.monotonic() - self._last_request)
            if wait > 0:
                time.sleep(wait)
        self._last_request = time.monotonic()

    def _backoff(self, attempt: int) -> float:
        return min(RETRY_BASE * (2 ** attempt) + random.uniform(0.0, 0.5), MAX_RETRY_WAIT)

    @staticmethod
    def _retry_after(headers) -> float | None:
        value = headers.get("Retry-After") if headers else None
        if value and value.strip().isdigit():
            return min(float(value.strip()), MAX_RETRY_AFTER)
        return None

    def _open(self, url: str):
        self._throttle()
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        return urllib.request.urlopen(request, timeout=self.timeout)

    def _raise_http_error(self, exc: urllib.error.HTTPError, url: str) -> None:
        try:
            body = exc.read(MAX_ERROR_BODY)
        except Exception:
            body = b""
        headers = exc.headers
        content_type = headers.get("Content-Type", "") if headers else ""
        code = exc.code
        reason = exc.reason
        try:
            exc.close()
        except Exception:
            pass
        if looks_like_challenge(body, content_type):
            raise BlockedError(
                f"HTTP {code}: pagina de desafio/HTML no lugar da arte; "
                f"salve manualmente: {url}"
            ) from None
        if code == 429 or 500 <= code < 600:
            raise RetryableTransfer(f"HTTP {code} {reason}", self._retry_after(headers)) from None
        raise FetchError(f"HTTP {code} {reason}: {url}") from None

    def _request(self, url: str):
        attempts = self.retries + 1
        last_error = "falha de rede"
        for attempt in range(attempts):
            try:
                return self._open(url)
            except urllib.error.HTTPError as exc:
                try:
                    self._raise_http_error(exc, url)
                except RetryableTransfer as retry:
                    last_error = str(retry)
                    if attempt + 1 >= attempts:
                        raise FetchError(f"HTTP em {url}: {last_error}") from None
                    wait = retry.retry_after
                    if wait is None:
                        wait = self._backoff(attempt)
                    log.warning(
                        "%s em %s; nova tentativa em %.1fs (%d/%d)",
                        last_error, url, wait, attempt + 1, self.retries,
                    )
                    time.sleep(wait)
            except (urllib.error.URLError, http.client.HTTPException, TimeoutError, OSError) as exc:
                last_error = str(getattr(exc, "reason", exc))
                if attempt + 1 >= attempts:
                    break
                wait = self._backoff(attempt)
                log.warning(
                    "falha de rede em %s (%s); nova tentativa em %.1fs (%d/%d)",
                    url, last_error, wait, attempt + 1, self.retries,
                )
                time.sleep(wait)
        raise FetchError(f"falha de rede em {url}: {last_error}")

    def _get_bytes(self, url: str) -> bytes:
        response = self._request(url)
        try:
            content_type = response.headers.get("Content-Type", "")
            raw = response.read(MAX_JSON_BYTES + 1)
        finally:
            response.close()
        if len(raw) > MAX_JSON_BYTES:
            raise FetchError(f"resposta grande demais da API: {url}")
        if looks_like_challenge(raw, content_type):
            raise BlockedError(
                f"API respondeu HTML/desafio anti-robo; consulte manualmente: {url}"
            )
        return raw

    def api_query(self, params: dict) -> tuple[dict, str]:
        query = dict(params)
        query["format"] = "json"
        url = API_URL + "?" + urllib.parse.urlencode(query)
        raw = self._get_bytes(url)
        try:
            data = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ApiError(f"JSON invalido da API: {exc}") from None
        if not isinstance(data, dict):
            raise ApiError("API devolveu JSON que nao e um objeto")
        if data.get("error"):
            error = data["error"]
            info = error.get("info") if isinstance(error, dict) else str(error)
            raise ApiError(f"erro da API: {info}")
        return data, url

    # ------------------------------------------------------------ download

    def _check_disk(self, expected: int | None) -> None:
        need = expected if expected is not None else min(self.max_bytes, 8 * 1024 * 1024)
        need = int(need * 1.25) + MIN_FREE_MARGIN
        try:
            free = shutil.disk_usage(DEST).free
        except OSError as exc:
            log.warning("nao foi possivel checar espaco em disco: %s", exc)
            return
        if free < need:
            raise FetchError(
                f"espaco em disco insuficiente em {DEST}: precisa de {need} bytes, "
                f"livres {free} bytes"
            )

    def _stream_once(self, url: str, part_path: Path) -> None:
        try:
            response = self._open(url)
        except urllib.error.HTTPError as exc:
            self._raise_http_error(exc, url)  # sempre levanta
            return
        except (urllib.error.URLError, http.client.HTTPException, TimeoutError, OSError) as exc:
            raise RetryableTransfer(str(getattr(exc, "reason", exc))) from None

        expected: int | None = None
        total = 0
        first = True
        try:
            content_type = response.headers.get("Content-Type", "")
            length_header = response.headers.get("Content-Length")
            if length_header and length_header.strip().isdigit():
                expected = int(length_header.strip())
            if expected is not None and expected > self.max_bytes:
                raise SizeError(
                    f"arquivo maior que --max-mb ({expected} bytes): {url}"
                )
            self._check_disk(expected)
            with open(part_path, "wb") as handle:
                while True:
                    chunk = response.read(CHUNK)
                    if not chunk:
                        break
                    if first:
                        first = False
                        if looks_like_challenge(chunk, content_type):
                            raise BlockedError(
                                "CDN devolveu pagina de desafio/HTML, nao a arte; "
                                f"salve manualmente: {url}"
                            )
                    total += len(chunk)
                    if total > self.max_bytes:
                        raise SizeError(
                            f"download passou de --max-mb ({self.max_bytes} bytes): {url}"
                        )
                    handle.write(chunk)
        except (http.client.HTTPException, TimeoutError, OSError) as exc:
            raise RetryableTransfer(f"leitura interrompida: {exc}") from None
        finally:
            response.close()

        if total == 0:
            raise RetryableTransfer("resposta vazia")
        if expected is not None and total != expected:
            raise RetryableTransfer(f"Content-Length {expected} != {total} bytes recebidos")

    def _download(self, url: str, part_path: Path) -> None:
        attempts = self.retries + 1
        last = "falha de rede"
        for attempt in range(attempts):
            try:
                self._stream_once(url, part_path)
                return
            except RetryableTransfer as exc:
                last = str(exc)
                _unlink(part_path)
                if attempt + 1 >= attempts:
                    break
                wait = exc.retry_after
                if wait is None:
                    wait = self._backoff(attempt)
                log.warning(
                    "download interrompido (%s); nova tentativa em %.1fs (%d/%d)",
                    last, wait, attempt + 1, self.retries,
                )
                time.sleep(wait)
        raise FetchError(f"download falhou em {url}: {last}")

    # --------------------------------------------------------- API/wiki

    def _pages(self, query: dict) -> list[dict]:
        pages = query.get("pages")
        if not isinstance(pages, dict) or not pages:
            raise ApiError("resposta da API sem 'pages'")
        return [page for page in pages.values() if isinstance(page, dict)]

    def _single_page(self, query: dict, title: str) -> dict:
        pages = self._pages(query)
        for page in pages:
            if "invalid" in page:
                raise FetchError(f"titulo invalido para a wiki: {title!r}")
        for page in pages:
            if "missing" in page:
                raise FetchError(
                    f"pagina {title!r} nao existe na wiki; confira o titulo ou use "
                    f"{manual_wiki_url(title)}"
                )
        if len(pages) > 1:
            pages.sort(key=lambda page: page.get("pageid") or 0)
        return pages[0]

    @staticmethod
    def _final_title(requested: str, query: dict) -> str:
        title = normalize_title(requested)
        for block in ("normalized", "redirects"):
            for item in query.get(block) or []:
                if not isinstance(item, dict):
                    continue
                if title_key(item.get("from", "")) == title_key(title) and item.get("to"):
                    title = item["to"]
        return title

    def _file_url(self, file_title: str) -> tuple[str, int | None, int | None]:
        data, url = self.api_query({
            "action": "query",
            "titles": file_title,
            "prop": "imageinfo",
            "iiprop": "url|size",
            "redirects": "1",
        })
        query = data.get("query") or {}
        page = self._single_page(query, file_title)
        infos = page.get("imageinfo") or []
        info = infos[0] if isinstance(infos, list) and infos else {}
        source = info.get("url")
        if not source:
            raise FetchError(f"imageinfo sem URL para {file_title} ({url})")
        return source, info.get("width"), info.get("height")

    def _resolve_from_images(self, title: str) -> dict:
        data, url = self.api_query({
            "action": "query",
            "titles": normalize_title(title),
            "prop": "images",
            "imlimit": "max",
            "redirects": "1",
        })
        query = data.get("query") or {}
        final_title = self._final_title(title, query)
        page = self._single_page(query, final_title)

        images = [
            item["title"]
            for item in page.get("images") or []
            if isinstance(item, dict) and item.get("title")
        ]
        candidates = [name for name in images if is_artwork_file(name)]
        if not candidates:
            listed = ", ".join(images[:25]) if images else "nenhuma imagem"
            raise FetchError(
                f"pageimages vazio e nenhum arquivo *_Artwork.* na pagina {final_title!r}; "
                f"imagens encontradas: {listed} (consulte {manual_wiki_url(final_title)})"
            )
        if len(candidates) > 1:
            raise AmbiguousError(
                f"{len(candidates)} arquivos *_Artwork.* na pagina {final_title!r}; "
                "escolha um manualmente",
                candidates,
            )
        source, width, height = self._file_url(candidates[0])
        return {
            "title": final_title,
            "url": source,
            "width": width,
            "height": height,
            "via": "images",
            "file_title": candidates[0],
            "api_url": url,
        }

    def resolve_artwork(self, title: str) -> dict:
        data, url = self.api_query({
            "action": "query",
            "titles": normalize_title(title),
            "prop": "pageimages",
            "piprop": "original|name",
            "redirects": "1",
        })
        query = data.get("query") or {}
        final_title = self._final_title(title, query)
        page = self._single_page(query, final_title)
        original = page.get("original") or {}
        source = original.get("source") if isinstance(original, dict) else None
        if source:
            return {
                "title": final_title,
                "url": source,
                "width": original.get("width"),
                "height": original.get("height"),
                "via": "pageimages",
                "file_title": page.get("pageimage"),
                "api_url": url,
            }
        log.info("pageimages vazio para %r; tentando prop=images", final_title)
        return self._resolve_from_images(final_title)

    # ------------------------------------------------------------- itens

    def _record(self, title: str, status: str, **extra) -> None:
        entry = {"title": title, "status": status}
        entry.update({key: value for key, value in extra.items() if value is not None})
        self.results.append(entry)

    def _upsert(self, stem: str, title: str, path: Path, url: str, digest: str, status: str) -> None:
        self.manifest["entries"][stem] = {
            "title": title,
            "file": path.name,
            "url": url,
            "bytes": path.stat().st_size,
            "sha256": digest,
            "date": utc_now(),
            "status": status,
        }
        self.save_manifest()

    def _check_existing(self, path: Path, entry: dict) -> tuple[str, str]:
        try:
            inspect_image(path)
        except FetchError as exc:
            return "CORROMPIDO", f"arquivo existente invalido ({exc}); use --force"
        recorded = entry.get("sha256") if isinstance(entry, dict) else None
        if recorded and recorded != sha256_of(path):
            return "CORROMPIDO", "sha256 nao confere com o manifesto; use --force"
        return "PULADO", ""

    def process(self, title: str) -> None:
        self._current_url = None
        art = self.resolve_artwork(title)
        final_title = art["title"]
        url = art["url"]
        self._current_url = url
        via = art.get("via")
        if via and via != "pageimages":
            log.info("fonte de %r: prop=images -> %s", final_title, art.get("file_title"))

        if self.dry_run:
            log.info(
                "DRY %s: %sx%s %s",
                final_title, art.get("width") or "?", art.get("height") or "?", url,
            )
            self._record(final_title, "DRY", url=url)
            return

        stem = safe_stem(final_title)
        existing = existing_file(stem)
        entry = self.manifest["entries"].get(stem) or {}

        if existing is not None and not self.force:
            status, note = self._check_existing(existing, entry)
            if status == "PULADO":
                self._upsert(stem, final_title, existing, url, sha256_of(existing), "PULADO")
                log.info(
                    "PULADO %s -> %s (ja existe e e valido)", final_title, existing.name
                )
                self._record(final_title, "PULADO", url=url, path=existing)
                return
            log.warning("%s %s: %s", status, final_title, note)
            self._record(final_title, status, url=url, path=existing, note=note)
            return

        part = DEST / (stem + ".part")
        ensure_inside(part)
        final_path: Path | None = None
        try:
            self._download(url, part)  # baixa para <nome>.part
            info = inspect_image(part, art.get("width"), art.get("height"))
            final_path = DEST / (stem + EXT_BY_KIND[info["kind"]])
            ensure_inside(final_path)
            os.replace(part, final_path)  # so troca depois de validar
        finally:
            if part.exists():
                _unlink(part)

        digest = sha256_of(final_path)
        for warning in info["warnings"]:
            log.warning("%s: %s", final_title, warning)
        self._upsert(stem, final_title, final_path, url, digest, "OK")
        log.info(
            "OK %s -> %s (%d bytes, %sx%s)",
            final_title, final_path.name, final_path.stat().st_size,
            info["width"] or "?", info["height"] or "?",
        )
        note = "; ".join(info["warnings"])
        if note:
            log.warning("AVISO %s: %s", final_title, note)
        self._record(final_title, "OK", url=url, path=final_path, note=note)

    def run(self, titles: list[str]) -> int:
        for raw in titles:
            log.info("--- %s", raw)
            try:
                self.process(raw)
            except AmbiguousError as exc:
                log.error("AMBIGUO %s: %s", raw, exc)
                for candidate in exc.candidates:
                    log.error("  candidato: %s", candidate)
                self._record(raw, "AMBIGUO", note=str(exc))
            except BlockedError as exc:
                log.error("BLOQUEADO %s: %s", raw, exc)
                self._record(raw, "BLOQUEADO", url=self._current_url, note=str(exc))
            except FetchError as exc:
                log.error("FALHOU %s: %s", raw, exc)
                self._record(raw, "FALHOU", url=self._current_url, note=str(exc))
            except Exception as exc:  # um item nao derruba o lote
                log.exception("FALHOU %s: erro inesperado", raw)
                self._record(raw, "FALHOU", note=f"erro inesperado: {exc}")
        self.save_manifest()
        self.report()
        failed = any(item["status"] in FAILED_STATUSES for item in self.results)
        return 1 if failed else 0

    # ------------------------------------------------------------ estado

    def cleanup_parts(self) -> None:
        for part in DEST.glob("*.part"):
            log.info("removendo .part antigo: %s", part.name)
            _unlink(part)

    def save_manifest(self) -> None:
        if self.dry_run:
            return
        entries = {key: self.manifest["entries"][key] for key in sorted(self.manifest["entries"])}
        payload = {
            "version": 1,
            "destination": DEST.relative_to(ROOT).as_posix(),
            "updated": utc_now(),
            "entries": entries,
        }
        DEST.mkdir(parents=True, exist_ok=True)
        MANIFEST_TMP.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        os.replace(MANIFEST_TMP, MANIFEST_PATH)

    def report(self) -> None:
        counts = {status: 0 for status in STATUSES}
        for item in self.results:
            counts[item["status"]] = counts.get(item["status"], 0) + 1

        log.info("")
        log.info("==== Relatorio: %s ====", DEST)
        for status in STATUSES:
            log.info("%-11s %d", status, counts.get(status, 0))
        log.info("%-11s %d", "Total", len(self.results))
        log.info("")

        for item in self.results:
            status = item["status"]
            line = f"{status:<11} {item['title']}"
            if item.get("path"):
                line += f" -> {Path(item['path']).name}"
            if item.get("note"):
                line += f" ({item['note']})"
            log.log(logging.INFO if status in QUIET_STATUSES else logging.ERROR, line)
            if status in FAILED_STATUSES and item.get("url"):
                log.error("%-11s URL: %s", "", item["url"])

        if self.dry_run:
            log.info("dry-run: nada foi baixado e nenhum arquivo foi criado")


# --------------------------------------------------------------------- main


def parse_args(argv=None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Baixa a arte oficial da Dragon Quest Wiki para sugimori/dqt_web/fandom/."
    )
    parser.add_argument(
        "titles",
        nargs="*",
        help="titulos dos monstros na wiki (padrao: Slime Orc Cyclops)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="so consulta a API e mostra URL e tamanho; nao baixa nem cria arquivos",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="rebaixa mesmo que o arquivo exista e confira com o manifesto",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=1.0,
        help="pausa entre requisicoes em segundos (padrao 1.0)",
    )
    parser.add_argument(
        "--max-mb",
        type=float,
        default=DEFAULT_MAX_MB,
        help=f"tamanho maximo por arquivo em MB (padrao {DEFAULT_MAX_MB:g})",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=3,
        help="tentativas por requisicao em falhas transitorias (padrao 3)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="timeout de conexao e leitura em segundos (padrao 30)",
    )
    return parser.parse_args(argv)


def main(argv=None) -> int:
    utf8_console()
    args = parse_args(argv)
    titles = [title for title in args.titles if title.strip()] or list(DEFAULT_TITLES)

    try:
        fetcher = Fetcher(args)
    except OSError as exc:
        print(f"falha ao preparar a pasta de destino {DEST}: {exc}", file=sys.stderr)
        return 1

    try:
        return fetcher.run(titles)
    except KeyboardInterrupt:
        log.warning(
            "interrompido pelo criador (Ctrl+C); removendo .part e salvando o manifesto"
        )
        if not fetcher.dry_run:
            fetcher.cleanup_parts()
            fetcher.save_manifest()
        return 130
    finally:
        _unlink(MANIFEST_TMP)


if __name__ == "__main__":
    sys.exit(main())
