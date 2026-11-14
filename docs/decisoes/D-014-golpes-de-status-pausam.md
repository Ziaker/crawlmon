<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-014 — Golpes de status pausam o jogo durante a ativação

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> moves de status pausam o jogo durante suas ativações, pausando ATBs e preparações, elas continuam após a conclusão do efeito visual do move

## Decisão

Durante a **ativação** de um golpe de status o jogo fica **pausado**: ATBs e preparações param e **continuam depois que o efeito visual do golpe termina**.

## Ambiguidades em aberto (perguntar antes de agir)

Pausa a partir de quando (aplicação do efeito ou desde a preparação)? Pausa também câmera/efeitos de outros ataques ou só a lógica? Perguntado, sem resposta.

## Estado no código

**Não implementado.**
