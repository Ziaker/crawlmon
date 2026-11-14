"""Runner automatizado de testes de combate, cenários e análise VFX para agentes de IA (D-1042, D-1044).

Valida:
1. Cenários de Dano e Reação (com verificação de telemetria real em SUMMARY_JSON: hits, crítico, fraqueza, ARMOR, STUN, Guard, KO)
2. Fases de Move e Fichas Visuais por Fase (Wind-up, Release, Trajeto, Strike, Impacto, Retorno + --isolate-phase)
3. Ferramentas de Análise VFX (Leak Detector, Scale Overlay, Bone Probe, Overdraw, Envelope Graph, Background Checker, Macro Cam)
4. Simetria D-235 Automatizada (--test-d235)

Uso:
    python tests/battle/run_agent_combat_tests.py
    python tests/battle/run_agent_combat_tests.py --changed [--only=texto]
    python tests/battle/run_agent_combat_tests.py --report=caminho.json
"""
import json
import os
import subprocess
import sys
import time
import hashlib
import threading

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
    ("Dodge errado (Pokémon): WHIFF + damage", ["--scenario=dodge_errado_pokemon_auto", "--summary-json", "--quit"],
     "dodge errado", lambda s: s.get("evade_mistimed_count", 0) >= 1
     and s.get("whiff_visual", {}).get("clip") == "damage"
     and s.get("whiff_visual", {}).get("fall_assist") is True
     and s.get("whiff_visual", {}).get("whiff_text") is True
     and s.get("whiff_visual", {}).get("dust_scheduled") is True
     and s.get("damage_dealt", 0) > 0),
    ("Evade ATB 0 recusado (D-1204)", ["--scenario=evade_atb_0", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) == 0 and s.get("damage_dealt", 0) > 0 and not any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Evade ATB 1,5 (abaixo do custo) recusado (D-1204)", ["--scenario=evade_atb_2", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) == 0 and s.get("damage_dealt", 0) > 0 and not any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Evade ATB 3,0 aceito (D-1204)", ["--scenario=evade_atb_3", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) >= 1 and any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Evade ATB cheio aceito (D-1204)", ["--scenario=evade_atb_5", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) >= 1 and any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Evade ATB 0 espelhado (D-1204)", ["--scenario=evade_atb_0_esp", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) == 0 and s.get("damage_dealt", 0) > 0 and not any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Evade ATB 3,0 espelhado (D-1204)", ["--scenario=evade_atb_3_esp", "--summary-json", "--quit"],
     None, lambda s: s.get("evade_ok_count", 0) >= 1 and not any("EvadeFlash" in str(n) for n in s.get("vfx_spawns", []))),
    ("Status combinados: todos juntos no cartão (D-1204)", ["--scenario=st_combo_todos", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["SHIELD", "STUN", "BURN", "BLIND", "MAG. IMMUNE", "ATK +2", "DEF -2", "SPD +3"])
     and _cards_have(s, "A1", ["SHIELD", "BURN", "BLIND", "MAG. IMMUNE", "ATK -1", "DEF +2", "SPD -3"])),
    ("Status combinados: Knock-up + Burn + Blind + buffs (D-1204)", ["--scenario=st_combo_knockup", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["KNOCK-UP", "BURN", "BLIND", "ATK +1", "DEF -1"])),
    ("Status: aplicar 2x não soma nem duplica (D-1204)", ["--scenario=st_empilha", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["STUN 4.0s", "BURN 4.0s", "BLIND 3.0s", "ATK +2"])
     and _peak(s, "E1").count("BURN") == 1 and _peak(s, "E1").count("STUN") == 1),
    ("Status: Blind e Burn expiram sozinhos (D-1204)", ["--scenario=st_expira", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["BURN", "BLIND"])
     and "BURN" not in s.get("status_cards", {}).get("E1", "") and "BLIND" not in s.get("status_cards", {}).get("E1", "")),
    ("Status longos expiram sozinhos: STUN, Shield, Imun. Mágica (D-1204)", ["--scenario=st_expira_longa", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["STUN", "SHIELD", "MAG. IMMUNE"])
     and s.get("status_cards", {}).get("E1", "") == "No active effects"),
    ("Status: Taunt + Invuln + Burn + buffs no cartão (D-1204)", ["--scenario=st_taunt_invuln", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "A1", ["BURN", "TAUNT", "INVULN", "ATK +1"])),
    ("Inimigos do debug fixos: sem sorteio (D-1204)", ["--scenario=st_burn", "--summary-json", "--quit"],
     None, lambda s: s.get("target") == "Cyclops"),
    ("Inimigos do debug: --enemies escolhe a espécie (D-1204)", ["--scenario=st_burn", "--enemies=pancham", "--summary-json", "--quit"],
     None, lambda s: s.get("target") == "Pancham"),
    ("Status via --status em qualquer cenário (D-1204)", ["--scenario=st_burn", "--status=E1:stun4+blind;A1:b:atk:2", "--summary-json", "--quit"],
     None, lambda s: _cards_have(s, "E1", ["STUN", "BLIND"]) and _cards_have(s, "A1", ["ATK +2"])),
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
    ("D-1180 dodge tardio + WHIFF limpo", "res://tests/battle/test_d1180_evade_feedback.gd",
     "D1180_EVADE_FEEDBACK_TEST_PASS"),
    ("Unit: fórmulas de dano (D-1204)", "res://tests/battle/unit/test_unit_damage_math.gd",
     "DAMAGE_MATH_UNIT_TEST_PASS"),
    ("Unit: ATB do Combatant (D-1204)", "res://tests/battle/unit/test_unit_atb.gd",
     "ATB_UNIT_TEST_PASS"),
    ("Unit: custo do Evade (D-1204)", "res://tests/battle/unit/test_unit_evade_cost.gd",
     "EVADE_COST_UNIT_TEST_PASS"),
    ("Unit: fila de Moves D-161 (D-1204)", "res://tests/battle/unit/test_unit_move_queue_d161.gd",
     "MOVE_QUEUE_D161_UNIT_TEST_PASS"),
    ("D-1200 aliado único, IA de aliado e alvo duplo (estrutura)", "res://tests/battle/test_d1200_ally_and_dual_target.gd",
     "D1200_ALLY_AND_DUAL_TARGET_TEST_PASS"),
    ("D-1200 menus de alvo na cena de batalha real", "res://tests/battle/test_d1200_target_menu.gd",
     "D1200_TARGET_MENU_TEST_PASS"),
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


