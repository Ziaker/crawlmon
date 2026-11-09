# D-1063 — NPCs no overworld 3D (`murky_forest_3d_lab`): 5 Pokémon Stage-1 e 5 DQT básicos

- **Data:** 2026-11-09.
- **Área:** Overworld 3D / Modelos 3D / NPCs (`scenes/debug/murky_forest_3d_lab.tscn`).
- **Relacionadas:** D-313, D-1022, D-1023, D-1027, D-1028, D-1037, D-1043.
- **Status:** **teste implementado, corrigido e verificado** no lab da Murky Forest; documentação e provas registradas; commit local; **sem push**; o jogo 2D, a batalha e as regras não mudam.

## Frase literal do criador

> vamos colocar npcs no novo overworld, pode trazer mais 5 pokemons e 5 DQTs aleatorios pra servirem como npcs, por favor use o extrator do C/games/tact para trazer eles corretamente com suas respectivas animacoes malhas rig e texturas

Respostas do criador às 4 perguntas de esclarecimento:

- **Em qual cena do novo overworld 3D os NPCs devem ser adicionados?** `murky_forest_3d_lab.tscn (Recomendado)`
- **Como os 10 novos NPCs (5 Pokémon + 5 DQT) devem ser posicionados na cena?** `Sortear/exibir 2 ou 3 por vez no corredor`
- **Qual comportamento os NPCs devem ter no overworld 3D?** `Parados em idle, olhando para o jogador ao se aproximar + marcador branco no mini-mapa + prompt de interação (Z/E: FALAR)`
- **Alguma preferência para a seleção dos 5 Pokémon e 5 monstros DQT, ou posso escolher 5 Pokémon Stage-1 e 5 DQT básicos variados?** `pesquise os monstros mais basicos primeiro do DQT e quanto aos pokemons lembre que estamos trabalhando primeiro nos stage-1`

## Decisão

1. **Cena alvo:** adicionar os NPCs em `scenes/debug/murky_forest_3d_lab.tscn` (`scripts/debug/murky_forest_3d_lab.gd`).
2. **Pool de 10 novos modelos 3D (5 Pokémon Stage-1 + 5 DQT básicos):**
   - **5 Pokémon Stage-1** (extraídos com `tools/export_pokemon.py` via Blender + `PokemonSwitchV3`, com bake de `ColorProcess` em textura base, rig, malhas e animações `idle`, `walk`, `run`, `attack`, `attack_special`, `charge`, `damage`, `down`, `victory`, `battle_idle`):
     1. `bulbasaur` (`pm0001_00_00`)
     2. `charmander` (`pm0004_00_00`)
     3. `squirtle` (`pm0007_00_00`)
     4. `pikachu` (`pm0025_00_00`)
     5. `eevee` (`pm0133_00_00`)
   - **5 DQT básicos/icônicos** (extraídos/validados pelo pipeline `C:\games\tact` / `tactlib 2.1.3` a partir das variantes individuais `cp_00_<id>_00_<Nome>.glb`, com rig, malhas, texturas e 12 animações `cm_00_<id>_*`, registrados em `scripts/combat/dqt_model_profiles.gd`):
     1. `dqt_dracky` (`0003_doraki-`, `cp_00_0003_00_Doraki-.glb` — Dracky)
     2. `dqt_healslime` (`0004_hoimislime`, `cp_00_0004_00_HoimiSlime.glb` — Heal Slime / Hoimi Slime)
     3. `dqt_sabrecub` (`0002_babypanther`, `cp_00_0002_00_BabyPanther.glb` — Sabrecub / Baby Panther)
     4. `dqt_platypunk` (`0001_momonja`, `cp_00_0001_00_Momonja.glb` — Platypunk / Momonja)
     5. `dqt_fungi` (`0038_obakekinoko`, `cp_00_0038_00_Obakekinoko.glb` — Funghoul / Obakekinoko)
3. **Posicionamento no corredor:** exibir **3 NPCs por vez** em pontos laterais do corredor de `murky_forest_3d_lab.tscn` (sem obstruir a passagem do grupo nem a patrulha do inimigo), com a tecla **2** alternando o trio pelo pool de 10. O ciclo é determinístico (+3); não é sorteio aleatório a cada carga.
4. **Comportamento no overworld 3D:**
   - Parados em animação `idle` (com toon shader do overworld D-1028, sombra no chão, etiqueta de nome e **colisão sólida com o jogador que não puxa a câmera D-1023**).
   - Giram suavemente no eixo Y para olhar na direção do jogador quando ele se aproxima.
   - Marcador branco no mini-mapa (`minimap_npc`, D-1027), **flat como em D-1072**.
   - Prompt de interação (`Z/E: FALAR`) quando o jogador está próximo e exibição de fala ao interagir (`lab_interact`).

## Implementação (2026-11-09)

