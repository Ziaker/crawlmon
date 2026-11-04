# D-238 — Rodada 78 Q3 (3A): bloquear Move com plano condicional sem máximo antes da confirmação e dos custos

- **Data:** 2026-11-04.
- **Área:** Combate / plano de eventos / validade do Move / recursos.
- **Origem:** resposta expressa do criador na Rodada 78.
- **Estado:** bloqueio específico aprovado; não implementado nesta atividade.

## Declaração literal do criador

> 3A — Bloquear a confirmação do Move cujo plano de ocorrências condicionais esteja incompleto por falta de máximo explícito, antes de consumir ação ou recursos, identificando a omissão.

## Regra aprovada

- Quando um Move tiver um **plano de ocorrências condicionais incompleto por ausência do limite máximo explícito obrigatório** (D-233), **bloquear a confirmação desse Move**.
- Executar a validação **antes de consumir a oportunidade de ação ou recursos**, inclusive **ATB, Burst e MP quando aplicável**, e **identificar exatamente a omissão do máximo exigido**. Não usar automaticamente um máximo ou reserva de índices fictícios.
- **Exemplo estritamente hipotético:** uma ficha permite um número variável de eventos condicionais, mas omite o **máximo de ocorrências**. Ao tentar confirmar esse Move, bloquear a ação, apontar a falta do máximo e **manter intactos os recursos e a ação**. A decisão não escolhe interface, mensagem literal ou valor de máximo.
- Preservar **D-218/D-222/D-226/D-233**: o plano determinístico precisa reservar na declaração os índices de ocorrências condicionais possíveis até um máximo **expressamente definido**, mantendo índices cancelados reservados sem reuso/renumeração.
- A D-238 constitui **um segundo motivo expressamente aprovado de bloqueio**, além de **prioridade ausente de status incompatíveis** de D-221/D-225. Nenhum desses bloqueios modifica custos e execução de Moves válidos (D-228 permanece em vigor para MP de Moves mágicos/especiais).

## Pendências e limites

- **Não determina automaticamente** se a IA deve excluir Moves com essa nova falha da lista tática (a D-232 já define o filtro para incompatibilidade sem prioridade), como detectar ou sinalizar a falha no editor, ou o que fazer se todas as ações estiverem indisponíveis.
- Não define política de exceder o limite durante a execução, texto da mensagem, UI, ou máximos concretos de qualquer Move.
- Apenas documentação; nenhum código, teste, IA, Move, ficha, cena, asset ou VFX modificado.
