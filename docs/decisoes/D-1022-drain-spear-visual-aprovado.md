<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1022 — Drain Spear: visual aprovado (por ora)

- **Data:** 2026-11-09.

## Frase literal do criador

> perfeito, por ora imagino que o move esteja pronto

## Decisão

O Drain Spear está aprovado no estado de D-1014 a D-1021: passo curto, antecipação e espera de 0,75 s, lança em pé ao lado do atacante que só deita no prelúdio, disparo 0,2 s após o prelúdio, contato no tempo do clipe, coroa que se separa (−25%), sem aviso Dread, Badge Steal em círculo de estilhaços em flipbook.

## Estado

Aprovado. Nada commitado.
