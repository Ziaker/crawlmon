# D-1193 — Esquiva automática passa a vir da AGI (10% base + 0,3% por ponto, buffs de ±3 pp por estágio)

- **Data:** 2026-11-12
- **Área:** Combate
- **Origem:** Conversa
- **Estado:** fase 1 em **TESTE** no código (`battle.gd`: `auto_dodge_chance`, `AUTO_DODGE_BASE/PER_AGI`, `AGI_EFFECT_CAP`, `AGI_STAGE_STEP`; também `move_behaviors.gd` e a esquiva da IA em `_roll_ai_dodge`). Não commitada. Os valores numéricos abaixo marcados "pendente" não foram decididos pelo criador.

## O que o criador disse (literal)

> "a ideia maior, alem de ser usado pra aumento de velocidade de atb, tambem devia servir para aumentar a chance automatica de desvio" (pedido original)
>
> "a - uma formula que teoricamente, com 50 agi, a chance seja 25%, tambem influenciando buffs de AGI que adicionam mais 3% para cada estagio em combate"
>
> "b - sim obviamente, tudo que afeta o jogador tambem afeta a IA"
>
> "2 - 10% base + %AGI nao definido + 3 para cada estagio de buff de AGI, ou - para debuff"
>
> "3 - sim" (a IA perde o cálculo atual por speed)

## Decisão

1. Chance de esquiva automática por golpe: `chance = 0,10 + 0,003 × min(AGI_efetiva, 50) + 0,03 × estágios_de_buff − 0,03 × estágios_de_debuff`. AGI 50 sem buffs = 25%.
2. **Pendente (não foi dito pelo criador):** teto de AGI efetiva em 50. É uma sugestão minha usada só no teste da fase 1; o criador só disse que com 50 AGI a chance "teoricamente" seja 25%.
3. Cada estágio de buff de AGI soma +3 pp; cada estágio de debuff, −3 pp. Vale igual para jogador e IA.
4. **Altera D-005**: o 10% deixa de ser a chance final e vira só a base da fórmula (`AUTO_DODGE_CHANCE`, `battle.gd:89`).
5. **Altera** a chance da IA igual a `speed` (`battle.gd:~798`): a IA usa a mesma fórmula. Quando ela tenta continua na janela da D-1014.
6. **Complementa D-117/D-119**: AGI volta a ter efeito defensivo, além do trajeto (D-1194).

## Ambiguidades em aberto

- O teto de 50 limita só a parcela de AGI ou também os ±3 pp dos buffs?
- "Estágio de buff de AGI": hoje existe só `speed_buff` (−5..+5, `combatant.gd:121`), usado no ATB. É o mesmo campo ou um novo?
- Piso da chance com estágios negativos.
- A esquiva automática continua dando +1 bloco de ATB (`battle.gd:1004`)?
- Continua sorteada em `_resolve_incoming` no fim do wind-up (`battle.gd:617`)?
- Relação com Sorte (complemento D-005/D-127) segue pendente.
