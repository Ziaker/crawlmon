"""Runner automatizado de testes de combate, cenários e análise VFX para agentes de IA (D-1042, D-1044).

Valida:
1. Cenários de Dano e Reação (com verificação de telemetria real em SUMMARY_JSON: hits, crítico, fraqueza, ARMOR, STUN, Guard, KO)
2. Fases de Move e Fichas Visuais por Fase (Wind-up, Release, Trajeto, Strike, Impacto, Retorno + --isolate-phase)
3. Ferramentas de Análise VFX (Leak Detector, Scale Overlay, Bone Probe, Overdraw, Envelope Graph, Background Checker, Macro Cam)
4. Simetria D-235 Automatizada (--test-d235)

Uso:
    python tests/battle/run_agent_combat_tests.py
"""
import json
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")
SCENE = "res://scenes/debug/vfx_room.tscn"

SCENARIO_TESTS = [
    # 1. Cenários de Dano e Reação (com validação de SUMMARY_JSON real)
    ("Dano Neutro Direto", ["--scenario=dano_direto", "--summary-json", "--quit"], "dano neutro direto",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("damage_dealt", 0) > 0),
    ("Dano Crítico", ["--scenario=dano_critico", "--summary-json", "--quit"], "crítico",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("crit_count", 0) >= 1),
    ("Dano Fraqueza (WEAK!)", ["--scenario=dano_weak", "--summary-json", "--quit"], "dano de fraqueza",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("weak_count", 0) >= 1),
    ("Dano ARMOR (D-1026)", ["--scenario=dano_armor", "--summary-json", "--quit"], "armor",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("armor_result") == "hit"),
    ("Dano sob STUN (D-980)", ["--scenario=dano_stun", "--summary-json", "--quit"], "stun",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("damage_dealt", 0) > 0),
    ("Dano com Guard (D-272)", ["--scenario=dano_guard", "--summary-json", "--quit"], "guard",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("guard_result") == "absorbed"),
    ("Dano Fatal (KO Launch)", ["--scenario=dano_ko", "--summary-json", "--quit"], "k.o.",
     lambda s: s.get("hits_count", 0) >= 1 and s.get("ko_triggered") is True),

    # 2. Fases de Move e Fichas Visuais (D-308 / D-1042 / D-1044)
    ("Fase 1: Wind-up", ["--scenario=fase_windup", "--quit"], "ficha_fase [windup]", None),
    ("Fase 2: Release", ["--scenario=fase_release", "--move=Fire Bullet", "--quit"], "ficha_fase [release]", None),
    ("Fase 3: Trajeto", ["--scenario=fase_trajeto", "--move=Fire Bullet", "--quit"], "ficha_fase [travel]", None),
    ("Fase 3b: Strike (Golpe)", ["--scenario=fase_golpe", "--move=Tackle", "--quit"], "ficha_fase [strike]", None),
    ("Fase 4: Impacto", ["--scenario=fase_impacto", "--move=Tackle", "--quit"], "ficha_fase [impact]", None),
    ("Fase 5: Retorno", ["--scenario=fase_retorno", "--move=Tackle", "--quit"], "ficha_fase [return]", None),
    ("Isolate Phase CLI", ["--move=Drain Spear", "--isolate-phase=windup", "--quit"], "ficha_fase [windup] (drain spear)", None),

    # 3. Ferramentas de Análise VFX (D-1044)
    ("Análise VFX Completa + Leak Audit", [
        "--move=Tackle",
        "--audit-leaks",
        "--scale-overlay",
        "--bone-probe",
        "--overdraw",
        "--envelope-graph",
        "--bg=gray",
        "--cam=macro",
        "--summary-json",
        "--quit"
    ], "[vfx_audit] leaks=0", lambda s: s.get("leaks_detected", -1) == 0),

    # 4. Fila D-161 e pausa de status (D-1150): a vaga sobrevive ou é limpa por interrupção real.
    ("Fila sobrevive à pausa real", ["--scenario=fila_status_pausa", "--summary-json", "--quit"],
     "fila sobrevive", lambda s: s.get("queue_lost", 1) == 0
     and any(e.get("started") for e in s.get("queue_events", []))),
    ("Fila escolhida durante a pausa", ["--scenario=fila_status_click", "--summary-json", "--quit"],
     "fila escolhida", lambda s: s.get("queue_lost", 1) == 0
     and any(e.get("started") for e in s.get("queue_events", []))),
    ("War Cry cancela a fila (esperado)", ["--scenario=fila_war_cry", "--summary-json", "--quit"],
     "war cry", lambda s: s.get("queue_lost", 0) == 1
     and any(e.get("started") is False for e in s.get("queue_events", []))),
    ("Wind-up durante a pausa", ["--scenario=windup_pausa_com_ataque", "--summary-json", "--quit"],
     "wind-up durante a pausa", lambda s: s.get("hits_count", 0) >= 1),
    ("Dodge errado (Pokémon): WHIFF + damage", ["--scenario=dodge_errado_pokemon", "--summary-json", "--quit"],
     "dodge errado", lambda s: s.get("evade_mistimed_count", 0) >= 1
     and s.get("whiff_visual", {}).get("clip") == "damage"
     and s.get("whiff_visual", {}).get("fall_assist") is True
     and s.get("whiff_visual", {}).get("whiff_text") is True
     and s.get("whiff_visual", {}).get("dust_scheduled") is True
     and s.get("damage_dealt", 0) > 0),
    ("Dodge no Dread: Evade válido sem WHIFF", ["--scenario=dodge_dread_valido", "--summary-json", "--quit"],
     "dodge certo no dread", lambda s: s.get("evade_ok_count", 0) >= 1
     and s.get("evade_mistimed_count", 0) == 0
     and not s.get("whiff_visual")),

    # 5. Simetria D-235 Automatizada (Normal + Espelhado)
    ("Runner D-235 Automatizado", ["--move=Tackle", "--test-d235", "--quit"], "d235_result: pass", None),

    # 6. Javelin Throw D-1162: simetria, VFX autoral e zero sobras
    ("Javelin Throw D-235", ["--move=Javelin Throw", "--test-d235", "--quit"], "d235_result: pass", None),
    ("Javelin Throw VFX leaks", ["--move=Javelin Throw", "--force=hit", "--audit-leaks", "--summary-json", "--quit"],
     "[vfx_audit] leaks=0", lambda s: s.get("leaks_detected", -1) == 0),
]

