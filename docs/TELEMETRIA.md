<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Telemetria do jogo — guia obrigatório de combate e debug

> **Leitura obrigatória para qualquer agente antes de mexer em combate, Moves, dano, animações, regras, fila, pausa de status ou VFX.** Fonte: **D-1154**, com D-1042/D-1044 e D-1150. Se o código divergir deste documento, diga a divergência; não invente um evento novo.

## 1. Regra de ouro

1. **Telemetria é opt-in**: só liga com `--trace`, `--stdout-trace`, `--strict-asserts` ou `CRAWL_TRACE=1`. O jogo normal não escreve arquivo nem paga o custo.
2. **Quem é dono do estado é o `Battle`/`Combatant`**, não o visual (D-019/D-1040). A telemetria lê esses donos.
3. **Não adivinhe pelo log**: use `--stdout-trace`/`--summary-json` e cite o evento/JSON que prova o diagnóstico.
4. **Se um detector sinalizar anomalia**, pergunte se o jogo ou o teste está errado; não altere a regra para o teste passar.
5. **Toda entrega de combate/debug/VFX deve dizer o que foi verificado e o que não foi.**

## 2. Como ligar

| Flag | O que faz |
|---|---|
| `--trace` | Grava tudo em `user://battle_trace.jsonl` (uma linha JSON por evento/quadro). |
| `--stdout-trace` | Imprime cada evento como `[TRACE_JSONL] {...}` no `stdout`. |
| `--strict-asserts` | Falha com `exit 1` na primeira anomalia de invariante. |
| `CRAWL_TRACE=1` | Equivale a `--trace` por variável de ambiente. |
| `--summary-json` | Na sala de debug, imprime `SUMMARY_JSON: {...}` (inclui `queue_events`, `queue_started`, `queue_lost`). |
| `--acts-ticks=` / `--step-ticks=N` | Agendamento e avanço determinístico por ticks físicos (D-1042). |

Comandos úteis:

```powershell
# batalha real com trace no stdout
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --stdout-trace

# sala de debug: fila antes da pausa
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --scenario=fila_status_pausa --summary-json --quit

# fila escolhida durante a pausa, com o fluxo de eventos
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --scenario=fila_status_click --stdout-trace --quit

# War Cry cancelando a vaga (esperado D-064)
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --scenario=fila_war_cry --summary-json --quit

# wind-up iniciado durante a pausa, com ataque em voo
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --scenario=windup_pausa_com_ataque --stdout-trace --quit

# suíte completa
python tests/battle/run_agent_combat_tests.py
```

## 3. Eventos do `BattleTrace`

Cada linha tem:

```json
{"t": 1.234, "f": 74, "ev": "evento", "data": { }}
```

Eventos de combate:

