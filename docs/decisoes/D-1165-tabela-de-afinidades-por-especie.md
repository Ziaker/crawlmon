# D-1165 — Tabela de afinidades por espécie (export do criador)

- **Data:** 2026-11-11
- **Área:** Conteúdo / afinidades / dano.
- **Origem:** o criador definiu a tabela na matriz de afinidades e exportou o JSON.
- **Estado:** aplicada nas 6 espécies que já existem no jogo; as outras 10 ainda não têm `species.tres`.

## Declaração literal do criador

> "já exportei o json das afinidades que é o que defini pras fraquezas e resistências"

## Fonte

- `content/affinities/crawlmon_affinities.json` — export de 2026-11-11T15:34:47Z, 16 personagens, **32 Weak** e **28 Resist**.
- O mesmo conteúdo estava em três exports idênticos; o mais recente foi o usado.
- A matriz `prototypes/affinity_matrix.html` agora carrega essa tabela como padrão (e no "Resetar jogo").

## Tabela oficial

| Personagem | Fraco a | Resiste a |
|---|---|---|
| Abra | Electric, Sound, Dark, Mystic | Psychic |
| Pancham | Psychic | Nature, Dark |
| Gible | Water | Neutral, Nature, Dark |
| Slime | Fire, Electric | Water, Nature |
| Orc | Electric, Psychic, Sound | Neutral, Earth, Dark |
| Cyclops | Psychic, Light | Neutral, Earth, Dark |
| Bulbasaur | Fire, Electric | Earth, Nature |
| Charmander | Earth | Fire, Nature |
| Squirtle | Electric | Fire, Earth, Nature |
| Pikachu | Earth | Electric |
| Eevee | Earth, Psychic | — |
| Dracky | Fire, Electric, Earth, Light | Wind, Sound |
| Heal Slime | Fire, Electric, Earth | Water, Wind, Nature |
| Sabrecub | Sound | — |
| Platypunk | Psychic, Sound, Light | — |
| Funghoul | Fire | Nature |

Todo o resto é **Neutral**.

## O que foi aplicado

- `tools/apply_affinities.py` lê o JSON e escreve nos `content/characters/<id>/species.tres`:
  - `affinities` com as **12 entradas explícitas** (elemento 0–11 → afinidade 0/1/2), para que `NEUTRAL` explícito vença o fallback;
  - `weaknesses` sincronizado com a lista de WEAK, porque StatusScreen/StatusPanel/Menus ainda leem esse campo legado.
- Espécies gravadas: `abra`, `pancham`, `gible`, `dqt_slime`, `dqt_orc`, `dqt_cyclops`.
- **Não aplicadas (sem `species.tres`):** bulbasaur, charmander, squirtle, pikachu, eevee, dqt_dracky, dqt_healslime, dqt_sabrecub, dqt_platypunk, dqt_fungi. A tabela delas fica no JSON para quando entrarem no jogo.

## Efeitos que merecem atenção

- **Abra agora é fraco a Mystic:** Megido (Mystic, D-1144) contra Abra passa a 1,5×.
- **Gible, Orc e Cyclops resistem a Neutral:** Tackle contra eles passa a 0,5×.
- Nenhum personagem recebeu `NULL`, `REPEL` ou `DRAIN` (D-1161).

## Verificação

- Godot headless carregou os 6 `.tres`: **12 entradas cada, 0 ausentes**.
- `test_d1157_affinity_schema.gd`: **D1157_PASS**.
- `test_d1152_damage_golden.gd`: **D1152_PASS**.
- O JSON da matriz bate com o que foi gravado (o script é idempotente: rodar de novo mostra "ja iguais").

## O que não foi feito

- 10 espécies sem `species.tres` não receberam dados no jogo.
- StatusScreen/StatusPanel/Menus continuam lendo `weaknesses` (agora sincronizado, mas não migrado para `affinities`).
- Nada de commit/push (D-022).
