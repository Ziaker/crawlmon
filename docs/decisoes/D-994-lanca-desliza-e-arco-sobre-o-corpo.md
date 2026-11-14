<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-994 — Lança: deslizar para trás no prelúdio; arco do Swing desenhado por cima do corpo

- **Data:** 2026-11-08.

## Frase literal do criador

> não aprovo essa direção no orc, imagino que uma deslizada pra trás durante o prelude é melhor do que snaps de posição quebrados
> pancham ainda não realiza o rastro (imagem 1) como eu te orientei na mensagem anterior (imagem 2)

## Decisão

1. Corrige D-993 item 1: o recuo visual da arma longa vira um **deslize suave para trás durante o prelúdio** (do início do golpe até 0,25 s antes do contato), sem saltos.
2. O rastro do Swing é desenhado **por cima do corpo** (sem teste de profundidade): no Pancham a mão direita percorre 5,6 m por trás das costas e o corpo escondia o arco.

## Estado

Implementado para revisão.