| `ev` | Quando | Campos principais |
|---|---|---|
| `battle_trace_started` | início do trace | `seed_args` |
| `log` | qualquer log do `Battle` | `text` |
| `telegraphed` | ataque declarado | `attacker`, `target`, `label`, `kind`, `phase`, `progress` |
| `resolved` | wind-up terminou e o plano começou | o mesmo + `instant`, `dodged`, `auto_dodged`, `interrupted`, `interruption_feedback` |
| `phase` | ataque entrou numa fase | o mesmo + `to` |
| `cancelled` | ataque cancelado | o mesmo + `queued` do atacante |
| `interrupted` / `interrupted_windup` | interrupção real por hit/War Cry | `attacker`/`actor`, `source`, `queued`, `interruption_feedback` |
| `clash` | dois corredores se chocaram | `a`, `b`, `point`, `mutual` |
| `hit` | acerto resolvido | `attacker`, `target`, `info` completo (dano, fraqueza, crítico, Guard, ARMOR, status, evade etc.) || `damaged` | dano direto (inclusive Burn/efeito) | `actor`, `amount`, `hp`, `max_hp` |
| `heal` / `died` | cura / morte | ator, alvo, valor |
| `manual_evade`, `evade_mistimed`, `evade_whiff`, `evade_teleported`, `evade_returned` | Evade em todas as variantes | ator, `inc`, origem/destino |
| `guard_started/ended` | Guard | ator, motivo |
| `armor_changed` | ARMOR | ator, `state`, timer |
| `shield_ended` | escudo | ator, motivo |
| `burn_applied/tick/ended` | Burn | alvo, dano, ticks, HP |
| `mp_regenerated` | regeneração de MP (D-1062) | ator, valor, MP atual/máximo |
| `buff_changed` | buff/debuff | ator, atributo, valor |
| `reward_spawned/landed` | ATB/Burst/Badge | dono, tipo, slot |
| `experience_gained` / `level_up` | XP / nível | ator, valor/nível/pontos |
| `martial_hand` | **D-1218:** um por quadro enquanto existe a mão holograma do Karate Chop | `move`, `attacker`, `target`, `pos` [x,y,z], `rot` (euler [x,y,z]), `scale`, `fade`, `dissolve`, `form`, `speed` (m/s da posição), `stage` (`windup`/`run`/`jump`/`cut`/`post`/`fade`/`cancel`), `contact_in` (s até o contato; negativo depois) |
| `vfx_frame` | **D-1220/D-1222:** um por quadro por nó ativo de `BattleFx`/`SmtVfx` na `vfx_room` (opt-in `--vfx-trace` / `--stdout-trace`) | `node`, `kind`, `stage`, `pos`, `rot` (graus), `vel`, `speed`, `ang_speed` (graus/s), `aabb_size`, `progress` (`0..1` no eixo atacante→alvo), `lateral_offset`, `height_y`, `dist_to_target`, `screen_px` `[w,h]`, `alpha`, `scale`, `visible`, `contact_delta_s` |
| `queue` | a vaga D-161 mudou | `actor`, `skill`, `target`, `started`, `lost`, `previous`, `current`, `status_pause`, `status_move`, `attacking`, `guarding`, `stunned`, `alive`, `atb`, `mp` |
| `status_pause_started/ended` | pausa D-031/D-1150 | `inc` + `queued` de todos |
| `employ` | **D-1229 (Fase 5):** a tentativa de Employ mudou de etapa | `stage`, `actor`, `target`, `atb`, `extra`, `blocks`, `burst` + campos da etapa (ver "Employ" abaixo) |
| `summon` | **D-1232/D-1244 (Fase 8):** a troca por Summon foi recusada (`refused`) ou feita (`done`) | `stage`, `payer`, `leaving`, `entering`, `slot`, `cost`, `blocks_before`, `blocks_after`, `burst_after`, `cancelled`, `queue_cleared` + `reason` (só em `refused`) |
| `battle_ended` | fim | `player_won` |
| `ANOMALY` | invariante quebrada | `kind`, `who`, `detail` |

**D-1160:** `interruption_feedback: true` é o que destrói o cartão no HUD (interrupção real). `interrupted: true` sozinho pode ser só o estado mecânico de fim (fim de batalha, golpe no retorno, Evade cancelando a própria corrida) e **não** prova interrupção visual. `dodged`/`auto_dodged` são erros (D-104/D-106), nunca interrupção.

**D-1166:** `evade_mistimed` significa Evade apertado **fora da janela** (D-1014): o ATB é gasto, o golpe não é desviado e o feedback visual é `WHIFF` + queda + poeira. Se o clipe `down` não derruba o corpo, o clipe base é `damage` (D-1167). Não é `manual_evade` (desvio válido) nem `auto_dodged`.

**D-1168 (sala de debug):** o `SUMMARY_JSON` expõe `evade_ok_count`/`evade_ok_actor`/`evade_ok_skill` para Evade válido, `evade_mistimed_count`/`evade_mistimed_actor`/`evade_mistimed_skill` para Evade fora da janela e `whiff_visual` com `clip`, `fall_assist`, `down_falls`, `whiff_text`, `dust_scheduled`/`dust_delay`. Use `--scenario=dodge_dread_valido` para provar Evade válido sem WHIFF e `--scenario=dodge_errado_pokemon_auto` para provar o WHIFF + `damage` + queda; o segundo é **automático** e dá WHIFF de propósito. `dodge_errado_pokemon` é manual, sem ação automática.

