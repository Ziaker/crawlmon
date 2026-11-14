<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-088 — R44-Q7 (7A): Trajetória fatal em arco aéreo exagerado

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Qual deve ser o formato visual da trajetória do lançamento fatal?
- **Escolha:** **7A — Arco aéreo exagerado: sobe, percorre a distância e cai.**

## Regra aprovada por delegação

O personagem atingido fatalmente segue uma trajetória visual de **arco aéreo exagerado**: sobe, desloca-se para longe de quem o atingiu e cai no chão. Preservar a intensidade e a duração compartilhadas; inimigos posteriormente desaparecem, enquanto aliados permanecem no chão.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-056; D-068; D-069; D-079; D-080; D-087.
- **Pendência:** Altura, distância, curva exata de interpolação e detalhes do impacto no solo ainda não possuem valores aprovados.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
