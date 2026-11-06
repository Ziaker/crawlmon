# Changelog — pipeline de tilesets

## 2.5.0 — 2026-11-06

- **Cantos internos sintéticos:** 4 de parede (base do canto externo + patch
  do canto diagonal) e 4 de chão (base `ground_c` + patch do canto). O topo,
  base, laterais, cantos da sala e o pilar 2×2 ficam com as bordas internas.
- Atlas ativo com **30 tiles** (18 núcleo + 2 Ground Alt + 2 strips + 8 inner).
- O laboratório reposicionou a sala para não sobrepor o catálogo de 30 tiles.
- O jogo não foi capturado nesta rodada: `game_state.gd` está com erro de
  compilação em `heal_gain_mark.gd` (outra sessão); o laboratório é independente.

## 2.4.0 — 2026-11-06

- **Strips sintéticas (D-348):** `wall_strip_h`/`wall_strip_v` são compostas
  das bordas de `wall_t/b/l/r` sobre `wall_c`, sem as juntas das formas do
  frame. Fecham os dois lados de paredes de 1 tile no topo, base e laterais.
- Atlas ativo com **22 tiles** (18 núcleo + 2 Ground Alt + 2 strips).
- `_is_solid` separa fora do mapa de parede; o lado aberto só é usado quando
  o vizinho é parede `#` que continua.

## 2.3.0 — 2026-11-06

- **Parede de 1 tile (D-348):** `_is_solid` separa fora do mapa de parede;
  strip vertical C3 R4 (descartada depois; a 2.4.0 usa strips sintéticas).
- Laboratório com **overlay** de célula/índice/papel sob o mouse.
- `--check` valida os papéis extras e índices duplicados.

## 2.2.0 — 2026-11-06

- **Ground Alt. 1/2** (C16 R1/C19 R1) entram no atlas/perfil como
  `ground_alt_1`/`ground_alt_2`; atlas ativo com 20 tiles.
- **Piso orgânico** no jogo: 92% `ground_c`, 4% alt 1, 4% alt 2 nas células de
  chão interiores, determinístico pelo `dungeon_seed`; bordas/cantos mantêm a
  máscara de 4 vizinhos.
- **Laboratório** volta ao renderer manual + piso orgânico; catálogo e sala
  mostram os 20 tiles e os 16 perfis.
- **Removidos** o terrain nativo e as peças extras de parede do atlas/lab
  ativo; a folha tem 9 peças de borda reais, não um blob 47.
- O jogo/lab lê o PNG atual por `Image.load_from_file` no editor.

## 2.1.0 — 2026-11-06

- **Peças extras de parede:** o importador detecta a borda escura das linhas
  extras do bloco Walls, adiciona máscaras únicas ao atlas (18 a 33 tiles por
  folha) e grava `role_masks` no perfil.
- **Terrain nativo no laboratório:** `TilesetTerrain` configura um terrain set
  de 8 bits e pinta com `set_cells_terrain_connect`; a sala mostra o audit.
- **Limite documentado:** a folha tem 9 peças reais de borda, não um blob 47;
  o audit não chega a 0/0 e o jogo mantém a máscara manual aprovada.
- **Seletor de bioma:** `biome_pool.json` com os 16 perfis, troca no 5º andar,
  fallback Temporal Tower e contador visual em `GameState`.
- **Atlas direto:** o jogo/lab lê o PNG atual por `Image.load_from_file` no
  editor, sem depender de um reimport completo a cada rebuild.

## 2.0.0 — 2026-11-06

- **Medição real da folha:** `pmd_sheet.probe()` detecta as linhas ciano, a
  origem `(9, 163)`, o pitch de 25 px e a célula de 24×24. A grade não é mais
  constante no importador.
- **Recorte da célula inteira:** 24×24, sem `(+4, +3)`, sem 19×19 e sem
  “limpeza” por vizinho. Escala nearest para 48.
- **Manifesto e perfil por folha:** fonte + hash, grade, categorias, auto-tile,
  papéis, atlas + hash, contatos e preview.
- **Perfil papel → índice:** o `map_visuals.gd` não usa mais índice cru; o
  campo `atlas` do perfil também define a textura ativa.
- **Validação automática:** 18 tiles de 48 px, células vazias, ciano/teal,
  duplicatas (aviso), costura (aviso), hashes no `--check`.
- **Folha de contato e atlas rotulado** para cada uma das 16 folhas.
- **Laboratório no Godot:** catálogo + sala de máscaras no 48 px real e câmera
  2,3×; cap