# Crawlmon

Dungeon crawler em Godot 4.7 com combate em turnos **ATB** (Active Time Battle).

## Estado atual
- Loop de batalha ATB básico (`scripts/combat/`): barras enchem com a velocidade; o jogo pausa enquanto o jogador escolhe a ação.
- Exploração 2D top-down (`scenes/exploration.tscn`, cena principal): mapa ASCII, movimento com setas/WASD, inimigos vermelhos iniciam batalha.
- Combate em 3D (`scenes/battle.tscn`): palco 3D com câmera, luz e modelos placeholder (cápsulas) - trocar por glTF em `_make_model()`.
- `GameState` (autoload) liga as duas cenas e guarda inimigos derrotados.
- `scripts/dungeon/`: reservado para exploração da masmorra.

## Rodar
Abra a pasta no Godot 4.7+ e pressione F5.
