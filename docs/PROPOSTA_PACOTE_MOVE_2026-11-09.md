# Proposta — pacote completo de Move (`move.tres` + `behavior.gd` + `vfx.gd` + `icon.svg`)

- **Data:** 2026-11-09
- **Decisões aplicáveis:** D-1079 (pacote de Move), D-308 (VFX de Move/elemento), D-1030 (Motion Composer auxiliar/opcional), D-235 (independente de personagem/time/lado), D-019/D-1040 (relógio único), D-1042/D-1044 (sala e análise VFX), D-022 (sem push).
- **Estado:** **Fases 1–3 implementadas e Fase 4 iniciada**: contrato `MoveVfx` + resolução de `vfx_script`, piloto `behavior.gd` do **Media**, piloto de ícone por Move (Media) e piloto de `vfx.gd` do **Tackle** (impacto delegando ao módulo atual, sem mudança visual). Nenhum VFX ou regra mudou; a aprovação visual do ícone e a evolução visual da Fase 4 aguardam o criador.

## 1. O que já existe

| Peça | Estado atual |
|---|---|
| `content/moves/<id>/move.tres` | 38 Moves com `id`, `display_name`, regras, textos e `vfx_key`. |
| `MoveData.behavior_script` | Campo existe e **já é lido** por `MoveBehaviorRegistry`; nenhum `.tres` usa ainda. |
| `MoveData.vfx_script` | Campo existe, mas **nenhum código o lê**; é o elo que falta do pacote. |
| VFX existentes | Centralizados em `MoveVfxRegistry` + módulos (`AbraMoveVfx`, `ElementMoveVfx`, `FireMoveVfx`, `ProjectileLibVfx`, `FxImpacts`, `FxProjectiles`). |
| Ícones | A UI usa `assets/ui/icons/move_types/<tipo>.svg` e `assets/ui/icons/range/<alcance>.svg`; não há ícone por Move. |
| Behavior existente | Centralizado em `scripts/combat/moves/move_behaviors.gd`; `behavior_script` permite migrar um por vez. |

## 2. Layout-alvo do pacote

```text
content/moves/<id>/
  move.tres          # MoveData (obrigatório)
  behavior.gd        # opcional; extends MoveBehavior
  vfx.gd             # opcional; extends MoveVfx
  icon.svg           # opcional; fallback para os ícones atuais
```

- `move.tres` continua sendo a fonte de dados; nenhum script é obrigatório.
- `behavior.gd` só existe quando o Move tem regra própria. A base continua em `MoveBehavior`.
- `vfx.gd` só existe quando o Move tem fases autorais. Moves sem `vfx.gd` continuam no `MoveVfxRegistry` atual.
- `icon.svg` é opcional; sem ele, a UI mantém exatamente o ícone de tipo/alcance de hoje.

## 3. Interface proposta para `vfx.gd`

`MoveVfx` é uma classe-base `RefCounted`, sem relógio próprio (D-019/D-1040):

```gdscript
class_name MoveVfx
extends RefCounted

var fx: BattleFx
var data: MoveData

func setup(p_fx: BattleFx, p_data: MoveData) -> void:
	fx = p_fx
	data = p_data

# Cada hook recebe o Incoming real; o script só desenha e lê o estado do Battle.
func windup(inc: Incoming, from: Vector3, to: Vector3, duration: float) -> Node3D:
	return null

func travel(inc: Incoming, from: Vector3, to: Vector3) -> Node3D:
	return null

func tick(inc: Incoming, delta: float) -> void:
	pass

func impact(inc: Incoming, pos: Vector3, big: bool, dir: Vector3) -> Array[Node3D]:
	return []

func finish(inc: Incoming) -> void:
	pass

func cleanup() -> void:
	pass
```

Regras da interface:

1. **Nada de regra de combate:** o script não decide dano, Evade, ATB, status ou tempo; só desenha o que o `Battle` já decidiu.
2. **Nada de relógio paralelo:** `tick()` é chamado pelo `BattleFx` no relógio existente; o script não cria `Timer`/`Tween` com tempo próprio.
3. **Independência de personagem/time/lado (D-235):** tudo é derivado de `inc.attacker`, `inc.target`, eixo, altura/raio medidos e câmera; nunca de nome, `is_player` ou posição fixa.
4. **Fases e transição (D-308):** quando o Move for aprovado para troca visual, o `vfx.gd` cobre Wind-up → Release → Trajeto → Impacto com transição contínua; a carga não some no release.
5. **Motion Composer é opcional (D-1030):** o piloto pode ser feito à mão; o Composer entra só no secundário/timing se ajudar.

