# D-217 — Rodada 74 Q2 (2A): ficha incompleta sem prioridade expressa para status incompatíveis

- **Data:** 2026-11-04.
- **Área:** Combate / status / completude de ficha de Move.
- **Origem:** escolha expressa do criador na Rodada 74.
- **Estado:** requisito de especificação aprovado; **não implementado** nesta atividade.

## Declaração literal do criador

> 2A — Considerar incompleta a configuração do Move enquanto faltar prioridade expressa entre status declarados incompatíveis, sem escolher vencedor automaticamente.

## Regra aprovada

- Quando a **ficha de um Move declarar dois status incompatíveis** e **não contiver a prioridade expressa entre eles**, **considerar a configuração do Move incompleta** nesse aspecto.
- **Não eleger automaticamente um status vencedor** usando a ordem de tentativa, ordem alfabética, identificador interno, primeiro/último aplicado ou outro fallback que não tenha sido aprovado.
- Esta regra complementa **D-215**, que exige prioridade expressa na ficha para incompatibilidades declaradas, e **D-213**, que separadamente estabelece a ordem explícita das tentativas de status. **Ordem de tentativa não constitui prioridade de incompatibilidade**.
- **Exemplo abstrato, não declaração de incompatibilidade real:** a ficha hipotética diz `Status A incompatível com Status B`, mas não diz quem tem prioridade. A ficha está **incompleta**; a regra **não decide A ou B**, mesmo que a ficha liste A antes de B.
- Preservar **D-210** (até uma tentativa por status distinto, alvo e execução), D-199/D-207/D-211 (acerto, sobrevivência e impacto próprio), e regras de probabilidades e LUK anteriores. **Nenhum par real de status é declarado incompatível** por esta decisão.

## Limites e pendências

- Esta escolha **não determina o mecanismo do validador** de fichas, quando/como a incompletude será sinalizada no editor ou no runtime, nem se um Move incompleto ficará bloqueado ou apresentará aviso; isso ainda necessita decisão específica.
- Não criar uma prioridade global ou alterar fichas de Moves existentes.
- Documentação somente; nenhum código, teste, ficha de Move, recurso, cena, asset ou VFX modificado.
