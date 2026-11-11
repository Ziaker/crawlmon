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
| `queue` | a vaga D-161 mudou | `actor`, `skill`, `target`, `started`, `lost`, `previous`, `current`, `status_pause`, `status_move`, `attacking`, `guarding`, `stunned`, `alive`, `atb`, `mp` |
| `status_pause_started/ended` | pausa D-031/D-1150 | `inc` + `queued` de todos |
| `battle_ended` | fim | `player_won` |
| `ANOMALY` | invariante quebrada | `kind`, `who`, `detail` |

**D-1160:** `interruption_feedback: true` é o que destrói o cartão no HUD (interrupção real). `interrupted: true` sozinho pode ser só o estado mecânico de fim (fim de batalha, golpe no retorno, Evade cancelando a própria corrida) e **não** prova interrupção visual. `dodged`/`auto_dodged` são erros (D-104/D-106), nunca interrupção.

**D-1166:** `evade_mistimed` significa Evade apertado **fora da janela** (D-1014): o ATB é gasto, o golpe não é desviado e o feedback visual é `WHIFF` + queda + poeira. Se o clipe `down` não derruba o corpo, o clipe base é `damage` (D-1167). Não é `manual_evade` (desvio válido) nem `auto_dodged`.

**D-1168 (sala de debug):** o `SUMMARY_JSON` expõe `evade_ok_count`/`evade_ok_actor`/`evade_ok_skill` para Evade válido, `evade_mistimed_count`/`evade_mistimed_actor`/`evade_mistimed_skill` para Evade fora da janela e `whiff_visual` com `clip`, `fall_assist`, `down_falls`, `whiff_text`, `dust_scheduled`/`dust_delay`. Use `--scenario=dodge_dread_valido` para provar Evade válido sem WHIFF e `--scenario=dodge_errado_pokemon` para provar o WHIFF + `damage` + queda; o segundo é **automático** e dá WHIFF de propósito.

### `hit`: campos de afinidade (D-1158)

O `info` do evento `hit` carrega:

- `affinity`: `Affinity.Type` do elemento do Move contra o alvo (Neutral/Weak/Resist/Null/Repel/Drain).
- `affinity_mult`: multiplicador aplicado (1.5 Weak, 0.5 Resist, 1.0 nos demais nesta fase).
- `affinity_applied`: `false` no Drain Spear, que usa `5 + MAG - SPI` e ignora a tabela.

Use esses campos para provar RESIST no `--stdout-trace`; não crie um evento novo para isso.

### `queue`: começou vs. foi perdido

- `started: true` → a vaga esvaziou porque **o Move começou** (`current` bate com o Move anterior).
- `lost: "Move>Alvo"` → a vaga foi **realmente descartada**; nunca confundir com `started`.
- `previous` → Move que estava na vaga; `current` → ataque atual do ator.
- `status_pause`/`status_move` dizem se uma pausa estava ativa; `attacking`, `guarding`, `stunned`, `alive`, `atb`, `mp` explicam o porquê.

## 4. Linha por quadro

Campos de topo:

`t`, `f`, `dt`, `ts` (`Engine.time_scale`), `paused`, `freeze_left`, `status_pause`, `status_move`, `c`.

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
