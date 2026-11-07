# Changelog — pipeline de tilesets

## 3.2.0 — 2026-11-06

- **16 paletas fortes:** o `BiomeVisuals` saiu dos tons pastel; verde, ciano,
  areia, azul, índigo, rosa, laranja, amarelo, violeta, cinza etc. O
  `AMBIENT`/`FOG` de cada bioma é claramente distinto.
- **Luz do jogador removida:** o `PointLight2D` do personagem saiu do
  `map_visuals`; a sala é iluminada só pelo `CanvasModulate`/névoa. A única
  `PointLight2D` restante é a vermelha dos inimigos.
- **Temporal/Spire compensados:** `c8dce8` e `a0b0c8` para continuarem legíveis
  sem as luzes dinâmicas.
- **16 capturas in-game** e baseline de brilho regeneradas.
- **Laboratório:** o `tileset_lab` também aplica o `AMBIENT` do bioma; os 16
  contatos do laboratório deixaram de ser cinza. A névoa só existe no jogo.

## 3.1.0 — 2026-11-06

- **Névoa e overlay por bioma:** `scripts/dungeon/biome_visuals.gd` tem 16
  `AMBIENT` e 16 presets de névoa (cor/densidade/warp/drift). O `fog_of_war`
  lê `GameState.visual_biome`; o `map_visuals` aplica o `AMBIENT` do perfil.
- **Luzes amarelas removidas:** não há mais `PointLight2D` de tocha; resta só a
  luz fria do jogador. A baseline do `check_occluder_brightness.py` foi
  regerada para a nova iluminação.
- **16 capturas in-game** atualizadas em `biomes_ingame_contact.png`.
- A água decorativa continua pendente de escolha visual (D-357).

## 3.0.0 — 2026-11-06

- **Atlas em Scale2x:** a célula 24×24 vai para 48×48 com Scale2x/EPX em vez
  de nearest (16 folhas, perfis 3.0.0). A câmera 2,3×, o tile de 48 px e a
  geração procedural não mudam.
- **Tochas visíveis removidas:** chama, cabo e brasas saíram; a `PointLight2D`
  invisível continua no lugar para a sala não escurecer.
- **Água decorativa adiada:** o Water do Temporal é cinza-escuro e lê como o
  chão; a escolha (água azul das folhas de gelo, shader ou fora) fica pendente.
- **Testes:** 16 capturas in-game atualizadas; golden 1D 0,60 / 2D 0,61; brilho
  do piso −0,7% a −2,1%; 6.970 paredes / 0 divergências; fallback 688/0;
  decals 8,1% / 0 adjacentes.

## 2.9.1 — 2026-11-06

- **16 biomas no jogo:** a cena real de exploração foi carregada com a seed
  12345 e o `Visuals.setup` foi chamado para cada perfil; 16 capturas em
  `scratch/exploration_biomes/` e contato em
  `docs/referencias/tilesets/biomes_ingame_contact.png`.
- **Setup re-entrante:** `MapVisuals.setup` agora chama `_clear_visuals()` e
  limpa camadas/tochas/brasas/poeira; antes, o teste in-game travava após ~9
  perfis por acúmulo de nós. O jogo chama o setup uma vez, sem mudança visual.
- **Gate:** aprovado em 2026-11-06 (30 tiles, Wall Alt. 5+5%).

## 2.9.0 — 2026-11-06

- **Fallback dos 12 perfis:** com `side_contract_ok=false`, o jogo usa as peças
  reais por papel (strip, island, tips, cross, alt); `murky_forest` testado com
  688 células e 0 divergências.
- **16 biomas:** captura de sala por perfil; contato em
  `docs/referencias/tilesets/biomes_contact.png`.
- **Porta no laboratório:** corredor de 1 tile atravessa a parede esquerda;
  wall tip + borda de chão visíveis.
- **Decals exatos:** mapa pré-computado 4%+4% por andar, shuffle e exclusão de
  1 tile; 8,1% medidos, 0 adjacentes.
- **Golden 2D:** correlação 0,61 e MAE2D 0,65 além do perfil 1D.
- **Occluder medido:** `check_occluder_brightness.py` com baseline por seed
  (51,1–68,5); falha se escurecer >12%.
- **Wall Alt tuning:** capturas 0+0, 2+3, 5+5 e 7+8%.
- **Investigação:** a folha não tem canto interno de chão; `Unused Ground` tem
  um tile isolado (não usado); Water bloqueada por D-312; padding adiado.
