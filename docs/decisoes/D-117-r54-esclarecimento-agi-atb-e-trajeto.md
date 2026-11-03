# D-117 — Rodada 54: Agilidade governa ATB e deslocamento nos trajetos de ataque

- **Data:** 2026-11-03
- **Origem:** correção expressa do criador durante o questionário da Rodada 54.
- **Estado:** regra explicitamente definida, apenas documentada; Rodada 54 ainda não foi aprovada integralmente.

## Declaração literal do criador

> AGI funciona diferente, afeta ambas a regeneração de ATB como também a velocidade de movimento do Pokémon durante seus trajetos de ataque

## Regra definida

- O atributo **Agilidade (AGI)** possui **duas consequências distintas e obrigatórias**: **(1) a velocidade da regeneração/preenchimento natural dos blocos ATB** e **(2) a velocidade de movimento do próprio Pokémon durante os trajetos de seus ataques**.
- A equivalência já aprovada **Agilidade = Velocidade do ATB** permanece (GDD R11-Q1, válido para a definição de atributos). Ela **não restringe** o atributo ao ATB: o criador explicitamente acrescentou velocidade de movimento em trajetos de ataque.
- A regra não fixa fórmula, multiplicador, limites nem relação numérica entre AGI e velocidade de deslocamento; isso precisa de definição própria antes de implementar.
- A regra de **passos de posicionamento** em D-018 (`base − 0,10 s × (posição do atacante + posição do alvo)`, piso `0,25 s`) permanece registrada. **Ainda é necessário conciliar tecnicamente AGI com os efeitos já aprovados dos passos**, sem eliminar a função dos passos ou escolher silenciosamente uma ordem de cálculo.
- Esta declaração fala de **movimento do Pokémon em seus trajetos de ataque**; não define por si só a velocidade de projéteis, ondas AoE, deslocamento no mapa 2D, Evade ou animações ociosas.

## Estado verificado do código

- `Combatant.speed` e `Combatant.tick()` influenciam o ATB a partir de `base_speed` e buffs; os cinco atributos permanentes ainda não estão integrados.
- `Battle.travel_seconds()` em `scripts/combat/battle.gd` considera duração-base e passos posicionais, mas **não considera AGI**. O deslocamento visual de ataques corpo a corpo é calculado dentro da fase `TRAVEL` por `AttackMotion.update()`. Logo, o segundo efeito de AGI **ainda não está implementado**.
- Nenhum código, VFX, dados, testes ou configuração foi alterado nesta atividade.

## Complemento posterior — D-119 (2026-11-03)

A declaração posterior do criador fixa que **cada Move possui seu próprio tempo de deslocamento declarado na ficha**, reduzido pela **AGI** e por **efeitos que aumentam AGI**. Preservar a relação ATB + movimento definida aqui e os passos de posicionamento da D-018. A fórmula de combinação e os coeficientes continuam pendentes; não inferir redução numérica nem mínimo novo.
