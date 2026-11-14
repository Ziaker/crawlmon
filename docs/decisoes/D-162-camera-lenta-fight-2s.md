<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-162 — Câmera lenta de decisão: 2 s no Fight; Itens continua com 3 s

- **Data:** 2026-11-03
- **Área:** Combate / UI / Game Feel
- **Origem:** Conversa

## O que o criador disse (literal)

> reduza o timer de camera lenta ao selecionar fight pra 2 segundos ao invés de 3

Pergunta: vale para qual menu? Resposta: "Só Fight".

## Decisão

Ao abrir **Fight**, a câmera lenta de decisão dura **2 s** reais. Em **Itens** continua **3 s**. O resto de D-047 não muda: 0,2x, uso único por ação, fim ao confirmar ou cancelar.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Implementado (`battle_scene.gd`).
