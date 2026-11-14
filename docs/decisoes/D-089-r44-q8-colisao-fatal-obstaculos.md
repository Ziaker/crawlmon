<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
