# D-1046 — Aumento global de 30% na escala dos personagens

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / Escala / D-1013 / D-1033 / D-1043
- **Origem:** resposta do criador ao vídeo do jogo normal após D-1043.

## Frase literal do criador

> "Estao absurdamente minusculos no jogo normal, deixe todos maiores, 30%"

## Decisão

1. Aplicar um multiplicador global de **1,3×** na altura-alvo de todos os modelos de batalha.
2. Com isso:
   - Pokémon comuns: 1,2 m → **1,56 m**;
   - Slime DQT: 1,4 m → **1,82 m**;
   - Orc DQT: 2,1 m → 2,73 m, limitado a **2,5 m**;
   - Cyclops DQT: 3,22 m → limitado a **2,5 m**;
   - nenhum modelo passa de **2,5 m** (D-1033 continua).
3. O teto de 2,5 m é mantido: Orc e Cyclops não recebem os 30% integrais porque já estavam no limite. Se o criador quiser 30% **sem** teto, isso exige nova decisão.
4. A D-1043 continua valendo na parte das proporções relativas dos perfis DQT; a D-1013 fica atualizada para o alvo de 1,56 m dos Pokémon comuns.
5. A correção é aplicada em `battle_scene._fit_height`, que mede a malha visível.

## Ambiguidades em aberto

- "Todos, 30%" incluía também o Orc e o Cyclops acima de 2,5 m? A decisão atual mantém o teto. Se o criador quiser ultrapassar, confirmar.

## Estado

**Revertida por D-1047** após o criador dizer "volte atras com todas essas mudancas de escala". O +30% não está mais no jogo. Sem commit/push.
