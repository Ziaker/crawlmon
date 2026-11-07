# Importação dos assets PMD

Pipeline dos tilesets de dungeon do **Explorers of Sky** (D-345). Ele mede a
folha, gera o atlas, o perfil papel → índice, o manifesto, a folha de contato e
o laboratório de teste. Nenhuma constante de grade é chutada.

## Fonte

- The Spriters Resource — **Pokémon Mystery Dungeon: Explorers of Sky**, seção **Dungeon Tiles**.
- Rip/format: **SilverJaws623**.
- Os 16 PNGs originais ficam em `assets/pmd/dungeons/sky/raw/` e não são importados pelo Godot (`.gdignore`).

## Grade real

A folha **não** é uma grade de 24 px. Cada célula é **1 px de linha ciano + 24×24 de arte**, repetindo a cada **25 px**. A origem da arte é `(9, 163)`. O `pmd_sheet.probe()` detecta isso pelas linhas ciano; se a grade não for 25/24, o build falha.

As 16 folhas compartilham as **primeiras 24 colunas**:

| Bloco | Colunas | Papel |
|---|---|---|
| Legend | 0..2 | máscaras de auto-tile |
| Walls | 3..5, R0..R2 | parede; centro C4 R1 |
| Wall Alt. 1 | 6..8, R0..R2 | parede alternativa |
| Wall Alt. 2 | 9..11, R0..R2 | parede alternativa |
| Ground | 12..14, R0..R2 | chão; centro C13 R1 |
| Ground Alt. 1 | 15..17, R1 | decal de chão; C16 R1 |
| Ground Alt. 2 | 18..20, R1 | decal de chão; C19 R1 |

Depois da coluna 20 a folha varia:

- **691 px / 27 linhas:** Unused Ground 21..23, Water 24..26;
- **813 px / 24 linhas:** Water 21..23, depois a paleta da água;
- **888 px / 27–30 linhas:** Unused Ground 21..23, Water 24..26, nota/paleta à direita.

O pipeline usa **Walls** (núcleo + peças extras), **Ground** e as **Ground Alt. 1/2**; as demais categorias ficam no manifesto.

O bloco 3×3 de Walls é uma **massa de parede**, não um autotile de 9 peças soltas: linha 0 = borda de trás, linha 1 = topo, linha 2 = face frontal; colunas 3/5 = laterais. O preview da folha, casado pixel a pixel, mostra `topo (linha 1) → face (linha 2) → chão`. A seleção no jogo é pela **assinatura de lados abertos medida** (D-354), não pela posição. Abaixo do bloco ficam as peças reais para paredes finas: strip V/H (lados opostos), island (4 lados), tips (3 lados) e cross (interseção). As linhas extras de Ground/Water continuam registradas em `autotile.extras` no manifesto.

## Saídas

Para cada folha:

O atlas tem **18 tiles** de núcleo (Walls 3×3 + Ground 3×3), as **Ground Alt.
1/2** e **8 peças reais de parede**: `wall_strip_v` (C3R4, lados W+E),
`wall_strip_h` (C4R3, N+S), `wall_island` (C4R4, 4 lados), `wall_tip_n/s/w/e`
(C4R6/C4R8/C3R7/C5R7, 3 lados) e `wall_cross` (C4R7). Total: **30 tiles** (os 2 ?ltimos s?o os centros Wall Alt. 1/2, C7R1/C10R1, usados s? como varia??o rara de interior, D-355).
Nenhuma peça é sintética. O atlas 48 px é gerado com **Scale2x 2×** da célula 24×24 (D-357). O perfil mapeia os papéis, a célula de origem
(`role_cells`), a assinatura de lado medida (`role_sides`) e
`side_contract_ok`; o jogo só usa a assinatura quando o contrato está OK.