### Alvo duplo e aliado único (D-1200)

- Eventos que carregam um `Incoming` (`telegraphed`, `resolved`, `phase`, `cancelled`, `clash`…) ganham `target2` **só quando o Move é de alvo duplo** (o alvo secundário); `target` continua sendo o primário.
- `queue` ganha `target2` (vazio se não houver) e a chave interna da vaga passa a ser `Move>Primário+Secundário`; `started`/`lost` seguem iguais.
- `interrupted_windup`/`action_interrupted` → `queued` inclui `target2` quando existe.
- Linha por quadro: `qt2` ao lado de `qt`.
- Aliado único (Heal) não tem campo novo: `telegraphed.target` é o aliado escolhido; `heal` e `hit` (`info.heal: true`) saem para esse aliado.

### `hit`: campos de afinidade (D-1158)

O `info` do evento `hit` carrega:

- `affinity`: `Affinity.Type` do elemento do Move contra o alvo (Neutral/Weak/Resist/Null/Repel/Drain).
- `affinity_mult`: multiplicador aplicado (1.5 Weak, 0.5 Resist, 1.0 nos demais nesta fase).
- `affinity_applied`: `false` no Drain Spear, que usa `5 + MAG - SPI` e ignora a tabela.

Use esses campos para provar RESIST no `--stdout-trace`; não crie um evento novo para isso.

### Employ (D-1229, Fase 5: só o fluxo mecânico)

Um evento `employ` por mudança de etapa. Campos comuns: `stage`, `actor`, `target` (vazio quando ainda não há alvo), `atb`, `extra`, `blocks` (`atb + extra`) e `burst` do ator **depois** da etapa.

| `stage` | Quando | Campos extras |
|---|---|---|
| `picking` | o seletor de alvo abriu (nada foi pago) | — |
| `cancelled` | o seletor fechou sem confirmar (nada foi pago) | — |
| `refused` | `Battle.begin_employ()` recusou; nada foi pago | `reason`: `not_running`, `busy` (já há tentativa), `actor_down`, `blocked` (fracasso anterior nesta batalha), `need_atb`, `no_target`, `last_enemy` (só resta um inimigo vivo: no jogo real não pode ser recrutado), `target_invalid` |
| `started` | alvo confirmado: 5 ATB pagos com `spend()` (Burst nunca paga) e a batalha congela **inteira**, inclusive wind-ups, ataques em voo e a fila (D-1239 revista: nada é cancelado aqui) | `cost`, `blocks_before`, `burst_before` |
| `rhythm` | D-1257: a sequência do minigame rítmico terminou; nada é pago aqui | `grades` (por nota: `perfect`/`good`/`miss`), `bonuses` (10/5/0 por nota, na ordem) e `total_pp` (soma = B, o bônus de ritmo da D-1230) |
| `ended` | a tentativa terminou e a batalha retoma de onde parou. **D-1239:** só no sucesso são cancelados, com o custo devolvido, os Moves que envolvem o recrutado (atacante ou alvo) e as filas dele ou apontadas a ele; o resto retoma | `result` (`success`/`failure`), `cancelled` (lista `{actor, move, phase, atb, mp, mp_timer, burst}`: o que voltou; `mp_timer` = timer de regeneração de MP restaurado), `queue_cleared` (lista `{actor, move}`), `forced` (`true` = resultado forçado por debug; na Fase 5 é sempre), `blocked` (Employ bloqueado no resto da batalha), `enemies_left` (inimigos vivos em campo); no sucesso também `uid`, `place` (`SUBSTITUTE`/`STATIONED`) e `in_field` (sempre `false`: só entra por Convocação) |

