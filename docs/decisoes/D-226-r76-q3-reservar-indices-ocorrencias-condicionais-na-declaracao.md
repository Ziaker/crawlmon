# D-226 — Rodada 76 Q3 (3A): reservar no plano inicial índices de ocorrências condicionais possíveis

- **Data:** 2026-11-04.
- **Área:** Combate / plano de eventos / índices estáveis / retarget.
- **Origem:** escolha expressa do criador na Rodada 76.
- **Estado:** regra de identidade e planejamento aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Exigir que o plano determinístico inicial preveja também as ocorrências condicionais possíveis, reservando seus índices na declaração do ataque.

## Regra aprovada

- Ao **declarar o ataque**, o **plano determinístico de eventos** previsto na D-218 deve **prever também as ocorrências condicionais possíveis** desse ataque e **reservar seus respectivos índices nesse mesmo momento**, ainda que a condição que as acionaria não venha a ocorrer.
- Cada ocorrência planejada mantém seu índice estável; preservar D-222: quando uma ocorrência condicionada não acontecer ou for cancelada, **não reutilizar o índice reservado e não renumerar os demais índices da mesma declaração**.
- **Exemplo hipotético:** a declaração prevê a ocorrência `A#1` e uma possível ocorrência condicional `A#2`, reservando ambos os índices. Se a condição de `A#2` não acontecer, o índice continua reservado na declaração; **não se simula o evento nem se sorteia RNG apenas por ter reservado esse índice**. Números e nomes são meramente ilustrativos.
- Preservar D-214/D-192 quanto à ordem de eventos simultâneos de retarget, D-188 quanto à ordem dos candidatos empatados e D-189 quanto ao **consumo exclusivo de RNG de retarget somente em empate realmente elegível**. A reserva de índice não implica execução de evento, nem altera prioridade de danos ou de KO simultâneo (D-095).

## Limites e pendências

- **Não foi definido** como representar o plano, quais tipos concretos de condição existem, como identificar todas as possibilidades, se eventos impossíveis de enumerar podem existir, qual o limite de ocorrências ou como serializar/reproduzir a declaração. Não criar exceção dinâmica nem proibição geral desses eventos por inferência.
- A regra se limita aos eventos de ataque a que se aplicam D-218/D-222; não impor planejamentos novos a sistemas não cobertos.
- Documentação somente; nenhum código, RNG, teste, Move, asset, cena ou VFX modificado.
