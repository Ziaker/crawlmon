# D-134 — Rodada 55 Q3 (A): LUK só afeta aplicação de status declarada como probabilística na ficha do Move

- **Data:** 2026-11-03
- **Área:** Atributos e progressão de Pokémon / Rodada 55.
- **Proveniência:** escolha **expressamente enviada pelo criador**, aceitando alternativa recomendada previamente pelo assistente; a decisão foi escolhida pelo criador, não deduzida de delegação à IA.
- **Estado:** decisão de design aprovada e registrada; **não implementada nesta atividade**.

## Declaração literal do criador

> 3A — Como Luck influencia a aplicação de status? LUK modifica apenas efeitos cuja ficha declare chance de aplicação; efeitos garantidos continuam garantidos. (recomendação aceita)

## Regra aprovada e compatibilidade

- A influência de **Luck (LUK)** na **aplicação de efeitos de status** ocorre **somente para efeitos cuja ficha do Move declare expressamente uma chance de aplicação**.
- Efeitos declarados **garantidos** continuam garantidos no que diz respeito à **rolagem de aplicação**: não acrescentar chance de falha por LUK quando não existe chance de aplicação definida para aquele efeito.
- Preservar **D-127**: LUK continua influenciando crítico e esquiva automática, além de aplicações probabilísticas de status. Esta escolha **não define** fórmulas de probabilidade dessas outras funções.
- Preservar **D-012**: o fato de um Move de debuff de alvo único **não poder ser desviado** é distinto de a ficha declarar uma rolagem de aplicação para um de seus efeitos; não criar Evade para esses Moves.
- **Pendências:** probabilidades-base, efeito de LUK do lançador ou do alvo, lista concreta de Moves probabilísticos e como outras regras de imunidade/proteção poderiam interagir; não presumir resistência a status ou classificações adicionais.
- **Exemplo ilustrativo:** um futuro efeito com chance de Poison poderia ser modificado por LUK; Rakunda, se definido como garantido, não ganharia uma rolagem por esta decisão.

## Estado de execução

- **Documentação somente:** não alterar código, cenas, tabelas, fichas de Moves, VFX, testes ou configurações do projeto.
- As fórmulas e dados marcados como pendentes não podem ser completados por suposição.
