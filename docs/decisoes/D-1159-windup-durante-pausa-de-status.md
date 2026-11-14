<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1159 — Wind-up pode começar durante a pausa de status e fica parado

- **Data:** 2026-11-11.
- **Área:** Combate / Pausa de status D-031 / Ações.
- **Origem:** conversa, depois de o criador relatar que Moves ainda eram cancelados após um Move de status e que o ATB era perdido.
- **Status:** regra registrada; implementado e testado headless.

## O que o criador disse (literal)

> "o problema persiste, moves tão sendo cancelados após a efetuação de um move de status, perdendo ATB também, inclusive permita que eles comecem suas wind-ups durante o pause (mas continuem parados)"

## Decisão

1. **Move de ataque pode começar durante a pausa de status.** Um Move **não-status** escolhido durante a pausa inicia o wind-up imediatamente: paga o ATB/MP normal, cria o `Incoming` e fica **parado** (o `time_left`/fase não avança) até a pausa terminar.
2. **A animação do novo wind-up também fica parada.** O `BattleFx` congela o AnimationPlayer do novo atacante e o coloca no lote da pausa ativa; ao terminar a pausa, ele é descongelado e o wind-up segue.
3. **Move de status não começa durante outra pausa.** Para não aninhar/trocar `_status_pause`, um Move de status escolhido durante a pausa continua indo para a vaga D-161 e espera a pausa acabar. Ataques (MELEE/CAST/PROJECTILE) podem começar.
4. **A pausa não cancela o Move iniciado.** Ele não é limpo nem interrompido pela pausa; fica congelado e continua depois. O cancelamento por hit/War Cry real continua valendo (D-064/D-161/D-1102).
5. **A vaga D-161 continua esperando a pausa** quando o Move foi enfileirado antes; a exceção do item 1 é para a escolha feita durante a pausa. (Se o criador quiser que a vaga também comece, é ajuste novo.)
6. **ATB:** o pagamento acontece no início do wind-up, como em qualquer Move. Se um hit/War Cry real interromper depois, o ATB não volta (D-1102/D-161); a pausa em si não cobra e não cancela.
7. **Simetria D-235:** vale para qualquer personagem, time, lado e alvo.

## Ambiguidades em aberto

- O relato de ATB perdido **não foi reproduzido** como cancelamento causado pela pausa em si. Se o culpado for War Cry ou hit, o trace mostrará `interrupted_windup`/`interrupted` + `queue.lost`; a regra de estorno continua a de D-1102/D-161.
- Se o criador quiser que **Move de status** também comece durante a pausa, é necessário decidir como lidar com duas pausas (fila de pausas, substituição ou bloqueio). Não implementado.
- Se quiser que a **vaga D-161** comece durante a pausa, também é ajuste novo.

## Relação com decisões

- **D-031:** a pausa continua; o novo wind-up não avança.
- **D-161:** a vaga continua esperando; a escolha direta durante a pausa inicia.
- **D-1150:** a pausa começa no quadro da declaração e não deixa ataque resolver depois.
- **D-1154:** o trace registra `queue`/`interrupted_windup`/`status_pause` e permite ver o culpado.
- **D-019/D-1040:** lógica e animação congelam juntas; nenhum relógio visual próprio.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle.gd`: `use_skill` permite não-status durante `_status_pause`; `request_skill` usa `can_start_windup_now`; `can_start_now` continua falso para fila/IA.
- `scripts/combat/battle_scene.gd`: a lista mostra `queue` só para Move de status durante a pausa; ataque começa no wind-up.
- `scripts/combat/battle_fx.gd`: congela o novo wind-up no lote da pausa ativa e descongela no fim.
- `tests/battle/test_d1159_windup_during_status_pause.gd` — **passa 10/10**.
- Cenário `windup_pausa_com_ataque` na sala: mostra que, se um ataque inimigo já está em voo, ele pode acertar o wind-up depois da pausa; o trace registra `interrupted`/`hit`, não `status_pause` como cancelador.
- **Não verificado:** vídeo in-game e o caso de vários wind-ups novos durante a mesma pausa.
