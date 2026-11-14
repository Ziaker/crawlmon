<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-278 — Restaurar o overworld e ajustar somente a paleta

- **Área** — Exploração / visual
- **Estado** — Direção definida pelo criador.

## O que o criador disse

> só volta tudo como era antes e mude as cores das coisas pra serem mais relacionadas ao visual 3D, já que fazer algo decente vc não consegue

## Decisão

Restaurar o overworld anterior à reforma, inclusive o comportamento de colisão, e alterar somente as cores do cenário existente usando a arena 3D como referência. Esta decisão substitui as mudanças de arte e colisão das D-275, D-276 e D-277. A D-033 continua em vigor.
