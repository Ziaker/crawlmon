# D-223 — Rodada 75 Q4 (4A): desempate de RNG de status para o mesmo alvo por atacante, declaração e ocorrência

- **Data:** 2026-11-04.
- **Área:** Combate / status simultâneos / consumo determinístico de RNG.
- **Origem:** decisão expressa do criador na Rodada 75.
- **Estado:** regra de ordenação aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 4A — Desempatar pelo ID estável do atacante e depois pela ordem estável de declaração e índice de ocorrência, somente para consumo de RNG.

## Regra aprovada

- Para **rolagens simultâneas de status destinadas ao mesmo alvo**, em que a ordenação pelo **ID estável do alvo** não as diferencia, **desempatar para fins de consumo de RNG** pelo **ID estável do atacante**, depois pela **ordem estável de declaração dos eventos/ataques** e, se necessário, pelo **índice estável da ocorrência**.
- Preservar **D-219**: a ordenação primária de rolagens simultâneas contra **alvos diferentes** continua sendo o **ID estável do alvo**. O desempate adicional da presente decisão é aplicado **quando o alvo é o mesmo**, sem substituir a regra primária por ordenação global de atacantes.
- **Somente a ordem dos consumos de RNG** é definida; a decisão **não modifica a simultaneidade lógica** de danos e efeitos, nem cria prioridade de acerto, morte, vitória/derrota ou prevalência entre status. Preservar **D-095** sobre KO simultâneo.
- Exemplo **hipotético:** Gible, atacante ID 2, e Pancham, atacante ID 5, têm rolagens de status elegíveis no mesmo instante lógico contra Abra, alvo ID 3. Para consumo de RNG, a rolagem do atacante **ID 2 antecede** a do atacante **ID 5**, sem antecipar logicamente a aplicação do primeiro efeito. Se o atacante for o mesmo, usar declaração/ocorrência estáveis. Os personagens e IDs são didáticos.
- Preservar **D-213** (ordem de efeitos distintos explicitamente declarados **na ficha do Move**), **D-210** (teto por efeito distinto/alvo/execução), D-199/D-202/D-207/D-211 (elegibilidade, dano, sobrevivência e impactos), e **D-214/D-218/D-222** quanto à identidade estável de declarações e ocorrências.
- O fluxo exclusivo de **RNG de retarget** (D-186–D-189/D-192) é distinto. Esta decisão não cria novo PRNG, seed, fluxo de RNG de status ou prioridade entre categorias de RNG.

## Limites e pendências

- Para duas tentativas ainda empatadas por **mesmo alvo, atacante, declaração e índice** (por exemplo, múltiplos efeitos distintos da mesma ocorrência), preservar a ordem já aprovada da ficha quando aplicável (D-213). **Não inventar desempates residuais**, política de status incompatíveis de Moves diferentes ou algoritmo de RNG.
- Somente documentação; nenhum código, testes, fichas, Moves, VFX, assets ou cenas alterados.
