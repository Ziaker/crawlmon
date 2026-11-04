# D-233 — Rodada 77 Q3 (3A): máximo explícito de ocorrências condicionais para completar o plano do Move

- **Data:** 2026-11-04.
- **Área:** Combate / plano determinístico / ocorrências condicionais / retarget.
- **Origem:** escolha expressa do criador na Rodada 77.
- **Estado:** regra de completude do plano aprovada; **não implementada nesta atividade**.

## Declaração literal do criador

> 3A — Exigir um limite máximo explícito de ocorrências condicionais para o Move, reservando todos os índices possíveis na declaração; sem limite definido, o plano fica incompleto.

## Regra aprovada

- Para um **Move cujos eventos planejados admitem uma quantidade variável de ocorrências condicionais**, **exigir limite máximo explícito de ocorrências condicionais daquele Move**.
- No **instante da declaração do ataque**, o plano determinístico deve **reservar índices para todas as ocorrências condicionais possíveis até esse limite**, mesmo que muitas não venham a ocorrer. **Sem limite máximo definido, o plano é considerado incompleto.**
- Preservar **D-226/D-218** (todas as possibilidades previstas e índices reservados ao declarar ataque) e **D-222** (índices de ocorrências canceladas/não executadas **não são reutilizados nem provocam renumeração na mesma declaração**). Preservar D-214/D-192/D-189 para ordenação e consumo de RNG de retarget somente quando há sorteio efetivo e elegível.
- **Exemplo hipotético e não um Move concreto:** uma habilidade futura pode produzir de zero a três ocorrências condicionais; **se** sua ficha aprovar máximo três, o plano reserva posições de todas as três ocorrências na declaração, sem disparar eventos ou consumir RNG por ocorrências que não acontecerem. **O número três não foi aprovado para nenhum Move real.**

## Pendências e limites

- **A exigência de plano completo não determina por si só o comportamento do runtime para Moves sem máximo** (bloquear seleção, lançar aviso, impedir salvar ficha etc.). O bloqueio pré-confirmação da D-225 refere-se à incompatibilidade de status sem prioridade; **não o estender automaticamente a esta nova causa de incompletude**.
- Não foram definidos máximos numéricos, formato do plano, política para exceder um limite, manipulação de eventos novos não previstos, fonte de regras condicionais ou formato de replay.
- Somente documentação; nenhum código, teste, ficha, IA, Move, cena, asset ou VFX modificado.
