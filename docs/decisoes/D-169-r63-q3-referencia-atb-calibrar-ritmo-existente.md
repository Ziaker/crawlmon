# D-169 — Rodada 63 Q3 (3A): calibrar referência numérica do ATB a partir do ritmo existente

- **Data:** 2026-11-03.
- **Área:** AGI / ATB / calibração de ritmo.
- **Origem:** resposta expressa do criador na Rodada 63.
- **Estado:** política de calibração aprovada; **valor numérico ainda não medido nem validado**; sem implementação.

## Declaração literal do criador

> 3A — Determinar a referência de ATB pela calibração do ritmo existente no jogo e apresentar o valor antes de implementar.

## Regra aprovada

- A **referência numérica de AGI para regeneração natural de ATB** deve ser **determinada a partir da calibração do ritmo existente do jogo**, e o **valor proposto deve ser apresentado ao criador antes de implementar**.
- Esta decisão mantém D-126 (preservar inicialmente o ritmo do combate) e D-145 (uma AGI, referências potencialmente diferentes para ATB e trajetos); **não obriga a referência ATB a ser igual à mediana dos trajetos** (D-162/D-167/D-168).
- **D-163** já estabelece que o tempo natural de preenchimento do ATB é inversamente proporcional à AGI efetiva; **D-164** protege a entrada do cálculo com AGI mínima de 1. A escolha atual apenas especifica **como calibrar a referência numérica**, sem substituir essa relação.
- **Exemplo não normativo:** medir em uma configuração de combate existente quanto tempo um personagem de velocidade conhecida demora para preencher dois blocos ATB, calcular uma referência compatível com o ritmo aprovado, **submeter o número ao criador** e só depois considerar sua implementação. Nenhuma medição ou número foi aprovada nesta decisão.

## Pendências e escopo

- Fonte da equivalência entre o sistema de velocidade atual e AGI, cenário de medição, dados reais, referências/coeficientes, critérios de tolerância, testes de calibração e **aprovação do número**.
- **Não foi realizada medição, calibração ou execução de gameplay** nesta atividade; apenas registro documental. Não alterar código, cenas ou testes.

## Complemento posterior — Rodada 64 / D-175 (2026-11-03)

**D-175 (R64-Q4C)** estabelece medir, para a calibração pelo ritmo atual, **ambos os intervalos de regeneração natural de ATB: de 3 a 5 e de 0 a 5 blocos**, comparando os resultados. O ATB inicial de 3 blocos continua conforme D-031. **Ainda não houve medição nem escolha de referência numérica**; apresentar o valor resultante ao criador antes de implementar, como exige esta D-169. Apenas documentação.
