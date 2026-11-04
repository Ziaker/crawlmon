# D-194 — Rodada 68 Q3 (3A): dano mínimo 1 após acerto válido, ressalvadas imunidades e bloqueios completos

- **Data:** 2026-11-04.
- **Área:** Combate / dano mínimo / mitigação.
- **Origem:** decisão expressa do criador na Rodada 68, aceitando a recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Manter dano mínimo de 1 para golpes que acertam validamente, exceto imunidades e bloqueios completos.

## Regra aprovada

- Quando um **golpe danoso acerta validamente** e não está sujeito a **imunidade ou bloqueio completo aplicável**, o dano efetivo após as mitigações não pode ser inferior a **1 ponto de HP**.
- **Imunidades e bloqueios completos efetivos são exceções explícitas**: esta decisão não força dano de 1 quando a regra aplicável determina ausência integral de dano. Não inventar novos tipos de imunidade, novas proteções ou chances de bloqueio.
- Exemplo apenas ilustrativo: um ataque danoso que acertou, sem imunidade nem bloqueio completo, chegaria a **0,4** após resistências/DEF; a regra de dano mínimo exige **1**. Se o golpe for bloqueado integralmente por uma regra já válida, a exceção permite **0**.
- Preservar **D-193** (ordem de defesa natural seguida pelos estágios de DEF), fraquezas elementais, crítico, condições especiais, regras de Evade e as proteções já aprovadas; o mínimo não converte errados ou esquivados em acertos.
- O código atual contém aplicação de mínimo em `battle.gd` e `combatant.gd`, mas não implementa a nova resistência natural VIT/SPI. **Não confundir o mínimo observado no código com integração concluída destas regras.**

## Limites e pendências

- A decisão não estabelece arredondamento do dano intermediário/final, fórmula numérica de VIT/SPI, precedência detalhada entre imunidade e outros eventos, nem status adicionais em dano nulo. Tampouco altera recursos ou dano não originado de um golpe válido.
- Somente registro documental; nenhum código, teste, cena, Move ou VFX alterado.
