#!/usr/bin/env python3
"""Analisa custo de MP/ATB dos Moves e grava prototypes/move_forge/cost_model.js (D-1206).

  python tools/build_move_forge_cost.py

Só lê prototypes/move_forge/move_forge_data.js e escreve cost_model.js; nenhuma regra do jogo muda.
"""
import json
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FORGE = ROOT / "prototypes" / "move_forge"
FIELDS = ("id", "kind", "element", "power", "atb_cost", "mp_cost", "windup",
          "is_aoe", "target_mode", "tags", "magic_flat")


def load_moves():
    text = (FORGE / "move_forge_data.js").read_text(encoding="utf-8")
    return json.loads(text[text.index("{"):text.rindex("}") + 1])["moves"]


def value(move, name, missing):
    raw = move.get(name)
    if raw is None:
        missing[name] = missing.get(name, 0) + 1
        return 0
    return raw


def stats(values):
    if not values:
        return None
    ordered = sorted(values)
    n = len(ordered)
    median = ordered[n // 2] if n % 2 else (ordered[n // 2 - 1] + ordered[n // 2]) / 2
    return {"min": ordered[0], "median": median, "max": ordered[-1]}


def solve(matrix, vector):
    n = len(vector)
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(matrix[r][col]))
        matrix[col], matrix[pivot] = matrix[pivot], matrix[col]
        vector[col], vector[pivot] = vector[pivot], vector[col]
        for row in range(col + 1, n):
            factor = matrix[row][col] / matrix[col][col]
            for k in range(col, n):
                matrix[row][k] -= factor * matrix[col][k]
            vector[row] -= factor * vector[col]
    result = [0.0] * n
    for row in range(n - 1, -1, -1):
        total = vector[row] - sum(matrix[row][k] * result[k] for k in range(row + 1, n))
        result[row] = total / matrix[row][row]
    return result


def main():
    missing = {}
    rows = []
    for move in load_moves():
        row = {name: value(move, name, missing) for name in FIELDS}
        row["is_aoe"] = 1 if row["is_aoe"] else 0
        rows.append(row)

    tiers = {}
    for tier in range(1, 6):
        group = [r for r in rows if int(r["atb_cost"]) == tier]
        if not group:
            continue
        tiers[str(tier)] = {
            "n": len(group),
            "power": stats([r["power"] for r in group if r["power"] > 0]),
            "mp_cost": stats([r["mp_cost"] for r in group]),
            "windup": stats([r["windup"] for r in group]),
        }

    x = [[1.0, r["power"], r["is_aoe"], r["atb_cost"]] for r in rows]
    y = [r["mp_cost"] for r in rows]
    size = 4
    xtx = [[sum(x[i][a] * x[i][b] for i in range(len(x))) for b in range(size)] for a in range(size)]
    xty = [sum(x[i][a] * y[i] for i in range(len(x))) for a in range(size)]
    coef = solve(xtx, xty)
    predicted = [sum(coef[k] * x[i][k] for k in range(size)) for i in range(len(x))]
    mean = sum(y) / len(y)
    ss_tot = sum((v - mean) ** 2 for v in y)
    ss_res = sum((y[i] - predicted[i]) ** 2 for i in range(len(y)))
    r2 = 0.0 if ss_tot == 0 else 1 - ss_res / ss_tot

    mp_by_kind = {}
    for kind in range(4):
        group = [r["mp_cost"] for r in rows if int(r["kind"]) == kind]
        mp_by_kind[str(kind)] = {"n": len(group), **stats(group)} if group else {
            "n": 0, "min": None, "median": None, "max": None}

    output = {
        "tiers": tiers,
        "fit": {
            "coef": {"const": coef[0], "power": coef[1], "is_aoe": coef[2], "atb_cost": coef[3]},
            "r2": r2,
            "moves": [{"id": rows[i]["id"], "mp_real": rows[i]["mp_cost"], "mp_previsto": round(predicted[i], 3)}
                      for i in range(len(rows))],
        },
        "mp_by_kind": mp_by_kind,
        "missing": missing,
        "generated": datetime.now().isoformat(timespec="seconds"),
    }
    if not FORGE.exists():
        FORGE.mkdir(parents=True)
    (FORGE / "cost_model.js").write_text(
        "window.MOVE_FORGE_COST = " + json.dumps(output, ensure_ascii=False, indent=1) + ";\n",
        encoding="utf-8")
    print(f"Moves: {len(rows)}")
    print("tiers n: " + ", ".join(f"{k}={v['n']}" for k, v in tiers.items()))
    print(f"R^2: {r2:.4f}")
    print(f"missing: {missing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
