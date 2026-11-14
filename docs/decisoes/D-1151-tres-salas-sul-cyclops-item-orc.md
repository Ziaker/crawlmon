<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1151 — Três salas ao sul: Cyclops + item, item consumível e Orc

- **Data:** 2026-11-11.
- **Área:** Overworld 3D / lab Murky Forest / salas / inimigos / itens.
- **Relacionadas:** D-1133 (cômodo leste), D-1142 (inimigos), D-1106, D-1028.
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> Agora o overworld precisa de seus respectivos itens, antes de começar faz uma compactação da conversa pois isso é um assunto novo.
>
> depois da compactação adicione mais 3 salas, 1 com um inimigo e 1 item (pode ser o cyclops de inimigo), uma só com item consumível, e 1 com um inimigo orc

## Regra

1. **Ala sul:** três salas em x -4..4, 4..10 e 10..18, z -14..-22, atrás da parede sul do corredor.
2. **Portas:** três vãos de **2 m** na parede z=-14,25 (x -1..1, 6..8, 13..15) e portas de 2 m nas divisórias x=4,25 e x=10,25 (z -19..-17).
3. **Sala 1 (oeste):** **Cyclops** patrulhando + item **AMULETO** (`amulet`) em `(2,4; 0,8; -16,2)`.
4. **Sala 2 (meio):** só o consumível **SUPER POÇÃO** (`super_potion`) em `(7,0; 0,8; -18,0)`.
5. **Sala 3 (leste):** **Orc** patrulhando; sem item.
6. **Coleta:** item 3D flutua/gira e é recolhido automaticamente ao chegar a **1,25 m**, entrando em `GameState.inventory`. Se a mochila estiver cheia, fica no chão.
7. **Inimigos:** Cyclops e Orc usam o mesmo controller de ataque, patrulham quatro pontos e perseguem o jogador em 5 m; ficam visíveis e com placa/anel.
8. **O que não muda:** salas/cômodo existentes, ataque, câmera, movimento, paredes 40%, HUD, regras, batalha e 2D.

## Implementação

- `murky_forest_3d_lab.gd`: piso/paredes/divisórias da ala sul; `ROOM_ENEMY_DATA`/`ROOM_ITEMS`; `_build_room_enemies()`, `_build_room_items()`, `_update_room_enemies()`; VFX/registro no attack controller; minimapa.
- `overworld_item_pickup.gd` (novo): Sprite3D do ícone, bob/gira, coleta automática e `GameState.add_item()`.
- Itens escolhidos do catálogo `Item`: `amulet` (held) e `super_potion` (consumable).

## Provas

- `docs/referencias/exploracao/3d/d1143_room_cyclops.png` — Cyclops na sala oeste.
- `docs/referencias/exploracao/3d/d1143_room_item.png` — super poção na sala do meio.
- `docs/referencias/exploracao/3d/d1143_room_orc.png` — Orc na sala leste.
- `docs/referencias/exploracao/3d/d1143_rooms_contact.png` — as três em contato.
- Log: `amulet=2` e `super_potion=1` após atravessar os itens; `Cyclops state=CHASE`, `Orc state=PATROL`.

## O que foi verificado

- As três salas existem com piso, paredes e portas.
- Cyclops e Orc nascem/patrulham nas salas corretas e são registrados no ataque.
- Os dois itens são visíveis, coletáveis e somam no inventário (amuleto 1→2; super poção 0→1).
- As capturas mostram os inimigos/itens nas salas.
- Cena headless `exit=0`.

## O que não foi verificado

- Caminhada real do jogador atravessando cada porta (as capturas usam teleporte).
- Navmesh das salas novas para o Slime/NPCs (Cyclops/Orc usam movimento direto).
- Escala/legibilidade final dos ícones no chão e persistência dos itens entre cenas.
- Todos os ângulos de câmera e desempenho.

## Estado

Implementado e provado. Código na árvore de trabalho; **sem push**.
