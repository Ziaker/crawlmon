class_name MoveInspectionModal
extends Control

## Full-Screen Move Technical Inspection Modal (D-420).
## 1:1 Parity with HTML prototype prototypes/hud_post_combat.html.

signal modal_closed

const SlantedPanel = preload("res://scripts/ui/components/slanted_panel.gd")
const SlantedButton = preload("res://scripts/ui/components/slanted_button.gd")

var _last_focus: Control
var _skill: Skill
var _caster: Combatant

@onready var modal_card: SlantedPanel = $CenterContainer/ModalCard
@onready var close_btn: Button = $CenterContainer/ModalCard/Margin/VBox/TopBar/CloseBtn
@onready var bottom_close_btn: SlantedButton = $CenterContainer/ModalCard/Margin/VBox/Footer/BottomCloseBtn

@onready var element_icon_box: PanelContainer = $CenterContainer/ModalCard/Margin/VBox/TopBar/ElementIconBox
@onready var element_icon: TextureRect = $CenterContainer/ModalCard/Margin/VBox/TopBar/ElementIconBox/Icon
@onready var type_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/TypePillBox/Margin/TypePill
@onready var range_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/RangePillBox/Margin/RangePill
@onready var element_pill_box: PanelContainer = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/ElementPillBox
@onready var element_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/ElementPillBox/Margin/ElementPill
@onready var title_label: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/MoveTitle

@onready var atb_chip: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/ChipsBox/AtbChip/Label
@onready var mp_chip: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/ChipsBox/MpChip/Label
@onready var dmg_chip: Control = $CenterContainer/ModalCard/Margin/VBox/TopBar/ChipsBox/DmgChip
@onready var dmg_label: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/ChipsBox/DmgChip/Label

# Block 1: Mechanics
@onready var desc_label: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/Desc
@onready var target_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/Grid/TargetVal
@onready var pierce_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/Grid/PierceVal
@onready var windup_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/Grid/WindupVal
@onready var interrupt_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/Grid/InterruptVal
@onready var formula_box: Control = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox
@onready var formula_label: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox/FormulaLabel
@onready var formula_result_badge: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox/DmgBadge/Label
@onready var synergy_label: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/SynergyLabel

# Block 2: Visual Effects
@onready var vfx_manifest_label: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/ManifestLabel
@onready var vfx_motion_label: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/MotionLabel
@onready var delivery_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/Grid/DeliveryVal
@onready var trajectory_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/Grid/TrajectoryVal
@onready var element_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/Grid/ElementVal
@onready var watermark_val: Label = $CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/Grid/WatermarkVal

