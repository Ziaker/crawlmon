"""Runner do Inspetor Visual de Pipeline do Crawlmon.

Executa o Godot com a suite test_visual_raster_inspector.gd para auditar
geometria, materiais, shaders e renderização de todos os 22 movimentos.

Uso:
    python tests/vfx/run_visual_pipeline_audit.py
"""
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT") or os.path.join(ROOT, "Godot_v4.7.2-stable_win64_console.exe")


def main():
    print("=" * 65)
    print("   CRAWLMON — AUDITORIA DE PIPELINE VISUAL & DETECÇÃO DE BLOCOS")
    print("=" * 65)

    proc = subprocess.run(
        [GODOT, "--path", ROOT, "--script", "res://tests/vfx/test_visual_raster_inspector.gd"],
        capture_output=True, text=True, timeout=120
    )

    output = proc.stdout + proc.stderr
    print(output)

    if "VISUAL_PIPELINE_INSPECTOR_PASS" in output and proc.returncode == 0:
        print("\n[SUCESSO] Auditoria de Pipeline Visual concluída com 100% de integridade!")
        sys.exit(0)
    else:
        print("\n[FALHA] Falhas visuais ou violações de blocos encontradas.")
        sys.exit(1)


if __name__ == "__main__":
    main()
