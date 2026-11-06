# D-931 — Voltar para 48 px

> **Renumerada em 2026-11-06:** D-329 → D-931. O ID D-329 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-05
- **Área:** Exploração / visual / implementação
- **Origem:** Conversa (feedback do teste de 24 px)

## O que o criador disse (literal)

> ok vamo voltar atras com 48px a perda de qualidade foi imensa

## Decisão

1. O jogo volta a usar **48 px por tile** na exploração 2D, na dungeon e no hub. A conversão para 24 px da D-930 fica **cancelada**.
2. A **cena de teste do hub permanece**, agora em 48 px, para avaliar a Treasure Town sem a perda de qualidade.
3. Os efeitos de ambiente que tinham sido reduzidos pela metade (tochas, brasas, poeira, sombras) voltam às medidas de 48 px.
4. A ordem dos assets (D-928) e o uso dos tilesets modulares continuam; os tilesets do PMD são de ~24 px e, se forem usados no jogo de 48 px, precisam de escala 2× ou de um tratamento próprio — a definir quando forem importados.
5. Nada de VFX novo por esta decisão.

## O que foi revertido

- `TILE` 24 → 48 em `exploration.gd`, `fog_of_war.gd`, `enemy.gd` e `map_visuals.gd`.
- Jogador: 90 → 180 px/s, colisão 7 → 14, câmera 3.0 → 1.5.
- NPC: colisão 14×14 → 28×28; interação 18 → 36.
- Inimigos: 21/52,5 → 42/105; contato 13 → 26; visual de volta ao tamanho original.
- Pickup: 12 → 24; visual original.
- Seguidores: 100 → 200; gap 24 → 48.
- `map_visuals`: atlas sem downscale; tochas/brasas/poeira/sombras de volta às medidas de 48 px.

## Estado no código

Revertido nesta sessão; a cena do hub passa a usar 48 px (câmera de teste em 2× inteiro para a folha nativa da Treasure Town). Testar no Godot 4.7.2 e capturar de novo.
