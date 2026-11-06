# Assets 2D do Pokémon Mystery Dungeon (Explorers)

> **Status:** primeira leva do hub e os 16 Dungeon Tiles do Sky importados. **Estado atual:** o visual ativo é o **Sky Temporal Tower de 30 tiles** (18 do núcleo + `ground_alt_1/2` + 8 peças reais de parede: strip V/H, island, tip N/S/W/E e cross), alinhado à grade real da folha; as peças sintéticas do atlas de 42 foram descartadas porque misturavam componentes (pitch de 25 px: 1 px de linha ciano + 24×24 de arte). O sheet do Time/Darkness fica como referência em `docs/referencias/`. O piso orgânico usa as Ground Alt em 4%+4% (D-347); a seleção de parede é por assinatura de lado medida (D-354).
> **Decisões:** D-325, D-326, D-329, D-330. **Páginas-fonte:** Explorers of Time/Darkness e Explorers of Sky (The Spriters Resource).
> **Créditos/proveniência:** `docs/CREDITOS_ASSETS.md`.

## Regras

1. **Pokémon do site ficam de fora por ora.** Sprites, retratos e map sprites de Pokémon continuam os que o projeto já tem.
2. **Assets não-Pokémon autorizados:** dungeons, backgrounds, itens, UI, murais, fundos de menu, céus, estátuas, props, fontes e mapa.
3. **Preservar o PNG original** em `raw/` e registrar fonte, ID, rip e URL.
4. **Não usar sombra elíptica sob entidades** (D-313).
5. **Nada de VFX novo** sem D-308 e o protocolo obrigatório.
6. A batalha 3D e o escopo da D-319 não mudam.

## Estrutura real

```text
assets/pmd/
  hub/
    treasure_town.png            # limpo, 1157x465, usado pelo hub_test
    raw/                         # backgrounds originais, ignorados pelo Godot
      treasure_town.png          # original 1157x985
      guild_1f_outside.png
      guild_2f.png
      guild_3f.png
      base_camp.png
      crossroads.png
      marowak_dojo.png
      sharpedo_bluff.png
      beach.png
  dungeons/
    sky/
      raw/                       # 16 folhas originais, ignoradas pelo Godot
      atlas/                     # 16 atlas de 30 tiles + 16 perfis JSON
      _intermediate/             # recortes 2x/48 antigos, ignorados; não usados
  referencias/tilesets/          # contato, atlas rotulado, labels e preview (docs)
    time_darkness/
      raw/
        temporal_tower.png       # sheet de referência (Time/Darkness 84824)
      atlas/
        temporal_tower_atlas.png # referência: 30 tiles, Sky (ativo)
  items/
    items.png                    # folha de itens original
  ui/
    world_map.png                # mapa original
  props/                         # vazio; Dimensional Hole ainda não baixado
```

Os `.gdignore` em `hub/raw/`, `dungeons/sky/raw/` e `dungeons/sky/_intermediate/` impedem o Godot de importar os originais/intermediários. O jogo lê só os arquivos limpos/atlas.

## Hub — importado

| Arquivo | Estado | Origem |
|---|---|---|
| `assets/pmd/hub/treasure_town.png` | **limpo** (fundo branco removido, recorte 1157×465) | Time/Darkness 5979 |
| `assets/pmd/hub/raw/treasure_town.png` | original 1157×985 | Time/Darkness 5979 |
| `assets/pmd/hub/raw/guild_1f_outside.png` | original, ainda com fundo branco | Time/Darkness 5962 |
| `assets/pmd/hub/raw/guild_2f.png` | original, ainda com fundo branco | Time/Darkness 5963 |
| `assets/pmd/hub/raw/guild_3f.png` | original, ainda com fundo branco | Time/Darkness 5964 |
| `assets/pmd/hub/raw/base_camp.png` | original, ainda com fundo branco | Time/Darkness 5973 |
| `assets/pmd/hub/raw/crossroads.png` | original, ainda com fundo branco | Time/Darkness 5972 |
| `assets/pmd/hub/raw/marowak_dojo.png` | original, ainda com fundo branco | Time/Darkness 5966 |
| `assets/pmd/hub/raw/sharpedo_bluff.png` | original, ainda com fundo branco | Time/Darkness 5970 |
| `assets/pmd/hub/raw/beach.png` | original, ainda com fundo branco | Time/Darkness 14797 |
| `assets/pmd/items/items.png` | original | Time/Darkness 15903 |
| `assets/pmd/ui/world_map.png` | original | Time/Darkness 279868 |

**Código que usa:** `scripts/hub/hub_test.gd` → `res://assets/pmd/hub/treasure_town.png`.

## Dungeons — Sky (16 importadas)