# Testes GDScript isolados (rodam com --script, sem a cena da sala de VFX).
SCRIPT_TESTS = [
    ("D-1160 interrupção visual só real", "res://tests/ui/test_d1160_interruption_feedback.gd",
     "D1160_INTERRUPTION_FEEDBACK_TEST_PASS"),
    ("D-1166 dodge errado: queda + WHIFF + poeira", "res://tests/battle/test_d1166_mistimed_visual.gd",
     "D1166_MISTIMED_VISUAL_TEST_PASS"),
    ("D-1168 Dread escolhe o ataque certo", "res://tests/battle/test_d1168_dread_target.gd",
     "D1168_DREAD_TARGET_TEST_PASS"),
]


def extract_summary_json(out: str) -> dict:
    for line in reversed(out.splitlines()):
        if "SUMMARY_JSON:" in line:
            idx = line.find("SUMMARY_JSON:") + len("SUMMARY_JSON:")
            raw = line[idx:].strip()
            try:
                return json.loads(raw)
            except Exception:
                pass
    return {}


def run_test(args, timeout=60):
    cmd = [GODOT, "--headless", "--path", ROOT, SCENE, "--"] + args
    start = time.time()
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout
        )
        elapsed = time.time() - start
        out = proc.stdout + proc.stderr
        ok = proc.returncode == 0
        # Fail if any GDScript error was emitted
        if "SCRIPT ERROR:" in out or "Parse Error:" in out:
            ok = False
        return ok, elapsed, out
    except subprocess.TimeoutExpired:
        return False, timeout, "TIMEOUT EXPIRED"


def run_script(script_path, timeout=90):
    cmd = [GODOT, "--headless", "--path", ROOT, "--script", script_path]
    start = time.time()
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout
        )
        elapsed = time.time() - start
        out = proc.stdout + proc.stderr
        ok = proc.returncode == 0
        if "SCRIPT ERROR:" in out or "Parse Error:" in out:
            ok = False
        return ok, elapsed, out
    except subprocess.TimeoutExpired:
        return False, timeout, "TIMEOUT EXPIRED"


def main():
    print("=" * 76)
    print("   CRAWLMON — SUÍTE DE COMBATE, CENÁRIOS & ANÁLISE VFX (D-1042, D-1044)")
    print("=" * 76)

    results = []
    all_ok = True

    for name, args, expect_text, summary_check in SCENARIO_TESTS:
        sys.stdout.write(f"[*] {name:<36} ... ")
        sys.stdout.flush()

        ok, elapsed, out = run_test(args)
        reason = ""
        if not ok:
            reason = "non-zero exit or script error"
        if ok and expect_text and expect_text.lower() not in out.lower():
            ok = False
            reason = f"missing expected text '{expect_text}'"
        summary_data = extract_summary_json(out)
        if ok and summary_check is not None:
            if not summary_data or not summary_check(summary_data):
                ok = False
                reason = f"summary telemetry check failed: {summary_data}"

        status = "PASS" if ok else "FAIL"
        if not ok:
            all_ok = False

        print(f"[{status}] ({elapsed:.2f}s)")
        if not ok:
            if reason:
                print(f"    ! Reason: {reason}")
            for line in out.strip().splitlines()[-10:]:
                print(f"    | {line}")

        results.append({
            "name": name,
            "status": status,
            "elapsed_sec": round(elapsed, 2),
            "args": args,
            "summary": summary_data,
        })

    for name, script_path, expect_text in SCRIPT_TESTS:
        sys.stdout.write(f"[*] {name:<36} ... ")
        sys.stdout.flush()

        ok, elapsed, out = run_script(script_path)
        reason = ""
        if not ok:
            reason = "non-zero exit or script error"
        if ok and expect_text and expect_text.lower() not in out.lower():
            ok = False
            reason = f"missing expected text '{expect_text}'"

        status = "PASS" if ok else "FAIL"
        if not ok:
            all_ok = False

        print(f"[{status}] ({elapsed:.2f}s)")
        if not ok:
            if reason:
                print(f"    ! Reason: {reason}")
            for line in out.strip().splitlines()[-10:]:
                print(f"    | {line}")

        results.append({
            "name": name,
            "status": status,
            "elapsed_sec": round(elapsed, 2),
            "args": [script_path],
            "summary": {},
        })

    print("-" * 76)
    summary = {
        "total": len(results),
        "passed": sum(1 for r in results if r["status"] == "PASS"),
        "failed": sum(1 for r in results if r["status"] == "FAIL"),
        "all_passed": all_ok,
    }
    print(f"RESUMO: {summary['passed']}/{summary['total']} testes passaram.")
    print("JSON_SUMMARY: " + json.dumps(summary))

    if all_ok:
        print("[SUCESSO] Suíte de combate e análise VFX validada com 100% de sucesso!")
        sys.exit(0)
    else:
        print("[FALHA] Um ou mais cenários de teste falharam.")
        sys.exit(1)


if __name__ == "__main__":
    main()
