# D-256 — Rodada 81 Q3 (3A): registrar violação do plano em estrutura com identificadores estáveis

- **Data:** 2026-11-04.
- **Área:** Combate / plano determinístico / rastreabilidade de violações.
- **Origem:** decisão expressa do criador na Rodada 81.
- **Estado:** conteúdo mínimo estruturado aprovado; formato técnico e implementação pendentes.

## Declaração literal do criador

> 3A — Registrar a violação de maneira estruturada com identificação do Move, atacante, declaração, máximo aprovado e ocorrência excedente, usando identificadores estáveis.

## Regra aprovada

- Quando uma **ocorrência condicional exceder o máximo explícito do Move** e for **rejeitada** conforme D-242/D-252, registrar a **violação do plano de forma estruturada**, incluindo no mínimo as identificações de:
  1. **Move**;
  2. **Atacante**, por seu identificador estável na batalha;
  3. **Declaração de ataque** relacionada;
  4. **Máximo explícito aprovado para aquele Move**;
  5. **Ocorrência excedente**, identificável de forma estável para diagnóstico.
- **Exemplo hipotético de campos, não estrutura serializada obrigatória:** `move_id`, `attacker_id`, `declaration_id`, `max_conditional_occurrences`, `rejected_occurrence_id`. Esses nomes são **ilustrações**; nenhuma API, arquivo de log, esquema persistente ou formato de UUID/índice foi aprovado.
- Preservar D-218/D-214/D-222/D-226/D-233: o plano e os índices das ocorrências **válidas** são previstos na declaração; nenhum índice reservado é reutilizado. A identificação estável da **solicitação excedente rejeitada** deve existir para diagnóstico, **sem criar índice válido novo de evento** e sem legitimar execução além do máximo. O mecanismo concreto desse identificador ainda não foi definido.
- Preservar D-242/D-252: **rejeitar só a ocorrência excedente**, **preservar eventos anteriores já validamente resolvidos** e **continuar eventos posteriores já previstos e elegíveis**. O registro não provoca rollback, consumo de RNG, danos adicionais ou interrupção de eventos válidos.
- Preservar D-235: a estrutura deve ser independente de espécie, personagem, lado e posição fixa; referenciar o atacante e o Move reais.

## Pendências e escopo

- Não foram decididos tipo de log, transporte, persistência, destino/visibilidade, representação de identificadores, deduplicação de alertas, política de retenção ou protocolo de replay. **Este requisito aprova os campos mínimos, não um mecanismo de registro.**
- Não há máximo numérico aprovado de ocorrências para qualquer Move real nesta decisão.
- Somente documentação; nenhum código, teste, IA, Move, ficha operacional, cena, asset ou VFX alterado.
