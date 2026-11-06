# D-944 — Orc e Cyclops 1,2× maiores no lado do jogador

> **Renumerada em 2026-11-06:** D-342 → D-944. O ID D-342 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-06
- **Área:** Visual / Piloto DQT
- **Origem:** Conversa

## O que o criador disse (literal)

> "o orc e o cyclope estão um pouco baixinhos demais pro tamanho deles no lado do jogador, faça eles terem 1.2x (que já tem no lado do oponente, sem mudar o tamanho nesse lado) no lado do jogador"

## Decisão

1. Quando o Orc ou o Cyclops estão no **lado do jogador**, o modelo fica **1,2×** maior.
2. No lado do oponente nada muda (lá já vale o aumento de inimigos da D-941).
3. Slime e Pokémon não mudam.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

`dqt_model_profiles.gd` (`ally_scale` nos perfis do Orc e do Cyclops) e `battle_scene.gd` (`_spawn`).
