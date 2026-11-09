# D-1004 — Clipes DQT para wind-up, Guard e moves à distância

- **Data:** 2026-11-08.

## Frase literal do criador

> Orc, clipe 32 para wind-up
> alias, use o clipe 12 pra Guard e pra moves de projetil, status e longo alcance
> use clipe 12 para o cyclops para moves de projetil, status e longo alcance. Use o clipe 32 para wind-ups e para guard

## Decisão

| | Wind-up | Guard | Projétil / status / longo alcance |
|---|---|---|---|
| Orc | clipe 32 (inteiro, em loop) | clipe 12 | clipe 12 (já era) |
| Cyclops | clipe 32 (inteiro, em loop) | clipe 32 | clipe 12 (já era) |

Antes o wind-up usava uma pose congelada do clipe 32; agora toca o clipe inteiro. O Guard ganha clipe próprio (antes usava o do wind-up).

## Ambiguidade

- "clipe 32 para wind-up": interpretado como o clipe inteiro em loop, não a pose parada de antes.

## Estado

Implementado.
