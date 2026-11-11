# D-1048 — FOV da câmera de combate em 72°

- **Data:** 2026-11-09
- **Área:** Câmera / Combate / Visual
- **Origem:** resposta do criador ao teste FOV 80 × 60.

## Frase literal do criador

> "deixe 72"

## Decisão

1. O FOV base da câmera de combate passa de **80° para 72°** (`BattleCamera.FOV`).
2. O valor vale para o enquadramento normal (CINEMA) e para os modos que usam o FOV base; a tela de Status mantém o FOV próprio.
3. A área segura (D-1010/D-1060) continua podendo **abrir** o FOV quando for necessário enquadrar todos; o novo base é 72°.
4. Não alterar escala de personagem nesta decisão. As exceções Cyclops/Slime de D-1047 continuam como estão.

## Ambiguidades em aberto

Nenhuma.

## Estado

Implementado em `scripts/combat/battle_camera.gd`; testar no jogo normal, normal e espelhado, com a câmera de combate e HUD. Sem commit/push.