- `reason` são códigos internos de telemetria, **não** textos de menu (os textos de motivo continuam pendentes).
- Linha por quadro: campo de topo `employ` (`true` enquanto a tentativa existe). Nesse intervalo `Battle._process` não avança nada e `use_skill`, `request_skill`, `use_item`, `use_guard`, `step` e `try_evade` devolvem `false`.
- **D-1240 (Fase 6):** no `ended` por rolagem real (`Battle.resolve_employ()`, `forced: false`) entram `chance` (`A`, `E`, `F`, `N`, `R`, `B`, `raw`, `P`, `members`, `level_traveler`, `level_enemy`, `respect`, `note_bonuses`, `rhythm_pp`, `rolled`, `roll`, `success`), `rolled` e `roll` (`-1` quando P é 0 ou 100 e nada foi sorteado). Participantes: vivos do time do ator; STR/MAG efetivos x multiplicador do estágio de ATK; respeito 50 e bônus de ritmo vindo do minigame (D-1257: `note_bonuses`; `rhythm_pp` é a soma). Sorteio: `randf() * 100`, sucesso se `roll < P`; `--seed` o controla.
- **D-1242 (Fase 7, BOOST):** no fracasso o alvo recebe o BOOST: o `ended` traz `boost` (`target`, `seconds`) e o evento `boost` (`actor`, `active`, `left`, `burst`, `blocks`, `str`, `mag`, `vit`, `wis`, `agi`, `luk`) sai ao começar (`active: true`) e ao acabar (`active: false`). +1 nos 6 atributos (WIS = SPI), +1 Burst (a invariante `BURST_RANGE` aceita 6 enquanto o BOOST dura), +2 ATB uma vez; 10 s contados só enquanto a batalha corre (pausa de status e congelamento do Employ param a conta); no fim os atributos voltam e o Burst acima de 5 volta a 5. Cenário `--employ=boost`.
- Sala de debug: `--employ=<modo>` imprime `[vfx_room] employ mode=... result=ok|fail ...` e `[vfx_room] EMPLOY_JSON: {...}` (ver "Employ no debug" no fim deste arquivo).

### Summon (D-1232/D-1244/D-1254, Fase 8)

**D-1254:** sem custo de ATB; sem cancelar; a batalha não congela. Quem sai vai na hora; a vaga fica **vazia** durante `arrival_seconds` (`Battle.SUMMON_ARRIVAL_SECONDS` = 6,9 = saída 0,95 + intervalo 1 + pentagrama 4 + queda 0,95) e só então quem entra chega em `party`. Enquanto chega (`Battle.arriving()`), não está em `party`: ninguém o alveja, não ganha ATB, não age; uma equipe sem ninguém vivo mas com alguém chegando não perde a batalha.

Um evento `summon` por etapa. `leaving` e `entering` são nomes; `slot` é o índice em `party` (o mesmo de quem saiu; `-1` na recusa); `arrival_seconds` é 6,9; `cancelled` e `queue_cleared` têm o mesmo formato do `employ`.

| `stage` | Quando | Campos extras |
|---|---|---|
| `refused` | `Battle.summon()` recusou; nada foi alterado | `reason`: `not_running`, `busy` (tentativa de Employ em curso), `no_roster`, `no_uid` (quem sai ou quem entra sem `uid`), `leaving_invalid` (não está em `party`), `entering_invalid` (não é `SUBSTITUTE` no roster, ou já está chegando) |
| `started` | quem sai foi embora; o pentagrama começa (a vaga fica vazia) | `slot`, `cancelled`, `queue_cleared` |
| `done` | passaram os 6,9 s (o raio tocou o chão): quem entra está em `party` com `atb = 0` | `slot` |

- Dono do menu: `menu_owner()` (o protagonista vivo em `party`, senão o 1º ativo vivo); com a vaga vazia no pentagrama, vale quem restar; ao chegar, o 1º ativo vivo pode voltar a ser quem entrou na vaga 0 (D-1244). Nada aqui lê `is_player` (D-235).
- Quem sai: perde todos os efeitos temporários (buffs, status, Guard, Burn, ARMOR, escudo, BOOST) e mantém HP e MP; seus Moves são cancelados com o custo devolvido, igual ao Employ (D-1239), e as filas dele e apontadas a ele são limpas. Quem entra: começa limpo, com `atb = 0`, `extra = 0` e sem efeitos; HP, MP e Burst ficam como estavam.
- O entrante assume o mesmo índice e a mesma colocação (`pos`, `home`, `rest`, `has_rest`, `yaw`, `pos_step`, `step_from`, `tactic_pos`); ele e quem estava engajado com quem saiu ficam com `engaged_with = null`.
- Roster: `swap(uid_saindo, uid_entrando)` (uids não mudam), `note_leave(uid_saindo, t)` e `note_enter(uid_entrando, t)` com `t` = relógio da batalha (`Battle.battle_time`), para a partilha de XP da D-1234.