### Como o registry usaria o script

`MoveVfxRegistry` ganha um cache `move_id -> MoveVfx` e uma resolução única:

```gdscript
static func move_vfx_for(move_id: StringName) -> MoveVfx:
	var move := MoveCatalog.get_move(move_id)
	if move == null or move.vfx_script == null:
		return null
	if move.vfx_script.can_instantiate():
		var custom := move.vfx_script.new()
		if custom is MoveVfx:
			custom.setup(/* fx */, move)
			return custom
	return null
```

- `windup()`, `impact()` e `travel()` tentam o script primeiro; se ele devolver `handled=false`/nulo, cai no caminho atual.
- Moves sem `vfx_script` mantêm **exatamente** o caminho atual; nenhum VFX existente muda.
- O cache é por `move_id`; não cria relógio nem estado global de batalha.

## 4. Fases de implementação (uma aprovação por fase)

### Fase 0 — Baseline
- Rodar `test_content_catalog`, `test_content_contract`, suíte de combate/VFX 16/16 e os testes verdes da lista.
- Nenhum arquivo de VFX tocado.

### Fase 1 — Contrato do `vfx_script` (sem VFX) — **implementada**
- Criados `scripts/combat/moves/move_vfx.gd` (`MoveVfx`) com os hooks `windup`, `travel`, `tick`, `impact`, `finish` e `cleanup`.
- `MoveVfxRegistry.move_vfx_for()` resolve e cacheia o `vfx_script` por `move_id`; `clear_move_vfx_cache()` limpa o cache de teste.
- Nenhum `.tres` recebe `vfx_script`; nenhum visual ou regra muda. O roteamento de combate continua nos módulos atuais até a Fase 4.
- Teste-contrato: `tests/combat/fixtures/contract_move_vfx.gd` + `test_content_contract.gd` provam a resolução; `test_content_catalog`, `test_vfx_room`, `test_move_vfx_routing`, `test_all_moves_vfx`, `test_tackle_vfx` e `test_abra_prototype_vfx` seguem verdes.

### Fase 2 — Piloto de `behavior.gd` (sem VFX) — **implementada com Media**
- A classe `Media` saiu de `scripts/combat/moves/move_behaviors.gd` para `content/moves/media/behavior.gd`, com o corpo idêntico (cura todos os aliados vivos por 10 + MAG e a IA mantém o mesmo valor tático).
- `content/moves/media/move.tres` aponta `behavior_script` para esse arquivo; a entrada `&"media"` saiu do mapa fixo de `MoveBehaviorRegistry`.
- `tools/build_content_catalog.gd` agora preserva `behavior.gd`/`vfx.gd` opcionais ao regerar o catálogo (checagem em tempo de edição, sem varredura em runtime).
- `test_content_catalog` verifica que o behavior do Media é o script do pacote e recebe a ficha do catálogo.
- Nenhum dano, tempo, regra ou visual mudou. `test_content_catalog`, `test_content_contract`, `test_attack_motion`, `test_d167_d168`, `test_battle_load`, `test_qol_batch`, `test_vfx_room`, `test_all_moves_vfx`, `test_move_vfx_routing` e a suíte 16/16 passaram.

### Fase 3 — Piloto de `icon.svg` (visual leve) — **implementada com Media**
- `content/moves/media/icon.svg` (cruz/faíscas de cura) é o ícone piloto; as faíscas ficam afastadas da cruz e o badge usa `icon_color` verde definido no `move.tres`.
- `scripts/ui/move_icons.gd` resolve `res://content/moves/<id>/icon.svg` por caminho fixo, com cache; não faz varredura de pasta.
- `FanMenu` e `SkillInfoPanel` usam o ícone do Move quando existe e mantêm o ícone de tipo/alcance atual quando não existe.
- `tests/ui/test_move_icons.gd` cobre Media com ícone, Tackle sem ícone e cache.
- Aprovação visual do ícone do Media antes de criar os ícones dos outros 37 Moves.

