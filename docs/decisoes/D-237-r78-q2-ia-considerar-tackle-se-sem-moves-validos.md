# D-237 — Rodada 78 Q2 (2A): IA pode considerar Tackle separadamente se não houver Move válido

- **Data:** 2026-11-04.
- **Área:** Combate / seleção tática da IA / Tackle / validação.
- **Origem:** resposta expressa do criador na Rodada 78.
- **Estado:** regra condicional aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 2A — Se nenhum Move da lista for válido, permitir à IA considerar Tackle separadamente, desde que esteja elegível; caso contrário, deixar a reação pendente de outra regra.

## Regra aprovada

- Depois de **excluir Moves incompletos da lista de candidatos antes da decisão tática** (D-232), **se não restar nenhum Move válido**, **permitir à IA considerar Tackle como ação separada**, **somente quando Tackle estiver elegível** de acordo com suas regras vigentes.
- **Permitir considerar não obriga escolher nem executar automaticamente Tackle:** não substituir Moves inválidos individualmente por Tackle, não tornar Tackle válido por presunção e não alterar seus requisitos ou custos.
- Se **Tackle também não estiver elegível**, **a reação da IA permanece pendente de outra regra aprovada**. Não presumir espera, perda da ação, seleção aleatória, retorno de Move inválido ou cobrança de recursos.
- **Exemplo didático:** todos os quatro Moves de um atacante controlado pela IA estão bloqueados porque não possuem prioridade obrigatória entre status declarados incompatíveis. Se **Tackle estiver elegível**, a IA poderá considerá-lo separadamente. Se Tackle não estiver elegível, **esta decisão não escolhe o próximo comportamento**.
- Preservar **D-215/D-217/D-221/D-225/D-232**: Moves incompletos por incompatibilidade sem prioridade ficam excluídos e **sua exclusão não debita ATB, Burst, MP nem a oportunidade de ação**. Para Tackle efetivamente escolhido, continuam valendo exclusivamente as regras de consumo e confirmação já aprovadas para **essa ação válida**.

## Pendências e limites

- Não define a reação para ausência simultânea de Move válido e Tackle elegível, nem altera a IA tática com novos pesos, alvos, regras de Tackle ou probabilidades.
- **A situação de plano de ocorrências condicionais incompleto** tem regra de bloqueio própria na D-238; a presente D-237 não decide por si novos filtros de candidatos fora do motivo de incompletude já previsto em D-232.
- Nenhum código, IA, teste, Move, ficha, cena, asset ou VFX alterado.