const ELEMENT_DATA: Dictionary = {
	Element.Type.FISICO: {"name": "Neutral", "bg": Color("#cbd5e1"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/neutral.svg"},
	Element.Type.FOGO: {"name": "Fire", "bg": Color("#f97316"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/fire.svg"},
	Element.Type.AGUA_GELO: {"name": "Water", "bg": Color("#38bdf8"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/water.svg"},
	Element.Type.RAIO: {"name": "Electric", "bg": Color("#fde047"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/electric.svg"},
	Element.Type.PSIQUICO: {"name": "Psychic", "bg": Color("#ec4899"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/psychic.svg"},
	Element.Type.VENENO: {"name": "Nature", "bg": Color("#22c55e"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/nature.svg"},
	Element.Type.SOM: {"name": "Sound", "bg": Color("#64748b"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/sound.svg"},
	Element.Type.TERRA: {"name": "Earth", "bg": Color("#78350f"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/earth.svg"},
	Element.Type.VENTO: {"name": "Wind", "bg": Color("#4ff7ba"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/wind.svg"},
	Element.Type.LUZ: {"name": "Light", "bg": Color("#fbbf24"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/light.svg"},
	Element.Type.TREVAS: {"name": "Dark", "bg": Color("#1e293b"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/dark.svg"},
	Element.Type.MYSTIC: {"name": "Mystic", "bg": Color("#65b5b3"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/mystic.svg"},
}


func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	bottom_close_btn.pressed.connect(close_modal)



func _on_focus_changed(control: Control) -> void:
	if visible and control and not is_ancestor_of(control):
		close_btn.grab_focus()
	if not get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.connect(_on_focus_changed)


func format_move_formula(skill: Skill, caster: Combatant) -> Dictionary:
	var is_magic := skill.is_magical()
	var stat_name := "MAG" if is_magic else "STR"
	var stat_val := (caster.mag if is_magic else caster.attack) if caster else 1
	var nature_name := "Modest"
	if caster and caster.nature_id != "" and ResourceLoader.exists("res://scripts/data/nature_data.gd"):
		var nd = NatureData.get_nature(caster.nature_id)
		nature_name = nd.get("name", "Modest")

	var live_dmg := DamageMath.base_damage(stat_val, skill.power, true)

	return {
		"formula": "%d [%s] × %.2f [Power] = %d DMG" % [stat_val, stat_name, skill.power, live_dmg],
		"dmg_display": "%d DMG" % live_dmg,
		"scaling": "Scaling: %s × Move power. The %s Nature modifier is already included in the attribute." % [stat_name, nature_name]
	}

func open(skill: Skill, caster: Combatant = null) -> void:
	_skill = skill
	_caster = caster
	_last_focus = get_viewport().gui_get_focus_owner()

	_populate_data()
	visible = true
	close_btn.grab_focus()
	if not get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.connect(_on_focus_changed)


func close_modal() -> void:
	if not visible:
		return
	visible = false
	modal_closed.emit()
	if get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
	if _last_focus and is_instance_valid(_last_focus):
		_last_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_Z or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		close_modal()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_card_rect = Rect2(modal_card.global_position, modal_card.size)
		if not local_card_rect.has_point(event.global_position):
			accept_event()
			close_modal()


func _populate_data() -> void:
	if _skill == null:
		return

	var el_info = ELEMENT_DATA.get(_skill.element, ELEMENT_DATA[Element.Type.FISICO])
	var type_name = _get_kind_name(_skill)
	var range_name = _get_range_name(_skill)

	# Element icon box
	var sb = StyleBoxFlat.new()
	sb.bg_color = el_info["bg"]
	sb.set_corner_radius_all(3)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color.BLACK
	element_icon_box.add_theme_stylebox_override("panel", sb)

	if ResourceLoader.exists(el_info["icon"]):
		element_icon.texture = load(el_info["icon"])
	element_icon.modulate = el_info["fg"]

	# Pills
	type_pill.text = type_name
	range_pill.text = range_name
	element_pill.text = el_info["name"].to_upper()
	element_pill.add_theme_color_override("font_color", el_info["fg"])
	var el_pill_sb = StyleBoxFlat.new()
	el_pill_sb.bg_color = el_info["bg"]
	el_pill_sb.set_corner_radius_all(2)
	el_pill_sb.border_width_left = 1
	el_pill_sb.border_width_top = 1
	el_pill_sb.border_width_right = 1
	el_pill_sb.border_width_bottom = 1
	el_pill_sb.border_color = Color.BLACK
	if element_pill_box:
		element_pill_box.add_theme_stylebox_override("panel", el_pill_sb)

	# Title & chips
	title_label.text = _skill.display_name.to_upper()
	atb_chip.text = "%d ATB" % _skill.cost
	mp_chip.text = "%d MP" % _skill.mp_cost

	var move_name = _skill.display_name.to_upper()
	var is_dmg = _skill.power > 0
	dmg_chip.visible = is_dmg

	var effective_stat_name = "MAG" if _skill.is_magical() else "STR"
	var effective_stat_val = 8
	var nature_name = "Modest"
	if _caster:
		effective_stat_val = _caster.mag if _skill.is_magical() else _caster.attack
		if _caster.nature_id != "" and ResourceLoader.exists("res://scripts/data/nature_data.gd"):
			var nd = NatureData.get_nature(_caster.nature_id)
			nature_name = nd.get("name", "Modest")

	var fmt = format_move_formula(_skill, _caster)
	if is_dmg:
		dmg_label.text = fmt["dmg_display"]
		formula_box.visible = true
		formula_label.text = fmt["formula"]
		formula_result_badge.text = fmt["dmg_display"]
		synergy_label.text = fmt["scaling"]
	else:
		formula_box.visible = false

	# Mechanics details
	desc_label.text = _get_move_description(move_name)
	target_val.text = "All Opponents" if _skill.is_aoe else "Single Opponent"
	pierce_val.text = "YES (Ignores Shield)" if move_name == "PSYBEAM" else "NO (Blocked)"
	pierce_val.add_theme_color_override("font_color", Color("#34d399") if move_name == "PSYBEAM" else Color("#9ca3af"))
	windup_val.text = "0.80s (Fast)" if _skill.cost == 1 else ("1.40s (Standard)" if _skill.cost == 2 else "2.10s (Heavy)")
	interrupt_val.text = "Interruptible" if _skill.cost > 1 else "Protected"
	interrupt_val.add_theme_color_override("font_color", Color("#fbbf24") if _skill.cost > 1 else Color("#9ca3af"))

	# Visuals details
	vfx_manifest_label.text = _get_vfx_manifestation(move_name)
	vfx_motion_label.text = _get_vfx_motion(move_name)
	delivery_val.text = "MELEE RANGE" if _skill.kind == Skill.Kind.MELEE else ("LONG RANGE" if _skill.kind == Skill.Kind.CAST else "MID RANGE")
	trajectory_val.text = "Linear Lunge" if _skill.kind == Skill.Kind.MELEE else ("Direct Beam / Arc" if _skill.kind == Skill.Kind.CAST else "Direct Line")
	element_val.text = el_info["name"]
	watermark_val.text = "Embossed Low-Relief"


func _get_kind_name(skill: Skill) -> String:
	var t := skill.type_icon_name()
	return t.to_upper() if not t.is_empty() else "STATUS"


func _get_range_name(skill: Skill) -> String:
	if skill.kind == Skill.Kind.STATUS:
		return "—"
	if skill.kind == Skill.Kind.MELEE:
		return "MELEE RANGE"
	elif skill.is_aoe:
		return "ALL OPPONENTS"
	elif skill.kind == Skill.Kind.PROJECTILE:
		return "MID RANGE"
	return "LONG RANGE"


func _get_move_description(name_upper: String) -> String:
	match name_upper:
		"TACKLE": return "Charges headfirst into the opponent with full bodily force."
		"CONFUSION": return "Fires telekinetic shockwaves that disorient and damage the mind."
		"PSYBEAM": return "Projects a concentrated psychic laser beam piercing barriers."
		"SHOCK WAVE": return "Zaps target with undodgeable crackling arcs of rapid electricity."
		"KARATE CHOP": return "Delivers a sharp, precise chop that has a high critical rate."
		"DARK FLING": return "Hurls an infused dark rock through the shadows."
		"GUARD": return "Braces for impact, mitigating incoming physical and elemental trauma."
		"TAUNT": return "Enrages the target, lowering their defense by 1 stage (-25%)."
	return "Tactical combat action executed with concentrated bodily and elemental energy."


func _get_vfx_manifestation(name_upper: String) -> String:
	match name_upper:
		"PSYBEAM": return "Concentrated high-energy psychic laser beam with violet distortion rings and particle fracture burst on impact."
		"CONFUSION": return "Swirling telekinetic sonic pressure waves that ripple through space, distorting the opponent's vision."
		"SHOCK WAVE": return "Instant crackling golden electrical discharge arcing directly into the foe without projectile travel time."
		"TACKLE": return "Physical bodily charge accompanied by ground dust puffs and a blunt kinetic shockwave."
		"KARATE CHOP": return "Swift downward diagonal strike with sharp crimson speed-lines and critical impact spark burst."
		"DARK FLING": return "Shadow-infused projectile lobbed in an arc, exploding into dark violet miasma upon contact."
		"GUARD": return "Translucent protective barrier manifestation mitigating incoming physical and elemental trauma."
	return "Intimidating battle roar sending reverberating shockwaves that disorient and enrage the target."


func _get_vfx_motion(name_upper: String) -> String:
	match name_upper:
		"TACKLE", "KARATE CHOP": return "User lunges forward 2.5m into close combat range, executes the strike, then springs back to formation."
		"PSYBEAM", "SHOCK WAVE": return "User anchors securely in backline formation; fires linear high-velocity projectile piercing target."
		"CONFUSION", "DARK FLING": return "User steps forward slightly into midfield casting stance; releases curving pressure wave."
	return "User remains stationary in defensive posture; gathers energy barrier around core."
