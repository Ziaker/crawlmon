# D-1116 — Paliçada de raízes + 5 variações nas paredes, em ordem aleatória

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / paredes.
- **Relacionadas:** D-1022 (direção 3D), D-1028 (visual toon), D-1082/D-1083 (luz do lab).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> palicada dd raizes mais 5 variacoes dela pra colocar nas paredes cada uma de forma aleatoria

## Regra

1. **Seis texturas da mesma família:** a paliçada de raízes atual + **5 variações** dela. As variações mudam a quantidade/largura das tábuas, as amarrações de cipó, a quantidade de musgo, os nós e o tom (quente/frio/verde), sem deixar de serem paliçadas.
2. **Uma por parede:** o lab tem **6 caixas de parede**; cada uma recebe **uma** das 6 texturas, **sem repetição**, em ordem **sorteada** a cada carregamento do lab.
3. **Aplicação:** material toon (`DIFFUSE_TOON`/`SPECULAR_TOON`), textura com **triplanar** para não esticar nas faces do `BoxMesh`, escala de **~2 m por tile**.
4. **O que não muda:** piso, pilares/troncos, NPCs, HUD/status, cards, câmera, combate, 2D e regras. A colisão das paredes continua igual.

## Interpretação registrada

- "cada uma de forma aleatória" foi lido como **permutação sorteada**: como são 6 paredes e 6 texturas e o criador disse "cada uma", todas aparecem uma vez, em ordem aleatória. Se ele queria sorteio independente (com repetição e alguma textura fora), é só ajustar.

## Implementação

- `tools/build_wall_textures.py`: `root_palisade()` parametrizada; gera `murky_wall_root_palisade.png` + `_v1.._v5`.
- `scripts/debug/murky_forest_3d_lab.gd`: materiais das 6 paredes sorteados em `_build_room()`.

## Provas

- `docs/referencias/exploracao/3d/wall_textures_palisade_6_sheet.png` — as 6 texturas e o 2×2 emendado.
- `docs/referencias/exploracao/3d/d1116_walls_start.png` — início, com duas paredes e o fundo.
- `docs/referencias/exploracao/3d/d1116_walls_corridor.png` — parede oeste de perto.
- `docs/referencias/exploracao/3d/d1116_walls_far.png` — parede do fundo.
- `docs/referencias/exploracao/3d/d1116_walls_end.png` — parede leste, junto da saída.
- `docs/referencias/exploracao/3d/d1116_walls_contact.png` — as quatro vistas em 2×2.
- `docs/referencias/exploracao/3d/d1116_walls_random.mp4` / `.gif` — 6,7 s caminhando pelas quatro vistas.

## O que foi verificado

- As 6 texturas são distintas e emendam; a diferença média das bordas ficou entre **2,2 e 5,4** (em 255) e o 2×2 não mostra costura.
- O lab tem **6 paredes**; cada uma recebeu **uma** textura, com `walls=6 unique=6` no log.
- Duas execuções tiveram ordens diferentes (por exemplo, `v1, v5, v4, v3, v2, base` e `v2, v1, v3, v5, base, v4`), provando o sorteio.
- Em jogo, a escala de **4 m por tile** deixa as tábuas, as frestas e os cipós legíveis sob a luz toon; a versão inicial de 2 m lia como ruído fino e foi trocada.
- Piso, pilares, NPCs, HUD, câmera, combate e 2D não foram alterados.

## O que não foi verificado

- Todas as **720 permutações** possíveis; só algumas foram vistas em jogo.
- Outras resoluções/aspectos e o custo de 6 materiais com triplanar em placas fracas.
- Se as variações mais verdes (V1/V4) ficaram mossy demais para o gosto do criador.
- As texturas são 1024×1024 sem mapas de normal/roughness; não há PBR.

## Estado

Implementado e provado. Commit local; **sem push**.
