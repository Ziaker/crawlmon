# D-132 — Rodada 55 Q1 (A): Variação individual persistente de até ±3 pontos por atributo-base

- **Data:** 2026-11-03
- **Área:** Atributos e progressão de Pokémon / Rodada 55.
- **Proveniência:** escolha **expressamente enviada pelo criador**, aceitando alternativa recomendada previamente pelo assistente; a decisão foi escolhida pelo criador, não deduzida de delegação à IA.
- **Estado:** decisão de design aprovada e registrada; **não implementada nesta atividade**.

## Declaração literal do criador

> 1A — Qual a amplitude das variações individuais? Até ±3 pontos por atributo-base, sorteados uma vez e persistentes. (recomendação aceita)

## Regra aprovada e compatibilidade

- Cada indivíduo pode possuir **variação aleatória entre −3 e +3 pontos**, inclusive, em **cada atributo-base** da espécie; o sorteio acontece **uma única vez por indivíduo**, e seu resultado **persiste**.
- A regra se aplica ao catálogo vigente de **seis atributos permanentes** — Strength (STR), Magic (MAG), Vitality (VIT), Spirit (SPI), Agility (AGI) e Luck (LUK) — sem introduzir IVs ocultos ou nova família de atributos.
- Preservar **D-121** (identidade individual), **D-120** (identidade biológica de espécie) e **D-129/D-131** (faixa permanente **1–100**, nomes ingleses). A nova variação não altera os coeficientes e curvas próprias das espécies.
- **Limite do que foi aprovado:** o intervalo de possíveis modificadores e a persistência foram escolhidos; **a distribuição/probabilidade de cada número, a regra de ajuste em 1 ou 100, a semente e a sequência de aplicação relativa a Nature** não foram definidas.
- **Exemplo ilustrativo, não fichas aprovadas:** duas instâncias com STR-base 40 poderiam ter STR 38 e 42 após o sorteio.

## Estado de execução

- **Documentação somente:** não alterar código, cenas, tabelas, fichas de Moves, VFX, testes ou configurações do projeto.
- As fórmulas e dados marcados como pendentes não podem ser completados por suposição.

## Complemento posterior — Rodada 57 (2026-11-03)

**D-139/D-141 (R57):** a variação individual de −3 a +3 continua persistente, mas pode produzir valores permanentes **acima de 100**, sem truncar ao antigo teto. O sorteio deve favorecer valores **próximos de zero** e tornar os extremos −3/+3 raros. Pesos numéricos e distribuição exata continuam pendentes.
