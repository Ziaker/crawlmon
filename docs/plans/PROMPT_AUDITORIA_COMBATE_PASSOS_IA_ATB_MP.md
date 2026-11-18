# Prompt: auditoria completa e correção das mudanças de combate de 2026-11-17

Cole isto numa sessão nova, na raiz do repositório `crawlmon`.

---

Você vai auditar e corrigir um conjunto de mudanças de combate feitas em 2026-11-17 por outra sessão. O objetivo é achar bugs, regressões e inconsistências e corrigi-los, sem mudar nenhuma regra além do que está descrito abaixo.

## Regras do criador (obrigatórias)

- Leia `AGENTS.md`, `CLAUDE.md`, `docs/TELEMETRIA.md` e as decisões **D-1297, D-1298, D-1299, D-1300, D-1301** em `docs/decisoes/` antes de qualquer coisa. Rode `node ~/.claude/tools/ds-decisions.mjs <arquivo-com-a-tarefa>` para ler as demais decisões, e refaça qualquer lote que falhar.
- Ao falar com o criador **não use códigos de decisão (D-xxxx) sem explicar em uma frase o que a decisão diz**. Ele pediu isso.
- Nunca decida regra, valor, visual ou escopo pelo criador. Se achar um defeito que exija escolher uma regra, pergunte, com a sua recomendação. Detalhe técnico pode decidir sozinho e dizer o que escolheu.
- Teste sempre pela sala de debug/`BattleDebug` e por scripts headless de lógica, nos **dois lados** (aliado e inimigo, nada fixo por personagem), cada teste em menos de 10 s. Nunca abra janela do Godot com foco (o hook acrescenta `--no-window`); use `--headless --script`. Nunca declare visual "pronto/aprovado": quem valida o visual é o criador.
- Não rode `git stash/checkout/reset`. Outras sessões editam a mesma árvore: confira `git status` e comite só os seus arquivos, sem push. Os arquivos `battle.gd`, `battle_scene.gd`, `battle_trace.gd` e `docs/TELEMETRIA.md` têm edições não commitadas de outras sessões: ao comitar, use só os trechos seus (`git apply --cached` de um patch filtrado).
- Delegue implementação mecânica ao `deepseek-code` via `ds-run.mjs` conforme `CLAUDE.md`; revise o diff inteiro.

## O que foi mudado (commits `2f67deca`, `98823619`, `39c965cf`, `0f477c35`, `685b9e95`)

1. **ATB flutuante em tempo real (D-1297):** o voo dos tokens de recompensa de ATB/Burst não para com hit-stop, pausa de status nem câmera lenta. Em `Battle._process` (`scripts/combat/battle.gd`) o `_reward_queue.step(delta / max(Engine.time_scale, 0.05))` foi movido para antes do freeze; a chamada antiga no fim foi removida. Continua congelado durante o Employ.
2. **Regen de MP em Move sem MP (D-1298):** durante o windup de um Move com `mp_cost == 0` o pulso de MP continua (`Battle._acting_spends_mp`, ramo `elif` no laço de `_process`).
3. **Passos de posição sem trava, sem ATB, em fila (D-1299):** `can_step` só recusa fora de −2..+2; `step` guarda em `Combatant.queued_step` se ocupado; `_run_queued_steps` roda quando ocioso (`_can_step_now`); `_do_step` aplica. `STEP_COST` foi removida. `step_block_reason` agora só devolve `"na fila"` ou vazio. `Combatant.tactic_manual` marca posição escolhida pelo jogador no Tactics (`battle_scene.gd`).
4. **IA de posição por Nature e contexto (D-1299, D-1301):** novo `scripts/combat/battle_positioning.gd` (`BattlePositioning`), ligado em `battle_ai.gd` (`_position`, `positioning`, `_weighted_target`). Sinal `Battle.ai_positioned`, evento `pos_decision` em `battle_trace.gd`, seção nova em `docs/TELEMETRIA.md`. A escolha de alvo da IA passou de aleatória para sorteio ponderado por dano esperado e Nature (o criador aprovou mudar a regra antiga de alvo aleatório).
5. **Idles do Orc/Cyclops (D-1300):** só investigado, **nada alterado**; causa não encontrada, aguarda o criador dizer qual é o idle novo.

