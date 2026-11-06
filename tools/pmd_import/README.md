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
| Ground Alt. 1 | 15..17, R1 | 1 tile (não usado) |
| Ground Alt. 2 | 18..20, R1 | 1 tile (não usado) |

Depois da coluna 20 a folha varia:

- **691 px / 27 linhas:** Unused Ground 21..23, Water 24..26;
- **813 px / 24 linhas:** Water 21..23, depois a paleta da água;
- **888 px / 27–30 linhas:** Unused Ground 21..23, Water 24..26, nota/paleta à direita.

O pipeline usa só **Walls** e **Ground**; as demais categorias ficam no manifesto para os próximos passos.

Cada bloco 3×3 é um **auto-tile de borda**: o centro é o preenchimento e os oito vizinhos são bordas/cantos. As linhas extras de Walls/Ground/Water são registradas em `autotile.extras` no manifesto como referência; só as **Ground Alt. 1/2** entram no atlas (D-347).

## Saídas

Para cada folha:

O atlas tem **18 tiles** de núcleo (Walls 3×3 + Ground 3×3), as **Ground Alt.
1/2** (C16 R1/C19 R1) e as **Wall strips H/V sintetizadas** (bordas de
`wall_t/b/l/r` sobre `wall_c`), totalizando **22** tiles. O perfil mapeia
`ground_alt_1/2` e `wall_strip_h/v`; o jogo usa as alts no piso orgânico
(D-347) e as strips nas paredes de 1 tile (D-348). As strips sintéticas não
têm as juntas das formas do frame.

| Saída | Caminho |
|---|---|
| Atlas núcleo + Ground Alt | `assets/pmd/dungeons/sky/atlas/<nome>_atlas.png` |
| Perfil papel → índice | `assets/pmd/dungeons/sky/atlas/<nome>_profile.json` |
| Manifesto | `tools/pmd_import/manifests/<nome>.json` |
| Folha de contato | `docs/referencias/tilesets/<nome>_contact.png` |
| Atlas rotulado | `docs/referencias/tilesets/<nome>_atlas_labeled.png` |
| Labels / preview | `docs/referencias/tilesets/<nome>_labels.png`, `<nome>_preview.png` |

O **perfil** é o que o jogo lê. O `map_visuals.gd` pede papéis (`wall_tl`,
`ground_c`, …) e o perfil traduz para índices. O campo `atlas` do perfil é a
fonte da textura: trocar o perfil troca o atlas e os papéis juntos.

## Como rodar

```bash
python tools/pmd_import/build_dungeon_atlases.py            # todos os 16
python tools/pmd_import/build_dungeon_atlases.py --only temporal_tower
python tools/pmd_import/build_dungeon_atlases.py --check    # valida sem regravar
```

O `--only` não reescreve o `manifests/index.json` global (para não apagar os
outros 15).

## Validação

O build falha se:

- as linhas ciano não formarem a grade 25/24;
- um dos 9 tiles de Walls/Ground estiver vazio;
- o atlas não tiver 18 tiles de 48 px;
- um tile contiver ciano/teal (linha ou fundo da folha);
- o perfil não tiver todos os papéis;
- o hash do atlas ou da fonte mudar no `--check`.

O build **avisa** (não falha) quando:

- dois tiles são idênticos — legítimo em arte uniforme;
- o tile central não se repete perfeitamente (L/R, T/B). Os blocos 3×3 são
  **conjuntos de borda**, então isso é diagnóstico, não um erro.

## Laboratório

`scenes/tileset_lab.tscn` mostra:

- o catálogo de todos os tiles com os índices;
- uma sala 10×6 no 48 px real e câmera 2,3×, com uma saliência 2×2 (testa os
  quatro cantos de parede);
- troca de perfil com **←/→**;
- a auditoria do terrain (side/corner).

O laboratório usa o **renderer manual de 4 vizinhos** (o mesmo do jogo) e o
**piso orgânico**: 92% `ground_c`, 4% `ground_alt_1`, 4% `ground_alt_2`,
determinístico por seed. As Ground Alt são **decals de chão** (flores, árvores,
pedras, entulho), não piso seamless; por isso a proporção baixa. O antigo
terrain nativo/blob 47 foi descartado (D-346/D-347): a folha tem 9 peças de
borda reais, não 47. Para capturar todas as 16:

```bash
Godot_v4.7.2-stable_win64_console.exe --path . scratch/capture_tileset_lab.tscn
```

As imagens vão para `scratch/tilesets/<nome>_catalog.png` e `_room.png`
(`scratch/` é ignorado pelo Godot).

## Estado atual

- O atlas ativo é o **Temporal Tower** (`temporal_tower_profile.json`), com 22
  tiles (18 do núcleo + `ground_alt_1/2` + `wall_strip_h/v` sintetizadas).
- Todos os 16 foram gerados e passaram na validação.
- O **seletor de bioma** (`scripts/dungeon/biome_selector.gd`) usa o
  `biome_pool.json`: andares 1–4 em Temporal Tower, troca no 5º andar, fallback
  para Temporal Tower.
- O **piso orgânico** usa `Ground Alt. 1/2` em 4%+4% das células de chão
  interiores, com seed do andar; bordas/cantos continuam na máscara de 4
  vizinhos.
- Water e Wall Alt. 1/2 ainda não são usados.
- O terrain nativo/blob 47 foi descartado; o jogo usa o renderer manual
  aprovado.
- Nada foi commitado ou publicado.
