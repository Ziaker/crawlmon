# D-1126 — Câmera volta a virar, bem devagar, sem trava

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / câmera e controle.
- **Relacionadas:** D-1124 (A/D reto, câmera sem auto-follow), D-1107 (WASD relativo à câmera), D-1123 (trava + auto-follow, revertida).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> agora a camera simplesmente não vira

## Regra

1. **A câmera volta a virar durante o movimento**, mas **bem devagar**: `CAM_FOLLOW_RATE = 0.45`, com zona morta de **0,12 rad** (~7°) e **1,2 s** de graça depois do olhar manual.
2. **Sem trava:** o WASD continua relativo à câmera a cada quadro; não existe direção presa.
3. **Curva assumida:** segurar A/D faz o personagem descrever uma **curva ampla** (a câmera vai junto), não um giro de 450°. É o compromisso para a câmera não ficar fixa.
4. **Manual manda:** Q/E e botão direito orbitam; a câmera só retoma o auto-follow depois de 1,2 s.
5. **Parado:** a câmera não gira sozinha.
6. **Diálogo e ataque:** continuam fora (D-1088/D-1100).
7. **O que não muda:** paredes a 40% (D-1122), HUD, cards, regras, batalha, 2D e o resto.

## Relação com decisões anteriores

- **D-1124** dizia "A/D reto, câmera sem auto-follow"; esta decisão **acrescenta o auto-follow lento** para a câmera não ficar parada. A parte de A/D de lado e personagem virando para o movimento continua.
- **D-1123** (trava de direção + auto-follow rápido) continua **revertida**.
- **D-1107** continua valendo no movimento (WASD relativo à câmera).

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: `_cam_yaw` faz `lerp_angle` para `player_yaw` enquanto anda, com `CAM_FOLLOW_RATE = 0.45`, `CAM_FOLLOW_DEADZONE = 0.12` e `CAM_FOLLOW_GRACE = 1.2`. Sem `_move_input`/`_move_dir`.

## Provas

- `docs/referencias/exploracao/3d/d1126_camera_start.png` — início.
- `docs/referencias/exploracao/3d/d1126_camera_w.png` — depois de W.
- `docs/referencias/exploracao/3d/d1126_camera_a.png` — depois de A (curva ampla).
- `docs/referencias/exploracao/3d/d1126_camera_s.png` — depois de S.
- `docs/referencias/exploracao/3d/d1126_camera_d.png` — depois de D.
- `docs/referencias/exploracao/3d/d1126_camera_contact.png` — início/A/S/D em 2×2.
- `docs/referencias/exploracao/3d/d1126_camera_follow.mp4` / `.gif` — 9,3 s com W, A, S e D.

## O que foi verificado

- A câmera volta a girar durante o movimento: em A, o yaw da câmera foi de **3,142** para **3,712** (~33°) no teste a 60 fps e para **4,223** (~62°) no vídeo a 30 fps — nunca os ~450° da D-1123.
- A/D move o personagem em curva ampla, não em círculo apertado; não há trava.
- Q/E continuam girando e setam a janela de 1,2 s.
- A cena roda com `exit=0`.

## O que não foi verificado

- Todas as combinações de A/D/S e a sensação final; o rate 0,45 pode ser ajustado (mais alto = câmera mais perto, curva mais fechada; mais baixo = câmera mais solta, curva mais ampla).
- Q/E/mouse no vídeo, gamepad/analógico, outros labs e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
