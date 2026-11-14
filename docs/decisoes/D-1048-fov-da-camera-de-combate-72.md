<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
