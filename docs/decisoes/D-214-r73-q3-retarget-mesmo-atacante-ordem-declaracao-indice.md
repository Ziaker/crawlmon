# D-214 — Rodada 73 Q3 (3A): desempatar retarget simultâneo do mesmo atacante por declaração e índice estáveis

- **Data:** 2026-11-04.
- **Área:** Combate / retarget simultâneo / determinismo e consumo de RNG.
- **Origem:** escolha expressa do criador na Rodada 73.
- **Estado:** critério de ordenação aprovado; não implementado nesta atividade.

## Declaração literal do criador

> 3A — Desempatar pela ordem estável de declaração dos eventos do ataque, com um índice estável para ocorrências da mesma declaração.

## Regra aprovada

- Para **dois ou mais eventos simultâneos de retarget originados do mesmo atacante** e elegíveis a consumir o **RNG exclusivo de retarget**, **desempatar primeiro pela ordem estável de declaração dos eventos do ataque**.
- Quando houver **mais de uma ocorrência da mesma declaração**, utilizar **um índice estável da ocorrência** como critério adicional de ordenação. A ordem deve ser reproduzível e **não depender da ordem incidental de chegada dos callbacks**.
- Complementar **D-192** (primeiro ordenar eventos pelo ID estável do **atacante**). A D-188 continua ordenando **candidatos empatados dentro de cada evento**; D-186/D-187 mantêm fluxo e seed exclusivos de retarget; D-189 continua determinando **não consumir RNG sem pelo menos dois candidatos empatados elegíveis**. Esta escolha não faz do menor ID o alvo vencedor (D-166).
- **Exemplo estritamente fictício:** o atacante ID 2 possui no mesmo instante lógico eventos de declaração `A` e `B`, com duas ocorrências de `A` indexadas `1` e `2`. Se a ordem declarativa for `A` antes de `B`, os sorteios elegíveis seguem `A#1`, `A#2`, `B`; os nomes e índices são apenas ilustrativos e **não aprovam formato ou início dos contadores**.
- Preservar **D-095**: esse desempate só controla **ordem do consumo do RNG de retarget**, não a prioridade do dano nem o veredito de eliminações simultâneas.

## Limites e pendências

- Não são definidos aqui a implementação/representação do índice, quando é capturado, política de serialização/replay, granularidade do instante lógico ou quantidade de chamadas internas do PRNG. **Não ordenar outras classes de eventos sem aprovação.**
- Se houver mais um critério residual de empate após os identificadores aprovados, não inventar fallback não declarado.
- Somente documentação; nenhum código, teste, cena, recurso, Move, RNG ou VFX modificado.
