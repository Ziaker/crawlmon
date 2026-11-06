# D-362 — Rodada 87B Q3 (3A): evento estruturado com identidade e referência temporal mecânica

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / contrato de eventos / integração com VFX e rastreabilidade.
- **Origem:** aprovação expressa da Rodada 87B, questão 3.
- **Estado:** conteúdo mínimo do evento aprovado; estrutura técnica e emissão não implementadas.

## Declaração literal do criador

> 3A — Usar eventos estruturados com identidade do Move, declaração, ocorrência, variante quando aplicável, tipo de evento, referência temporal mecânica e participantes envolvidos.

## Decisão aprovada

- Eventos comunicados entre plano mecânico e apresentação visual devem ser **estruturados** e conter identificação do **Move**, da **declaração**, da **ocorrência**, da **variante quando aplicável**, do **tipo de evento**, da **referência temporal proveniente do plano mecânico** e dos **participantes envolvidos**.
- Preservar **D-348**: o plano mecânico é a **única autoridade dos eventos e tempos**; o consumidor visual não cria uma segunda cronologia mecânica. Preservar **D-349**: validar correspondência entre recursos mecânico/visual, variantes e gatilhos referenciados.
- Preservar **D-218/D-222/D-226**: ocorrências condicionais previstas têm índices estáveis reservados na declaração e índices não reutilizados. **D-256/D-266** distinguem diagnósticos de excedentes de índices válidos; um evento visual não deve legitimar ocorrência mecânica excedente.
- Preservar **D-235/AGENTS.md §7**: participantes devem ser identificados a partir dos atacantes/alvos reais, sem fixação a personagem, espécie, lado ou câmera.
- **Exemplo abstrato:** um impacto pode transportar `move_id`, identidade da declaração e ocorrência, uma variante válida se existir, tipo `impact`, referência de tempo mecânica e atacante/alvo reais. **Os nomes técnicos dos campos são ilustrativos e não aprovam formato, unidade de tempo, identificação concreta nem novo evento mecânico.**

## Pendências e limites

- Não estão definidos nome de classe, transporte (sinal/objeto/fila), serialização, representação temporal, identidade global das declarações, versionamento, fontes de participantes nem política de correlação visual. Essas escolhas não podem ser presumidas a partir da lista de campos.
- Somente documentação; nenhum evento, Resource, código, teste, Move ou VFX implementado.
