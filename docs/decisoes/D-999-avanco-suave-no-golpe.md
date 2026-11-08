# D-999 — O corpo avança suave durante o golpe corpo a corpo

- **Data:** 2026-11-08.

## Frase literal do criador

> Sim, avança suave

(em resposta a: "Faço o corpo avançar aos poucos durante o golpe, sem o salto final?")

## Causa medida

No golpe, a regra deixa o corpo recuado (coil) e só faz o avanço nos últimos 0,18 s, com curva exponencial: no Pancham o corpo ficou parado de 0,11 a 0,71 s e saltou ~0,6 u no contato.

## Decisão

Só no desenho (D-019): da saída do coil até o contato, o corpo avança suave (smoothstep) até o mesmo ponto de contato da regra. Vale para todos os golpes corpo a corpo, exceto choques (clash). O momento e o ponto do contato não mudam.

## Estado

Implementado para revisão.
