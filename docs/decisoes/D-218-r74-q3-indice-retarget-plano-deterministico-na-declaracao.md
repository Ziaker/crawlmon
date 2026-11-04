# D-218 — Rodada 74 Q3 (3A): índices de retarget fixados por plano determinístico na declaração do ataque

- **Data:** 2026-11-04.
- **Área:** Combate / retarget / identidade e ordem estável dos eventos.
- **Origem:** escolha expressa do criador na Rodada 74.
- **Estado:** regra de design aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 3A — Atribuir o índice da ocorrência a partir de um plano determinístico dos eventos, no momento da declaração do ataque, mantendo-o fixo até a resolução.

## Regra aprovada

- Para ocorrências de uma **mesma declaração de evento do ataque** que precisem de desempate estável, **atribuir o índice da ocorrência a partir de um plano determinístico dos eventos, no momento da declaração do ataque**.
- **Conservar o índice atribuído até a resolução da respectiva ocorrência**; não depender da ordem incidental de callbacks para estabelecer a identidade ou ordenar seus consumos de RNG.
- Complementar **D-214**: entre eventos de retarget simultâneos do **mesmo atacante**, a ordem é primeiro a **ordem estável da declaração do evento** e depois o **índice estável da ocorrência**. Preservar **D-192** para ordenação inicial pelo ID estável do atacante, **D-188** para a lista de candidatos, **D-189** para não consumir RNG quando não houver dois ou mais candidatos empatados, e **D-186/D-187** para fluxo/seed exclusivos de retarget.
- **Exemplo hipotético:** ao declarar um ataque, um plano determinístico identifica duas ocorrências `A#1` e `A#2` de um evento A. Se `A#1` terminar antes de `A#2`, ambas conservam o identificador atribuído; a ordem de retarget simultâneo que consuma RNG não precisa ser reconstruída a partir do callback que chegou primeiro. **Nomes e índices são ilustrativos, não formato ou base numérica obrigatórios.**
- O índice **não escolhe automaticamente o alvo sorteado** nem altera a regra de empate de eliminação simultânea (D-095).

## Limites e pendências

- Não foi escolhido o formato do plano determinístico, o valor de início dos índices, sua serialização para replay, a granularidade dos instantes lógicos nem o tratamento de tipos de eventos que só possam ser criados dinamicamente. **Não inventar regras para outras classes de eventos**.
- A decisão não especifica realocação ou reutilização do índice caso uma ocorrência seja cancelada antes de ser resolvida; não criar implicitamente essa política.
- Somente documentação; nenhum código, teste, algoritmo de RNG, cena, ficha, Move, recurso ou VFX alterado.
