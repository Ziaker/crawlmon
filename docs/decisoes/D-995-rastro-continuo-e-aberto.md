<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-995 — Rastro do Swing contínuo e aberto

- **Data:** 2026-11-08.

## Frase literal do criador

> o movimento do rastro está desligando e ligando ao invés de seguir como uma animação completa
> nas duas imagens, a forma como vc fez (em vermelho) está erro, o trajeto tem que estar aberto eamplo como na segunda imagem

## Decisão

1. O membro seguido é **travado** assim que escolhido (a troca de mão a cada quadro fazia o rastro piscar).
2. O rastro vira uma **faixa aberta e larga ao longo do caminho da mão** (centrada na mão, abrindo para fora do centro do corpo), não mais a cunha estreita do antebraço que se fechava junto ao corpo.
3. Vale para todos os atacantes com mão (inclui o Abra, que precisa ser reconferido).

## Em aberto

- Parada estranha entre as animações (corrida → pulo/golpe) do Pancham entre 2 e 3 s: a investigar.

## Estado

Implementado para revisão.
