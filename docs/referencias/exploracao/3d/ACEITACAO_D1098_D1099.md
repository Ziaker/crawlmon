<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Aceitação — ícones 3D e placas (D-1098/D-1099)

- **Data:** 2026-11-10.
- **Cena:** `scenes/debug/murky_forest_3d_lab.tscn` (lab isolado; cópia de teste).
- **Objetivo:** verificar os 5 estados do ícone no NPC e no inimigo, perto/médio/longe, o espelho e o vão com o Flat Card A. **Nenhuma regra ou código do jogo foi alterado.**

## Método

- Bulbasaur (NPC 0) e Slime (inimigo) posicionados no corredor do lab; HUD, player, aliados e os outros NPCs ocultos.
- A folhagem foi ocultada nas provas para não cobrir os marcadores por acaso (ela balança com o vento); os troncos continuam.
- Estados trocados por `_set_icon`, com os tints do lab; sem o “pop”.
- Escalas reais: ícone `0,55 + dist/16` (0,55..1,15); placa `dist/8` (0,28..1,10).
- Vão medido pelo AABB da malha da frente:
  - **NPC:** base do ícone menos topo da placa (o ícone fica **acima** da placa).
  - **Inimigo:** base da placa menos topo do ícone (o ícone fica **abaixo** da placa).
- Câmera alta de terceira pessoa, como no lab; a câmera baixa não foi testada.

## Resultados

| Caso | Resultado | Vão |
|---|---|---|
| NPC, 5 estados, 4,4 m | **OK** — arte, tint, 3D, sem contorno | 0,43–0,50 m |
| NPC perto, 3,0 m | **OK** | 0,58 m |
| NPC médio, 4,4 m | **OK** | 0,45 m |
| NPC longe, 9,0 m | **OK, no limite** | **0,025 m** |
| Inimigo, 5 estados, 4,3 m | **OK** — arte/tint (corpo oculto só para ler o ícone) | 0,53–0,63 m |
| Inimigo in-game, corpo visível | **OK com ressalva** — o `?` e o `!` aparecem acima; o `✳` de fúria encosta no topo do Slime | 0,58 m |
| Inimigo perto, 2,6 m | **OK** | 0,74 m |
| Inimigo longe, 6,1 m | **OK** | 0,42 m |
| Inimigo espelho, 4,0 m | **OK** — ícone e placa de frente para a câmera oposta | 0,61 m |
| Placas NPC/inimigo | **OK** — a arte nova não mexe na placa; os 10 nomes já foram validados na D-1097 | — |

- **Limite conhecido:** a 9,0 m o vão do NPC cai para **0,025 m** (2,5 cm); com o balanço de ±0,045 m, o ícone pode **encostar** na placa. Isso já estava previsto na D-1098 e não é uma regressão da arte sem contorno.
- **Oclusão de cenário:** na prova do NPC a 9 m, um tronco cobre parte do card; o vão do ícone continua visível. Não é falha do marcador.
- **Inimigo:** o diagnóstico com o corpo oculto foi só para ler os 5 estados; a prova in-game com o corpo visível mostra o `!` inteiro acima do Slime. No vídeo, o `✳` de fúria (mais largo) encosta no topo do Slime; o `?` e o `!` ficam acima.

## Conclusão

**Aceitação passa com uma ressalva** para os casos testados. Nenhuma regra, código ou asset foi alterado nesta rodada. O limite do NPC é o vão de 2,5 cm a 9 m, que o balanço pode reduzir a zero/encostar. No inimigo, o ícone fica na altura da cabeça: o `?` e o `!` aparecem acima, mas o `✳` largo encosta no topo do Slime.

## Vídeo

- `docs/referencias/exploracao/3d/murky_forest_lab_state_icons.mp4` — **35,8 s**, 1280×720, 30 fps: walkthrough com a câmera real do jogo + inspeção dos 5 estados, 9 m, inimigo e espelho.
- `docs/referencias/exploracao/3d/murky_forest_lab_enemy_states_preview.gif` — recorte dos 5 estados do inimigo.
- **Ressalva do vídeo:** o ícone do inimigo em `1,05 m` fica na altura da cabeça do Slime; o `?` e o `!` aparecem acima, mas o `✳` de fúria encosta no topo do Slime. Na câmera baixa pode ficar atrás. Se incomodar, o próximo ajuste é **subir o ícone do inimigo** (nova decisão).

## Provas

- `docs/referencias/exploracao/3d/acceptance_d1098_npc_states.png` — NPC, 5 estados.
- `docs/referencias/exploracao/3d/acceptance_d1098_enemy_states.png` — inimigo, 5 estados + in-game.
- `docs/referencias/exploracao/3d/acceptance_d1098_distances.png` — perto/médio/longe e espelho.

## O que não foi verificado

- Câmera baixa/outros pitch (o ícone do inimigo pode ficar atrás do Slime).
- O inimigo na patrulha real (a prova fixou o corpo no corredor).
- As 10 alturas de NPC com o ícone 3D (a D-1097 validou as placas; o nó do ícone é o mesmo).
- O jogo 3D principal (a cena principal ainda é 2D) e mobile/60 fps/resoluções.

## D-1105 (posterior)

O card ficou com 40% da base e o ícone do inimigo subiu para **cima da placa**; a ressalva do `✳` encostando no Slime deixa de valer. As medidas e alturas desta aceitação são históricas.

## Estado

Aceitação registrada; vídeo gravado. Commit local; **sem push**.