### `queue`: começou vs. foi perdido

- `started: true` → a vaga esvaziou porque **o Move começou** (`current` bate com o Move anterior).
- `lost: "Move>Alvo"` → a vaga foi **realmente descartada**; nunca confundir com `started`.
- `previous` → Move que estava na vaga; `current` → ataque atual do ator.
- `status_pause`/`status_move` dizem se uma pausa estava ativa; `attacking`, `guarding`, `stunned`, `alive`, `atb`, `mp` explicam o porquê.

## 4. Linha por quadro

Campos de topo:

`t`, `f`, `dt`, `ts` (`Engine.time_scale`), `paused`, `freeze_left`, `status_pause`, `status_move`, `employ` (D-1229: tentativa de Employ em curso), `c`.

Cada item de `c`:

- `n` (nome), `pos`, `cpos`, `yaw`, `scale`, `vis`, `anim`, `mover`;
- `hp`, `max_hp`, `mp`, `max_mp`, `atb`, `extra`, `burst`, `step`;
- `eng`, `counter`, `pend`;
- `buff` (`atk`, `def`, `spd`);
- `stun`, `blind`, `guard`, `armor`, `shield_hp`, `shield_t`, `burn`;
- `burning`, `guard_on`, `armor_on`, `shield_on`, `blind_on`, `stunned`, `alive`;
- `winding`, `attacking`, `held`;
- `q`, `qt` (fila e alvo), `sp`, `sp_by` (pausa e lançador);
- `atk` (fase/progresso do ataque atual).

## 5. `SUMMARY_JSON` da sala de debug

Além dos campos antigos (dano, HP, fases, leaks, VFX), a sala inclui:

- `queue_events`: lista de eventos de fila com `t`, `actor`, `skill`, `target`, `status_pause`, `attacking`, `current`, `started`, `lost`;
- `queue_started`: quantas vezes uma vaga foi preenchida;
- `queue_lost`: quantas vezes uma vaga foi realmente perdida.

## 6. Como diagnosticar “o Move foi cancelado”

1. Rode o cenário com `--stdout-trace` (ou a batalha com `--trace`).
2. Procure `queue` para o ator: se houver `lost`, veja `status_pause`, `status_move`, `attacking`, `guarding`, `stunned`, `atb`, `mp` e `current`.
3. Procure `interrupted` / `interrupted_windup` / `cancelled` no mesmo `t`: um hit ou War Cry real limpa a vaga (D-064/D-161).
4. Procure `status_pause_started/ended`: a pausa em si **não** limpa a vaga; ela congela e a fila continua (D-1150). Desde D-1159, um **ataque não-status** escolhido durante a pausa **começa** o wind-up (`telegraphed`) e fica congelado; ele não aparece como `queue`.
5. Se `started: true`, o Move **não foi cancelado**: ele começou; o problema é outro (animação/pausa/leitura).
6. Se houver `interrupted`/`hit` com outro atacante depois, o cancelamento é um golpe real, não a pausa. Se houver `interrupted_windup` com `source=War Cry`, é D-1102.
7. Cite o evento JSON exato na resposta. Não diga “parece que” sem o evento.

## 7. Cobertura e lacunas

- **Coberto:** combate (Battle/Combatant), fila D-161, pausa D-031/D-1150, status/buffs/Guard/ARMOR/escudo/Burn, MP/ATB/Burst, recompensas, XP/level, ataques/fases, VFX via sala.
- **Não coberto nesta camada:** overworld/exploração, áudio, UI fora do combate e decisões internas da IA (a IA é observada pelas ações que gera). Para essas áreas, criar `GameTrace` separado, com o mesmo princípio opt-in.

## 8. Regra para agentes

