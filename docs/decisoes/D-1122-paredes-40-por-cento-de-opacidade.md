<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1122 — Paredes com 40% de opacidade

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / paredes.
- **Relacionadas:** D-1118 (60% de opacidade e crossfade), D-1117, D-1116.
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> reduz pra 40% da opacidade

## Regra

1. O shader das paredes passa de **60% para 40%** de textura: **40% textura + 60% da cor antiga** (`0.075, 0.145, 0.135`).
2. A parede continua **opaca**; não é transparência literal.
3. O resto da D-1118 não muda: mistura de 20% com a média, contraste 1,25, ganho 1,35, crossfade de 2 m nos cantos, textura 20% mais escura, tile de 5 m e uma textura sorteada por parede.

## Implementação

- `scripts/debug/murky_forest_3d_lab.gd`: `strength` de `0.60` para `0.40`.

## Provas

- `docs/referencias/exploracao/3d/d1122_walls_start.png` — início.
- `docs/referencias/exploracao/3d/d1122_walls_corridor.png` — parede de perto.
- `docs/referencias/exploracao/3d/d1122_walls_far.png` — parede do fundo.
- `docs/referencias/exploracao/3d/d1122_walls_end.png` — parede leste.
- `docs/referencias/exploracao/3d/d1122_walls_contact.png` — as quatro vistas em 2×2.
- `docs/referencias/exploracao/3d/d1122_walls_random.mp4` / `.gif` — 7 s pelas vistas.

## O que foi verificado

- O shader passa **40% de textura + 60% da cor antiga**; a parede continua opaca.
- As 6 paredes continuam com uma textura cada, sem repetição, em ordem sorteada (`walls=6 unique=6`).
- O resto da D-1118 (mistura 20%, contraste/ganho, crossfade de 2 m, tile de 5 m) não mudou.
- Piso, pilares, NPCs, HUD, câmera, combate e 2D não mudaram.

## O que não foi verificado

- Se 40% ficou escuro demais; o ganho 1,35 da textura pode ser ajustado depois, mas não foi mexido nesta rodada.
- Todos os cantos no look final, as 720 permutações, outras resoluções/aspectos e o custo do shader.

## Estado

Implementado e provado. Commit local; **sem push**.
