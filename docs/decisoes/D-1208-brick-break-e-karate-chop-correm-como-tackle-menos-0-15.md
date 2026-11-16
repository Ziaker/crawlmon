# D-1208 — Brick Break e Karate Chop: corrida igual à do Tackle normal, 0,15 s mais curta

- **Data:** 2026-11-14.
- **Área:** Combate / trajetória (travel) / Moves corpo a corpo.
- **Relacionadas:** D-169, D-241, D-1194, D-018, D-341, D-1079, D-235.
- **Status:** implementado; testes não rodados após a mudança.

## O que o criador disse (literal)

> "remova o run base fixo dos dois e os deixe com o mesmo travel de um tackle normal porém com 0,15 segundos a menos"

## Decisão

1. Brick Break e Karate Chop perdem o `run_base` fixo (0,24 s e 0,45 s). A corrida passa a ser a do Tackle (distância ÷ velocidade de corrida, AGI, passos, `travel_extra`), menos 0,15 s.
2. Novo campo genérico do `MoveData`: `run_offset` (segundos somados à corrida final; 0 = desligado). Os dois Moves usam `-0.15`. Vale para qualquer Move e personagem (D-235).

## Escolhas técnicas da IA (o criador pode mudar)

- O desconto é aplicado depois de AGI, passos e `travel_extra`; piso de 0 s.
- O menu de luta (`preview_travel`) não considera o `run_offset`; não foi pedido.
- O 0,12 s de partida do TRAVEL e o tempo de STRIKE (0,53 s) não mudam.

## Substitui

O `run_base` de 0,45 s do Karate Chop (D-169) e a corrida fixa de 0,24 s do Brick Break.
