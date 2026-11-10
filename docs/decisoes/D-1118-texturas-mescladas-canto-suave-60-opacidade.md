# D-1118 — Texturas mais mescladas entre si, canto suave e 60% de opacidade

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / paredes.
- **Relacionadas:** D-1116 (paliçada + 5 variações), D-1117 (textura mais escura e 5 m/tile), D-1028 (toon), D-1083 (luz baixa).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> deixa as texturas mais mescladas uma com a outra e reduza a opacidade delas mais 15%

Respostas da rodada:

> as 3 opções

> 15 pontos: 75% → 60%

## Regra

1. **Variações mais parecidas:** as 6 texturas (base + V1..V5) são misturadas **20%** com a média delas, com **contraste 1,25** e **ganho 1,35** para a paliçada não sumir no escuro.
2. **Transição suave no canto:** um shader faz **crossfade espacial** entre as duas texturas que se encontram, numa largura de **2,0 m**; no canto exato, as duas paredes mostram **50% de cada** textura, então a emenda deixa de ser um corte seco.
3. **Mais misturadas com a cor da parede:** a textura entra a **60%** sobre **40%** da cor antiga (`0.075, 0.145, 0.135`). A parede continua **opaca**.
4. **Escurecimento mantido:** a textura continua **20% mais escura** (×0,80) e o tile continua **5 m**.
5. **O que não muda:** a distribuição sorteada de uma textura por parede, o piso, pilares, NPCs, HUD, câmera, combate e 2D.

## Implementação

- `tools/build_wall_textures.py`: mantém ×0,80; remove a mistura de 25% para o shader controlar a opacidade; mistura as 6 com a média (20%), contraste 1,25 e ganho 1,35.
- `shaders/wall_palisade_blend.gdshader`: triplanar, crossfade de 2,0 m nos cantos, 60% textura + 40% cor antiga, toon.
- `scripts/debug/murky_forest_3d_lab.gd`: materiais das 6 paredes viram `ShaderMaterial` com textura própria + 2 vizinhas e os cantos.

## Provas

- `docs/referencias/exploracao/3d/wall_textures_palisade_6_sheet.png` — as 6 texturas mais próximas entre si.
- `docs/referencias/exploracao/3d/d1118_walls_start.png` — início.
- `docs/referencias/exploracao/3d/d1118_walls_corridor.png` — parede de perto.
- `docs/referencias/exploracao/3d/d1118_walls_far.png` — parede do fundo.
- `docs/referencias/exploracao/3d/d1118_walls_end.png` — parede leste.
- `docs/referencias/exploracao/3d/d1118_walls_contact.png` — as quatro vistas em 2×2.
- `docs/referencias/exploracao/3d/d1118_walls_random.mp4` / `.gif` — 7 s pelas vistas.

## O que foi verificado

- As 6 texturas foram misturadas **20%** com a média, com contraste 1,25 e ganho 1,35; as palettes ficaram mais próximas sem a paliçada sumir.
- O shader entrega **60% de textura + 40% da cor antiga**; a parede continua opaca.
- O crossfade de canto foi verificado com um diagnóstico de **100% e 5 m** de largura: no canto exato as duas paredes mostram a mesma mistura 50/50. No look final de 60% ele fica **sutil**, como esperado.
- As 6 paredes continuam com uma textura cada, sem repetição, em ordem sorteada (`walls=6 unique=6`).
- Piso, pilares, NPCs, HUD, câmera, combate e 2D não mudaram.

## O que não foi verificado

- Todos os cantos no look final de 60% (o crossfade é sutil e o lab é escuro).
- As 720 permutações, outras resoluções/aspectos e o custo do shader.
- Se o ponto final ficou escuro demais; o ganho (1,35) e a força (0,60) podem ser ajustados um por vez.

## Estado

Implementado e provado. Commit local; **sem push**.