1. **Leia este arquivo antes de qualquer tarefa de combate/debug/VFX** e cite **D-1154** na resposta.
2. Use `--stdout-trace` ou `--summary-json` como prova; não substitua por inspeção visual quando o dado existe.
3. Se precisar de um evento novo, registre a decisão e documente o campo antes de usar.
4. Se um teste falhar, diga se é o jogo ou o teste; não altere a regra para passar.
5. Entregue sempre: comando usado, arquivo/linha ou JSON de evidência, o que foi verificado e o que não foi.

## Câmera na sala de VFX (D-1205/D-1204)

- `SUMMARY_JSON.camera_travel_m`: metros que a câmera real andou na rodada; `camera_fov_travel`: soma da variação do FOV (graus); `camera_travel_bins`: metros por janela de 0,5 s do relógio da sala.
- `--cam-trace`: imprime `[cam] clock=… step=… mode=… fov=…` a cada quadro em que a câmera andou mais de 2 cm (modo 0 = CINEMA, 2 = IMPACTO). O relógio da sala é ~1,5 s à frente do `t` do `--stdout-trace`.

## Ferramentas de teste adicionadas pela D-1204

- **`acts` com `atb`:** `[segundos, "atb", "A1", valor]` define o ATB exato (0 a 5 blocos) do papel. O ATB regenera durante o cenário: use valores bem abaixo do limite, no segundo certo (ver `evade_atb_2`).
- **Cenários `evade_atb_0`, `evade_atb_2`, `evade_atb_3`, `evade_atb_5`, `evade_atb_0_esp`, `evade_atb_3_esp`:** Evade x ATB (custo 3 parado), normal e espelhado. O Dread (D-1203) aparece como o nó `EvadeFlash` em `vfx_spawns` do `--summary-json`: só acende com ATB suficiente e só para o líder (D-1168).
- **Runner paralelo:** `python tests/battle/run_agent_combat_tests.py --jobs=6 [--only=texto]` (cada teste é um processo Godot; com 12 processos há timeout, 6 a 7 é o ponto bom; suíte de 36 testes em ~93 s).
- **Flags do runner (D-1204):** `--changed` (roda só o escopo dos arquivos alterados no `git status`; arquivo desconhecido ou runner/`vfx_room*.gd` = tudo), `--cache` (pula teste cujo hash de `scripts/ scenes/ content/ shaders/ tests/battle` não mudou; arquivo `tests/battle/.cache_runner.json`, ignorado pelo git), `--fail-fast` (para no primeiro erro), `--budget=SEG` (marca como FALHA, motivo `BUDGET`, o teste que passou mas passou do tempo), `--report=caminho.json` (relatório por teste). Suíte atual: 40 testes em ~90 s com `--jobs=6` (o limite de 1 minuto para a suíte inteira ainda é pergunta aberta na D-1204).
- **Status combinados (D-1204):** o verbo `status` aceita combinações com `+`: `[0.0, "status", "E1", "stun4+burn+blind+shield+magic_immune+knockup+guard+b:atk:2+b:def:-1+b:spd:3"]` (`b:atk|def|spd:N` = buff/debuff). Em qualquer cenário, `--status="E1:stun4+burn;A1:b:atk:2"` aplica combinações em t=0. O `--summary-json` traz `status_cards_peak` (o cartão com mais efeitos de cada personagem logo após aplicar, mesmo texto do cartão do HUD) e `status_cards` (no fim da rodada, quando os temporizados já expiraram). As chaves são os papéis (`A1`, `E1`…), não os nomes (o inimigo é sorteado). Cenários: `st_combo_todos`, `st_combo_knockup`, `st_empilha` (2x o mesmo status não soma), `st_expira` (Blind e Burn somem sozinhos). Também `taunt` e `invuln` (e `clear` limpa os dois), e os cenários `st_expira_longa` (STUN, Shield e Imun. Mágica expiram) e `st_taunt_invuln`. O atraso máximo de `atk` na sala subiu de 4 s para 20 s (antes o cenário cortava em silêncio). Todos têm teste no runner.
- **Inimigos fixos no debug (D-1204):** a sala não sorteia mais o inimigo. Sem flag, o sorteio usa semente fixa (padrão 1204; hoje dá Cyclops, Orc, Cyclops); `--seed=N` muda a semente e `--enemies=pancham,abra` escolhe as espécies (ids de `EnemyFactory`). Vale para `vfx_room` não espelhado.
- **Sem o painel (`--no-panel`, D-1204):** a sala roda e captura em tela cheia, sem o painel "SALA DE VFX" aberto. Tudo que o painel faz já tem flag ou cenário (`--scenario`, `--move`, `--status`, `--enemies`, `--attacker`, `--hide=`, `--pause-at`, `--shot`); a IA nunca precisa abrir o painel. Se algum controle só existir no painel, é um buraco do debug: crie a flag.
- **Captura do cartão com status:** `godot --path . scenes/debug/vfx_room.tscn -- --scenario=st_combo_todos --pause-at=impact --shot=res://tests/battle/_shots/st_combo.png --quit` (janela, não headless).
- **Dois povs (`scenes/debug/vfx_room_dual.tscn`, D-1204):** duas salas lado a lado, cada uma com mundo 3D próprio. Esquerda = jogador usa o Move (câmera padrão); direita = oponente usa o Move no jogador (`cam=2`, atrás do atacante). Uso: `godot --path . scenes/debug/vfx_room_dual.tscn -- --move="Fire Bullet" --summary-json --quit` (~10 s headless; imprime dois `SUMMARY_JSON`, um por lado, com `attacker_side`). `--attacker` inverte os lados. O painel das salas fica escondido. Só foi testado headless; a janela renderizada ainda não foi vista.
- **Lista fixa de Moves na sala (D-1204):** a aba Moves lista o catálogo inteiro numa ordem que não muda (número permanente por Move, igual para qualquer atacante, D-235); 9 por página (◀ ▶), busca por nome + Enter, teclas 1 a 9 escolhem na página atual; trocar de atacante mantém o Move selecionado. `--move=` funciona para qualquer Move com qualquer atacante.
- **Efeito de cartão no Knock-up (debug):** `F11` na sala alterna `BattleHud.card_style_override` entre nenhum, `thrown_slab` e `trapdoor_slam` e imprime o valor; `--card-style=thrown_slab` (ou `trapdoor_slam`; vazio = nenhum) define o mesmo ao iniciar.

