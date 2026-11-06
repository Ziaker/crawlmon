# D-956 — Rodada 89B Q4 (4A): fluxo determinístico de eventos mecânicos para VFX e rastreamento

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / transmissão de eventos / VFX / observabilidade.
- **Origem:** aprovação expressa da Rodada 89B, questão 4.
- **Estado:** contrato de fluxo aprovado; transporte e implementação pendentes.

## Declaração literal do criador

> 4A — Transmitir eventos mecânicos estruturados por um fluxo determinístico ordenado conforme as prioridades já aprovadas, permitindo consumo independente por VFX e rastreamento, sem alterar a resolução mecânica.

## Regra aprovada

- **Transmitir eventos mecânicos estruturados por um fluxo determinístico**, respeitando **as prioridades e regras de desempate já aprovadas**, sem criar prioridade ou ordenação mecânica nova.
- **Permitir consumidores independentes**, em particular **apresentação/VFX** e **rastreamento/diagnósticos**, sem que seu processamento altere a resolução mecânica, os tempos aprovados, a ordem dos efeitos ou o consumo de RNG.
- Preservar **D-362** (eventos com identidade do Move, declaração, ocorrência, variante quando aplicável, tipo, referência temporal mecânica e participantes) e **D-363** (cancelamento/interrupção explícitos); **D-348** mantém a autoridade dos eventos e tempos no plano mecânico.
- **Exemplo abstrato:** quando um impacto válido é resolvido, o fluxo disponibiliza o evento identificado aos consumidores visual e de diagnóstico, sem que qualquer consumidor reaplique dano ou avance o relógio da execução mecânica.
- Preservar D-235 (qualquer personagem, lado ou anatomia), D-351 (testes de identidade, ordem, tempos e VFX), D-375 (estado terminal de ocorrências) e decisões já vigentes sobre simultaneidade (IDs estáveis de participantes e ordem de resolução).

## Pendências e limitações

- **Não escolhidos:** implementação do transporte (sinais/fila/barramento), identificador individual de entrega, política de redelivery/replay, deduplicação/idempotência por consumidor, buffers/retentativa, sincronismo com threads e serialização. Não impor nova ordem total para casos ainda não homologados.
- A **D-363** contém uma referência editorial incorreta à D-358 como contrato de eventos; o contrato pertinente é D-362. **Este registro não altera D-363 nem corrige sua redação histórica.**
- **Somente documentação; nenhum código, Resource, Move, VFX, teste, IA ou cena alterado.**
