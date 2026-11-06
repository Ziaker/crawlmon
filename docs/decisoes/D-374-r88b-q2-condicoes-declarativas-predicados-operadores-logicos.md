# D-374 — Rodada 88B Q2 (2A): condições declarativas tipadas e operadores lógicos

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / condições dos efeitos.
- **Origem:** decisão expressa do criador na Rodada 88B.
- **Estado:** contrato documental aprovado; não implementado.

## Declaração literal do criador

> 2A — Usar condições declarativas tipadas, compostas por predicados reutilizáveis e operadores lógicos explícitos, sem scripts arbitrários na ficha do Move.

## Regra aprovada

- As condições declaradas nos efeitos da ficha são **dados tipados**, compostos por **predicados reutilizáveis** e **operadores lógicos explicitamente representados**.
- **Não utilizar scripts arbitrários nas fichas individuais de Moves** como alternativa à expressão declarativa das condições.
- Preservar D-340/D-361: interpretador genérico de efeitos tipados e ordenados; preservam-se os parâmetros, condições e abrangência dos efeitos efetivamente declarados. Preservar D-260: herança padrão de seleção/facção/abrangência quando não houver exceção expressa.
- **Exemplo somente ilustrativo:** dados referentes a “acerto válido” e “interrupção” poderiam alimentar predicados se sua disponibilidade e combinação fossem aprovadas no contrato aplicável. Não introduzir condições novas ou alterar o Burn já especificado de Fire Bullet.
- A nova representação não altera elegibilidade, chances, prioridades ou **consumo de RNG**, que permanecem regidos pelas decisões vigentes (D-234/D-267 e correlatas). Preservar D-235.

## Pendências e limites

- **Não escolhidos:** catálogo de predicados, assinatura/tipos de seus parâmetros, operadores concretos, avaliação de curto-circuito, momento/ordem de avaliação, tratamento de referências ausentes e formato técnico do Resource. Não criar linguagem de script por inferência.
- Apenas documentação; nenhum código, Resource, Move ou teste modificado.
