# D-1098 — Ícones de estado em 3D, maiores

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / ícones de estado (`?`, `!`, fúria, suor, conversado).
- **Relacionadas:** D-1086 (ícones de estado), D-1090 (ícones +25%), D-1097 (placa A e alturas), D-235 (nada depende de personagem/time/lado), D-1093 (arte estabelecida).
- **Status:** **implementado/provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera, retratos e a placa A não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> prioridade 3 tem coisas irrelevantes e redundantes

> aumente o tamanho e deixe 3D

(anexo: o ícone `?` amarelo acima do NPC)

## Regra

1. **Os ícones de estado do overworld deixam de ser `Sprite3D` 2D** e passam a ser **malhas 3D extrudadas** com a mesma arte na frente e laterais/fundo no tom escuro do próprio tint. O `?` do anexo é a referência; o mesmo tratamento vale para `!`, fúria, suor e conversado.
2. **Tamanho:** o ícone passa de **0,56 m** (128 px a 0,004375) para **1,00 m** de altura (~+79%). A profundidade é de **0,16 m**, para o volume aparecer.
3. **Leitura 3D:** o ícone continua de frente para a câmera, mas com um **yaw de ~-28°** (mais uma oscilação suave), para a espessura/lateral aparecer sem perder a leitura.
4. **Mesmo comportamento de estado:** os ícones continuam trocando por `_set_icon()` (questão, alerta, fúria, suor, conversado), com o mesmo tint e o mesmo "pop"; nada de regra de jogo muda.
5. **Alturas:** placa A em `altura + 0,65 m`; **ícone de estado em `altura + 1,85 m`**; reticências de fala em `altura + 1,65 m`; inimigo: placa em `2,20 m` e ícone em `1,05 m`.
6. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, retratos e o Flat Card A (D-1097).

## Implementação

- `assets/ui/overworld_icons3d/`: para cada um dos 5 ícones, uma malha de frente com UV e uma malha de lateral/fundo escuro.
- `scripts/debug/overworld_state_icon.gd`: nó 3D com frente texturizada, lateral/fundo no tom escuro do tint, billboard com yaw de -28°, troca de estado e tint.
- `murky_forest_3d_lab.gd`: `_add_state_icon`, `_update_state_icons` e `_set_icon` usam o nó 3D; ícone em `altura + 1,85 m`; inimigo em `2,20 m`; reticências em `altura + 1,65 m`.

## Provas

- `docs/referencias/exploracao/3d/state_icon_3d_states.png` — os 5 estados em 3D.
- `docs/referencias/exploracao/3d/state_icon_3d_front.png` — o `?` 3D de frente, com a lateral.
- `docs/referencias/exploracao/3d/state_icon_3d_side.png` — lateral, espessura de 0,16 m.
- `docs/referencias/exploracao/3d/state_icon_3d_back.png` — fundo fechado.
- `docs/referencias/exploracao/3d/state_icon_3d_inworld.png` — o `?` 3D dourado acima do Flat Card A.

## O que foi verificado

- Os 5 estados (`question`, `alert`, `anger`, `sweat`, `talked`) carregam frente e lateral, com tints diferentes.
- O `?` 3D no cenário, dourado (quest), acima do Flat Card A; vão de 0,14 m entre a base do ícone e o topo da placa (escala-base).
- `_set_icon` troca o estado e a malha; o `pop` e a escala por distância continuam.
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`; checks dos scripts OK.

## O que não foi verificado

- Todos os estados em todos os ângulos/distâncias e no inimigo em jogo; a prova cobre os 5 estados e o `?` no NPC.
- Mobile/60 fps/resoluções e a cena principal completa (VFX de outra sessão).

## Estado

Implementado e provado. Commit local; **sem push**.
