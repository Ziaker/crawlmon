# Crawlmon

Dungeon crawler em Godot 4.7 com mapa 2D top-down e combate em 3D com **ATB** em blocos.

## Controles
| Tecla | Ação |
|---|---|
| Setas | Mover / navegar menus |
| Z | Confirmar / realizar ação |
| X | Abrir menu (Itens, Status, Segurar) no mapa; voltar nos submenus |
| C | Configurações |

## Combate
- Cada personagem tem um ATB de **5 blocos** que enche gradualmente. Ações custam **2 blocos**; itens custam **1**.
- **Fight**: ataque genérico físico + 4 ataques do personagem.
- **Itens**: usa um consumível (1 bloco).
- **Evade** (3 blocos): desvia de um ataque inimigo em andamento (inimigos têm um tempo de preparo). Ganha um bloco **Burst**: uma ação extra imediata e gratuita.
- **Esquiva automática**: todo golpe tem chance de ser esquivado igual à velocidade (SPD) do alvo; se esquivar, o alvo ganha +1 bloco de ATB (diferente do Evade manual, que dá Burst).
- **Elementos**: Físico, Fogo, Água/Gelo, Raio, Psíquico, Veneno, Som, Terra, Vento, Luz, Trevas. Golpe no elemento fraco do alvo causa dano x1,5 e dá +2 blocos de ATB ao atacante.
- **Tactics**: define como os aliados agem (Atacar / Habilidades / Segurar) e reagem (Nada / Esquivar). O jogador controla o líder; aliados seguem as Tactics.
- Configurações (C): ainda vazio.

## Estrutura
- `scenes/exploration.tscn` — mapa 2D (cena principal).
- `scenes/battle.tscn` — palco 3D (modelos placeholder; trocar em `_make_model()`).
- `personagens/` — biblioteca de 11.185 imagens com nomes (ícones, retratos de combate Conquest e sprites de caminhada 2D overworld).
- `documentos/` — documentação do projeto (`personagens.md`) e catálogo `pokedex_manifest.json`.
- `scripts/combat/` — regras do ATB (`battle.gd`, `combatant.gd`) e UI do combate.
- `scripts/data/` — itens e habilidades.
- `scripts/ui/` — menus (X/C), lista de menu, barra de ATB.
- `scripts/autoload/game_state.gd` — grupo, inventário, configurações, input.

## Rodar
Abra a pasta no Godot 4.7+ e pressione F5.
