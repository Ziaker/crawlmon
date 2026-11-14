<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1123 — Câmera segue o jogador durante o movimento, com direção travada

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / câmera e controle.
- **Relacionadas:** D-1107 (WASD relativo à câmera; auto-alinhamento removido), D-1027 (câmera), D-1088 (diálogo), D-1100 (ataque).
- **Status:** **revertida pela D-1124**; commit local; **sem push**.
- **Nota D-1124 (2026-11-10):** a trava e o auto-follow de yaw foram removidos; o lab voltou ao WASD relativo à câmera com A/D andando de lado e a câmera seguindo só a posição (D-1107). O teste mostrou que o auto-follow de yaw fazia o personagem girar em círculo.

## O que o criador disse (literal)

> inclusive faça com que a camera vire quando o jogador virar, só de que forma suave pq no teste humano o personagem nunca vira a câmera

Escolha da rodada:

> Segue durante, direção travada

## Regra

1. **A câmera segue o yaw do jogador durante o movimento**, de forma suave, com `CAM_FOLLOW_RATE = 3.0` (não é snap).
2. **Direção travada:** o WASD continua relativo à câmera no instante em que o vetor de input muda; enquanto a mesma combinação de teclas estiver pressionada, a direção no mundo fica **presa**. Assim segurar A/D/S não faz o personagem girar em círculo quando a câmera vem atrás.
3. **Manual manda:** Q/E e o botão direito continuam orbitando. A câmera só retoma o auto-follow depois de **1,2 s** sem input manual (`_last_look`), como no auto-alinhamento antigo.
4. **Parado:** a câmera não gira sozinha; o jogador pode orbitar para olhar em volta. O auto-follow volta no próximo movimento.
5. **Diálogo e ataque:** continuam travando o jogador/câmera como antes (D-1088/D-1100); a direção travada é limpa nesses estados.
6. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera de diálogo, placas, ícones e as paredes (D-1122).

## Relação com a D-1107

- A D-1107 dizia "a câmera segue a posição, não o yaw" e "o auto-alinhamento sai". Esta decisão **substitui só essa parte**: a câmera volta a seguir o yaw, agora durante o movimento e com a direção travada. O WASD relativo à câmera e o personagem virando para a direção do movimento continuam.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: `_move_input`/`_move_dir` travam a direção; `_cam_yaw` faz `lerp_angle` para `player_yaw` enquanto anda e depois da janela de 1,2 s do olhar manual.

## Provas

- `docs/referencias/exploracao/3d/d1123_camera_start.png` — início.
- `docs/referencias/exploracao/3d/d1123_camera_w.png` — depois de W.
- `docs/referencias/exploracao/3d/d1123_camera_a.png` — depois de A.
- `docs/referencias/exploracao/3d/d1123_camera_s.png` — depois de S.
- `docs/referencias/exploracao/3d/d1123_camera_d.png` — depois de D.
- `docs/referencias/exploracao/3d/d1123_camera_contact.png` — início/A/S/D em 2×2.
- `docs/referencias/exploracao/3d/d1123_camera_follow.mp4` / `.gif` — 12,7 s com W, A, S e D.

## O que foi verificado

- Com W, A, S e D a câmera converge para trás do yaw do jogador e **não** faz o personagem girar em círculo.
- Diferença final `player_yaw - _cam_yaw` no teste: **0,000** (W), **0,001** (A), **0,002** (S) e **0,001** (D).
- A direção fica travada por combinação de input; ao soltar/repressar, a nova direção usa o yaw atual da câmera.
- O giro manual por Q/E continua e seta `_last_look`; o auto-follow só volta depois de 1,2 s.
- A câmera não gira sozinha quando o jogador está parado.
- Diálogo/ataque continuam fora do auto-follow; a direção travada é limpa nesses estados.
- A cena roda headless com `exit=0`.

## O que não foi verificado

- Q/E e botão direito em movimento no vídeo (a lógica foi revisada, mas não gravada).
- Gamepad/analógico, sensibilidade, outros labs e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
