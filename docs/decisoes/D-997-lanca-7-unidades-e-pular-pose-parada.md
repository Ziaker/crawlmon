<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-997 — Spear Thrust para a 7 unidades; clipes de ataque pulam a pose parada do início

- **Data:** 2026-11-08.

## Frase literal do criador

> spear thrust? é o nome do tackle único dele? gostei mas se for um move novo, está errado. Faça parar em 7 unidades ao invés de 4
> sim,pule e faça a correção que pedi para o vfx do rastro

## Decisão

1. Spear Thrust (move que o Orc já tinha no grupo DQT; não é move novo) para a **7,0** unidades do alvo (2,6 + 4,4). Corrige D-996.
2. Ao tocar o clipe de ataque, o jogo **pula o trecho parado do início** do clipe: o primeiro instante em que os ossos começam a mexer de verdade, medido no próprio clipe (nunca por espécie), limitado à metade do tempo até o contato. O momento do contato no combate não muda.

## Estado

Implementado para revisão.
