# D-375 — Rodada 88B Q3 (3A): estados terminais determinísticos das ocorrências condicionais reservadas

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / plano determinístico / rastreabilidade.
- **Origem:** decisão expressa do criador na Rodada 88B.
- **Estado:** contrato de resultados aprovado; não implementado.

## Declaração literal do criador

> 3A — Registrar um resultado terminal determinístico para cada ocorrência condicional reservada: executada, cancelada ou não acionada, sem transformar ocorrências não acionadas em efeitos ou consumo de RNG.

## Regra aprovada

- Para **cada ocorrência condicional validamente reservada** no plano (D-218/D-222/D-226), registrar resultado terminal **executada**, **cancelada** ou **não acionada**, de maneira determinística.
- Uma ocorrência **não acionada** preserva seu índice reservado, mas **não produz efeito, impacto ou consumo de RNG por não ter sido acionada**. Não reutilizar nem renumerar o índice; registrar o estado não altera a execução mecânica.
- **Exemplo abstrato:** a declaração prevê ocorrências condicionais A#1 e A#2. Caso a condição de A#2 nunca se cumpra, seu registro terminal é “não acionada”; a reserva não gera dano, status ou RNG.
- **Ocorrências excedentes rejeitadas** não são ocorrências válidas reservadas: continuam tendo **ID diagnóstico separado** conforme D-256/D-266, com rejeição que preserva eventos válidos (D-242/D-252).
- Preservar D-362/D-363 (eventos estruturados, cancelamento/interrupção), D-348 (plano mecânico autoritativo) e D-235 (participantes independentes de personagem/lado).

## Pendências e limites

- **Não definidos:** formato e armazenamento dos resultados, momento exato de encerramento, replay/rollback, tratamento de tentativas internas falhas dentro de ocorrências executadas e integração com logs visuais. Não criar estados extras ou RNG implícito.
- Apenas documentação. Nenhum código, Resource, Move, teste ou VFX alterado.
