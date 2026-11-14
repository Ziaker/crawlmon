<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1007 — A IA desvia num momento aleatório do wind-up ao contato

- **Data:** 2026-11-08.

## Frase literal do criador

> corrige as ações da IA

Resposta: **"Momento aleatório"**.

## Decisão

Com o dodge liberado do wind-up ao contato (D-1006), o alvo controlado pela IA que vai desviar (mesma chance de antes, pela SPD) sorteia **um único instante** entre o início do wind-up e o contato e tenta o Evade ali. A espera antiga pela janela do prelúdio (D-988) foi removida.

## Estado

Implementado.
