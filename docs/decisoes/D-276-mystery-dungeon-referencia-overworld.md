<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-276 — Pokémon Mystery Dungeon como referência do overworld

- **Área** — Exploração / visual
- **Estado** — Direção visual definida pelo criador.

## O que o criador disse

> sim mas não é pra usar pokemon firered como referência, use mystery dungeon, além dos tiles serem estranhos, tem esses icones de + no chão sem lógica, refaz tudo

## Decisão

Refazer os tiles 2D com Pokémon Mystery Dungeon como referência para o visual da exploração. Retirar os sinais decorativos de “+” do chão. A D-275 continua valendo quanto ao formato 2D e à referência visual da arena de combate.
