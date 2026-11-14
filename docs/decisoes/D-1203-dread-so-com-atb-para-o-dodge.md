# D-1203 — O Dread só aparece se o jogador tem o ATB necessário para o dodge

- **Data:** 2026-11-12.
- **Área:** Combate / Evade / Dread (visual).
- **Origem:** conversa com o criador.
- **Status:** regra registrada; implementação delegada ao `deepseek-code`.

## Frase literal do criador

> uma feature nova, mande o deepseek criar uma condição, só aparece o dread se o jogador tiver a quantidade necessária de ATB (3) pra poder realizar o dodge

## Decisão

1. O Dread (`FxEvadeFlash`) só acende se o líder do jogador tem ATB suficiente para o Evade: `leader.blocks() >= battle.evade_cost(leader)` (hoje 3 blocos; o valor vem do custo real, não de um 3 fixo).
2. Sem ATB suficiente, nenhum Dread aparece, para qualquer Move (corpo a corpo e projétil).
3. Só visual (D-019): custo, janela, regra do Evade e IA não mudam. Apertar Evade sem ATB continua como já é.

## Resposta do criador (2026-11-13)

Sobre o ATB cair abaixo do custo com o Dread já aceso (apagar na hora ou terminar o fade):

> apaque na hora

Decisão: o Dread apaga na hora.

## Estado

Implementado em `FxEvadeFlash.update` (`leader_can_afford_dodge`), teste isolado `tests/battle/test_dread_atb_d1203.gd` e suíte de combate 30/30. Falta verificação no jogo com ATB zerado (cenário de debug), delegada ao DeepSeek.