### Fase 4 — Piloto de `vfx.gd` (D-308) — **roteamento iniciado com Tackle**
- `content/moves/tackle/vfx.gd` (`MoveVfx`) agora **é dono da composição** do impacto; `FxImpacts._tackle_impact` virou uma ponte de compatibilidade que chama o pacote. `move.tres` aponta `vfx_script` e `MoveVfxRegistry.impact()` tenta o script antes do caminho por família.
- **Nenhum look mudou:** o corpo movido é idêntico ao original (47 linhas, só a assinatura do hook mudou) e cria os mesmos nós (`TackleShockCone`, `TackleSlashArcA/B`, flipbooks, fumaça), na mesma ordem. `test_tackle_vfx`, `test_all_moves_vfx`, `test_move_vfx_routing`, `test_vfx_room` e a suíte 16/16 passaram.
- O `vfx.gd` ainda cobre só o impacto; `windup`/`travel`/`release`/`strike`/`return` continuam no caminho central até a próxima fase visual.
- A mudança visual do Tackle (se houver) e o vídeo normal/espelhado D-308 continuam pendentes de aprovação.
- Verificação obrigatória:
  - `vfx_room.tscn`, vista normal e espelhada, câmera do jogo;
  - quatro fases com transição contínua;
  - `--audit-leaks` (`leaks=0`), `--envelope-graph` (sem `[POP_DETECTED]`), `--scale-overlay`, `--bg=gray|black|white`, `--overdraw`, `--solo-node`/`--mute-node`, `--bone-probe`, `--cam=macro`, `--proof-sheet`, `--isolate-phase`;
  - um único vídeo com as duas vistas (`tests/fx_lab/record_move_video.py`);
  - checklist literal do criador, item por item, com o quadro que prova;
  - `python tests/battle/run_agent_combat_tests.py` + `--test-d235`.
- **Um ajuste por vez**, esperando aprovação antes do próximo.

### Fase 5 — Expansão
- Migrar os outros Moves **só quando aquele Move for revisado visualmente**, não em bloco.
- Se um Move não precisa de `vfx.gd`, ele continua no `MoveVfxRegistry` com `vfx_key`.
- Remover código morto só depois que o último Move migrado estiver aprovado.

## 5. Testes-contrato a acrescentar

1. `test_content_contract`: Move novo com `behavior_script` (já coberto) e com `vfx_script` mock; confirma que o registry usa o script e que o caminho antigo continua quando não há script.
2. `test_content_catalog`: para todo `move.tres`, se `behavior_script`/`vfx_script` estiverem preenchidos, o script deve ser instanciável e estender a base correta; `icon.svg` é opcional e, se existir, tem caminho fixo.
3. `test_vfx_room`: Move com `vfx_script` e Move sem script continuam disparando na sala, nas duas vistas.
4. Nenhum teste novo deve alterar regra ou visual existente.

## 6. Riscos

| Risco | Mitigação |
|---|---|
| Migrar VFX em bloco e quebrar D-308/D-235 | Um Move por vez; checklist e vídeo normal/espelhado. |
| `vfx_script` virar um segundo relógio | Hooks recebem `inc`/`delta` do `BattleFx`; proibido `Timer`/`Tween` próprio. |
| Script por Move depender de personagem/time | Teste D-235 com outro atacante e lado espelhado. |
| Ícone por Move mudar a UI sem aprovação | Fallback para o ícone atual; aprovação visual antes de expandir. |
| `behavior.gd` duplicar a classe central | Piloto move a classe e remove a entrada central; teste de dispatcher confirma. |
| Export quebrar por caminho fixo | Caminhos `res://content/moves/<id>/...` explícitos; sem varredura de pasta em runtime. |

## 7. Decisões que preciso do criador

1. **Piloto de behavior:** `media`, `armored_bulk` ou outro? (recomendação: `media`).
2. **Piloto de VFX:** `tackle`, `fire_bullet` ou outro? (recomendação: `tackle`, migração sem mudar o look).
3. **Ícone por Move:** opcional com fallback (recomendação) ou substitui os ícones de tipo/alcance?
4. **Expansão:** migrar os 38 em bloco ou só quando cada Move for revisado? (recomendação: só quando revisado).
5. **Interface do `vfx.gd`:** aceitar a classe-base `MoveVfx` acima ou outro contrato?

**Nada foi implementado além da proposta.** Nenhum commit e nenhum push.
