# Compactação — 2026-11-11 — fim do ciclo de câmera/ataque, início das salas e itens

## Estado do lab 3D (Murky Forest)

- **Câmera/controle:** WASD/setas movem, **A/D giram a câmera** a 2,6 rad/s, sem auto-follow. Personagem a **4,8 m/s**.
- **Ataque Z:** ataca com ou sem inimigo; 2,0 m de teto; **wind-up 0,15 s**; animação `attack` a **1,0×**; **endlag** até o clipe terminar; inimigos têm telegraph 0,4 s + wind-up 0,15 s + o mesmo endlag. Jogador e inimigos usam o comprimento do próprio clipe. **E** fala/interage.
- **Paredes:** paliçada base + 5 variações, 40% textura, crossfade 2 m, tile 5 m.
- **Cômodo leste (D-1133):** x 4..18, z -6..6, porta de 3 m em z=-5,75 (x 8..11); Gible nasce em (11,0) e patrulha (6,4)/(16,4)/(16,-4)/(6,-4).
- **Código não commitado:** `scripts/overworld/`, `tests/overworld/`, e as mudanças de `murky_forest_3d_lab.gd` do ataque/Gible pertencem à árvore de trabalho da outra sessão. Meus commits recentes são só docs/provas.

## Decisões recentes

- D-1133: cômodo leste + Gible patrulhando.
- D-1135: ataque 2,0 m, Z sem wind-up (depois revisto).
- D-1137: câmera 2,6 rad/s, personagem 4,8 m/s, Z ataca sempre.
- D-1139: animação na duração do dash (substituída para o jogador).
- D-1141: wind-up 0,15 s + endlag do jogador.
- D-1142: mesmas regras para inimigos (telegraph 0,4 + wind-up 0,15 + endlag).

## Assunto novo

Adicionar **3 salas** ao overworld 3D:

1. Sala com **Cyclops** e **1 item**.
2. Sala só com **1 item consumível**.
3. Sala com **1 Orc**.

Itens usam o catálogo `Item` (`potion`, `super_potion`, `amulet` etc.) e entram no `GameState.inventory` ao serem recolhidos.

## Arquivos-chave

- `scripts/debug/murky_forest_3d_lab.gd` — geometria, inimigos, itens, minimapa.
- `scripts/debug/third_person_3d_lab.gd` — movimento/câmera.
- `scripts/overworld/overworld_attack_controller.gd` — ataque.
- `scripts/data/item.gd` — catálogo de itens.
- `scripts/autoload/game_state.gd` — inventário.
