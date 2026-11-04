# D-197 — Rodada 69 Q2 (2A): mitigação percentual de VIT/SPI com retornos decrescentes

- **Data:** 2026-11-04.
- **Área:** Combate / atributos defensivos / mitigação.
- **Origem:** escolha expressa do criador, aceitando a recomendação na Rodada 69.
- **Estado:** regra de design aprovada e registrada; fórmula ainda não parametrizada nem implementada.

## Declaração literal do criador

> 2A — Mitigação percentual com retornos decrescentes, com a mesma curva estrutural para VIT e SPI.

## Regra aprovada

- A **resistência natural ao dano** conferida por **Vitality (VIT)** ou **Spirit (SPI)** é uma **mitigação percentual**, com **retornos decrescentes** à medida que cresce o atributo defensivo.
- **VIT e SPI usam a mesma estrutura de curva de mitigação**. Preservar D-130 e D-138: VIT mitiga **somente dano físico**; SPI mitiga **somente dano mágico/especial**; os **estágios comuns de DEF** continuam afetando ambos os tipos.
- Preservar D-193: **primeiro a mitigação natural VIT/SPI, depois os estágios de DEF**. Preservar D-139 (atributos permanentes sem teto superior de 100), D-194 (dano mínimo de 1 em acertos válidos, salvo imunidades/bloqueios completos) e D-198 (arredondamento único final).
- Exemplo **conceitual, sem coeficientes aprovados**: o aumento hipotético de SPI de 40 para 50 pode reduzir um percentual do dano mágico; um crescimento de 90 para 100 mantém benefício, mas com aumento percentual de proteção menor. **Nenhuma porcentagem é autorizada pelo exemplo.**

## Limites e pendências

- **Ainda não foi escolhida a equação ou família exata da curva** (por exemplo, racional, exponencial ou por faixas), seus coeficientes, eventual limite de mitigação, referências de balanceamento ou igualdade/diferença de parâmetros de VIT e SPI. **Aprovar a mesma estrutura não permite inventar números.**
- Não alterar por inferência fraqueza elemental, crítico, imunidades, estágio de DEF ou outros fatores; a ordem destes com a mitigação e os parâmetros permanecem pendentes fora do par natural→DEF já definido.
- Apenas documentação; sem código, tests, Move, asset, cena ou VFX alterado.