- **Foto de um instante (debug, <10 s):** `tools/room_shot.sh <cenario> <fase> <atraso_s> <saida.png>` (ex.: `tools/room_shot.sh dig impact 0.45 /tmp/dig.png`). Os flags da sala (`--scenario=`, `--pause-at=`, `--shot=`, `--quit`...) vão **depois do `--`**; sem ele o Godot trata `--quit` como flag do motor e fecha no primeiro quadro, sem foto. `--scenario=` e `--card-style=` também funcionam sem o `--`, mas não os flags de saída.
- **Vários instantes numa folha (debug, ~10 s por foto):** `python tools/room_seq.py <cenario> --phase <fase> --delays 0,0.3,0.6,0.9 --out <saida.png> [--cols N] [--crop x0,y0,x1,y1] [--scale S] [-- flags da sala]` roda até 3 Godot em paralelo (~10 s cada) e monta uma folha de contato rotulada de vários instantes do cenário.
- Cada atraso de `--delays` é escrito em amarelo no canto de cada tile; os flags da sala vão **depois do `--`**, como no `room_shot.sh`.
- Execução que falha (exit diferente de 0, timeout de 100 s ou png ausente) não derruba a folha: vira um tile vermelho `FAIL t=...`, e o motivo com as últimas linhas do stderr é impresso no fim (`FAILED RUNS: n`).

## Respeito do grupo de Travelers: `RESPECT_JSON` (D-1231, D-1235)

Fora do `BattleTrace` (o Respeito muda fora da batalha). Com `--stdout-trace`, cada chamada de `GameState.apply_respect()` imprime uma linha:

```
RESPECT_JSON: {"event":"EXPEDITION_DEFEAT","source":"expedition_defeat","feat_id":"","delta":-2,"value":48,"challenging_left":3}
```

