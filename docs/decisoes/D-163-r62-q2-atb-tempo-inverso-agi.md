# D-163 — Rodada 62 Q2 (2A, versão prevalente): tempo de ATB inversamente proporcional à AGI efetiva

- Data: 2026-11-03.
- Origem: resposta expressa do criador e confirmação de prevalência desta versão da Rodada 62.
- Estado: regra de design aprovada; não implementada.

## Declaração literal

> 2A — Tempo de preenchimento do ATB inversamente proporcional à AGI efetiva.

## Regra vigente

- O **tempo para regenerar naturalmente a mesma quantidade de ATB** é **inversamente proporcional à AGI efetiva**, nas mesmas condições. Equivalentemente, a **taxa de regeneração** é diretamente proporcional à AGI efetiva.
- Dobrar AGI efetiva positiva reduz à metade o tempo natural necessário para preencher a mesma quantidade de ATB. A decisão não altera pausas, travas, custos, Burst, ATB extra, recompensas instantâneas ou a quantidade de cinco blocos normais.
- D-164 aprova AGI mínima 1 **somente como entrada da fórmula de ATB** quando AGI efetiva não for positiva, sem modificar o atributo.
- Expressão proporcional simbólica, sem fixação de números: `T_ATB = T_ref_ATB × AGI_ref_ATB / max(1, AGI_efetiva)`, para preenchimento natural equivalente e enquanto não houver pausa/bloqueio.
- Exemplo ilustrativo **não normativo**: se uma referência hipotética preenchesse cinco blocos em 5 s, AGI duas vezes maior resultaria em 2,5 s; isso não escolhe novos parâmetros do combate.
- Preservar D-117, D-126 e D-145. A referência numérica para ATB **continua pendente**; isso não significa que a relação matemática permaneça indefinida.

## Limites e escopo

- Ainda não foi escolhido valor de AGI de referência ATB, política exata de leitura/atualização da AGI durante preenchimento, precisão ou arredondamento.
- A D-161 da versão divergente permanece histórica; nenhum código, teste ou recurso foi alterado.

## Complemento posterior — Rodada 63 / D-169 e D-170 (2026-11-03)

**D-169 (R63-Q3A):** obter a **referência numérica de AGI para ATB** pela **calibração do ritmo existente** do jogo e **apresentar o valor ao criador antes de implementar**; ainda não houve medição ou validação. **D-170 (R63-Q4A):** **reavaliar a AGI efetiva a cada atualização da regeneração natural ATB**, sem recálculo retroativo do progresso já acumulado, mantendo a proporcionalidade inversa de tempo desta D-163 e o piso numérico da D-164. Nenhum código ou teste alterado.
