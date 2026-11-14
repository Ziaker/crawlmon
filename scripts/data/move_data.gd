class_name MoveData
extends Resource
## Definição imutável de um Move (D-1079).
##
## O `id` é a identidade estável usada pelo motor, pela IA, pelo VFX e pelos
## testes. `display_name` é apenas o texto exibido. O estado de batalha fica no
## `Skill`/`Incoming`; este Resource é carregado uma vez e tratado como somente
## leitura.

enum DamageType { PHYSICAL, MAGICAL }
## D-1200: who the player/AI must choose. AUTO = legacy (enemy target, or the caster/team for friendly Moves).
## SINGLE_ALLY = one living ally of the caster's team (the caster included). DUAL = a primary and a secondary target
## (structure only: which half affects whom is still the creator's to define).
enum TargetMode { AUTO, SINGLE_ALLY, DUAL }
## D-1200: for a DUAL Move, which side each pick may be (relative to the caster): ANY, ALLY (caster's team, caster included) or ENEMY.
## Each Move declares it in its own text/data; the engine never assumes which half is the enemy.
enum TargetSide { ANY, ALLY, ENEMY }

@export var id: StringName = &""
@export var display_name: String = ""

# --- Mecânica ---------------------------------------------------------------
## `Skill.Kind`: 0 = MELEE, 1 = PROJECTILE, 2 = CAST, 3 = STATUS.
@export_enum("Melee", "Projectile", "Cast", "Status") var kind: int = 0
@export var element: Element.Type = Element.Type.FISICO
## D-1140: the Move declares whether its damage scales with STR or MAG (D-122).
@export_enum("Physical", "Magical") var damage_type: int = DamageType.PHYSICAL
@export var power: float = 1.0
@export var atb_cost: int = 2
@export var mp_cost: int = 0
@export var windup: float = -1.0
@export var ground: bool = false
@export var is_aoe: bool = false
@export var is_friendly: bool = false
@export var target_mode: TargetMode = TargetMode.AUTO  ## D-1200
@export var primary_side: TargetSide = TargetSide.ANY  ## D-1200: side of the primary pick (DUAL only)
@export var secondary_side: TargetSide = TargetSide.ANY  ## D-1200: side of the secondary pick (DUAL only)
@export var aoe_on_contact: bool = false
@export var visual_push: int = -1

# --- Planejamento e regras próprias (Etapa 2) -------------------------------
@export var stand_gap: float = -1.0
@export var run_base: float = -1.0
@export var run_fixed: float = -1.0
@export var hit_offset: float = 0.0
@export var strike_time: float = -1.0
@export var hold: float = -1.0
@export var teleport: bool = false
@export var untargetable: bool = false
@export var status_pause: float = -1.0
@export var redirectable: bool = true
@export var plan_profile: StringName = &""
@export var plan_fly: float = -1.0
@export var plan_return: float = -1.0
## D-1196: duração do salto de volta de um melee (s); -1 = calculada pela distância. Com `plan_return` >= 0 num melee, ele é a duração total da fase RETURN.
@export var hop_time: float = -1.0
@export var blink_distance: float = 1.35
@export var hit_stop_duration: float = -1.0
@export var bw_pulse: bool = false
@export var magic_flat: int = -1
@export var bypass_def: bool = false
@export var transfer_time: float = -1.0

# --- Reação de impacto genérica (D-1205): qualquer Move liga o que quiser trocando números; 0 = desligado -----------
## Knock-up: altura do ápice (m). > 0 liga o Knock-up (status stun com outro nome + voo do alvo).
@export var knockup_height: float = 0.0
## Tempo TOTAL no ar (s), subida + queda. É também a duração do status: o alvo fica atordoado exatamente enquanto está no ar.
@export var knockup_air_time: float = 0.0
## Gravidade da queda (m/s²): maior que a da subida para ele cair rápido, não flutuar. A subida sai do tempo e da altura.
@export var knockup_gravity_down: float = 48.0
## Giro do alvo no proprio eixo durante o voo: numero de voltas inteiras (0 = nao gira). Termina alinhado ao pousar.
@export var knockup_spin_turns: float = 0.0
## Aneis de vento girando em volta do alvo durante o voo.
@export var knockup_wind: bool = false
## Ao pousar: raio (m) do anel de poeira e intensidade do tremor de camera do impacto (0 = nada).
@export var knockup_landing_dust: float = 0.0
@export var knockup_landing_shake: float = 0.0
## Segundos de tremor lateral do alvo depois do acerto.
@export var knockup_shudder: float = 0.0
## Cartão/efeito de HUD no Knock-up: "" = nenhum, "thrown_slab", "trapdoor_slam".
@export var card_style: StringName = &""
## Recuo suave do alvo ao longo do eixo atacante->alvo (m), 0 = sem recuo.
@export var target_push: float = 0.0
## Recuo suave do atacante para o lado oposto ao oponente (m), 0 = sem recuo.
@export var attacker_push: float = 0.0
## Segundos depois do acerto em que os dois começam a voltar (0 = assim que o voo/recuo termina) e duração dessa volta.
@export var push_return_at: float = 0.0
@export var push_return_time: float = 0.5
## Graus de FOV a mais na câmera enquanto a reação dura (0 = nada).
@export var impact_fov_boost: float = 0.0
## true = o acerto não faz a câmera tremer nem mostra linhas de velocidade.
@export var camera_still_on_hit: bool = false

# --- Ganchos futuros (Etapas 2/3) ------------------------------------------
@export var tags: Array[StringName] = []
@export var behavior_script: Script = null
@export var vfx_key: StringName = &""
@export var vfx_script: Script = null
## Optional badge/background color for the Move icon. Alpha 0 = use the
## type/range fallback color (Phase 3, D-1079).
@export var icon_color: Color = Color(0, 0, 0, 0)
@export var ai_profile: Dictionary = {}

# --- Textos da ficha (D-420) ------------------------------------------------
@export_multiline var effect_line_text: String = ""
@export_multiline var short_effect_text: String = ""
@export_multiline var description_text: String = ""
@export_multiline var mechanics_text: String = ""
@export_multiline var visual_text: String = ""
@export_multiline var motion_text: String = ""
@export_multiline var windup_text: String = ""
@export_multiline var tactical_text: String = ""
@export_multiline var visual_motion_text: String = ""
@export var phase_visuals: Dictionary = {}


## Knock-up: {"v": velocidade inicial, "g_up": gravidade da subida, "fall": tempo da queda} para a altura e o tempo no ar dados
## (queda = sqrt(2h / g_descida); subida = tempo total - queda; v = 2h / subida; g_subida = v / subida). Vazio se desligado.
func knockup_launch() -> Dictionary:
	if knockup_height <= 0.0 or knockup_air_time <= 0.0 or knockup_gravity_down <= 0.0:
		return {}
	var fall := sqrt(2.0 * knockup_height / knockup_gravity_down)
	var rise := maxf(knockup_air_time - fall, 0.05)
	var v := 2.0 * knockup_height / rise
	return {"v": v, "g_up": v / rise, "fall": fall}


func is_status() -> bool:
	return kind == 3


func has_tag(tag: StringName) -> bool:
	return tag in tags


func kind_name() -> String:
	return ["melee", "projectile", "ranged", "status"][kind] if kind >= 0 and kind < 4 else "melee"
