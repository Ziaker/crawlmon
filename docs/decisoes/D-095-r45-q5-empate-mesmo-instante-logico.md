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
