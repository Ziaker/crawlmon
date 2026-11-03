# D-085 — R44-Q4 (4B): Onda continua visualmente se todos os alvos morrerem

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Se todos os alvos de uma onda AoE morrerem antes de serem alcançados?
- **Escolha:** **4B — Deixar a onda completar sua propagação visual, mas sem novos danos ou reações.**

## Regra aprovada por delegação

Mesmo que todos os alvos participantes de uma onda AoE morram antes de serem alcançados, a **propagação visual da onda continua até completar sua sequência**. Não aplicar dano adicional, nova reação ou redirecionamento para substitutos.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-007; D-009; D-058; D-077; D-078.
- **Pendência:** A duração visual concreta depende dos dados e da geometria do Move, ainda não totalmente especificados; o término lógico da batalha e a tela de resultado devem respeitar D-081 e as decisões posteriores.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
