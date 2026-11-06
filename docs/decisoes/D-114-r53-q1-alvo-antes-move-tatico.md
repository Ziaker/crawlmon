# D-114 — Rodada 53, Q1: alvo aleatório antes da escolha tática do Move

- **Data:** 2026-11-03
- **Origem:** o criador aceitou as recomendações do assistente sobre como a IA deve agir, mas **não selecionou a letra de cada alternativa**. O assistente recomendou **1A** após consultar código e decisões existentes.
- **Estado:** recomendação do assistente aceita por delegação expressa; decisão de design documentada, **não implementada**.

## Declaração literal do criador

> sigo suas recomendacoes quanto a forma que a IA deve agir, ate mesmo para as proximas perguntas

## Pergunta e recomendação aceita (redação do assistente, não do criador)

- **R53-Q1:** Em qual ordem a IA escolhe o alvo e o Move?
- **Recomendação do assistente: 1A —** Sortear primeiro o inimigo-alvo, respeitando engajamento. Depois escolher o Move mais adequado contra ele.

## Regra consolidada

- Quando a IA for agir ofensivamente, **primeiro seleciona o alvo** conforme D-111: aleatório entre adversários vivos elegíveis, exceto que um engajamento ativo restringe ao alvo engajado.
- **Depois escolhe o Move taticamente** para o alvo já definido, considerando dano, fraquezas elementais, efeitos e situação do combate (D-112).
- Essa ordem **não autoriza** escolher o adversário mais fraco nem mudar o sorteio do alvo para favorecer o dano. Escolha de alvo e escolha de Move são sistemas distintos.
- A regra se aplica a aliados e inimigos controlados por IA (D-021). Preservar Tactics, custos, opções de Moves disponíveis e demais restrições.

## Fonte e limites

- Em `scripts/combat/battle.gd`, `_run_ai()` chama atualmente `_pick_skill()` **antes** de selecionar o alvo determinístico `_first_alive(foes)` ou engajado. A nova ordem aprovada **diverge do código existente**; nenhum código foi modificado.
- Não foram definidos pesos de pontuação, fórmulas, desempates ou escolha de Move para situações específicas.
- **Escopo:** somente documentação.

## Complemento posterior (2026-11-03)

**D-911:** implementado em `scripts/combat/battle_ai.gd`.
