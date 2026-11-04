# D-186 — Rodada 66 Q5 (5A): RNG reproduzível exclusivo para desempates de retarget

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / aleatoriedade reproduzível.
- **Origem:** aprovação expressa do criador, Rodada 66.
- **Estado:** regra de projeto aprovada; não implementada.

## Declaração literal do criador

> 5A — Usar fluxo de números pseudoaleatórios reproduzível exclusivo para desempates de retarget, separado dos demais sorteios do combate.

## Regra aprovada

- Os **sorteios de desempate entre alvos vivos mais próximos** durante **WINDUP** (D-108/D-166) deverão utilizar **um fluxo de números pseudoaleatórios reproduzível exclusivo para esses desempates de retarget**.
- O fluxo do desempate deve ser **separado dos demais sorteios aleatórios do combate** (ex.: crítico, esquiva ou efeitos de status). Consumir aleatoriedade de outros subsistemas **não deve avançar esse fluxo exclusivo**.
- Preservar a geometria e elegibilidade vigentes: distância entre **posições lógicas no plano horizontal** (D-176/D-181), **empate até 0,01 unidade da arena, inclusive** (D-171), escolha aleatória apenas entre os candidatos vivos dentro dessa faixa, e **um recálculo de duração por troca efetiva** ainda em WINDUP (D-155).
- **Exemplo ilustrativo:** uma rolagem de crítico antes de um empate de retarget não deve, por si, avançar a sequência aleatória exclusiva de retarget. Isso não significa que o mesmo alvo deva ser sempre escolhido; em execuções com **mesmas entradas, estado e seed reproduzível** a sequência de desempates deverá poder ser reproduzida.
- Esta escolha **não fixa** algoritmo gerador, estratégia de seed, serialização de RNG, ordem de candidatos, consumo no caso de somente um elegível, ou política para múltiplos desempates concorrentes. Não afirmar que o combate atual já tenha fluxo exclusivo.

## Pendências e escopo

- Definir mecanismo de inicialização do RNG de retarget, ordem estável de candidatos e eventos para replay, e detalhes de consumo sem alterar outras mecânicas. Essas definições exigem decisões adicionais.
- Documentação apenas; nenhum código, RNG, cena ou teste alterado.

## Complemento posterior — Rodada 67 / D-187, D-188 e D-189 (2026-11-03)

**D-187 (R67-Q1B):** gerar **seed própria para retarget no início de cada combate** e **registrá-la para reprodução**. **D-188 (R67-Q2A):** ordenar **os candidatos empatados pelo identificador estável do combatente dentro da batalha antes de sortear**, sem escolher o menor ID como resultado fixo. **D-189 (R67-Q3A):** **consumir o fluxo de RNG exclusivo somente quando houver pelo menos dois candidatos vivos elegíveis empatados**. Seed, ordenação e consumo são requisitos documentais, não implementação do gerador ou do replay. Algoritmo, formato do registro e ordenação de eventos simultâneos ainda pendem. Histórico preservado.
