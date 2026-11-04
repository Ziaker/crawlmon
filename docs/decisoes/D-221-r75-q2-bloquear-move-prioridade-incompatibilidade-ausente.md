# D-221 — Rodada 75 Q2 (2A): bloquear Move em combate se faltar prioridade de status incompatíveis

- **Data:** 2026-11-04.
- **Área:** Combate / validade de ficha de Move / incompatibilidade de status.
- **Origem:** decisão expressa do criador na Rodada 75.
- **Estado:** regra de design aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 2A — Bloquear o uso em combate do Move cuja configuração de incompatibilidade esteja incompleta, indicando exatamente a prioridade ausente.

## Regra aprovada

- Quando a ficha declarar **status incompatíveis** e **não definir expressamente a prioridade necessária entre eles**, a configuração do Move está **incompleta (D-217)** e o **uso desse Move em combate deverá ser bloqueado** enquanto persistir a omissão.
- Ao bloquear, **indicar exatamente qual prioridade obrigatória está ausente**, em vez de selecionar um status vencedor automaticamente. A forma de apresentação, interface e ponto técnico da validação **não foram escolhidos nesta rodada**.
- Preservar **D-215** (precedência entre status declarados incompatíveis exige prioridade na ficha) e **D-213** (ordem de tentativa é distinta da prioridade). **Não estabelecer incompatibilidade entre nenhum par real de status**, nem presumir que toda ficha multi-status seja incompleta.
- **Exemplo abstrato:** ficha hipotética declara `Status A` incompatível com `Status B`, mas não declara precedência. O Move **não pode ser utilizado em combate** e a informação deve identificar a **prioridade A/B ausente**. Definir prioridade válida na ficha remove essa causa específica de incompletude, sem aprovar outros aspectos eventualmente pendentes.

## Limites e pendências

- Não estão definidos o mecanismo do validador, a mensagem textual exata, apresentação na HUD/editor, momento de verificação durante a seleção e comportamento de **ATB/Burst/custos** diante do bloqueio; não decidir esses pontos por inferência.
- O bloqueio é restrito à situação **expressamente coberta**; não se aprovam bloqueios genéricos de Moves por outras causas.
- Somente documentação; nenhum código, ficha de Move, teste, cena, asset ou VFX modificado.