| Dungeon | ID | Raw | Atlas |
|---|---:|---|---|
| 4th Station Pass | 86307 | `raw/4th_station_pass.png` | `atlas/4th_station_pass_atlas.png` |
| 7th Station Pass | 86310 | `raw/7th_station_pass.png` | `atlas/7th_station_pass_atlas.png` |
| Barren Valley | 86329 | `raw/barren_valley.png` | `atlas/barren_valley_atlas.png` |
| Dark Ice Mountain | 101867 | `raw/dark_ice_mountain.png` | `atlas/dark_ice_mountain_atlas.png` |
| Dark Ice Mountain Peak | 101866 | `raw/dark_ice_mountain_peak.png` | `atlas/dark_ice_mountain_peak_atlas.png` |
| Dark Wasteland | 86330 | `raw/dark_wasteland.png` | `atlas/dark_wasteland_atlas.png` |
| Deep Boulder Quarry | 86311 | `raw/deep_boulder_quarry.png` | `atlas/deep_boulder_quarry_atlas.png` |
| Deep Limestone Cavern | 86324 | `raw/deep_limestone_cavern.png` | `atlas/deep_limestone_cavern_atlas.png` |
| Icicle Forest | 101865 | `raw/icicle_forest.png` | `atlas/icicle_forest_atlas.png` |
| Limestone Cavern | 86313 | `raw/limestone_cavern.png` | `atlas/limestone_cavern_atlas.png` |
| Murky Forest | 61817 | `raw/murky_forest.png` | `atlas/murky_forest_atlas.png` |
| Spacial Cliffs | 101868 | `raw/spacial_cliffs.png` | `atlas/spacial_cliffs_atlas.png` |
| Temporal Spire (Future of Darkness) | 86345 | `raw/temporal_spire.png` | `atlas/temporal_spire_atlas.png` |
| Temporal Tower (Future of Darkness) | 86331 | `raw/temporal_tower.png` | `atlas/temporal_tower_atlas.png` |
| Vast Ice Mountain | 101864 | `raw/vast_ice_mountain.png` | `atlas/vast_ice_mountain_atlas.png` |
| Vast Ice Mountain Peak | 101862 | `raw/vast_ice_mountain_peak.png` | `atlas/vast_ice_mountain_peak_atlas.png` |

**Código que usa:** `scripts/dungeon/map_visuals.gd` → `res://assets/pmd/dungeons/sky/atlas/temporal_tower_profile.json` (o perfil aponta para o atlas e para os papéis).

**Mapeamento do atlas ativo (30 tiles de 48 px, Sky Temporal Tower):**

- 0..8: bloco 3×3 de **Walls** (C3..C5, R0..R2; centro C4 R1)
- 9..17: bloco 3×3 de **Ground** (C12..C14, R0..R2; centro C13 R1)
- 18: **Ground Alt. 1** (C16 R1)
- 19: **Ground Alt. 2** (C19 R1)
- 20: **Wall strip V** (C3 R4; lados opostos W+E)
- 21: **Wall strip H** (C4 R3; lados opostos N+S)
- 22: **Wall island** (C4 R4; quatro lados abertos)
- 23..26: **Wall tips** N/S/W/E (C4 R6, C4 R8, C3 R7, C5 R7; três lados abertos)
- 27: **Wall cross** (C4 R7; quatro vizinhos ortogonais em parede, diagonais em chão)

A folha usa **pitch de 25 px**: 1 px de linha ciano + célula de arte de 24×24. A origem da arte é `(9, 163)`, o recorte é a célula inteira de 24×24 e a escala é nearest para 48. Não há moldura de 4 px nem limpeza de fundo. O `map_visuals.gd` pede papéis (`wall_tl`, `ground_c`, …) ao perfil e escolhe a parede pela **assinatura de lados abertos medida** (`role_sides`), com fallback pelos nomes do núcleo; o chão usa a máscara de 4 vizinhos. A auditoria de percepção (`tools/pmd_import/audit_components.py`) mede orientação, preview, costura, espelho e contrato de face antes de usar o atlas (D-345/D-354). Pipeline reproduzível: `tools/pmd_import/build_dungeon_atlases.py`; manifesto em `tools/pmd_import/manifests/`; contato/labels/preview em `docs/referencias/tilesets/`; laboratório em `scenes/tileset_lab.tscn` (D-345/D-354). O atlas de **21 tiles do Time/Darkness** (`time_darkness/atlas/`) fica como referência, não é o ativo.

## Não importados ainda

- **Various Graphics** (19952): contém retratos de Pokémon; fora enquanto Pokémon do site estiverem excluídos.
- **Dimensional Hole** (158011): download não completou; `assets/pmd/props/` está vazio.
- **Spinda Cafe** (27765), **Boards & Wanted Posters** (233234), **Menu Backgrounds** (47829), **Statues** (175670), **Skies** (59281/232235/618277), **Dungeon Title Font** (84937), **Treasure Town variante** (81003).
- **Backgrounds de dungeon do Time/Darkness** (Amp Plains, Apple Woods, etc.): só referência por ora.
- **Pokémon do site** (sprites, retratos, map sprites): excluídos por D-325.

## Pendências

- Os 16 foram capturados no laboratório e **no jogo** na mesma seed/mapa (`scratch/exploration_biomes/`, contato `docs/referencias/tilesets/biomes_ingame_contact.png`); só o **Temporal Tower** está aprovado visualmente. O `MapVisuals.setup` virou re-entrante (`_clear_visuals`) para o teste in-game não travar após ~9 perfis.
- O contrato de face passa no Temporal Tower; as outras 12 folhas têm arte ambígua (o lado escuro não é consistente) e ficam com `side_contract_ok=false`. Para elas o jogo usa o **fallback por papel** (strips, tips, island, cross e alt) e o `murky_forest` foi testado com 688 células e 0 divergências (D-356).
- O renderizador escolhe a parede pela assinatura de lado medida; o “Legend” da folha ainda não é lido como máscara automática.
- O preview da folha foi casado pixel a pixel: ele usa a linha 1 (topo) + linha 2 (face) + Ground; isso está documentado em D-354.
- A folha **não tem peças reais de canto interno de chão**; o fallback é `ground_c`. O `Unused Ground` tem um tile isolado em C22R1, não um conjunto, e não foi usado como decal (D-356).
- **Water** não é usada: exige células de água, colisão e regra de mapa (D-312), ainda sem decisão.
- Os decals de piso agora são **4%+4% exatos** por andar (8,1% medidos), com exclusão de 1 tile.
- Os backgrounds do hub em `raw/` ainda têm fundo branco e não foram limpos.
- O seletor de bioma por andar existe (16 perfis), mas os **3 biomas de D-312** (floresta/fortaleza/caverna) não.
- Nada foi commitado ou publicado.
