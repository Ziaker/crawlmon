<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1150 — A pausa de status começa no quadro da declaração e não deixa um ataque resolver depois

- **Data:** 2026-11-11.
- **Área:** Combate / Pausa de status / Fila D-161 / Ordem de quadro.
- **Origem:** relato do criador de que o Move clicado ainda era cancelado ao mesmo tempo que um personagem entrava no wind-up de um status que pausa o jogo.
- **Status:** regra registrada; implementado e testado headless.

## O que o criador disse (literal)

> "tá mas os bugs relacionados ao Queue e a moves sendo cancelados quando clicados ao mesmo tempo que um personagem entra no wind-up de um move que pausa o jogo ainda persiste."

Respostas da rodada:

- **Golpe:** "Status real que pausa" (Rakunda/Tarukaja/Sukunda/Media/Bubble Shield/Armored Bulk).
- **O que acontece:** "não sei dizer, é meio que tudo ao mesmo tempo, simplesmente cancela".
- **ATB:** "Sim e PERDEU depois que foi cancelado".

## Diagnóstico

O `_process` do `Battle` fazia, na mesma passagem:

1. `_ai.run(delta)` — a IA podia declarar um Move de status e gravar `_status_pause`;
2. `_resolve_incoming(delta)`;
3. `_step_attacks(delta)`;
4. `_run_queued()`.

Não havia nova checagem de `_status_pause` depois do passo 1. Assim, **no mesmo quadro em que a pausa começava**, um ataque que já estava em voo ainda podia resolver. Se esse ataque interrompesse o Move atual do líder, `_interrupt_attacks_of` cancelava o Move e limpava a vaga da fila (D-161). O ATB já pago não voltava, e o jogador via “tudo ao mesmo tempo”: o status entrava no wind-up, o Move sumia e o ATB ficava gasto.

## Decisão

1. **A pausa de status começa no quadro em que é declarada.** Depois de `_ai.run`, se `_status_pause` ficou ativo, o `Battle._process` emite `state_changed` e retorna **sem** `_resolve_incoming`, `_step_attacks`, `_run_queued`, recompensas ou engajamento naquele quadro. Vale D-031 (“desde o preparo”).
2. **O mesmo vale quando a fila inicia um Move de status:** se `_run_queued` criar `_status_pause`, o resto do quadro não roda.
3. **A fila não é limpa pela pausa em si.** Um Move escolhido durante a pausa continua na vaga e começa quando ela termina, com o alvo vivo e o ATB/MP disponíveis (D-161/D-1146).
4. **O cancelamento por interrupção real continua:** se um hit ou War Cry realmente interromper o Move atual, a vaga cai (D-064/D-161) e o ATB já pago não volta.
5. **War Cry não entra nesta pausa:** ele continua sem `_status_pause` (D-1127/D-1147); o guard só se aplica a Moves de status que pausam de verdade.

## Ambiguidade / limite do diagnóstico

- O relato não trouxe o nome exato do Move nem um vídeo. A ordem de quadro acima é uma causa real e reproduzível em código; se o caso do criador não for esse, ainda pode haver outro caminho.
- Não foi alterado o descarte da vaga quando o alvo morre, o ATB falta na execução ou o ator é atordoado (D-161).
- Não foi alterado o cancelamento por interrupção real (D-064/D-161).

## Estado no código

Implementado (2026-11-11):

- `scripts/combat/battle.gd`: dois guards de `_status_pause` no `_process` (depois da IA e depois da fila).
- `tests/battle/test_d1146_queue_and_status_pause.gd`: novo caso com um ataque em `STAGGER` no `_landing` e IA declarando status no mesmo quadro; o ataque **não** avança depois da pausa e a fila sobrevive.
- Regressões: `test_d160_d164_combat_fixes.gd` e `test_d1146_queue_and_status_pause.gd`.

## Ferramentas de debug adicionadas

> **Leia `docs/TELEMETRIA.md` (D-1154) antes de interpretar os eventos.**

- `scripts/combat/battle_trace.gd`: eventos `queue`, `status_pause_started/ended` e `interrupted_windup`; cada quadro traz `q` (Move na vaga), `qt` (alvo), `sp` (Move de status que pausa) e `sp_by`. O evento `queue` diz `started` quando a vaga esvaziou porque o Move começou e `lost` quando foi realmente descartada.
- `scripts/debug/vfx_room.gd`: ação `queue` para enfileirar de verdade pelo `Battle.request_skill`; `SUMMARY_JSON` agora inclui `queue_events`, `queue_started` e `queue_lost`; `_busy()` considera a pausa de status, então a sala não encerra no meio dela.
- `scripts/debug/vfx_room_scenarios.gd`: cenários `fila_status_pausa`, `fila_status_click` e `fila_war_cry` (o último mostra o cancelamento esperado por D-064).
- `tests/battle/run_agent_combat_tests.py`: três cenários novos; execução final **19/19 PASS**.
- Evidência: `fila_status_pausa` termina com `queue_lost=0` e `started=true`; `fila_status_click` começa em t=2,45 s com `queue_lost=0`; `fila_war_cry` registra `lost` em t=1,11 s (War Cry), como esperado.
