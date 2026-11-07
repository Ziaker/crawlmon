# D-382 — Clima: 20% por andar, 20–40 s e mapa de biomas de D-362

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima
- **Origem:** respostas do criador às pendências de D-381.
- **Status:** números definidos; clima fora do Motion Composer (D-383); neblina implementada (D-384); calor/chuva/neve/distorção pendentes.

## O que o criador escolheu (literal)

> ~20% por andar (1 em 5)

> 20–40 s

> Manter o de D-362

## Decisão

1. **Cadência:** uma rolagem determinística por andar, **20% de chance** (1 em 5). No máximo **um evento por andar**, sem empilhar. A rolagem usa o seed do andar (`dungeon_seed` + índice do andar); revisitar o mesmo andar mantém o mesmo resultado.
2. **Duração:** **20–40 s** por evento, com fade de entrada/saída; a duração exata é determinística pelo seed.
3. **Biomas:** manter o mapeamento de D-362:
   - **calor:** barren valley, dark wasteland, deep boulder quarry, deep limestone cavern, limestone cavern;
   - **chuva:** 4th station pass, murky forest, spacial cliffs, temporal spire;
   - **neve:** biomas de gelo; **cinza:** dark wasteland (variante da chuva);
   - **neblina:** murky forest, spacial cliffs, 7th station pass, icicle forest, vast ice mountain/peak, temporal spire/tower;
   - **distorção temporal:** temporal tower/spire.
4. **Início:** o evento entra no começo do andar, depois do fade de entrada; a batalha é outra cena, então o clima não roda durante o combate. Se o criador preferir no meio do andar, é um ajuste de implementação, não uma regra fechada.
5. **Continua só visual:** nada de regra (D-381); clima fora do Motion Composer (D-383); D-308 fica restrito a VFX de Move/elemento em combate; chuva/neve com CPUParticles2D sob GL Compatibility.
6. **Ordem:** neblina → calor → chuva/neve → distorção temporal; um efeito por vez, com aprovação visual antes do próximo.

## Ambiguidades

- Nenhuma bloqueante para a neblina. Para o calor e a chuva, intensidade, quantidade/velocidade das gotas e respingo serão calibrados visualmente, um ajuste por vez.
- O início no começo do andar é a implementação inicial; não foi uma escolha explícita do criador.

## Estado

Nada implementado. Nenhum código, shader, partícula, cena ou asset alterado. Nada publicado.
