<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-087 — R44-Q6 (6A): Duração global configurável do lançamento fatal

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Como definir a duração do lançamento fatal?
- **Escolha:** **6A — Uma duração global configurável, igual para todos os personagens.**

## Regra aprovada por delegação

A sequência de **lançamento fatal** utiliza uma **duração global configurável**, aplicada igualmente a todos os personagens, preservando a intensidade padronizada entre Moves. A duração é um parâmetro visual compartilhado; não modificar HP, posições lógicas ou condições de derrota por essa decisão.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-045; D-056; D-068; D-069; D-079; D-081.
- **Pendência:** O valor numérico ainda não foi escolhido. Colisões com obstáculos podem interromper o voo conforme D-089, sem implicar que a duração global seja ignorada em outros cenários.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
