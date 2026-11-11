#!/usr/bin/env python3
"""Aplica a matriz de afinidades exportada (JSON) nos species.tres.

Fonte: content/affinities/crawlmon_affinities.json (exportado de
prototypes/affinity_matrix.html).

O script escreve `affinities` (12 entradas explícitas, índice do elemento ->
Affinity.Type) e sincroniza `weaknesses` (lista legada usada por algumas UIs).
Nao mexe em nenhum outro campo. Por padrao so mostra o diff; use --write para
gravar.

Uso:
  python tools/apply_affinities.py              # dry-run (mostra o diff)
  python tools/apply_affinities.py --write      # aplica
  python tools/apply_affinities.py --json CAMINHO
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_JSON = ROOT / "content" / "affinities" / "crawlmon_affinities.json"
CHARACTERS_DIR = ROOT / "content" / "characters"

ELEMENT_INDEX = {
    "neutral": 0,
    "fire": 1,
    "water": 2,
    "electric": 3,
    "psychic": 4,
    "nature": 5,
    "sound": 6,
    "earth": 7,
    "wind": 8,
    "light": 9,
    "dark": 10,
    "mystic": 11,
}
AFFINITY_INDEX = {"neutral": 0, "weak": 1, "resist": 2}
AFFINITY_NAME = {0: "neutral", 1: "weak", 2: "resist"}


def element_order() -> list[str]:
    return sorted(ELEMENT_INDEX, key=ELEMENT_INDEX.get)


def build_table(character: dict) -> dict[int, int]:
    """Devolve {elemento_int: afinidade_int} com as 12 entradas."""
    explicit = character.get("affinities") or {}
    weak = set(character.get("weak") or [])
    resist = set(character.get("resist") or [])
    table: dict[int, int] = {}
    for name in element_order():
        value = explicit.get(name)
        if value is None:
            value = "weak" if name in weak else "resist" if name in resist else "neutral"
        if value not in AFFINITY_INDEX:
            raise ValueError(
                f'afinidade invalida "{value}" para {character.get("id")} / {name}'
            )
        table[ELEMENT_INDEX[name]] = AFFINITY_INDEX[value]
    return table


def render_affinities(table: dict[int, int]) -> str:
    body = ",\n".join(f"{element}: {table[element]}" for element in range(len(ELEMENT_INDEX)))
    return f"affinities = {{\n{body}\n}}"


def render_weaknesses(table: dict[int, int]) -> str:
    weak = [element for element in range(len(ELEMENT_INDEX)) if table[element] == AFFINITY_INDEX["weak"]]
    return "weaknesses = Array[int]([" + ", ".join(str(element) for element in weak) + "])"


def update_species_text(text: str, table: dict[int, int]) -> str:
    new_weak = render_weaknesses(table)
    text, count = re.subn(r"^weaknesses = .*$", new_weak, text, count=1, flags=re.M)
    if count != 1:
        raise ValueError("campo weaknesses nao encontrado")
    text = re.sub(r"^affinities = \{\n.*?^\}\n", "", text, count=1, flags=re.M | re.S)
    text = text.replace(new_weak, f"{new_weak}\n{render_affinities(table)}", 1)
    if not text.endswith("\n"):
        text += "\n"
    return text


def describe(table: dict[int, int]) -> str:
    weak = [element_order()[element] for element in range(len(ELEMENT_INDEX)) if table[element] == 1]
    resist = [element_order()[element] for element in range(len(ELEMENT_INDEX)) if table[element] == 2]
    return (
        f"W: {', '.join(weak) or '-'} | R: {', '.join(resist) or '-'}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--json", default=str(DEFAULT_JSON), help="JSON exportado da matriz")
    parser.add_argument("--write", action="store_true", help="grava os arquivos (sem isso, so mostra)")
    args = parser.parse_args()

    source = Path(args.json)
    if not source.exists():
        print(f"ERRO: JSON nao encontrado: {source}", file=sys.stderr)
        return 1

    data = json.loads(source.read_text(encoding="utf-8"))
    characters = data.get("characters") or []
    if not characters:
        print("ERRO: JSON sem characters", file=sys.stderr)
        return 1

    applied = 0
    unchanged = 0
    missing: list[str] = []

    for character in characters:
        char_id = character.get("id")
        species = CHARACTERS_DIR / str(char_id) / "species.tres"
        if not species.exists():
            missing.append(str(char_id))
            continue

        table = build_table(character)
        original = species.read_text(encoding="utf-8")
        updated = update_species_text(original, table)
        changed = updated != original

        if not changed:
            unchanged += 1
            print(f"= {char_id:16} {describe(table)}")
            continue

        print(f"{'+' if changed else '='} {char_id:16} {describe(table)}")
        if args.write:
            species.write_text(updated, encoding="utf-8", newline="")
            applied += 1

    print()
    print(f"personagens no JSON: {len(characters)}")
    print(f"sem species.tres (nao implementados no jogo): {len(missing)} -> {', '.join(missing) or '-'}")
    if args.write:
        print(f"gravados: {applied} | ja iguais: {unchanged}")
    else:
        print(f"dry-run: {len(characters) - len(missing) - unchanged} mudariam | ja iguais: {unchanged}")
        print("use --write para aplicar")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