| Saída | Caminho |
|---|---|
| Atlas núcleo + Ground Alt + extras | `assets/pmd/dungeons/sky/atlas/<nome>_atlas.png` |
| Perfil papel → índice | `assets/pmd/dungeons/sky/atlas/<nome>_profile.json` |
| Manifesto | `tools/pmd_import/manifests/<nome>.json` |
| Folha de contato | `docs/referencias/tilesets/<nome>_contact.png` |
| Atlas rotulado | `docs/referencias/tilesets/<nome>_atlas_labeled.png` |
| Labels / preview | `docs/referencias/tilesets/<nome>_labels.png`, `<nome>_preview.png` |
| Auditoria de componentes | `docs/referencias/tilesets/<nome>_components.png` + `tools/pmd_import/audits/<nome>.json` |

O **perfil** é o que o jogo lê. O `map_visuals.gd` pede a assinatura de lados
abertos (`N/S/W/E`) e o perfil devolve o índice; o campo `atlas` é a fonte da
textura. Trocar o perfil troca o atlas e os papéis juntos.

## Como rodar

```bash
python tools/pmd_import/build_dungeon_atlases.py            # todos os 16
python tools/pmd_import/build_dungeon_atlases.py --only temporal_tower
python tools/pmd_import/build_dungeon_atlases.py --check    # valida sem regravar
python tools/pmd_import/audit_components.py                 # auditoria de percepção
python tools/pmd_import/audit_components.py --only temporal_tower
python tools/pmd_import/audit_components.py --only temporal_tower --approve
Godot_v4.7.2-stable_win64_console.exe --path . scenes/tileset_lab.tscn -- --golden
python tools/pmd_import/check_golden_room.py
python tools/pmd_import/check_occluder_brightness.py --baseline   # uma vez
python tools/pmd_import/check_occluder_brightness.py              # regressão
Godot_v4.7.2-stable_win64_console.exe --path . scratch/capture_tileset_lab.tscn  # 16 biomas
```

O `--only` não reescreve o `manifests/index.json` global (para não apagar os
outros 15). O `--approve` grava `audits/<folha>_approved.json` com o hash da
fonte e o mapa de componentes; é o gate humano. O build **avisa** quando a
folha ativa não tem aprovação ou quando ela ficou velha.

## Validação

O build falha se:

- as linhas ciano não formarem a grade 25/24;
- um dos 9 tiles de Walls/Ground estiver vazio;
- o atlas não tiver 30 tiles de 48 px;
- um tile contiver ciano/teal (linha ou fundo da folha);
- o perfil não tiver todos os papéis;
- o hash do atlas ou da fonte mudar no `--check`;
- na **folha ativa**, o lado medido de um papel não bater com o contrato de face.

O build **avisa** (não falha) quando:

- dois tiles são idênticos — legítimo em arte uniforme;
- o tile central não se repete perfeitamente (L/R, T/B). Os blocos 3×3 são
  **conjuntos de borda**, então isso é diagnóstico, não um erro;
- uma folha não ativa tem contrato de face ambíguo (as 12 folhas de arte
  danificada/gélida ficam com `side_contract_ok=false` até revisão);
- a folha ativa ainda não tem aprovação humana.

## Laboratório

`scenes/tileset_lab.tscn` mostra:

- o catálogo dos 30 tiles com os índices;
- uma sala **14×10 embutida numa massa de parede** (o mesmo caso do jogo), com
  piso 6×4, anel de parede e uma **parede fina de 3 tiles** (testa a strip
  horizontal e as duas pontas); câmera 2,3× e 48 px;
- troca de perfil com **←/→**;
- overlay de célula/índice/papel no hover;
- a auditoria do terrain (side/corner).

O laboratório usa a **assinatura de lado** do perfil e o **piso orgânico**:
92% `ground_c`, 4% `ground_alt_1`, 4% `ground_alt_2`, determinístico por seed.
As Ground Alt são **decals de chão** (flores, árvores, pedras, entulho), não
piso seamless; por isso a proporção baixa. O antigo terrain nativo/blob 47 foi
descartado (D-346/D-347). Para capturar todas as 16:

```bash
Godot_v4.7.2-stable_win64_console.exe --path . scratch/capture_tileset_lab.tscn
```

As imagens vão para `scratch/tilesets/<nome>_catalog.png`, `_room.png` e
`_masks.png` (`scratch/` é ignorado pelo Godot).

## Estado atual

- O atlas ativo é o **Temporal Tower** (`temporal_tower_profile.json`), com 30
  tiles (18 do núcleo + 2 Ground Alt + 8 peças reais de parede + 2 centros Wall
  Alt.).
- Todos os 16 foram gerados com 30 tiles e passaram na validação estrutural.
- O contrato de face passa no Temporal Tower; 12 folhas têm arte ambígua e
  ficam com `side_contract_ok=false`. Para elas o jogo usa o **fallback por
  papel** (strip, island, tips, cross, alt) e o `murky_forest` foi medido com
  688 células e 0 divergências.
- A auditoria de percepção cobre as 16 e grava o preview composto:
  `topo (linha 1) → face (linha 2) → chão`.
- O golden da sala passa (correlação 0,60; 2D 0,61; topo 137,8 > face 83,2;
  chão 48,0) e as máscaras 8-vizinhos têm 19 papéis.
- Os decals de piso ficam em **4%+4% exatos** por andar (8,1% medidos), sem
  pares adjacentes; os centros Wall Alt. aparecem em 9,25% das células
  totalmente interiores.
- O occluder é ciente da face: o centro do piso não escureceu; a massa de
  parede ficou um pouco mais escura (efeito desejado). O
  `check_occluder_brightness.py` guarda a baseline das 10 seeds; ela foi
  regerada após remover as luzes de tocha (D-358).
- A aprovação do Temporal foi **gravada** em 2026-11-06 (30 tiles, 5+5% Wall Alt);
  o build não avisa mais que falta aprovação.
- 16 capturas de sala em `scratch/tilesets/` e **16 no jogo** em
  `scratch/exploration_biomes/` (mesma seed/mapa); contatos em
  `docs/referencias/tilesets/biomes_contact.png` e `biomes_ingame_contact.png`.
  O laboratório também aplica o `AMBIENT` do bioma; a névoa (explorado) só
  existe na cena do jogo.
- O `MapVisuals.setup` é re-entrante (`_clear_visuals`), necessário para o teste
  in-game dos 16 perfis; o jogo chama uma vez.
- O **seletor de bioma** (`scripts/dungeon/biome_selector.gd`) usa o
  `biome_pool.json`: andares 1–4 em Temporal Tower, troca no 5º andar, fallback
  para Temporal Tower.
- O **piso orgânico** usa `Ground Alt. 1/2` em 4%+4% das células de chão
  interiores, com seed do andar; bordas/cantos continuam na máscara de 4
  vizinhos.
- Water ainda não é usada: o bloco Water do Temporal é cinza-escuro e lê como
  o chão; nas folhas de gelo é azul. Exige escolha visual (água azul das folhas
  de gelo, shader ou fora) antes de virar sistema de mapa (D-312/D-357). O
  Unused Ground tem um tile isolado e não virou decal.
- Os centros Wall Alt. 1/2 são usados em 10% do interior.
- As tochas e luzes amarelas foram removidas, e D-359 removeu também a luz do
  jogador; a única `PointLight2D` restante é a vermelha dos inimigos. A
  névoa/overlay por bioma fica em `scripts/dungeon/biome_visuals.gd` com 16
  paletas fortes; D-360 deu à névoa duas cores laterais e ruído/scale próprios
  por bioma (D-358/D-359/D-360).
- O terrain nativo/blob 47 foi descartado; o jogo usa o renderer manual
  aprovado.
- Nada foi commitado ou publicado.
