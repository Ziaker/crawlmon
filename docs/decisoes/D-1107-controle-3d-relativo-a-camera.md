<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1107 — Controle 3D relativo à câmera

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / laboratório da Murky Forest / controle do jogador.
- **Relacionadas:** D-1022 (overworld 3D/terceira pessoa), D-1027 (câmera), D-1088 (câmera de diálogo), D-1105 (lab jogável/vídeo).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> pq ele tem controle de tank pq o controle movimentacao em 3D ta assim

Escolha de esclarecimento: **“Câmera relativa (moderno)”** — WASD relativo à câmera, personagem vira para a direção do movimento, Q/E e botão direito orbitam, a câmera segue a posição.

## Regra

1. **WASD/setas relativos à câmera:** W/S andam na direção em que a câmera olha; A/D andam para a esquerda/direita da câmera; diagonais normalizadas.
2. **O personagem vira para a direção do movimento**, com giro suave (`TURN_RATE`). A/D **não** giram mais o personagem no próprio eixo.
3. **Câmera livre:** Q/E e o botão direito orbitam; a câmera segue a **posição** do jogador, não o yaw dele. O auto-alinhamento de 1,2 s (`_cam_yaw` atrás do `player_yaw`) **sai**.
4. **Conversa (D-1088) e ataque (D-1100, outra sessão):** continuam travando o jogador como antes; a conversa vira o jogador para o NPC; o ataque segue dono do movimento.
5. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmeras de diálogo/tres-quartos, placas e ícones (D-1097–D-1105). O jogo 2D principal não usa este controle; é o lab 3D.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: `_physics_process` passa a usar o vetor de input relativo ao `_cam_yaw`; o `player_yaw` segue a direção com `lerp_angle`; o bloco de auto-alinhamento da câmera é removido; `TURN_RATE` novo.
- A câmera continua com colisão/zoom (D-1027) e o diálogo (D-1088).

## Provas

- `JOGAR_LAB_3D.bat` — o lab para testar.
- `docs/referencias/exploracao/3d/murky_forest_lab_gameplay_camera_relative.mp4` — 10,7 s com o controle relativo à câmera.
- `docs/referencias/exploracao/3d/murky_forest_lab_gameplay_camera_relative.gif` — o mesmo em GIF.
- O vídeo antigo `murky_forest_lab_gameplay_cards_40.mp4` mostra o controle de tanque (histórico).

## O que foi verificado

- A cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`.
- W/S andam na direção da câmera; A/D andam para os lados; o personagem vira para a direção do movimento.
- Q/E e o botão direito orbitam a câmera; o auto-alinhamento de 1,2 s foi removido.
- O vídeo mostra o personagem mudando de direção com a câmera parada.

## O que não foi verificado

- O ataque da D-1100 durante o novo controle (a outra sessão está mexendo; os hooks ficaram fora do commit).
- Gamepad/analógico, sensibilidade, câmera baixa e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
