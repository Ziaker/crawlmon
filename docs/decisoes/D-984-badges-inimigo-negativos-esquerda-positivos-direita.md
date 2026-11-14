<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-984 — Badges dos inimigos: negativos à esquerda, positivos à direita

- **Data:** 2026-11-08.

## Frase literal do criador

> para o caso do reposicionamento de badges do inimigo, tem como mover elas pra extrema esquerda ao invés de deixar no meio, as que ficam na orientação extrema direita serão seus buffs e efeitos de status positivos, na esquerda serão seus debuffs e efeitos de status negativos

## Decisão

Acima da etiqueta do inimigo:
- **Extrema esquerda:** debuffs e status negativos (STUN, BURN, BLIND, TAUNT, ATK/DEF/SPD negativos).
- **Extrema direita:** buffs e status positivos (ATK/DEF/SPD positivos, Guard, Invulnerável, Escudo, Imunidade mágica).

## Ambiguidade

- "QUEUE" (move na fila) não é efeito positivo nem negativo; ficou do lado direito, depois dos positivos. Confirmar.

## Estado

Implementado.
