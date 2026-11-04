# D-241 — Rodada 79 Q2 (2A): IA sem Move válido nem Tackle elegível não age e reavalia na próxima oportunidade normal

- **Data:** 2026-11-04.
- **Área:** Combate / IA / elegibilidade / consumo de recursos.
- **Origem:** aprovação expressa do criador na Rodada 79.
- **Estado:** regra condicional de IA aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 2A — Não iniciar ação nem consumir recursos; reavaliar elegibilidade na próxima oportunidade normal de decisão da IA.

## Regra aprovada

- Se, após filtrar os Moves incompletos conforme **D-232**, **não restar nenhum Move válido** e **Tackle também não estiver elegível** (D-237), a IA **não deve iniciar uma ação nem consumir recursos** nessa tentativa de decisão.
- A IA deve **reavaliar a elegibilidade no próximo momento normal de decisão da IA**, segundo a temporização e condições já vigentes do combate; **não criar nesta decisão cronômetro, polling contínuo, tentativa automática imediata nem período de espera novo**.
- **Exemplo hipotético:** o atacante controlado pela IA não possui Move válido e tampouco Tackle elegível. Ele não inicia Move ou Tackle e não consome ATB, Burst ou MP pela tentativa sem opção; na **próxima oportunidade normal de decisão** verifica novamente o conjunto de ações elegíveis.
- Preservar D-225/D-232/D-237: a exclusão de Moves incompletos ocorre antes da seleção tática; Tackle pode ser considerado separadamente quando elegível. Esta regra **não invalida** os custos e o consumo normais de **ações válidas efetivamente confirmadas**.
- A política não depende do nome, espécie, posição, lado ou time do atacante (D-235).

## Pendências e escopo

- A decisão **não fixa a frequência exata** das oportunidades normais da IA, duração da espera, comportamento de animação ou regra caso o sistema deixe de produzir uma próxima oportunidade. Não tomar “não iniciar ação” como aprovação de consumir a oportunidade, reduzir ATB ou descartar um turno.
- **Não estende automaticamente o filtro da D-232 a outras causas de incompletude de Move**, como falta de máximo condicional da D-238; esta questão continua separada.
- Somente documentação; nenhum código, IA, teste, Move, ficha, cena, asset ou VFX alterado.
