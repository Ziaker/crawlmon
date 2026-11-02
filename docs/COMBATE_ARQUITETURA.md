# Combate: quem decide o quê

Regra de ouro: **o motor decide onde cada personagem e cada projétil está e quando cada fase
acontece; o FX só desenha o que o motor diz.** O modelo 3D segue `Combatant.pos`.

## Motor (regras)

| Arquivo | Responsabilidade |
|---|---|
| `combatant.gd` | `home` (ponto no passo 0), `yaw`, `pos` (posição autoritativa, x/z), `rest` (onde fica fora do passo: engajado/atordoado/corpo), `clips` (duração das animações, registrada por quem carrega o modelo). |
| `battle_space.gd` | Geometria da arena: `STEP_DIST`, `STAND_GAP`, `RUN_SPEED`, tempos base, `move_id()`. |
| `incoming.gd` | Um ataque: fases (`WINDUP→TRAVEL→STRIKE→RETURN`), plano de durações, cinemática (`from`, `stand`, `dir`, `aim`, `proj_pos`, `dest`). |
| `attack_planner.gd` | Ao fim da preparação: durações, ponto de parada, projétil/teleporte. A interceptação de projétil é decidida **na declaração** do ataque (o aviso e a janela de Evade já são de quem será atingido). |
| `attack_motion.gd` | Cinemática por frame: corrida (seguindo o alvo vivo), golpe (a investida termina no frame de contato), volta, recuo ao ser atingido, projétil guiado, teleporte. `arrive()` põe tudo no ponto exato do contato no frame do dano. |
| `battle_evade.gd` | Evade, interrupção, estado engajado e as voltas para casa. |
| `battle.gd` | Relógio da batalha, ATB, IA, dano. `freeze()` = hit-stop do relógio. |

## FX (desenho)

`fx_attack_plan.gd`, `fx_motion.gd`, `fx_projectiles.gd`… leem `inc.*` e `Combatant.pos`.
Só eles decidem: altura (saltos, arcos), squash, rotação, partículas, tremor do hit-stop,
recuo cosmético de quem está parado, passo lateral do desvio, intro/vitória.
Camada cosmética = nunca muda `pos`/`rest`.

## Relógios

Tudo que é prazo usa o relógio escalado do jogo (`Battle` / `BattleFx.clock`), não
milissegundos reais. Exceções deliberadas: animações da HUD e o balanço do idle.

## Como validar

```
python tests/battle/run_sync_check.py 1 2 3 4        # batalhas com semente, o líder joga sozinho
godot --headless --path . --script res://tests/battle/test_attack_motion.gd   # regras puras
```

`BattleTrace` (`-- --trace --drive --seed=N`) grava `user://battle_trace.jsonl` e registra, a
cada dano, `sync`: distância entre as posições **das regras**, desvio da animação em
relação ao contato. Anomalias duras: `MELEE_HIT_FAR`, `PROJ_HIT_FAR`, `ANIM_DRIFT`,
`TELEPORT`, `TOO_FAST`, `DEAD_ATTACKING`.
