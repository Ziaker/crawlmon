# D-1047 — Reverter as mudanças globais de escala; só Cyclops maior e Slime reduzido

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / Escala / D-1013 / D-1043 / D-1046
- **Origem:** resposta do criador ao vídeo de +30%.

## Frase literal do criador

> "pelo amor de deus, volte atras com todas essas mudancas de escala, so deixe o cyclops um pouco maior e o slime no seu tamanho reduzido tambem"

## Decisão

1. **Reverter** as mudanças globais de escala introduzidas por D-1043/D-1046:
   - sai o `GLOBAL_HEIGHT_SCALE = 1.3`;
   - sai o alvo por malha visível para todos;
   - sai o teto global de 2,5 m aplicado a todos;
   - `_fit_height` volta ao comportamento anterior para Pokémon e Orc.
2. Manter **apenas duas exceções**, usando os alvos que já existem nos perfis DQT:
   - **Cyclops:** fica no `target_height` do perfil, **3,22 m** (um pouco maior que o original de 2,76 m); **D-1053 elevou para 3,58 m e D-1054 para 4,00 m**;
   - **Slime:** fica no `target_height` do perfil, **1,40 m** (reduzido em relação ao original de 3,52 m).
3. Orc, Abra, Pancham, Gible e demais voltam à escala anterior. O Cyclops passa de 2,5 m; isso é consequência direta do pedido "um pouco maior" e supera o teto global anterior **para ele**.
4. A partir daqui, não aplicar +30% nem normalização global sem nova decisão.

## Ambiguidades em aberto

- "Um pouco maior" para o Cyclops foi interpretado como o alvo já existente no perfil (3,22 m). Se o criador quiser outro valor, ajustar.
- "Tamanho reduzido" para o Slime foi interpretado como o alvo já existente no perfil (1,40 m). Se quiser outro valor, ajustar.

## Estado

Implementado em `battle_scene.gd`; testado no jogo normal e na sala. Medições: Orc 3,191 m, Slime 1,427 m, Cyclops 3,275 m, Gible 2,891 m. Vídeos: `test_captures/scale_test/game_revert_normal_mirror.mp4` (jogo normal restaurado) e `test_captures/scale_test/dqt_revert_normal_mirror.mp4` (só Cyclops maior e Slime reduzido). Sem commit/push.
