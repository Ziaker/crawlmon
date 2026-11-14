<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-095 — R45-Q5 (5A): Empate por eliminação simultânea mesmo com ataques diferentes

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 45
- **Origem:** decisão expressa do criador, R45-Q5.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 5A — Se as duas equipes forem eliminadas por ataques diferentes no mesmo instante lógico, qual o resultado? Declarar empate sempre que a eliminação das duas equipes ocorrer no mesmo instante lógico.

## Regra aprovada

Se **as duas equipes forem totalmente eliminadas no mesmo instante lógico**, o resultado é **empate sem vencedor**, inclusive quando os golpes que provocaram a eliminação forem diferentes. A regra de empate por um único AoE (D-091) permanece.

## Referências e limites

- **Decisões relacionadas:** D-019; D-081; D-090; D-091.
- **Limite / pendência:** A granularidade técnica exata de mesmo instante lógico não foi especificada; não transformar uma eliminação simultânea em vitória por ordem arbitrária dos callbacks.
- **Escopo:** registro documental somente; nenhum código, VFX, teste ou dado de jogo modificado.

## Complemento posterior — Rodada 49

D-107: o empate quando ambas as equipes são eliminadas no mesmo instante lógico permanece válido. Projétil que atinge apenas DEPOIS de vitória ou derrota já definitiva não altera o resultado (D-105/D-107).
