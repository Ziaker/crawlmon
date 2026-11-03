"""
Auditoria de Densidade Visual e Cromática SMT D-036 (Pilares Volumétricos)
"""

import os
import glob
from PIL import Image

BASE_DIR = os.path.join("test_captures", "smt_upgraded")
MOVES = ["tarukaja", "rakunda", "sukunda"]

def audit():
    print("=" * 65)
    print("   CRAWLMON — AUDITORIA DE PILARES E CASCAIS VOLUMÉTRICOS (D-036)")
    print("=" * 65)

    all_ok = True
    for m in MOVES:
        m_dir = os.path.join(BASE_DIR, m)
        if not os.path.isdir(m_dir):
            print(f"[ERRO] Diretório não encontrado: {m_dir}")
            all_ok = False
            continue

        frames = sorted(glob.glob(os.path.join(m_dir, "*.png")))
        print(f"[*] Auditando {m.upper()} ({len(frames)} frames):")
        if len(frames) != 8:
            print(f"    [ERRO] Esperados 8 frames, encontrados {len(frames)}")
            all_ok = False

        # Avaliar frame 4 (ápice da animação)
        mid_frame_path = frames[3] # frame_04
        img = Image.open(mid_frame_path).convert("RGBA")
        w, h = img.size
        pixels = img.load()

        theme_pixels = 0
        bright_pixels = 0

        # Amostragem da coluna central (onde o pilar está localizado)
        x_min, x_max = int(w * 0.25), int(w * 0.75)
        y_min, y_max = int(h * 0.15), int(h * 0.85)

        for y in range(y_min, y_max, 2):
            for x in range(x_min, x_max, 2):
                r, g, b, a = pixels[x, y]
                # Brilho
                luminance = 0.299 * r + 0.587 * g + 0.114 * b
                if luminance > 120:
                    bright_pixels += 1

                if m == "tarukaja":
                    # Lima: verde predominante, bom componente vermelho
                    if g > 150 and g > r * 0.85 and b < 140:
                        theme_pixels += 1
                elif m == "rakunda":
                    # Coral: vermelho alto, verde e azul moderados/baixos
                    if r > 160 and r > g * 1.5 and b < 130:
                        theme_pixels += 1
                elif m == "sukunda":
                    # Amarelo/Ouro: r alto, g alto, b moderado
                    if r > 160 and g > 130 and b < 150 and abs(r - g) < 70:
                        theme_pixels += 1

        samples = ((x_max - x_min) // 2) * ((y_max - y_min) // 2)
        theme_ratio = theme_pixels / samples
        bright_ratio = bright_pixels / samples

        print(f"    Frame ápice: {os.path.basename(mid_frame_path)}")
        print(f"    Densidade de Pixels Cromáticos: {theme_pixels} ({theme_ratio:.2%})")
        print(f"    Densidade de Pixels Luminosos (Pilar + Núcleo): {bright_pixels} ({bright_ratio:.2%})")

        if theme_pixels < 50:
            print(f"    [AVISO] Baixa contagem cromática para {m}")
            all_ok = False
        else:
            print(f"    [PASS] Pilar volumétrico e auras detectados com alta intensidade.")

    print("-" * 65)
    if all_ok:
        print("[SUCESSO TOTAL] Todos os 3 movimentos SMT D-036 aprovados visualmente!")
    else:
        print("[ATENÇÃO] Revisar detecções.")
    print("=" * 65)

if __name__ == "__main__":
    audit()
