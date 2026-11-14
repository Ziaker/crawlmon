<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1020 — Badge Steal: faixas minúsculas que se dispersam e voltam ao atacante

- **Data:** 2026-11-09.

## Frase literal do criador

> ao inves de ser 1 circulo grande poderia ser minusculas faixas que se dispersam em várias direções e vão em direção ao jogador

## Decisão

Substitui o círculo/esfera da D-1019: ~42 faixas minúsculas saem do ponto de contato em direções diferentes (cada uma no seu instante, até 0,18 s), abrem até ~2,4 m e fazem a curva de volta até o atacante, sumindo ao entrar nele (0,55–0,95 s cada). Medidas pelo contato e pelo centro real do atacante (D-235).

## Estado

Implementado para revisão.
