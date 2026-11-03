# D-110 — Rodada 51, Q1 (1A): preservar interceptação existente de projéteis por personagens

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 51
- **Origem:** escolha expressa do criador.
- **Estado:** decisão de design aprovada e registrada; implementação não declarada.

## Declaração literal do criador

> 1A — Manter a interceptação de projéteis por outros personagens? Manter a interceptação existente: quem está na linha à frente do alvo pode receber o projétil.

## Regra aprovada

- **Manter a interceptação existente por personagens:** quando um personagem adversário está na **linha do projétil antes do alvo visado**, ele **pode receber o projétil no lugar do alvo originalmente escolhido**, conforme o comportamento existente do motor.
- A referência concreta é `AttackPlanner.redirect_if_blocked()` / `interceptor()` em `scripts/combat/attack_planner.gd`, chamada na **declaração** da ação em `Battle.use_skill()` (`scripts/combat/battle.gd`). O motor atual escolhe o interceptador na linha antes do alvo, para os Moves que aceitam essa regra.
- **Não criar interceptação dinâmica durante o voo por esta decisão.** A alternativa aprovada foi manter a interceptação existente, não alterar sua fase de determinação nem ampliar o conjunto de Moves afetados.
- **Compatibilidade:** D-047 (perseguição do alvo do projétil), D-109 (morte do alvo do projétil já em voo não causa seleção de substituto), D-108 (troca de alvo durante wind-up se o alvo morrer). Um personagem pode se tornar o alvo efetivo por interceptação na declaração, sem autorizar a substituição após o disparo.

## Limites e verificação

- A implementação existente contém **exceções por identificação de Move** em `redirect_if_blocked()`. Esta aprovação não modifica as exceções nem torna a interceptação universal para todos os projéteis.
- Não foi aprovada uma nova colisão por paredes, cenário, cobertura, objetos ou mudanças físicas na arena.
- **Escopo:** somente documentação. Nenhuma edição do motor Godot, FX, dados ou testes.
