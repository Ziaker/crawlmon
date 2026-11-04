# D-196 — Rodada 69 Q1 (1A): IDs únicos estáveis atribuídos ao início do combate

- **Data:** 2026-11-04.
- **Área:** Combate / identificadores / RNG de retarget reproduzível.
- **Origem:** escolha expressa do criador, aceitando a recomendação na Rodada 69.
- **Estado:** regra de design aprovada e registrada; não implementada nesta atividade.

## Declaração literal do criador

> 1A — Atribuir IDs únicos no início do combate, segundo uma ordem estável e documentada, sem renumerar combatentes durante a batalha.

## Regra aprovada

- **Ao iniciar cada combate**, atribuir **identificadores únicos aos combatentes** por meio de uma **ordem estável e documentada**, sem renumerar combatentes durante a mesma batalha.
- Esses identificadores servem de base às regras de **ordenação dos candidatos empatados antes de sorteios** (D-188) e de **eventos simultâneos de retarget ordenados pelo ID do atacante antes do consumo do RNG exclusivo** (D-192). Não escolher o menor ID automaticamente como alvo: o desempate entre alvos permanece pseudoaleatório, conforme D-166 e D-186–D-189.
- **Exemplo somente ilustrativo, não definição da ordem:** participantes Gible, Abra e Pancham recebem três IDs distintos ao começar uma batalha. Ainda que um deles seja derrotado, os demais não mudam de ID. O exemplo **não aprova** a sequência numérica concreta nem qual participante fica com qual ID.
- Preservar **D-095**: IDs e ordem de consumo do RNG não criam prioridade de vitória/derrota quando ambas as equipes forem eliminadas no mesmo instante lógico.

## Limites e pendências

- A regra **exige uma ordem estável e documentada**, porém **não escolhe qual ordem específica** deve ser usada (equipe, posição, ordem de criação, slots ou outro critério), sua representação, nem o tratamento de entradas de participantes após o início do combate.
- Permanecem a definir forma de persistir IDs para replay, granularidade de simultaneidade e tratamento de mais de um retarget simultâneo do mesmo atacante; não inventar esses comportamentos.
- Apenas documentação; nenhum código, teste, cena, ficha ou VFX foi modificado.