| Campo | Significado |
|---|---|
| `event` | nome em `RespectState.Event` |
| `source` | de onde veio: `expedition_defeat` (`GameState.end_battle(false)` em expedição saída do Hub), `retreat` (`return_to_hub_from_expedition`) ou o nome de um teste |
| `feat_id` | identificador do feito (chefe, desafio); vazio quando não se aplica |
| `delta` | variação realmente aplicada, depois das proteções e do limite 0–100 |
| `value` | Respeito depois do evento |
| `challenging_left` | recompensas de encontro desafiador que restam na expedição (máx. 3) |

Os últimos 32 eventos ficam em `GameState.respect_log`. **Fontes ligadas hoje:** início de expedição (zera o contador), derrota definitiva (−2) e retirada (0). **Não ligadas** (sem fonte aprovada): encontro desafiador, chefe importante, desafio tático, corrida de rivais.

Teste: `--script res://tests/combat/test_respect_expedition_cycle.gd` (menos de 10 s).

## Employ no debug: `--employ=<modo>` (D-1229, Fase 5; D-1204)

Atalho da sala (`scripts/debug/vfx_room.gd`) que percorre o caminho real do menu (leque lateral de TACTICS → EMPLOY → seletor de alvo → tentativa) e imprime `[vfx_room] employ mode=<modo> view=<normal|mirror> result=<ok|fail>` e `[vfx_room] EMPLOY_JSON: {...}`. Menos de 10 s; `--mirror` roda a vista espelhada; com `--stdout-trace` saem também os eventos `employ`. Sai com código 1 quando `result=fail`.

| Modo | O que prova |
|---|---|
| `cancel` | abrir o seletor e cancelar não gasta ATB nem Burst (`stages = ["picking","cancelled"]`) |
| `noatb` | com 4 ATB a entrada EMPLOY fica desabilitada, o seletor não abre e `begin_employ` recusa com `need_atb` |
| `fail` | confirmar gasta exatamente 5 ATB e 0 Burst; batalha congelada (`frozen`, Guard/Evade/Move recusados, `step_ticks(30)` sem efeito); fracasso forçado retoma, bloqueia novo Employ (`blocked`) e deixa o SUMMON disponível |
| `fail:flight` | o mesmo, com um ataque inimigo em voo: ele fica parado durante a tentativa e continua depois |
| `success` | sucesso forçado: o inimigo sai de campo sem K.O., entra no elenco uma única vez (`uid`, `recruited`, `re_uid`), não entra em campo, sem `battle_ended` |
| `status` | **D-1239:** Armored Bulk do recrutado (pausa de status aberta) é cancelado no sucesso: `cancelled` com 1 entrada, `pause_started: 1`, `pause_ended: 1`, `paused_after: false` |
| `returning` | **D-1239:** o recrutado já acertou e só falta o retorno: ao recrutá-lo, `moves_of_recruit_left: 0` (o Move some com ele) e a batalha segue (`running: true`) |
| `moves[:flight][:burst][:mp][:win]` | **D-1239 (revista):** três atacantes com um Move em wind-up (ou em voo com `:flight`) e outro na fila: o recrutado (alvo do Employ), um inimigo sem relação e o líder (que ataca o recrutado). Fracasso (padrão): `cancelled` vazio, `live_after = live_before`, fila intacta, `resumed_progress: true`, ATB só perde os 5 do líder. `:win`: só os 2 Moves do recrutado e do líder contra ele são cancelados (`live_after = live_before − 2`), `queue_left` 1 (a do inimigo sem relação), custos devolvidos (`refund_*`; ATB final = antes + reembolso − 5) e o inimigo sem relação retoma. `:burst` prova o Burst devolvido; `:mp` (Bubble Shot) prova MP e timer de regeneração devolvidos |
| `lastblock` | no jogo real o último inimigo vivo não pode ser recrutado: entrada desabilitada, `refusal`/`reason` = `last_enemy`, nada é gasto |
| `last` | recruta todos os inimigos: só observa e relata `running`, `ended_emitted`, `player_won` (vitória/XP/loot desse caso não estão decididos) |

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --employ=fail --stdout-trace --quit
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://scenes/debug/vfx_room.tscn -- --employ=success --mirror --quit
```
