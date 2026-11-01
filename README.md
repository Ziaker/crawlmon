# Crawlmon

Dungeon crawler em Godot 4.7 com mapa 2D top-down e combate em 3D com **ATB** em blocos.

## Controles
| Tecla | Ação |
|---|---|
| Setas | Mover / navegar menus |
| Z | Confirmar / realizar ação |
| X | Abrir menu (Itens, Status, Segurar) no mapa; voltar nos submenus |
| Espaço | Evade (atalho, em combate) |
| C | Configurações |

## Combate
- Cada personagem tem um ATB de **5 blocos** que enche gradualmente. Ações custam **2 blocos**; itens custam **1**.
- **Fight**: ataque genérico físico + 4 ataques do personagem.
- **Itens**: usa um consumível (1 bloco).
- **Evade** (3 blocos): desvia de um ataque inimigo em andamento (inimigos têm um tempo de preparo). Ganha um bloco **Burst**: uma ação extra imediata e gratuita.
- **Esquiva automática**: todo golpe tem chance de ser esquivado igual à velocidade (SPD) do alvo; se esquivar, o alvo ganha +1 bloco de ATB (diferente do Evade manual, que dá Burst).
- **Elementos**: Físico, Fogo, Água/Gelo, Raio, Psíquico, Veneno, Som, Terra, Vento, Luz, Trevas. Golpe no elemento fraco do alvo causa dano x1,5 e dá +2 blocos de ATB ao atacante.
- **Efeitos visuais** (placeholders em `scripts/combat/battle_fx.gd`): ataque inimigo é sinalizado (inimigo recua, anel vermelho encolhe no alvo), investida/projétil por elemento, impacto por elemento, esquiva com afterimage e números flutuantes. Anel dourado no personagem = Burst.
- **Combate (visual V9)**: grupo perto da câmera olhando para a frente, inimigos 30 unidades adiante e deslocados à direita. HUD nativo em `scripts/ui/battle_hud.gd` (cartão do líder acima dos comandos, cartão do aliado junto ao modelo, etiquetas sobre cada inimigo). Câmera automática em `scripts/combat/battle_camera.gd`: Cinema (padrão), Tática (ao escolher alvo) e Impacto (ao acertar), com transições suaves e sem tremor/inclinação. MP ainda não existe no jogo (cartões mostram `MP N/D`).
- **Crítico**: 10% de chance por golpe, dano x2, e o atacante ganha +1 bloco de ATB.
- **Simetria**: toda mecânica do jogador vale para o oponente. Inimigos têm habilidades com elementos, inventário (poção), fraquezas, Evade manual (e ganham Burst), esquiva automática, crítico e ganho de ATB; e todo ataque, de qualquer lado, tem tempo de preparo e pode ser desviado. Inimigos seguem as mesmas Tactics dos aliados (Habilidades + Esquivar).
- **Tactics**: define como os aliados agem (Atacar / Habilidades / Segurar) e reagem (Nada / Esquivar). O jogador controla o líder; aliados seguem as Tactics.
- Configurações (C): ainda vazio.

## Estrutura
- `scenes/exploration.tscn` — mapa 2D (cena principal). Visual procedural em `scripts/dungeon/map_visuals.gd`: tiles de pedra/tijolo, decoração, tochas com luz e sombra tremulante, luz no jogador, sombras e inimigos animados.
- `scenes/battle.tscn` — palco 3D (modelos placeholder; trocar em `_make_model()`).
- `personagens/` — biblioteca de sprites dos **303 Pokémon utilizáveis** no jogo (com modelo 3D disponível).
- `personagens_sem_modelo/` — pasta separada (com `.gdignore`) contendo os **418 Pokémon arquivados** que não possuem modelo 3D.
- `documentos/` — documentação técnica do projeto (`personagens.md`, `modelos_za_comparativo.md`) e catálogo `pokedex_manifest.json`.
- `scripts/combat/` — regras do ATB (`battle.gd`, `combatant.gd`) e UI do combate.
- `scripts/data/` — itens e habilidades.
- `scripts/ui/` — menus (X/C), lista de menu, barra de ATB.
- `scripts/autoload/game_state.gd` — grupo, inventário, configurações, input.

## Rodar
Abra a pasta no Godot 4.7+ e pressione F5.
