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

## Conteúdo: Move e Personagem como pacotes (D-1079)

- **Move:** `content/moves/<id>/move.tres` (`MoveData`) + `behavior.gd` opcional + `vfx.gd` opcional + ícone/textos. O `id` é a identidade estável; `display_name` é só texto.
- **Personagem:** `content/characters/<id>/species.tres` (`CharacterData`) + `loadout.tres` + `model_profile.tres`.
- **Catálogos explícitos:** `content/catalogs/move_catalog.tres` e `content/catalogs/character_catalog.tres`; sem varredura de pasta em runtime.
- **Runtime:** `Skill` é um wrapper fino de `MoveData`; `CharacterFactory` constrói o `Combatant` a partir de `CharacterData`. `EnemyFactory`, `GameState._build_party` e `DqtTestParty` delegam a ele.
- **Regra preservada:** a lógica continua dona do relógio (D-019/D-1040); o VFX só desenha. O comportamento é por `move_id` (D-235).
- **Etapa 1:** dados e catálogos implementados sem mudar regra/tempo/visual.
- **Etapa 2 concluída:** `Incoming.move_data` + `MoveBehavior`/`MoveBehaviorRegistry`/`MoveBehaviors`. `AttackPlanner` lê `MoveData` (stand gap, run, hit, hold, plano) e `BattleAI` lê os hooks de status; `Battle` usa os hooks de hit/status. A cadeia do Tidal Surge, as constantes de Boulder/Electric/Armor e a tag `guard_break` também saíram do núcleo do `Battle`.
- **Etapa 3 (roteamento de VFX) concluída:** `MoveData.vfx_key` + `MoveVfxRegistry`; `fx_telegraph` (wind-up), `fx_projectiles` (família do projétil) e `fx_impacts` (todos os impactos autorais, incluindo Electric/Tidal) leem o registro. `BattleFx` usa tags do `MoveData` para Drain, guard break, Burn/Fire Bullet, status com VFX de palco, Shock Wave no miss e Quick Punch no pulso BW; hit-stop e BW pulse saíram das tabelas para o `MoveData`.
- **Etapa 4 concluída nos blocos seguros:** `skill.gd` (887 → 327 linhas) com textos/custos legados em `SkillLegacyData` (561 linhas); `battle_hud.gd` (1557 → 1241) com os helpers de desenho em `BattleHudDraw` (322); `battle.gd` (1153 → 1053) com `BattleRewards` (58) e `BattleBadges` (78); `vfx_room.gd` (2736 → 2328) com `VfxRoomScenarios` (112) e `VfxRoomAnalysis` (442). Restam os núcleos coesos de timeline/hit e o painel/gravação da sala, cuja divisão exige decisão.
- **Etapa 6 concluída:** `tests/combat/test_content_contract.gd` valida um Move e um Personagem novos em memória (catálogo, `Skill`, dispatcher, VFX registry e `CharacterFactory`), sem alterar os `.tres`.
- **Etapa 5 concluída:** `scripts/vfx/` é a raiz única de VFX; `scripts/combat/fx/*` virou `scripts/vfx/combat/*` (com `projectile_lib/` e `.uid` preservados). Preloads, `RELOAD_DIRS` e o cache de classes foram atualizados; a suíte completa de combate/VFX passou 16/16. Não há `export_presets.cfg` para ajustar. Docs históricos podem citar o caminho antigo.
- **Auditoria de arquitetura (2026-11-09):** `behavior_script` passou a ser lido pelo registry; impacto/trajeto de um Move novo respeitam `vfx_key`; catálogos/fichas devolvem cópias das definições.
- **Pacote de Move, Fases 1–3 e 4:** `MoveVfx` + `MoveVfxRegistry.move_vfx_for()` (contrato de `vfx_script`), piloto `Media` em `content/moves/media/behavior.gd`, piloto de ícone `content/moves/media/icon.svg` com `scripts/ui/move_icons.gd` e fallback em `FanMenu`/`SkillInfoPanel`, e piloto de VFX do **Tackle** (`content/moves/tackle/vfx.gd`) agora dono da composição do impacto; `FxImpacts._tackle_impact` é ponte de compatibilidade. O corpo movido é idêntico ao original; nenhum VFX ou regra mudou. A mudança visual/vídeo D-308 continua pendente. Evidências em [`AUDITORIA_ARQUITETURA_2026-11-09.md`](AUDITORIA_ARQUITETURA_2026-11-09.md) e [`PROPOSTA_PACOTE_MOVE_2026-11-09.md`](PROPOSTA_PACOTE_MOVE_2026-11-09.md).