def _peak(s, who):
    return s.get("status_cards_peak", {}).get(who, "")


def _cards_have(s, who, parts):
    """D-1204: o cartão (pico logo após aplicar) do personagem contém todos os trechos."""
    peak = _peak(s, who)
    return bool(peak) and all(p in peak for p in parts)


def evade_name(name):
    low = name.lower()
    return "evade" in low or "dodge" in low or "dread" in low


def change_scope(path):
    base = os.path.basename(path)
    if path == "tests/battle/run_agent_combat_tests.py":
        return "all"
    if base == "vfx_room_scenarios.gd":
        return "scenarios"
    if path.startswith("scripts/debug/") and base.startswith("vfx_room"):
        return "all"
    if base in ("battle_evade.gd", "battle_fx.gd", "incoming.gd", "fx_evade_flash.gd"):
        return "evade"
    return None


def git_changed_files():
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30
        )
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    files = []
    for line in proc.stdout.splitlines():
        if len(line) < 4:
            continue
        path = line[3:].strip()
        if " -> " in path:
            path = path.split(" -> ", 1)[1].strip()
        if path:
            files.append(path.strip('"').replace("\\", "/"))
    return files


def select_tests(changed, only):
    scenarios = list(SCENARIO_TESTS)
    scripts = list(SCRIPT_TESTS)
    if changed is not None:
        if not changed:
            scenarios, scripts = [], []
        else:
            scopes = [change_scope(p) for p in changed]
            run_all = any(s is None or s == "all" for s in scopes)
            if not run_all:
                if "scenarios" not in scopes:
                    scenarios = [t for t in scenarios if evade_name(t[0])]
                scripts = [t for t in scripts if evade_name(t[0])]
    if only:
        scenarios = [t for t in scenarios if only in t[0].lower()]
        scripts = [t for t in scripts if only in t[0].lower()]
    return scenarios, scripts


