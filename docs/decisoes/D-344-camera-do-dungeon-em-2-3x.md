<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-344 — Câmera do dungeon em 2,3×

- **Data:** 2026-11-06
- **Área:** Exploração / visual / câmera
- **Origem:** Conversa (depois da aprovação do tileset do Temporal Tower)

## O que o criador disse (literal)

> sim, incrivel, eu so queria que a camera n ficasse tao longe assim dos personagens

E, na escolha do comparativo:

> 2.00x (Recomendado)

Depois:

> mais 0,30x de zoom.

## Decisão

1. A câmera do **dungeon/exploração** passa de **1,5×** para **2,0×** e depois para **2,3×** (`scripts/dungeon/player.gd`), somando os 0,30× pedidos pelo criador.
2. Nada mais muda: a velocidade do jogador, a suavização (`position_smoothing_speed = 8.0`), os limites da câmera e a colisão continuam iguais.
3. A câmera do **teste do hub** já estava em 2,0× e continua assim.
4. A câmera 3D de batalha não é afetada; esta decisão é só da exploração 2D.

## Comparativo que originou a escolha

Quatro capturas da mesma dungeon em `scratch/zoom_compare.png`:

- 1,75× — pouco mais perto que o 1,5× antigo;
- 2,0× — escolhido no comparativo;
- 2,25× — mais fechado;
- 2,5× — bem fechado nos personagens.

Depois da escolha, o criador pediu **mais 0,30×**: o valor final ficou **2,3×**.

## O que foi verificado

- `player.gd` com `cam.zoom = Vector2(2.3, 2.3)`.
- Captura windowed da exploração em `scratch/exploration_48.png`.

## O que não foi verificado

- Nenhuma outra cena além da exploração e do teste do hub.
- A câmera de batalha 3D e as cenas de VFX não foram tocadas.

## Estado no código

Implementado em 2026-11-06. Nada foi commitado ou publicado.
