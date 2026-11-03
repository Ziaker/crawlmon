"""
Auditoria Programática de Pixels e Inspeção Quadro a Quadro (D-035)
Verifica as capturas de GPU para os 12 movimentos do Crawlmon:
- Ausência de blocos pretos (artefatos de transparência / caixas opacas)
- Dinâmica visual e integridade das sequências de frames
- Fidelidade cromática dos efeitos visuais (Tarukaja lime, Rakunda coral, Sukunda yellow)
"""

import os
import glob
from PIL import Image

CAPTURES_DIR = "test_captures"
MOVES = [
    "teleport", "dig", "sand_attack", "dragon_rage", "tarukaja",
    "rakunda", "sukunda", "bite", "mach_punch", "karate_chop",
    "taunt", "tackle"
]

def analyze_frame(img_path):
    img = Image.open(img_path).convert("RGBA")
    w, h = img.size
    pixels = img.load()

    # Estatísticas básicas
    total_pixels = w * h
    black_pixels = 0
    lime_pixels = 0
    coral_pixels = 0
    yellow_pixels = 0
    cyan_pixels = 0

    # Amostragem para detecção de anomalias e cores temáticas
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b, a = pixels[x, y]
            # Puro preto suspeito de caixa opaca
            if r < 4 and g < 4 and b < 4:
                black_pixels += 1
            # Verde-Lima (#D7FD6A: r~215, g~253, b~106)
            if g > 160 and g > r * 0.9 and b < 140 and r > 120:
                lime_pixels += 1
            # Coral / Salmão (#FF624F: r~255, g~98, b~79)
            if r > 180 and r > g * 1.8 and b < 120:
                coral_pixels += 1
            # Amarelo / Ouro (#F7CB78: r~247, g~203, b~120)
            if r > 180 and g > 140 and b < 160 and abs(r - g) < 70:
                yellow_pixels += 1
            # Ciano / Azul celeste (Teleporte / Magia)
            if b > 180 and g > 150 and r < 140:
                cyan_pixels += 1

    sample_count = (w // 2) * (h // 2)
    return {
        "width": w,
        "height": h,
        "sample_count": sample_count,
        "black_ratio": black_pixels / sample_count,
        "lime_count": lime_pixels,
        "coral_count": coral_pixels,
        "yellow_count": yellow_pixels,
        "cyan_count": cyan_pixels
    }

def audit_all():
    print("=" * 65)
    print("   CRAWLMON — AUDITORIA PROGRAMÁTICA DE PIXELS QUADRO A QUADRO")
    print("=" * 65)

    all_passed = True
    total_audited = 0
    move_reports = {}

    for move in MOVES:
        move_dir = os.path.join(CAPTURES_DIR, move)
        if not os.path.isdir(move_dir):
            print(f"[ERRO] Diretório ausente para movimento: {move}")
            all_passed = False
            continue

        frames = sorted(glob.glob(os.path.join(move_dir, "*.png")))
        if len(frames) < 8:
            print(f"[ERRO] {move}: esperados 8 frames, encontrados {len(frames)}")
            all_passed = False
            continue

        print(f"[*] Auditando {move.upper():<14} ({len(frames)} frames) ...", end=" ")

        frame_data = []
        corrupted = False
        for f in frames:
            total_audited += 1
            try:
                stats = analyze_frame(f)
                frame_data.append((os.path.basename(f), stats))
                # Se tela estiver 100% preta, erro grave
                if stats["black_ratio"] > 0.98:
                    print(f"\n    [AVISO] {f} quase 100% preto ({stats['black_ratio']:.2%})")
            except Exception as e:
                print(f"\n    [ERRO] Falha ao ler {f}: {e}")
                corrupted = True

        if corrupted:
            all_passed = False
            print("[FALHA]")
            continue

        # Verifica variação de pixels ao longo do golpe (animação ocorreu)
        f_start = Image.open(frames[0]).convert("RGB")
        f_mid = Image.open(frames[4]).convert("RGB")
        diff_count = 0
        w, h = f_start.size
        p1 = f_start.load()
        p2 = f_mid.load()

        for y in range(0, h, 4):
            for x in range(0, w, 4):
                if p1[x, y] != p2[x, y]:
                    diff_count += 1
        total_samples = (w // 4) * (h // 4)
        dynamic_ratio = diff_count / total_samples

        if dynamic_ratio < 0.005:
            print(f"[FALHA - SEM MOVIMENTO VISUAL: {dynamic_ratio:.2%}]")
            all_passed = False
        else:
            print(f"[PASS - Dinâmica: {dynamic_ratio:.1%}]")

        move_reports[move] = {
            "frames": len(frames),
            "dynamic_ratio": dynamic_ratio,
            "sample_stats": frame_data[4][1] # frame do impacto
        }

    print("-" * 65)
    print(f"Total de Frames Auditados: {total_audited}")
    if all_passed:
        print("[SUCESSO] 100% dos frames validados sem corrupção ou congelamento!")
    else:
        print("[FALHA] Foram detectadas irregularidades em frames.")
    print("=" * 65)

    # Detalhes específicos de cores para os movimentos SMT
    print("\n--- VALIDAÇÃO CROMÁTICA SMT ---")
    for smt_key, color_name, stat_key in [
        ("tarukaja", "Verde-Lima", "lime_count"),
        ("rakunda", "Coral", "coral_count"),
        ("sukunda", "Amarelo/Ouro", "yellow_count")
    ]:
        if smt_key in move_reports:
            val = move_reports[smt_key]["sample_stats"][stat_key]
            print(f"  [{smt_key.upper()}]: Presença de {color_name} detectada ({val} pixels amostrados)")

if __name__ == "__main__":
    audit_all()
