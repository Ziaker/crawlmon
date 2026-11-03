# D-127 — Rodada 54 Q8 (C): Sorte modifica crítico, esquiva automática e aplicação de status

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 8C — Sorte modifica críticos, esquiva automática e aplicação de efeitos de status.

## Regra aprovada

- **Sorte influencia três classes de probabilidades:** (1) crítico normal, (2) esquiva automática e (3) aplicação de efeitos de status.
- **D-005 era fixa em 10% para todos os alvos** como valor histórico e ainda é o comportamento atual do código. A decisão mais recente acrescenta variação com Sorte e, portanto, **substitui a universalidade da chance fixa**, sem escolher a nova fórmula ou a chance efetiva de cada Pokémon.
- **D-012 preservada:** não ser possível desviar de debuffs de alvo único é distinto de existir uma probabilidade de aplicação de efeito de status; não introduzir uma nova possibilidade de Evade manual nesses Moves.
- A existência de Sorte não transforma automaticamente todos os efeitos hoje garantidos em tentativas probabilísticas; deve-se definir, por Move/efeito, quando se aplica uma rolagem de status.
- A chance de reação/evade da IA durante trajetos (D-021) é separada da esquiva automática (D-005). Esta decisão não modifica silenciosamente essa reação.

## Referências, pendências e limitação

- **Referências:** D-005; D-012; D-021; GDD R11-Q5; Battle.gd.
- **Ainda não definido:** Curva e limites de Sorte, função de chance básica de crítico/esquiva, quais status rolam aplicação, valores e resistência, simultaneidade com efeitos garantidos; compatibilidade de D-005 delimitada.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.

## Complemento posterior — Rodada 55 (2026-11-03)

A decisão posterior **D-134 (R55-Q3, 3A)** delimita **Luck (LUK) na aplicação de status**: somente **efeitos cuja ficha do Move declare uma chance de aplicação** sofrem influência de LUK. **Efeitos garantidos permanecem garantidos**, sem rolagem adicional criada por essa regra. Não alterar D-012 (Moves de status não esquiváveis) nem a influência de LUK sobre crítico e esquiva automática, também aprovada nesta D-127.