- **Performance:** 4.800 células constroem em 44–69 ms; sem redraw por frame.
- **Commit:** feito localmente (tilesets, ferramentas, docs D-354..D-356 e gate
  aprovado); push não autorizado.

## 2.8.0 — 2026-11-06

- **Golden room diff:** `--golden` no laboratório + `check_golden_room.py`;
  compara topo/face/chão com o preview. Passa com correlação 0,60.
- **Máscaras 8-vizinhos:** grade de 19 papéis (núcleo, strip, island, tips,
  cross, alt centres), capturada em `_masks.png`; tecla **M** no laboratório.
- **Occluder ciente da face:** cada parede bloqueia luz só no lado da massa;
  o centro do piso não escureceu. O full-tile antigo foi rejeitado.
- **Decals de piso com espaçamento:** 13% de candidatos + desempate por célula
  → 8,7% reais, sem pares adjacentes; a média visual 4%+4% de D-347 continua.
- **Wall Alt. 1/2 centres:** 30 tiles; C7R1/C10R1 só em células totalmente
  interiores, 10% (5% cada), nunca em borda/canto/strip/tip/cross (D-355).
- **Gate:** a aprovação do Temporal fica stale (28 → 30 tiles) e o build avisa
  até nova revisão + `--approve`.
- **Validação:** 16 atlas/perfis com 30 tiles; `--check` OK; 6.970 células de
  parede em 10 seeds com 0 divergências; decals 8,7% sem adjacentes; alt 9,25%.

## 2.7.0 — 2026-11-06

- **Pipeline de percepção (D-354):** `audit_components.py` mede simetria H/V,
  linhas topo/face/fundo, assinatura de lado (`N/S/W/E`), costura, espelho,
  contrato de face e composição do preview.
- **Preview como gabarito:** casado pixel a pixel nas 16 folhas; a composição é
  `topo (linha 1) → face (linha 2) → chão`.
- **28 tiles reais:** 18 núcleo + 2 Ground Alt + strip V/H, island, tip N/S/W/E
  e cross. Nenhuma peça sintética.
- **Contrato de face:** `role_sides`/`role_cells`/`side_contract_ok` no perfil;
  o jogo escolhe a parede pela assinatura de lado medida, com fallback.
- **Gate humano:** `audit_components.py --only <folha> --approve` grava a
  aprovação; o build avisa quando falta ou envelhece.
- **Laboratório:** sala 14×10 embutida numa massa de parede (o caso do jogo),
  piso 6×4, parede fina de 3 tiles (strip + tips), câmera 2,3× e 48 px.
- **16 perfis/atlas** regerados com 28 tiles; `--check` OK. O contrato passa no
  Temporal Tower; 12 folhas de arte ambígua ficam sinalizadas até revisão.
- O atlas de 2.6.0 (21 tiles) fica superado por esta versão.

## 2.6.0 — 2026-11-06

- **Reversão das peças sintéticas:** o atlas de 42 tiles misturava topo/frente/
  centro de componentes diferentes e piorou os lados. Voltou para **21 tiles**:
  18 núcleo + 2 Ground Alt + `wall_strip_v` real C3 R4.
- Topo/base usam `wall_b`/`wall_t` reais, escolhidos pelo lado do chão.
- Nenhuma peça sintética no jogo/lab ativo; o pipeline não gera mais strips/
  ends/islands/inner. **Superado pela 2.7.0** (28 tiles + assinatura de lado).

## 2.5.0 — 2026-11-06

- **Autotile sintético completo:** 7 peças de parede, 7 de chão e 8 inner
  corners; atlas de 42 tiles. **Descartado na 2.6.0** por misturar componentes
  da folha e piorar os lados.

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
  2,3×; captura das 16 em `scratch/tilesets/`.
- **Índice global** em `tools/pmd_import/manifests/index.json`; `--only` não o
  sobrescreve mais.
- **Limpeza:** removido o gerador procedural antigo de atlas em
  `map_visuals.gd` e o `docs/referencias/tilesets/` recebeu `.gdignore`.
- **Todos os 16 atlas** regerados e validados.

## 1.x — legado (descartado)

- Origem `(14, 160)`, pitch 24 e recorte 19×19 em `(+4, +3)`.
- O deslocamento de 1 px por coluna fazia o Ground ser lido meio tile fora;
  foi a causa dos resultados embaralhados.
- Não usar como referência de implementação.
