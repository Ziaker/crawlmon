# D-232 — Rodada 77 Q2 (2A): excluir Moves incompletos antes da seleção tática da IA

- **Data:** 2026-11-04.
- **Área:** Combate / IA / validação de Moves / consumo de recursos.
- **Origem:** escolha expressa do criador na Rodada 77.
- **Estado:** regra de IA aprovada; **não implementada nesta atividade**.

## Declaração literal do criador

> 2A — Excluir Moves com configuração incompleta da lista de candidatos da IA antes da seleção tática, sem gastar ação ou recursos.

## Regra aprovada

- **Antes de a IA avaliar e selecionar taticamente um Move**, **excluir da lista de Moves candidatos aqueles cuja configuração esteja incompleta** no sentido já aprovado de **prioridade obrigatória ausente entre status expressamente declarados incompatíveis** (D-215/D-217/D-221).
- A exclusão ocorre **antes** da escolha tática: a IA **não deve selecionar um Move inválido para depois tentar executá-lo**. Não debitar **ATB, Burst, MP ou oportunidade de ação** em razão dessa **exclusão/validação**; preservar **D-225**, que exige validação antes da confirmação e proíbe cobrança da ação bloqueada. A referência a MP abrange apenas a ausência de custo no bloqueio, sem aprovar custos ou regras adicionais de MP além da D-228.
- **Exemplo abstrato:** a IA possui quatro opções de Moves, mas uma ficha declara `Status A` e `Status B` incompatíveis sem registrar quem tem prioridade. **Essa opção é excluída antes de a IA comparar taticamente as válidas**; a exclusão não consome recursos nem uma ação, e não introduz uma prioridade de status.
- Preservar a regra de **D-221** de identificar **exatamente a prioridade ausente** quando o Move é bloqueado. A lógica de seleção tática entre candidatos válidos não é alterada; **não transformar uma opção excluída em Tackle automaticamente**.

## Pendências e limites

- **Não foi decidido o comportamento caso não haja nenhum Move candidato válido** ou como outras classes de ficha incompleta são tratadas. A decisão não cria um fallback (Tackle, espera ou outro), nem autoriza generalizar o bloqueio a toda irregularidade de ficha sem aprovação própria.
- Não definir interface de erro, mecanismo técnico de validação, novos critérios de escolha de Move, custos individuais de MP ou exceções de ATB/Burst.
- Somente documentação; nenhum código, IA, Move, ficha, testes, cena, asset ou VFX modificado.
