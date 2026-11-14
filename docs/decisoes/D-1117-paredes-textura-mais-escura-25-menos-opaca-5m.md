<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1117 — Paredes com textura mais escura, 25% menos opaca e 5 m por tile

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / paredes.
- **Relacionadas:** D-1116 (paliçada + 5 variações), D-1028 (toon), D-1083 (luz baixa).
- **Status:** **implementado/provado**; commit local; **sem push**.
- **Nota D-1118 (2026-11-10):** o visual foi ajustado de novo: texturas **20% misturadas com a média**, **60% de textura + 40% cor antiga**, crossfade de **2 m** nos cantos e ganho 1,35. Os valores atuais são os da D-1118.

## O que o criador disse (literal)

> reduza a opacidade dessas texturas e deixe elas um pouco maiores
>
> mais escuras também

Resposta da rodada:

> escurecer a textura e reduzir a opacidade em 25%

## Regra

1. **Escurecer a textura:** multiplicar a paliçada por **0,80** (20% mais escura) antes de aplicar.
2. **Opacidade 25% menor:** a textura entra a **75%** sobre a **cor antiga da parede** (`0.075, 0.145, 0.135`), que fica com os 25% restantes. A parede continua **opaca**; não é transparência literal.
3. **Um pouco maiores:** o tile passa de **4 m** para **5 m** (`uv1_scale` de `0.25` para `0.20`), deixando tábuas e cipós ~25% maiores.
4. **O que não muda:** as 6 texturas (base + V1..V5), o sorteio de uma por parede, o toon/triplanar, o piso, pilares, NPCs, HUD, câmera, combate e 2D.

## Interpretação registrada

- "reduzir a opacidade em 25%" foi aplicado como **75% de textura + 25% da cor antiga**, com a parede opaca. Se o criador queria transparência literal (ver através), é outro ajuste.
- "um pouco maiores" foi aplicado como **4 m → 5 m** por tile.

## Implementação

- `tools/build_wall_textures.py`: `root_palisade()` escurece 20% e mistura 25% da cor antiga antes de salvar.
- `scripts/debug/murky_forest_3d_lab.gd`: `uv1_scale = Vector3(0.20, 0.20, 0.20)`.

## Provas

- `docs/referencias/exploracao/3d/wall_textures_palisade_6_sheet.png` — as 6 texturas escuras e o 2×2 emendado.
- `docs/referencias/exploracao/3d/d1117_walls_start.png` — início.
- `docs/referencias/exploracao/3d/d1117_walls_corridor.png` — parede de perto.
- `docs/referencias/exploracao/3d/d1117_walls_far.png` — parede do fundo.
- `docs/referencias/exploracao/3d/d1117_walls_end.png` — parede leste.
- `docs/referencias/exploracao/3d/d1117_walls_contact.png` — as quatro vistas em 2×2.
- `docs/referencias/exploracao/3d/d1117_walls_random.mp4` / `.gif` — 6,7 s pelas vistas.

## O que foi verificado

- A textura foi multiplicada por **0,80** e misturada com **25%** da cor antiga da parede; o resultado ficou visivelmente mais escuro e integrado ao lab.
- O tile passou de **4 m** para **5 m**; as tábuas e os cipós ficaram ~25% maiores.
- As 6 paredes continuam com **uma textura cada, sem repetição**, em ordem sorteada (`walls=6 unique=6`).
- A parede continua **opaca**; não há transparência literal.
- Piso, pilares, NPCs, HUD, câmera, combate e 2D não mudaram.

## O que não foi verificado

- Se o ponto final (20% mais escura + 25% de mistura) agradou ou ficou escuro demais; pode ser ajustado em um parâmetro.
- As 720 permutações, outras resoluções/aspectos e o custo dos 6 materiais.
- As texturas continuam 1024×1024 sem normal/roughness (não são PBR).

## Estado

Implementado e provado. Commit local; **sem push**.
