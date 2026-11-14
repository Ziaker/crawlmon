<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-275 — Overworld 2D com referência visual da arena

- **Área** — Exploração / visual
- **Estado** — Direção visual definida pelo criador.

## O que o criador disse

> quero que comece a trabalhar no overworld, dê um overhaul visual completo a ele pra ser mais parecido com o visual que é no combate 3D pois é este o visual que estaremos utilizando durante a aventura por ora, seja ambicioso mas não mescle visuais 2D sprite com visuais 2D desenhados, se for preciso redesenhar cada tile então faça

> EU MANDEI VC SÓ USAR DE REFERÊNCIA, NÃO É PRA DEIXAR O VOERWORLD 3D, MEU DEUS

## Decisão

O overworld permanece 2D. O combate 3D é referência visual. Cenário e sprites devem ter uma linguagem visual coerente, com liberdade para refazer os tiles. A iluminação e a visibilidade das áreas exploradas seguem a D-033.

## Ambiguidades

A paleta, a textura dos materiais e a composição dos tiles são escolhas de implementação da direção visual.
