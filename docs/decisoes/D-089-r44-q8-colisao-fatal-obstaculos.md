# D-089 — R44-Q8 (8A): Colisão fatal interrompe o voo e causa queda

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** O que acontece se o personagem lançado fatalmente atingir uma parede ou obstáculo?
- **Escolha:** **8A — Interromper o voo na colisão e fazer o personagem cair no local.**

## Regra aprovada por delegação

Se o personagem visualmente lançado por hit fatal atingir uma **parede ou obstáculo durante o voo**, **interromper o deslocamento aéreo na colisão e fazê-lo cair naquele local**. Preservar a sequência final: desaparecimento do inimigo após a queda ou permanência do aliado.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-056; D-068; D-079; D-087; D-088.
- **Pendência:** A resposta não define stagger, ricochete, dano adicional, destruição de obstáculos ou deslocamento de posição lógica. Tais efeitos não são autorizados.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
