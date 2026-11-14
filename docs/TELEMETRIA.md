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
| `queue` | a vaga D-161 mudou | `actor`, `skill`, `target`, `started`, `lost`, `previous`, `current`, `status_pause`, `status_move`, `attacking`, `guarding`, `stunned`, `alive`, `atb`, `mp` |
| `status_pause_started/ended` | pausa D-031/D-1150 | `inc` + `queued` de todos |
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
