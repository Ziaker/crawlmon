# D-152 — Rodada 61 Q1 (1B): ganho de esquiva automática por LUK tem retorno decrescente

- **Data:** 2026-11-03.
- **Área:** Combate / esquiva automática / LUK.
- **Origem:** escolha literal do criador na Rodada 61.
- **Estado:** decisão aprovada e registrada documentalmente; não implementada.

## Declaração literal do criador

> 1B — retorno decrescente: contribuição por ponto cai pela metade a cada 10 pontos adicionais de diferença.

## Regra aprovada

- A chance-base de esquiva automática continua em **10% por golpe** (D-005), modificada pela **diferença de LUK do defensor menos a LUK do atacante** (D-127).
- Para uma diferença de LUK positiva, o **ganho marginal em pontos percentuais por ponto de LUK** é **1 pp/ponto nos primeiros 10 pontos**, **0,5 pp/ponto nos próximos 10**, **0,25 pp/ponto nos próximos 10**, e assim sucessivamente, sempre reduzindo à metade a taxa a cada faixa adicional de 10 pontos.
- Dentro de cada faixa, aplicar o coeficiente da faixa aos pontos de diferença nela contidos, inclusive em faixas incompletas.
- Exemplo escolhido na questão: LUK defensor **70**, atacante **40**, diferença **+30**: ganho **10 + 5 + 2,5 = 17,5 pontos percentuais**, chance **27,5%**.
- **D-151 permanece:** limitar a chance final ao intervalo **0–100%**. A diferença negativa fica expressamente definida em D-153, aprovada na mesma rodada.

## Relações e limites

- D-150 mantém sua **fórmula própria para crítico** (10% + 1 pp/ponto de diferença de LUK), sem retorno decrescente.
- D-146 mantém sua **fórmula própria para aplicação de status probabilístico**, sem retorno decrescente.
- D-021 (reação ativa da IA no trajeto), Evade manual/perfeito e os debuffs de alvo único não esquiváveis da D-012 permanecem separados da esquiva automática. A regra vale tanto para aliados como inimigos.
- Não definir curva nova para AGI ou alterar taxas de ATB.

## Escopo

Registro documental apenas. Sem alterações em código, dados, Move, cena, assets, testes ou VFX.
