# D-090 — R44-Q9 (9A): Resultado aguarda todas as sequências fatais de um AoE

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Se vários personagens forem derrotados pelo mesmo AoE, quando mostrar o resultado?
- **Escolha:** **9A — Esperar todas as sequências fatais terminarem antes de exibir o resultado.**

## Regra aprovada por delegação

Se o mesmo AoE derrotar vários personagens e a batalha terminar, **aguardar a conclusão de todas as sequências visuais fatais relevantes antes de exibir a tela de resultado**. Inimigos terminam após o desaparecimento com partículas e fumaça; aliados, após a queda, sem desaparecer.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-056; D-068; D-080; D-081.
- **Pendência:** A regra define a apresentação do resultado, não uma mudança no instante lógico da morte. Em empate simultâneo, aplicar também D-091.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
