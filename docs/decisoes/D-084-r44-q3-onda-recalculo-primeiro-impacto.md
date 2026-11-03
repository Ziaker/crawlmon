# D-084 — R44-Q3 (3A): Recalcular previsão do primeiro impacto com alvos móveis

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Se um alvo se mover e mudar qual seria o primeiro impacto da onda?
- **Escolha:** **3A — Recalcular continuamente a previsão e manter uma única janela global de Evade perfeito.**

## Regra aprovada por delegação

Enquanto os alvos da onda AoE mudam de posição, recalcular continuamente a **previsão do primeiro impacto** para temporizar o Evade perfeito, respeitando posições atuais, velocidade espacial constante e **uma única janela compartilhada** de 0,22 s para toda a onda. Não criar janelas independentes por alvo.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-057; D-059; D-066; D-067; D-075; D-083.
- **Pendência:** Se a previsão mudar durante a própria janela ou depois que ela terminar, ainda é necessário fixar o tratamento de reabertura/encurtamento; esta decisão não autoriza múltiplas janelas. A regra de morte do primeiro alvo está em D-083.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
