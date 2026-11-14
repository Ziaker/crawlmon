<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-019 — Lógica e visual numa só linha do tempo; o visual só desenha

- **Data:** 2026-11-02
- **Área:** Arquitetura
- **Origem:** PROMPT

## O que o criador disse (literal)

> Lógica e visual andam numa só linha do tempo, perfeitamente sincronizadas. A lógica é a única dona do estado e do relógio de cada ataque; o visual apenas desenha esse estado.

## Decisão

A lógica (`battle.gd`) é a única dona do estado e do relógio do ataque; o visual (`battle_fx.gd`, `fx/*`) só desenha. Proibido o visual ter temporizador/tween próprio que decida **quando** algo acontece. Pausa e câmera lenta valem para os dois.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Em vigor (Fase 1; a Fase 2 foi revertida, D-025).

> **D-1040 (2026-11-09):** decisão **renovada** pelo criador após a divergência A2 da `AUDITORIA_PROIBICOES.md` ("renova"). Vale de novo como regra.
