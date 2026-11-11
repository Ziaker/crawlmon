# D-1033 — Tamanho coerente: nenhum personagem acima de 2,5 m; VFX não obstrui a visão

- **Data:** 2026-11-09
- **Área:** Visual / VFX / Modelos / D-1013
- **Origem:** resposta do criador à pergunta 4 da auditoria.

## Frase literal do criador

> "4 - os tamanhos devem ser coerentes e não obstruir visão, nada de gigantes, ngm deve ter mais do que 2,5M"

## Decisão

1. **Nenhum personagem/modelo de batalha pode ter mais de 2,5 m de altura.** O teto é uma proteção contra "gigantes"; não substitui a altura-alvo da D-1013.
2. A D-1013 continua valendo como alvo: **1,2 m** para todos os modelos de batalha. O teto de 2,5 m é o limite absoluto; 1,2 m é o valor normal.
3. Os **VFX devem ser coerentes com o corpo real** e não podem obstruir a visão do jogador. Nada de efeito gigante que cubra personagem, alvo ou HUD.
4. A ferramenta 4 deve reportar a altura real e sinalizar qualquer unidade acima de 2,5 m; ela não deve normalizar nem inventar escala por conta própria.
5. Esta decisão **não altera código de jogo** nesta rodada. A correção de escala dos modelos DQT (medidos em 2,76–3,52 m) exige uma rodada própria.
6. **Conflito resolvido com a D-308 item 6:** para VFX, vale o tamanho **coerente com o corpo real e sem obstruir a visão** (esta decisão), **não** o "tamanho fixo em metros" da D-308 item 6. O item 6 fica superado por D-1033.

## Ambiguidades em aberto

- O teto de 2,5 m vale **só para personagens/modelos** ou também para o tamanho final de um VFX? A frase "ngm" foi lida como personagens; se o criador quiser o mesmo teto para VFX, confirmar.
- A pergunta original sobre `pose_height` foi respondida em D-1041: não trocar para pose canônica; a canônica dos DQT é muito maior que a dos Pokémon. A leitura oficial continua pendente.

## Estado

Regra registrada. **D-1047/D-1054 (2026-11-09):** o Cyclops ficou em **4,00 m** por pedido do criador; é exceção ao teto de 2,5 m. O restante da regra continua. Sem commit/push.
