# D-1194 — Tempo de trajeto reduzido por AGI (20% × min(AGI,50)/50), só melee e mid-range

- **Data:** 2026-11-12
- **Área:** Combate
- **Origem:** Conversa
- **Estado:** fase 1 em **TESTE** no código (`battle.gd`: `agi_travel_factor`, `TRAVEL_AGI_MAX_REDUCTION`; `attack_planner.gd`: melee `run_t` e `cast_travel_strike` de Move CAST). Não commitada. Valores marcados "pendente" não foram decididos pelo criador.

## O que o criador disse (literal)

> "e pra influenciar no tempo de trajeto ate o alvo em moves que envolvem moimentacao no caso os melee e mid range"
>
> "c - uma reducao balanciada que nao afete tanto os valores, numeros pequenos mas que tambem sejam influenciados por buffs, e pra ter um balanciamento entre personagens rapidos de lentos"
>
> "d - efeito de reducao de agi afeta o tempo que leva ate o personagem chegar no oponente com moves melee e mid range, nao de forma drastica mas de forma notavel, nao mais o atb, o que afeta o atb vai ser uma condicao de status chamada de EXHAUST"
>
> "e - vamos manter a tabela atual mas ter a informacao do tempo de corrida para os moves presentes em suas fichas"
>
> "f - projeteis tem sim trajeto mas nao sao afetados por agi"
>
> "4 - acho que 20%" · "5 - sim [buffs de AGI também entram]"
>
> Esclarecimento: mid-range = `Skill.Kind.CAST` (D-1073).

## Decisão

1. Redução do tempo de corrida: `0,20 × min(AGI_efetiva, 50) / 50 + 0,03 × estágios_de_buff − 0,03 × estágios_de_debuff`, sobre o tempo declarado na ficha do Move. AGI 50 sem buffs = −20%.
2. Só Moves melee e mid-range. Projéteis não são afetados.
3. Ordem (D-133): tempo da ficha → redução por AGI → correção de passos (D-018, `battle.gd:102`) → piso 0,25 s (`battle.gd:103`, `448-449`).
4. **Complementa D-119**: o tempo de corrida passa a ser campo da ficha do Move; a tabela de `attack_planner.gd:75-80` é mantida.
5. **Altera D-341**: `travel_extra` deixa de ser usado para isso (`attack_planner.gd:80`, `209`).
6. D-018 não é revogada: os passos continuam valendo, sobre o tempo já reduzido.
7. **Pendente (não foi dito pelo criador):** se `RUN_START := 0.12` (`attack_motion.gd:9`) é reduzido por AGI. No teste da fase 1 ele NÃO é reduzido (escolha de implementação, não decisão).

## Ambiguidades em aberto

- Resolvido: mid-range é `Skill.Kind.CAST` (D-1073). Hoje só o Onda de Choque (`cast_travel_strike`, `plan_fly`) é CAST com trajeto. Moves de `plan_profile` `cast_strike_travel` (Fúria do Dragão, Provocação) não são Kind CAST e não são afetados.
- RUN_START fora da redução: a redução real sobre o trajeto total fica menor que 20%. Confirmar.
- Limites da redução com buffs/debuffs (acima de 20% ou abaixo de 0).
- O teto 50 vale aqui como na esquiva (D-1193)?
- Piso 0,25 s antes ou depois de somar RUN_START.
- Campo de tempo de corrida em `MoveData`: nome e unidade pendentes.
- `preview_travel` (`attack_planner.gd:207-209`) deve usar a mesma fórmula.