Testes novos: `tests/combat/test_d1297_d1298.gd` e `tests/combat/test_d1299_positioning.gd` (headless: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/combat/<arquivo>.gd`; antes rode `--headless --path . --import` se mexer em `class_name`).

## O que auditar (cada item com evidência por dado, não por impressão)

**A. Passos livres e fila**
- Todos os chamadores de `Battle.step`, `can_step`, `step_block_reason`: `battle_scene.gd` (Tactics, `_pos_text`, `_on_menu_side`), `scripts/debug/vfx_room.gd` (linhas ~3818 e ~4231), `battle_ai.gd`, testes antigos. Algum ainda supõe custo de 1 ATB, recusa por bloqueio ou texto "1 ATB"/"falta ATB"/"em ação"? Atualize os textos e a sala de debug.
- `queued_step` é limpo na morte, no fim da batalha, no `clear_pending`, no `save_state`/`restore_state` do `Combatant` (`combatant.gd` ~linhas 929–1000) e no Summon/troca de aliado (`_finish_arrival`)? Hoje o snapshot **não** guarda `queued_step` nem `tactic_manual`: confira e corrija.
- A cópia de `tactic_manual` na troca de aliado (Summon) **ficou de fora do commit** (o trecho de `battle.gd` tem edição de outra sessão misturada): reaplique-a com cuidado.
- Passo durante Guard, stun, engajamento (Evade perfeito), pausa de status e Employ: `_can_step_now` usa `can_start_now` (que já exclui Guard e pausa de status) — confirme que o passo na fila roda **uma vez** quando fica ocioso, sem andar no meio de um ataque, e que não fica preso para sempre (ex.: Guard longo, engajamento sem fim).
- Posição lida no instante do golpe (`Battle._hit`, ~linha 1226): confira que `pos_step` muda instantaneamente e que nada (planner, `AttackPlanner`, alcance, `BodyFootprint`, câmera, HUD das marcas de posição) depende de o passo ter custado ATB ou de `step_t == 1`.
- `attack_planner.gd`/`travel_seconds`: a posição afeta o tempo de viagem. Com passos livres e instantâneos, existe oscilação ou "teleporte" visual de modelo durante um ataque em curso? Verifique `_update_positions`/`rest_pos`.

**B. IA de posição (`battle_positioning.gd`, `battle_ai.gd`)**
- Leia o arquivo inteiro. Procure: divisão por zero, tipos (`Array[Combatant]` vs `Array`), chamadas a métodos privados do `BattleAI` (`_moves_of`, `_damage_to`, `_plans`), uso de `ai.COST_WEIGHT`/`BattleAI.UNRESOLVED_ETA`, desempenho (cálculo por combatente a cada 0,3 s com N×M foes×skills), `inc.skill == null`, `Skill.target_mode`, `MoveData.TargetMode.DUAL`, AoE, Moves de status, Burst, `mp` insuficiente.
- Nature: confira os eixos (`profile`) contra `scripts/data/nature_data.gd` (18 Natures); `nature_id` vazio é neutro. O criador recebeu estes números do medido em IA contra IA (120 s, 6 Natures): Timid/Modest/Calm quase sempre em −2; Adamant 72–94% no centro (menos ousado que o esperado); Brave 94–100% parado no centro (AGI −3 encarece o passo); Jolly o mais móvel. Não ajuste pesos sem pedir: reporte e pergunte.
- O líder que o jogador controla e quem tem `tactic_manual` não usam a IA de posição; confirme também para o `menu_owner()` mudando (protagonista morto).
- Sem personagem/time/lado fixo (D-235): rode os testes com o ator nos dois times e com 2 e 3 combatentes por lado.
- `_weighted_target`: confira engajamento, taunt, alvo morto, lista vazia, `top == 0`, e que não quebrou `_pick_target` em Moves de alvo aliado (`pick_ally_target`) nem o Employ/Summon.
- Telemetria: `pos_decision` só quando a posição muda; confira `--strict-asserts` e `--stdout-trace` num cenário real e documente quaisquer lacunas.

**C. ATB flutuante e MP**
- Os tokens continuam coerentes com o HUD (`reward_layer.gd`, `battle_hud.gd` `reward_dest/reward_source`, `_on_reward_landed`), inclusive com `Engine.time_scale = 0` (pausa do debug), `freeze`, status pause e fim de batalha (`running == false`, vitória: `_reward_queue` ainda anda?). Há vazamento de tokens se a batalha reinicia (`rewards.clear()`)?
- `Engine.time_scale` pequeno: `delta / max(time_scale, 0.05)` pode dar saltos grandes? Avalie o `0.05`.
- MP: `_acting_spends_mp` percorre `incoming + _landing + _returning` a cada quadro por combatente: custo aceitável? Cobre `STAGGER`/retorno? Moves com `mp_cost > 0` que o Employ cancela e devolve (`inc.paid_mp_timer`) continuam corretos? O estado de `stun_timer`/`blind_timer`/`guard_timer`, que também param durante o windup por `tick()`, **não** foi tocado: confirme que o `tick_mp_regen` isolado não duplica contagem quando o combatente sai do windup.

**D. Regressões**
- Rode `python tests/battle/run_agent_combat_tests.py` (e os de `tests/combat/*.gd`, incluindo `test_employ_rhythm.gd`, `test_d1223_ally_proficiency.gd`) e a sala de debug `--scenario=...` nos grupos de fila/pausa (`windup_pausa_com_ataque`, `choque_*`, `dano_*`). Compare com o estado anterior aos commits (`git stash` é proibido; use `git worktree` temporário só se o criador permitir, ou leia os diffs).
- Procure por usos antigos: `grep -rn "STEP_COST\|step_block_reason\|can_step\|falta ATB\|1 ATB" scripts tests docs`.
- `docs/REGRAS_DO_JOGO.md` e `docs/TELEMETRIA.md`: atualize o que mudou (passos sem custo, tokens em tempo real, regen de MP, IA de posição, alvo ponderado) e registre cada correção sua em uma decisão nova antes do código, com a frase literal do criador quando houver.

**E. Fora do escopo, só relate**
- Idles novos do Orc e do Cyclops: se o criador responder qual é, investigue; do contrário, não mexa.

## Entrega

1. Lista de achados ordenada por gravidade, cada um com arquivo:linha, cenário que reproduz e saída de comando.
2. Correções pequenas e seguras feitas (com teste novo cobrindo cada bug); mudanças que exijam decisão do criador viram perguntas numeradas com a sua recomendação, sem implementar.
3. Comando(s) de teste e resultado; o que **não** foi verificado; visual sempre a cargo do criador.
4. Commit só dos seus arquivos, sem push.