def write_report(path, results, summary):
    slow = sorted(results, key=lambda r: r["elapsed_sec"], reverse=True)[:5]
    report = {
        "slowest": [{"name": r["name"], "elapsed_sec": r["elapsed_sec"]} for r in slow],
        "total": summary["total"],
        "passed": summary["passed"],
        "failed": summary["failed"],
        "tests": [
            {"name": r["name"], "status": r["status"], "elapsed_sec": r["elapsed_sec"], "args": r["args"]}
            for r in results
        ],
    }
    parent = os.path.dirname(os.path.abspath(path))
    try:
        os.makedirs(parent, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
    except OSError as exc:
        print(f"[relatorio] falha ao escrever {path}: {exc}")


CACHE_PATH = os.path.join(ROOT, "tests", "battle", ".cache_runner.json")
CACHE_DIRS = ("scripts", "scenes", "content", "shaders", os.path.join("tests", "battle"))


def tree_hash():
    """sha1 do conteúdo de tudo que um teste pode ler (D-1204 --cache)."""
    h = hashlib.sha1()
    for d in CACHE_DIRS:
        for dp, dn, fn in os.walk(os.path.join(ROOT, d)):
            dn[:] = sorted(x for x in dn if not x.startswith("."))
            for f in sorted(fn):
                if f.startswith(".cache_runner"):
                    continue
                fp = os.path.join(dp, f)
                h.update(fp.encode("utf-8", "replace"))
                try:
                    with open(fp, "rb") as fh:
                        h.update(fh.read())
                except OSError:
                    pass
    return h.hexdigest()


def load_cache():
    try:
        with open(CACHE_PATH, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def main():
    print("=" * 76)
    print("   CRAWLMON — SUÍTE DE COMBATE, CENÁRIOS & ANÁLISE VFX (D-1042, D-1044)")
    print("=" * 76)

    results = []
    all_ok = True

    # D-1204: os testes rodam em paralelo (cada um é um processo Godot independente), para a suíte
    # inteira caber em menos de 1 minuto. --jobs=N muda o número de processos; --only=texto filtra.
    jobs = next((int(a.split("=", 1)[1]) for a in sys.argv if a.startswith("--jobs=")), min(8, os.cpu_count() or 4))
    only = next((a.split("=", 1)[1].lower() for a in sys.argv if a.startswith("--only=")), "")
    report_path = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--report=")), "")
    changed_mode = "--changed" in sys.argv
    changed_files = None
    if changed_mode:
        changed_files = git_changed_files()
        if changed_files is None:
            print("[--changed] git status falhou; rodando tudo.")
        elif not changed_files:
            print("[--changed] nenhum arquivo alterado; nada a rodar.")
        else:
            print(f"[--changed] {len(changed_files)} arquivo(s) alterado(s)")
    scenarios, scripts = select_tests(changed_files, only)
    # D-1204: --cache pula o teste que já PASSOU com exatamente os mesmos arquivos; --fail-fast para na
    # primeira falha; --budget=SEG falha (com o texto BUDGET) o teste que passar do limite.
    use_cache = "--cache" in sys.argv
    fail_fast = "--fail-fast" in sys.argv
    budget = next((float(a.split("=", 1)[1]) for a in sys.argv if a.startswith("--budget=")), 0.0)
    new_pass = []
    cache_key = lambda n: ""
    cache = {}
    if use_cache:
        th = tree_hash()
        cache = load_cache()
        cache_key = lambda n: hashlib.sha1((th + "|" + n).encode("utf-8")).hexdigest()
        skipped = [t[0] for t in scenarios + scripts if cache_key(t[0]) in cache]
        scenarios = [t for t in scenarios if cache_key(t[0]) not in cache]
        scripts = [t for t in scripts if cache_key(t[0]) not in cache]
        print(f"[cache] {len(skipped)} teste(s) pulados (já passaram com os mesmos arquivos)")
    abort = threading.Event()
    fail_stop = False

    def guarded(fn, arg):
        if abort.is_set():
            return False, 0.0, "SKIPPED (fail-fast)"
        res = fn(arg)
        if fail_fast and not res[0]:
            abort.set()
        return res
    from concurrent.futures import ThreadPoolExecutor
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        scen_futs = [pool.submit(guarded, run_test, t[1]) for t in scenarios]
        script_futs = [pool.submit(guarded, run_script, t[1]) for t in scripts]
        scen_res = [f.result() for f in scen_futs]
        script_res = [f.result() for f in script_futs]
    print(f"[paralelo] {len(scenarios) + len(scripts)} testes, {jobs} processos, {time.time() - t0:.1f}s no total")

    for (name, args, expect_text, summary_check), (ok, elapsed, out) in zip(scenarios, scen_res):
        if fail_stop:
            break
        sys.stdout.write(f"[*] {name:<36} ... ")
        sys.stdout.flush()

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

        if ok and budget and elapsed > budget:
            ok = False
            reason = f"BUDGET: {elapsed:.1f}s > {budget:.0f}s (o teste passou logicamente)"
        if ok and use_cache:
            new_pass.append(cache_key(name))
        if not ok and fail_fast:
            fail_stop = True
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

    for (name, script_path, expect_text), (ok, elapsed, out) in zip(scripts, script_res):
        if fail_stop:
            break
        sys.stdout.write(f"[*] {name:<36} ... ")
        sys.stdout.flush()

        reason = ""
        if not ok:
            reason = "non-zero exit or script error"
        if ok and expect_text and expect_text.lower() not in out.lower():
            ok = False
            reason = f"missing expected text '{expect_text}'"

        if ok and budget and elapsed > budget:
            ok = False
            reason = f"BUDGET: {elapsed:.1f}s > {budget:.0f}s (o teste passou logicamente)"
        if ok and use_cache:
            new_pass.append(cache_key(name))
        if not ok and fail_fast:
            fail_stop = True
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
    if use_cache and new_pass:
        cache.update({k: True for k in new_pass})
        try:
            with open(CACHE_PATH, "w", encoding="utf-8") as f:
                json.dump(cache, f)
        except OSError:
            pass
    print(f"RESUMO: {summary['passed']}/{summary['total']} testes passaram.")
    print("JSON_SUMMARY: " + json.dumps(summary))

    if report_path:
        write_report(report_path, results, summary)
        print(f"[relatorio] {report_path}")

    if all_ok:
        print("[SUCESSO] Suíte de combate e análise VFX validada com 100% de sucesso!")
        sys.exit(0)
    else:
        print("[FALHA] Um ou mais cenários de teste falharam.")
        sys.exit(1)


if __name__ == "__main__":
    main()
