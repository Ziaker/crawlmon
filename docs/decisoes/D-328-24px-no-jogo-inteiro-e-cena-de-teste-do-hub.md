<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-328 — 24 px no jogo inteiro e cena de teste do hub

> **Revertida por D-329:** o jogo voltou a 48 px. A cena de teste do hub permanece, agora em 48 px.

- **Data:** 2026-11-05
- **Área:** Exploração / visual / implementação
- **Origem:** Conversa (respostas às duas perguntas do plano de assets)

## O que o criador disse (literal)

> 1 - 24 pro jogo inteiro

> 2 - sim

## Decisão

1. **24 px por tile no jogo inteiro**, não só no hub. A conversão vale para a exploração 2D, a dungeon procedural, o hub e os sistemas de mapa (câmera, movimento, colisão, névoa, inimigos, NPCs, itens e seguidores). O combate 3D não é afetado.
2. **Cena de teste do hub autorizada.** Uma cena isolada, sem serviços, para avaliar a escala e o enquadramento com a Treasure Town.
3. A conversão preserva o comportamento **em tiles**: o mesmo número de tiles visíveis, a mesma velocidade em tiles/s e as mesmas distâncias de detecção/contato.

## Conversão aplicada

| Item | Antes (48 px) | Agora (24 px) |
|---|---:|---:|
| `TILE` da exploração, névoa, inimigos e mapa | 48 | 24 |
| Velocidade do jogador | 180 px/s | 90 px/s |
| Zoom da câmera | 1.5 | 3.0 |
| Colisão do jogador | raio 14 | raio 7 |
| Colisão do NPC | 28×28 | 14×14 |
| Interação do NPC | 36 px | 18 px |
| Velocidade de patrulha/ perseguição | 42/105 px/s | 21/52,5 px/s |
| Contato do inimigo | 26 px | 13 px |
| Raio da névoa | 7,5 tiles | 7,5 tiles |
| Dimensões do andar | 40×26 tiles | 40×26 tiles |
| Seguidores | 200 px/s, gap 48 | 100 px/s, gap 24 |

## Cena de teste

- `scenes/hub_test.tscn`, com script `scripts/hub/hub_test.gd`.
- Fundo: `assets/pmd/hub/treasure_town.png` (recorte 1157×530, fundo branco removido).
- Jogador: `player.gd` com os valores de 24 px; câmera com limites no mapa.
- Colisão básica: borda, prédios principais e rio; NPCs de teste.
- Atalho de debug: **F10** abre a cena a partir do jogo; **ESC** volta para a exploração.
- Sem lojas, sem equipe, sem economia, sem combate e sem VFX novo.

## Ambiguidades em aberto

- A escala visual final dos personagens e inimigos (1.2 nos sprites) precisa da aprovação visual do criador.
- As posições de colisão dos prédios são aproximadas nesta primeira cena.
- Os tilesets do Sky ainda não foram importados; a dungeon segue com o atlas procedural atual, redimensionado para 24 px.
- O recorte da Treasure Town removeu o fundo branco e a faixa inferior (plantas/creditos); o resto do fundo ainda pode ter franjas.
- O dungeon de 24 px ficou escuro no teste; a troca pelos tilesets do PMD deve corrigir a leitura visual.

## Estado no código

Implementado e testado nesta sessão com **Godot 4.7.2**:

- 24 px aplicado em `exploration.gd`, `player.gd`, `npc.gd`, `enemy.gd`, `pickup.gd`, `follower.gd`, `fog_of_war.gd` e `map_visuals.gd`.
- `map_visuals.gd` gera o atlas em 48 px e reduz para 24 px (nearest), preservando o desenho atual até a chegada dos tilesets do PMD.
- Cena `scenes/hub_test.tscn` + `scripts/hub/hub_test.gd`, aberta por **F10** no jogo; **ESC** volta à exploração.
- Capturas: `scratch/hub_test.png` (hub) e `scratch/exploration_24.png` (dungeon).
- Teste headless das duas cenas sem erro de script; captura windowed gerada.

Nada foi commitado ou publicado.
