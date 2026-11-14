<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1017 — Drain Spear: disparo 0,20 s depois do prelúdio

- **Data:** 2026-11-09.

## Frase literal do criador

> eu não gosto como o disparo está ocorrendo no prelude do ataque, é pra ser depois do prelude, talvez .20s depois, quando a animação do orc por exemplo,ainda tiver na pose de preparacao pro stok

## Decisão

O prelúdio é a lança deitando (0,2 s no início do golpe). O disparo (estocada + coroa) começa **0,20 s depois** dele (0,4 s após o início do golpe), com o atacante ainda na pose de preparação, e cresce até o contato.

## Ambiguidade

- "Prelúdio" lido como a lança deitando (D-1016). Se for outro trecho da animação, ajustar.

## Estado

Implementado para revisão.

## D-1018 (adendo)

> inclusive a lança não está visivel em ambas visões durante seu wind up e trajeto da corrida do personagem. é pra estar na frente dele

A lança em pé fica ao lado da silhueta, do lado da tela, além da largura do corpo e um pouco à frente: o corpo não a esconde em nenhuma vista.
