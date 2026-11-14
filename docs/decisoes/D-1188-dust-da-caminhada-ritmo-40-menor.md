# D-1188 — Dust da caminhada no overworld: ritmo de geração 40% menor

- **Data:** 2026-11-12.
- **Área:** Overworld 3D / VFX / dust de caminhada.
- **Status:** implementado e testado headless; aguardando aprovação visual.

## O que o criador disse

> "no overworld, reduza o ritmo de geração de dust ao caminhar em 40%"

## Decisão

1. A **taxa** de geração do dust da caminhada cai 40% (passa a 60% da atual): a cadência vai de **0,130952 s** para **0,218253 s** (0,130952 / 0,6).
2. Só a caminhada. O dust do dash (cadência 0,055 s e continuação de caminhada de 0,0917 s dentro do dash) **não muda**. Tamanho, alpha, pés alternados e espalhamento não mudam.
3. Só visual (D-019/D-235).

## Ambiguidade resolvida pela leitura literal

"Ritmo de geração" foi lido como **taxa** (puffs por segundo) reduzida em 40%, e não como intervalo 40% maior (que daria 0,183 s).