- **Pool e slots:** `NPC_POOL` com 10 entradas; `NPC_SLOTS` com 3 posições laterais. O trio inicial é Bulbasaur, Dracky e Pikachu; `cycle_npcs(+3)` percorre os 10 e recria os marcadores.
- **Colisão sólida:** o NPC é `StaticBody3D` na **layer 16 (bit 4)**; o jogador da Murky Forest passa a usar `collision_mask = 1 | 16 = 17`, então **não atravessa** o NPC. O raio da câmera continua com máscara **1**, então **não puxa** por causa dos NPCs (D-1023). Aliados e inimigo mantêm máscara 1 e passam pelos NPCs para não travar a formação/patrulha.
- **Toon e apresentação:** `_apply_toon` no NPC, sombra blob, etiqueta 3D branca e altura do rótulo especial para o Dracky (que flutua). Todos os NPCs auditados ficaram em **100% toon**.
- **Mini-mapa:** cada NPC entra no grupo `minimap_npc` e recebe bolinha **branca de 10 px**. O `ExplorationBattleHud` (D-1072) achata as bolinhas novas criadas pelo ciclo; `dots_flat=true` antes e depois do ciclo.
- **Diálogo:** `npc_data.gd` fornece as falas; o prompt e o painel usam `lab_interact` (Z/E). O painel fica na layer 22, acima do HUD.
- **Pikachu:** o GLB tem **9 clipes** (sem `battle_idle`; o arquivo de origem `pm0025_00_00_00001_battlewait01_loop.tranm` não existe no dump). O NPC usa `idle`; no jogo, `CharacterModelLoader` já cai para `idle` quando não há `battle_idle`. Os outros 4 Pokémon têm 10 clipes.
- **Correção de continuidade:** a linha truncada `s Label3D).layers = layer` no fim de `murky_forest_3d_lab.gd` foi removida; o `--check-only` e a cena principal voltaram a rodar.

## Teste implementado (2026-11-09)

- **Modelos:** 10 GLBs presentes; 5 DQT com **SHA-256 idêntico** às variantes de `C:\games\tact\monstros\00\...` e **`validate_glb.py` PROBLEMS 0** nos 5.
- **Pokémon:** rigs com 112–142 joints, 4–6 imagens de textura e 9–10 animações com canais reais. Bulbasaur, Charmander, Squirtle e Eevee têm 10; Pikachu tem 9 (sem `battle_idle`).
- **NPCs:** 3 por vez; `idle`; etiquetas; sombras; marcadores brancos; prompt `Z/E: FALAR` e diálogo funcionando; ciclo `+3` verificado.
- **Colisão:** `player_mask=17`, `npc_layer=16`, `test_move=true`; a câmera usa máscara 1 e ignora os NPCs.
- **Bolinhas:** `dots_flat=true` no início e depois do ciclo; bordas todas em 0.
- **HUD D-1072:** cards 3 (1 visível no solo, 3 no party), badges antigos escondidos; Slime em 0,49 m.
- **Auditoria de caminho (solo/party):** `wall_hits=0`, `cam_inside=0`, `cam_close_frames=0`, `path_short=0`, `path_min=2`, `stack_pairs=0`, porta `near/visible/used`; HUD/alerta/toon intactos.
- **Cena principal:** `godot --headless --path . --fixed-fps 30 --quit-after 120 scenes/debug/murky_forest_3d_lab.tscn` terminou sem erro após a correção.
- **Provas:** `docs/referencias/exploracao/3d/murky_forest_npcs_10_models.png`, `murky_forest_npcs_corredor.png`, `murky_forest_npcs_dialogo.png` e `murky_forest_npcs_auditoria.txt`. As imagens de corredor/diálogo foram feitas antes do HUD D-1072 (mostram os badges antigos); a prova do HUD novo está em `murky_forest_hud.png` e nos vídeos D-1072.

## O que não foi verificado

- **Pikachu `battle_idle`:** a fonte não existe; não inventei o clipe. O fallback para `idle` cobre o uso atual.
- **Câmera e colisão em movimento:** o `test_move` prova a colisão; não gravei um vídeo caminhando contra cada NPC.
- **Look-at quadro a quadro:** o código de `lerp_angle` existe; a suavidade não foi medida.
- **60 fps, mobile/web, outras resoluções** e o comportamento em uma dungeon real.
- **Batalha 3D/2D:** os 5 Pokémon e 5 DQT não foram testados como combatentes ativos; a D-1063 é só NPC no overworld.
- **Lab de pedra D-1023:** continua rodando, mas ganhou 1 nó `DqtEyes` pela mudança no script base; a diferença visual não foi comparada com uma referência antiga.

## Estado

Teste implementado, corrigido e verificado no lab da Murky Forest. 10 modelos, 3 NPCs por vez, colisão sólida sem puxar a câmera, bolinhas flat, prompt/diálogo e HUD D-1072 convivendo. Documentação registrada em README/REGRAS; commit local; **sem push**. O jogo 2D, a batalha e as regras não mudam.
