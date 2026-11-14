<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1021 — Badge Steal: círculo que abre 0,35 s, estilhaços em flipbook que voltam ao atacante

- **Data:** 2026-11-09.

## Frase literal do criador

> essas faixas são mt genéricas, além que de na sua nascença elas deviam se espalhar de forma círcular, se expandindo por .35 segundos antes de começar a ir até o jogador, pode usar o motion composer e flipbooks de shaders pra melhorar ela

## Decisão

1. 24 estilhaços nascem em **círculo** em volta do contato (plano voltado para o atacante) e o círculo se expande e gira por **0,35 s**.
2. Depois cada estilhaço faz a curva e acelera até o atacante (0,40–0,60 s, escalonado).
3. Cada estilhaço é um **flipbook animado** (folha "lightning", ciano) com rastro curto.
4. Motion Composer não usado nesta versão (efeito feito à mão com flipbook); registrado por D-308.

## Estado

Implementado para revisão.
