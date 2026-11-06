# D-330 — Importar os Dungeon Tiles do Sky e trocar o atlas procedural

> **Estado atual (2026-11-06):** o atlas ativo é o **Sky Temporal Tower de 22 tiles** (18 do núcleo + `ground_alt_1/2`, D-347 + `wall_strip_h/v` sintetizadas, D-348), alinhado à grade real da folha. A causa dos resultados ruins era o recorte: a folha usa **pitch de 25 px** (1 px de linha ciano + 24×24 de arte), e o importador antigo usava pitch 24 com origem (14, 160), deslocando 1 px por coluna. O sheet do Time/Darkness (21 tiles) fica só como referência. A geração procedural continua.

- **Data:** 2026-11-05
- **Área:** Exploração / visual / assets
- **Origem:** Conversa (depois da volta para 48 px)

## O que o criador disse (literal)

> agora importe os sprites das dungeons e troque

## Decisão

1. Ficam importados os **16 Dungeon Tiles do Pokémon Mystery Dungeon: Explorers of Sky** em `assets/pmd/dungeons/sky/raw/`, com os atlas em `assets/pmd/dungeons/sky/atlas/`.
2. O **visual da dungeon procedural** usa o tileset do **Sky Temporal Tower** com um atlas de **18 tiles de 48 px**: bloco 3×3 de **Walls** (C3..C5, R0..R2; centro C4 R1) e bloco 3×3 de **Ground** (C12..C14, R0..R2; centro C13 R1). O `map_visuals.gd` escolhe o tile por uma máscara de 4 vizinhos.
3. A **geração procedural continua** (GDD R7-Q5): o tileset só troca a aparência; não vira mapa fixo.
4. Os outros 15 tilesets ficam prontos para os biomas futuros (D-312/D-317). O seletor de bioma ainda não foi implementado; Temporal Tower é o visual ativo.
5. A troca é **somente visual**: colisão, movimento, tempos, encontros e regras não mudam.
6. Nenhum VFX novo; a iluminação, tochas, brasas e poeira existentes continuam.

## Como foi feito

- **Grade real da folha:** linha ciano de 1 px + célula de arte de 24×24, repetindo a cada **25 px**. A origem da arte é `(9, 163)`; não existe moldura branca/preta de 4 px. O recorte é a célula inteira de 24×24, sem “limpeza” de fundo, escalada para 48×48 com nearest.
- **O bug antigo:** o script usava `TILE = 24`, origem `(14, 160)` e recorte 19×19 em `(+4, +3)`. Isso deslocava 1 px por coluna; na coluna do Ground (C13) o recorte já estava meio tile fora, misturando paredes, chão e vazio. Era isso que deixava o resultado “pessimo” e “piorou ainda mais”.
- **Categorias:** a folha tem três colunas por grupo: Legend, Walls, Wall Alt. 1, Wall Alt. 2, Ground, Ground Alt. 1, Ground Alt. 2, Unused Ground, Water. Walls e Ground começam com um bloco 3×3 de auto-tile: centro = preenchimento, os oito vizinhos = bordas/cantos. As linhas extras de Ground/Water são peças de canto externo, não usadas nesta primeira passada.
- **Atlas ativo:** `assets/pmd/dungeons/sky/atlas/temporal_tower_atlas.png`, 22 tiles (0..8 Walls, 9..17 Ground, 18/19 Ground Alt. 1/2, 20/21 Wall strip H/V sintetizadas). O perfil `temporal_tower_profile.json` traduz papel → índice e define a textura; o manifesto e a folha de contato ficam em `tools/pmd_import/manifests/` e `docs/referencias/tilesets/`. Pipeline: `tools/pmd_import/build_dungeon_atlases.py` (D-345; piso orgânico D-347; strips D-348).
- **Sem face layer:** a parede é de uma linha; o relevo vem da borda escura do bloco 3×3. O sheet do Time/Darkness e o atlas de 21 tiles com face ficam em `assets/pmd/dungeons/time_darkness/` e `docs/referencias/` como referência, não como estado ativo.
- **Referência de sala pintada:** `docs/referencias/temporal_tower_sky_map.png` mostra que os quartos do jogo são backgrounds pintados, não um grid uniforme. O tileset é um kit de montagem; o atlas atual usa só as categorias Walls/Ground.

## O que foi verificado

- Importação no Godot 4.7.2 sem erro; os 16 atlas foram regerados com a grade correta e passaram no `--check` (dimensões, vazio, ciano/teal, hashes, artefatos).
- `scenes/exploration.tscn` headless sem erro.
- Captura windowed em `scratch/exploration_48.png`: parede clara com borda escura contínua, chão de tijolo escuro contínuo, cantos e bordas do bloco 3×3, tochas e sombras existentes. Os tijolos do chão agora alinham de um tile para o outro, sem o deslocamento de 1 px.
- O atlas de 4× em `scratch/atlas_fixed_4x.png` mostra os 18 tiles na ordem esperada.
- Laboratório `scenes/tileset_lab.tscn` e as 16 salas em `scratch/tilesets/` mostram os quatro cantos, as bordas e o centro; a troca de perfil para `murky_forest` mudou a textura, provando que o perfil manda no atlas.

## O que não foi verificado

- Os outros 15 atlases não foram testados em cena; só o Temporal Tower.
- O seletor de bioma/andar ainda não existe.
- A máscara usa os **quatro vizinhos ortogonais**; cantos/diagonais, água e as categorias Wall Alt. 1/2, Ground Alt. 1/2 e Unused Ground não foram incorporados.
- O TileSet terrain + `terrain_tools.audit_layer` (0 side / 0 corner) ainda não foi montado.
- As funções antigas do atlas procedural continuam em `map_visuals.gd`, sem uso; limpeza pendente.
- Nada de combate, VFX ou regras foi alterado.

## Estado no código

Implementado nesta sessão, em 48 px. Nada foi commitado ou publicado.
