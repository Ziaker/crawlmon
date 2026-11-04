# D-225 — Rodada 76 Q2 (2A): bloquear Move incompleto antes da confirmação, sem consumir ação ou ATB/Burst

- **Data:** 2026-11-04.
- **Área:** Combate / validação de ficha / recursos de ação.
- **Origem:** escolha expressa do criador na Rodada 76.
- **Estado:** regra de gameplay aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 2A — Validar antes de confirmar a ação e antes de consumir ATB/Burst; Move bloqueado não consome recurso nem ação.

## Regra aprovada

- Para o caso de **Move bloqueado por prioridade obrigatória ausente entre status expressamente declarados incompatíveis** (D-221/D-217/D-215), **executar a validação antes de confirmar a ação e antes de debitar ATB ou Burst**.
- Se o Move estiver bloqueado por esse motivo, **não consumir ATB, Burst nem a oportunidade de ação do combatente**. Preservar a obrigação da D-221 de **indicar exatamente qual prioridade obrigatória está ausente**; não decidir automaticamente um status vencedor.
- **Exemplo abstrato, sem aprovar incompatibilidade real:** o jogador tem `3 ATB` e `1 Burst` e tenta selecionar um Move hipotético cuja ficha declara efeitos A e B incompatíveis sem prioridade. A validação impede confirmar essa ação; **os recursos e a ação permanecem disponíveis** e a omissão específica é indicada. Os números de recursos são apenas didáticos.
- A validação aprovada **não altera a política de consumo para Moves válidos** (inclusive a prioridade de Burst quando cabível nas decisões anteriores), nem introduz qualquer status incompatível real.

## Limites e pendências

- Não foram aprovados a interface visual, texto exato do aviso, API do validador, tratamento de erros de ficha não relacionados à incompatibilidade nem possibilidade de editar fichas durante o combate.
- A regra de **não consumir recursos nem ação** aplica-se à tentativa bloqueada especificada e **não representa uma nova regra geral de reembolso** para outros motivos de cancelamento.
- Somente documentação; nenhum código, testes, fichas de Moves, cenas, assets ou VFX modificado.
