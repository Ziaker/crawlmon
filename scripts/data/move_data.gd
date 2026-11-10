class_name MoveData
extends Resource
## Definição imutável de um Move (D-1079).
##
## O `id` é a identidade estável usada pelo motor, pela IA, pelo VFX e pelos
## testes. `display_name` é apenas o texto exibido. O estado de batalha fica no
## `Skill`/`Incoming`; este Resource é carregado uma vez e tratado como somente
## leitura.

@export var id: StringName = &""
@export var display_name: String = ""

# --- Mecânica ---------------------------------------------------------------
## `Skill.Kind`: 0 = MELEE, 1 = PROJECTILE, 2 = CAST, 3 = STATUS.
@export_enum("Melee", "Projectile", "Cast", "Status") var kind: int = 0
@export var element: Element.Type = Element.Type.FISICO
@export var power: float = 1.0
@export var atb_cost: int = 2
@export var mp_cost: int = 0
@export var windup: float = -1.0
@export var ground: bool = false
@export var is_aoe: bool = false
@export var is_friendly: bool = false
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
@export var blink_distance: float = 1.35
@export var hit_stop_duration: float = -1.0
@export var bw_pulse: bool = false
@export var magic_flat: int = -1
@export var bypass_def: bool = false
@export var transfer_time: float = -1.0

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


func is_status() -> bool:
	return kind == 3


func has_tag(tag: StringName) -> bool:
	return tag in tags


func kind_name() -> String:
	return ["melee", "projectile", "ranged", "status"][kind] if kind >= 0 and kind < 4 else "melee"
