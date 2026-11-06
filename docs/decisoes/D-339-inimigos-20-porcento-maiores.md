# D-339 — Inimigos 20% maiores em todas as batalhas (em vez de trazê-los para perto)

- **Data:** 2026-11-05
- **Área:** Combate / Visual
- **Origem:** Conversa

## O que o criador disse (literal)

> "Ainda estão mt longes, é difícil ver eles,  trazer mais pra perto pode comprometer o trajeto? Se sim deixe os inimigos naturalmente 20% maiores em todas batalhas, mas primeiro me responda"

## Resposta dada

Sim: a duração da corrida é `distância / 30` (limitada a 0,6–1,1 s) e a do voo de projétil `distância / 50` (0,25–0,7 s), em `attack_planner.gd` (`base_run`, `base_fly`). Aproximar as linhas encurta o trajeto e, com ele, a janela de Evade (D-016, D-030).

## Decisão

Os inimigos não se aproximam. Em todas as batalhas, a escala extra dos modelos inimigos sobe 20%: `ENEMY_SCALE` 1,8 → **2,16**. Posições, distância entre as linhas e tempos de trajeto não mudam.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

`scripts/combat/battle_scene.gd` (`ENEMY_SCALE`).
