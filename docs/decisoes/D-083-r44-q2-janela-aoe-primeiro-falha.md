<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-083 — R44-Q2 (2A): Janela de AoE preservada quando o primeiro impacto falha

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Se o primeiro impacto previsto da onda AoE deixar de acontecer, o que ocorre com a janela perfeita?
- **Escolha:** **2A — Manter a janela baseada no primeiro impacto originalmente previsto, mesmo se o alvo morrer.**

## Regra aprovada por delegação

Se o primeiro impacto previsto de uma onda AoE não chegar a ocorrer, por exemplo devido à morte daquele alvo, a **única janela perfeita compartilhada** continua ligada ao **instante de impacto originalmente previsto**; a morte não desloca o marco temporal para outro alvo. Preservar 0,22 s de duração e ausência de dano/reação em alvos mortos.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-058; D-066; D-075.
- **Pendência:** Se a previsão tiver sido recalculada por movimento dos alvos antes da morte, a interação entre esse recálculo e o registro do instante originalmente previsto precisa de definição de implementação sem inventar uma segunda janela.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
