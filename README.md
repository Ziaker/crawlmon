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
- Cada personagem tem um ATB de **5 blocos** que enche gradualmente. Ações normais custam **2 blocos**.
- **Fight**: ataque genérico físico + 4 ataques do personagem.
- **Itens**: usa um consumível (2 blocos).
- **Evade** (3 blocos): tenta desviar de um ataque inimigo em andamento (inimigos têm um tempo de preparo). Se der certo, ganha um bloco **Burst**: uma ação extra imediata e gratuita.
- **Tactics**: define como os aliados agem (Atacar / Habilidades / Segurar) e reagem (Nada / Esquivar). O jogador controla o líder; aliados seguem as Tactics. Aliados com reação "Esquivar" só agem com o ATB cheio, para manter reserva.
- Em Configurações: pausar o ATB em submenus e velocidade do ATB.

## Estrutura
- `scenes/exploration.tscn` — mapa 2D (cena principal).
- `scenes/battle.tscn` — palco 3D (modelos placeholder; trocar em `_make_model()`).
- `scripts/combat/` — regras do ATB (`battle.gd`, `combatant.gd`) e UI do combate.
- `scripts/data/` — itens e habilidades.
- `scripts/ui/` — menus (X/C), lista de menu, barra de ATB.
- `scripts/autoload/game_state.gd` — grupo, inventário, configurações, input.

## Rodar
Abra a pasta no Godot 4.7+ e pressione F5.
