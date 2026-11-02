"""Runner para todos os testes automatizados de efeitos visuais (VFX) do Crawlmon.

Executa de forma headless pelo console do Godot e relata o status de cada suite visual:
- Tackle VFX (Investida A2/B1)
- Roteamento e despacho de VFX
- Gible VFX
- Teste mestre de todos os 22 movimentos (incluindo SMT)

Uso:
    python tests/vfx/run_vfx_tests.py
"""
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")

TESTS = [
    ("Tackle (A2 Golpe + B1 Impacto)", "res://tests/vfx/test_tackle_vfx.gd", "TACKLE_VFX_TEST_PASS"),
    ("Roteamento e Despacho de VFX", "res://tests/vfx/test_move_vfx_routing.gd", "MOVE_VFX_ROUTING_TEST_PASS"),
    ("Gible VFX (Mordida, Tiro de Areia, etc.)", "res://tests/vfx/test_gible_vfx.gd", "GIBLE_VFX_TEST_PASS"),
    ("Suite Mestre (Todos os 22 Golpes + SMT + Leaks)", "res://tests/vfx/test_all_moves_vfx.gd", "ALL_MOVES_VFX_TEST_PASS"),
]


def run_test(name, script_path, pass_token):
    proc = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", script_path],
        capture_output=True, text=True, timeout=120
    )
    output = proc.stdout + proc.stderr
    ok = pass_token in output and proc.returncode == 0
    return ok, output


def main():
    print("=" * 65)
    print("   CRAWLMON — EXECUÇÃO DE TESTES VISUAIS (VFX HEADLESS)")
    print("=" * 65)

    all_passed = True
    for name, script_path, pass_token in TESTS:
        sys.stdout.write(f"[*] {name} ... ")
        sys.stdout.flush()
        ok, out = run_test(name, script_path, pass_token)
        if ok:
            print("[PASS]")
        else:
            print("[FAIL]")
            all_passed = False
            for line in out.splitlines()[-15:]:
                print("   | " + line)

    print("-" * 65)
    if all_passed:
        print("[SUCESSO] Todos os testes visuais passaram com 100% de integridade!")
        sys.exit(0)
    else:
        print("[ERRO] Uma ou mais suites visuais falharam.")
        sys.exit(1)


if __name__ == "__main__":
    main()
