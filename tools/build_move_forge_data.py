#!/usr/bin/env python3
"""Gera prototypes/move_forge/move_forge_data.js a partir dos dados reais do jogo.

Passo de exportacao de dados do Move Forge (D-1206). Somente leitura nos dados
do jogo: nada em content/, assets/, shaders/ ou scripts/ e alterado.
Sem dependencias externas (apenas a biblioteca padrao do Python 3).
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

# Raiz do projeto = pasta acima de tools/ (este arquivo fica em tools/).
ROOT = Path(__file__).resolve().parent.parent

MOVES_DIR = ROOT / "content" / "moves"
CATALOG_PATH = ROOT / "content" / "catalogs" / "move_catalog.tres"
REGISTRY_PATH = ROOT / "scripts" / "vfx" / "combat" / "move_vfx_registry.gd"
OUT_DIR = ROOT / "prototypes" / "move_forge"
OUT_PATH = OUT_DIR / "move_forge_data.js"

TEXT_FIELDS = {
    "effect_line_text": "effect_line",
    "short_effect_text": "short_effect",
    "description_text": "description",
    "mechanics_text": "mechanics",
    "visual_text": "visual",
    "motion_text": "motion",
    "windup_text": "windup",
    "tactical_text": "tactical",
}

KNOWN_KEYS = {
    "id", "display_name", "kind", "element", "damage_type", "power",
    "atb_cost", "mp_cost", "windup", "is_aoe", "is_friendly", "ground",
    "aoe_on_contact", "teleport", "untargetable", "bypass_def",
    "target_mode", "magic_flat", "tags", "vfx_key", "phase_visuals",
} | set(TEXT_FIELDS)

KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$")
FLOAT_RE = re.compile(r"-?(?:(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?|\d+[eE][+-]?\d+)")
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".tga", ".bmp"}


def warn(message):
    """Aviso vai para stderr e nunca interrompe a geracao."""
    print(f"[build_move_forge_data] AVISO: {message}", file=sys.stderr)


def read_text(path):
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        warn(f"nao foi possivel ler {path}: {exc}")
        return ""


# --- Parser do .tres (somente a secao [resource]) ---------------------------

def value_complete(text):
    """True quando strings e colchetes/chaves/parenteses estao fechados."""
    depth = 0
    in_string = False
    escaped = False
    for ch in text:
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
    return not in_string and depth <= 0


def collect_value(lines, index, column):
    """Junta o valor da linha (e continuacoes) ate ele ficar completo."""
    raw = lines[index][column:]
    while not value_complete(raw):
        index += 1
        if index >= len(lines):
            warn("valor multi-linha sem fechamento no fim do arquivo")
            break
        raw += "\n" + lines[index]
    return raw.strip(), index


def decode_escapes(text):
    result = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\\" and i + 1 < len(text):
            nxt = text[i + 1]
            result.append({"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}.get(nxt, nxt))
            i += 2
        else:
            result.append(ch)
            i += 1
    return "".join(result)


def is_quoted(text):
    return len(text) >= 2 and text[0] == '"' and text[-1] == '"'


def unquote(text):
    return decode_escapes(text[1:-1])


def read_dict_value(text, pos):
    """Le um valor dentro de um dict: string entre aspas ou token simples."""
    n = len(text)
    while pos < n and text[pos] in " \t\r\n":
        pos += 1
    if pos >= n:
        return "", pos
    if text[pos] == '"':
        i = pos + 1
        while i < n:
            if text[i] == "\\":
                i += 2
                continue
            if text[i] == '"':
                i += 1
                break
            i += 1
        return text[pos:i], i
    start = pos
    depth = 0
    while pos < n:
        ch = text[pos]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            break
        pos += 1
    return text[start:pos], pos


def parse_dict(text):
    """Dict Godot simples ({ "chave": valor, ... }), inclusive multi-linha."""
    if not (text.startswith("{") and text.endswith("}")):
        return None
    inner = text[1:-1]
    result = {}
    pos = 0
    n = len(inner)
    while pos < n:
        while pos < n and inner[pos] in " \t\r\n,":
            pos += 1
        if pos >= n:
            break
        match = re.match(r'&?"((?:[^"\\]|\\.)*)"\s*:', inner[pos:])
        if not match:
            warn(f"chave de dict invalida perto de: {inner[pos:pos + 40]!r}")
            return None
        key = decode_escapes(match.group(1))
        pos += match.end()
        token, pos = read_dict_value(inner, pos)
        value, kind = convert_value(token)
        if kind == "raw":
            warn(f"formato de valor desconhecido no dict em {key!r}: {token[:60]!r}")
        result[key] = value
    return result


def parse_array(text):
    """Array[StringName]([...]), PackedStringArray(...), [...] -> lista de str."""
    if text.startswith("Array[StringName](") or text.startswith("Array[String](") \
            or text.startswith("PackedStringArray("):
        if not text.endswith(")"):
            return None
        text = text[text.index("(") + 1:-1].strip()
    if not (text.startswith("[") and text.endswith("]")):
        return None
    inner = text[1:-1].strip()
    if not inner:
        return []
    items = re.findall(r'&?"((?:[^"\\]|\\.)*)"', inner)
    if not items:
        warn(f"array sem strings reconheciveis: {text[:60]!r}")
        return None
    return [decode_escapes(item) for item in items]


def convert_value(raw):
    """Converte um valor do .tres. Retorna (valor, tipo)."""
    text = raw.strip()
    if text == "true":
        return True, "scalar"
    if text == "false":
        return False, "scalar"
    if re.fullmatch(r"-?\d+", text):
        return int(text), "scalar"
    if FLOAT_RE.fullmatch(text):
        return float(text), "scalar"
    if text.startswith("&") and is_quoted(text[1:]):
        return unquote(text[1:]), "scalar"
    if is_quoted(text):
        return unquote(text), "scalar"
    array = parse_array(text)
    if array is not None:
        return array, "array"
    mapping = parse_dict(text)
    if mapping is not None:
        return mapping, "dict"
    return text, "raw"


def parse_resource_section(text):
    """Le apenas a secao [resource] do .tres; retorna chave -> (valor, tipo)."""
    lines = text.splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.strip() == "[resource]":
            start = index + 1
            break
    if start is None:
        warn("secao [resource] nao encontrada")
        return {}

    parsed = {}
    index = start
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            break
        if not stripped or stripped.startswith(";"):
            index += 1
            continue
        match = KEY_RE.match(line)
        if not match:
            index += 1
            continue
        key = match.group(1)
        raw, index = collect_value(lines, index, match.start(2))
        value, kind = convert_value(raw)
        if kind == "raw" and not re.match(r"^(Ext|Sub)Resource\(", raw):
            warn(f"formato de valor desconhecido em {key}: {raw[:60]!r}")
        parsed[key] = (value, kind)
        index += 1
    return parsed


# --- Elementos (enum Type) --------------------------------------------------

def parse_elements():
    candidates = [ROOT / "scripts" / "data" / "element.gd"]
    candidates += sorted((ROOT / "scripts").rglob("element.gd"))
    seen = set()
    for path in candidates:
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        text = read_text(path)
        match = re.search(r"enum\s+Type\s*\{(.*?)\}", text, re.S)
        if not match:
            continue
        elements = []
        next_id = 0
        for item in match.group(1).split(","):
            item = item.strip()
            if not item:
                continue
            name, _, explicit = item.partition("=")
            name = name.strip()
            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                warn(f"elemento ignorado em {path.name}: {item!r}")
                continue
            explicit = explicit.strip()
            if explicit:
                try:
                    next_id = int(explicit)
                except ValueError:
                    warn(f"valor de enum nao numerico em {path.name}: {explicit!r}")
            elements.append({"id": next_id, "key": name})
            next_id += 1
        return elements
    warn("enum Type nao encontrado em scripts/**/element.gd")
    return []


# --- Familias de VFX --------------------------------------------------------

def parse_family_by_id():
    if not REGISTRY_PATH.is_file():
        warn(f"{REGISTRY_PATH.relative_to(ROOT)} nao existe; familias = {{}}")
        return {}
    text = read_text(REGISTRY_PATH)
    match = re.search(r"FAMILY_BY_ID\s*:=\s*\{", text)
    if not match:
        warn("bloco FAMILY_BY_ID nao encontrado")
        return {}
    brace = text.find("{", match.start())
    depth = 0
    end = None
    for index in range(brace, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                end = index
                break
    if end is None:
        warn("bloco FAMILY_BY_ID sem fechamento")
        return {}
    block = text[brace:end + 1]
    return dict(re.findall(r'&?"([^"]+)"\s*:\s*&?"([^"]+)"', block))


# --- Arquivos de VFX --------------------------------------------------------

def relative_files(base, suffixes, root=None):
    if not base.is_dir():
        warn(f"pasta nao encontrada: {base.relative_to(ROOT)}")
        return []
    anchor = root or ROOT
    found = []
    for path in base.rglob("*"):
        if path.is_file() and path.suffix.lower() in suffixes:
            found.append(path.relative_to(anchor).as_posix())
    return sorted(found)


def collect_vfx(families):
    flipbooks = relative_files(ROOT / "assets" / "vfx", IMAGE_SUFFIXES, ROOT / "assets" / "vfx")
    meshes = relative_files(ROOT / "assets" / "vfx", {".glb"})
    shaders = []
    for base in (ROOT / "shaders", ROOT / "vfx" / "shaders"):
        shaders += relative_files(base, {".gdshader"})
    behaviors = []
    motion_dir = ROOT / "scripts" / "motion_composer"
    if motion_dir.is_dir():
        behaviors = sorted({path.stem for path in motion_dir.rglob("*.gd")})
    else:
        warn("pasta scripts/motion_composer nao encontrada")
    return {
        "families": sorted(set(families.values())),
        "family_by_id": dict(sorted(families.items())),
        "flipbooks": flipbooks,
        "meshes": meshes,
        "shaders": sorted(set(shaders)),
        "motion_behaviors": behaviors,
    }


# --- Moves ------------------------------------------------------------------

def int_field(data, key, default, ctx):
    value = data.get(key)
    if value is None:
        return default
    if isinstance(value, bool) or not isinstance(value, int):
        warn(f"{ctx}.{key}: esperado int, veio {type(value).__name__}")
        return default
    return value


def float_field(data, key, default, ctx):
    value = data.get(key)
    if value is None:
        return default
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        warn(f"{ctx}.{key}: esperado numero, veio {type(value).__name__}")
        return default
    return float(value)


def bool_field(data, key, default, ctx):
    value = data.get(key)
    if value is None:
        return default
    if not isinstance(value, bool):
        warn(f"{ctx}.{key}: esperado bool, veio {type(value).__name__}")
        return default
    return value


def str_field(data, key, default, ctx):
    value = data.get(key)
    if value is None:
        return default
    if not isinstance(value, str):
        warn(f"{ctx}.{key}: esperado str, veio {type(value).__name__}")
        return default
    return value


def list_field(data, key, ctx):
    value = data.get(key)
    if value is None:
        return []
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        warn(f"{ctx}.{key}: esperado lista de str")
        return []
    return value


def dict_field(data, key, ctx):
    value = data.get(key)
    if value is None:
        return {}
    if not isinstance(value, dict):
        warn(f"{ctx}.{key}: esperado dict")
        return {}
    return value


def build_move(folder, catalog_text, families):
    move_id = folder.name
    path = folder / "move.tres"
    if not path.is_file():
        warn(f"move.tres ausente em {folder.relative_to(ROOT).as_posix()}")
        return None

    parsed = parse_resource_section(read_text(path))
    data = {key: value for key, (value, _kind) in parsed.items()}
    ctx = move_id

    texts = {target: str_field(data, source, "", ctx) for source, target in TEXT_FIELDS.items()}
    vfx_key = str_field(data, "vfx_key", "", ctx)

    extra = {}
    for key, (value, kind) in parsed.items():
        if key in KNOWN_KEYS or kind != "scalar":
            continue
        extra[key] = value

    move = {
        "id": str_field(data, "id", "", ctx) or move_id,
        "name": str_field(data, "display_name", "", ctx),
        "kind": int_field(data, "kind", 0, ctx),
        "element": int_field(data, "element", 0, ctx),
        "damage_type": int_field(data, "damage_type", 0, ctx),
        "power": float_field(data, "power", 1.0, ctx),
        "atb_cost": int_field(data, "atb_cost", 2, ctx),
        "mp_cost": int_field(data, "mp_cost", 0, ctx),
        "windup": float_field(data, "windup", -1.0, ctx),
        "is_aoe": bool_field(data, "is_aoe", False, ctx),
        "is_friendly": bool_field(data, "is_friendly", False, ctx),
        "ground": bool_field(data, "ground", False, ctx),
        "aoe_on_contact": bool_field(data, "aoe_on_contact", False, ctx),
        "teleport": bool_field(data, "teleport", False, ctx),
        "untargetable": bool_field(data, "untargetable", False, ctx),
        "bypass_def": bool_field(data, "bypass_def", False, ctx),
        "target_mode": int_field(data, "target_mode", 0, ctx),
        "magic_flat": int_field(data, "magic_flat", 0, ctx),
        "tags": list_field(data, "tags", ctx),
        "vfx_key": vfx_key,
        "vfx_family": families.get(move_id, vfx_key),
        "has_behavior": (folder / "behavior.gd").is_file(),
        "has_vfx_script": (folder / "vfx.gd").is_file(),
        "texts": texts,
        "phase_visuals": dict_field(data, "phase_visuals", ctx),
        "extra": extra,
    }
    if catalog_text is not None:
        move["in_catalog"] = f"content/moves/{move_id}/move.tres" in catalog_text
    return move


def build_moves(catalog_text, families):
    if not MOVES_DIR.is_dir():
        warn(f"pasta nao encontrada: {MOVES_DIR.relative_to(ROOT)}")
        return []
    moves = []
    for folder in sorted(MOVES_DIR.iterdir()):
        if folder.is_dir():
            move = build_move(folder, catalog_text, families)
            if move is not None:
                moves.append(move)
    return sorted(moves, key=lambda move: move["id"])


def main():
    catalog_text = None
    if CATALOG_PATH.is_file():
        catalog_text = read_text(CATALOG_PATH)
    else:
        warn(f"{CATALOG_PATH.relative_to(ROOT)} nao existe; in_catalog omitido")

    families = parse_family_by_id()
    data = {
        "generated": datetime.now().isoformat(timespec="seconds"),
        "elements": parse_elements(),
        "moves": build_moves(catalog_text, families),
        "vfx": collect_vfx(families),
    }

    os.makedirs(OUT_DIR, exist_ok=True)
    payload = json.dumps(data, ensure_ascii=False, indent=1)
    OUT_PATH.write_text("window.MOVE_FORGE_DATA = " + payload + ";\n", encoding="utf-8")

    print(f"Moves: {len(data['moves'])}")
    print(f"Familias VFX: {len(data['vfx']['families'])}")
    print(f"Shaders: {len(data['vfx']['shaders'])}")
    print(f"Flipbooks: {len(data['vfx']['flipbooks'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
