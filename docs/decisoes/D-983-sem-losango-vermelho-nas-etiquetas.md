<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-983 — Sem o losango vermelho embaixo das etiquetas dos inimigos

- **Data:** 2026-11-08.

## Frase literal do criador

> o que são estes prismas vermelhos? pode remover eles também?

## Decisão

Removido o losango vermelho (marcador de alvo: cheio no alvo selecionado, contorno nos outros) desenhado embaixo de cada etiqueta de inimigo. O alvo selecionado continua indicado pelo fundo claro da etiqueta. As linhas verticais rosadas vistas atrás deles não são da HUD (cenário) e não foram mexidas.

## Estado

Implementado.
