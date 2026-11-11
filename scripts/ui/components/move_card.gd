class_name MoveCard
extends Control

## Universal Move Card (D-235: 100% independent of combatant, side or position).
## Replicates the verified flat neo-brutalist styling of prototypes/hud_post_combat.html.

signal move_inspect_requested(skill: Skill)

const SlantedPanel = preload("res://scripts/ui/components/slanted_panel.gd")

const ELEMENT_DATA: Dictionary = {
	Element.Type.FISICO: {"name": "Neutral", "bg": Color("#cbd5e1"), "fg": Color.BLACK, "sub": Color("#334155"), "icon": "res://assets/ui/icons/elements/neutral.svg"},
	Element.Type.FOGO: {"name": "Fire", "bg": Color("#f97316"), "fg": Color.WHITE, "sub": Color("#fef08a"), "icon": "res://assets/ui/icons/elements/fire.svg"},
	Element.Type.AGUA_GELO: {"name": "Water", "bg": Color("#38bdf8"), "fg": Color.BLACK, "sub": Color("#082f49"), "icon": "res://assets/ui/icons/elements/water.svg"},
	Element.Type.RAIO: {"name": "Electric", "bg": Color("#fde047"), "fg": Color.BLACK, "sub": Color("#422006"), "icon": "res://assets/ui/icons/elements/electric.svg"},
	Element.Type.PSIQUICO: {"name": "Psychic", "bg": Color("#ec4899"), "fg": Color.WHITE, "sub": Color("#fce7f3"), "icon": "res://assets/ui/icons/elements/psychic.svg"},
	Element.Type.VENENO: {"name": "Nature", "bg": Color("#22c55e"), "fg": Color.WHITE, "sub": Color("#f3e8ff"), "icon": "res://assets/ui/icons/elements/nature.svg"},
	Element.Type.SOM: {"name": "Sound", "bg": Color("#64748b"), "fg": Color.WHITE, "sub": Color("#cbd5e1"), "icon": "res://assets/ui/icons/elements/sound.svg"},
	Element.Type.TERRA: {"name": "Earth", "bg": Color("#78350f"), "fg": Color.WHITE, "sub": Color("#fef3c7"), "icon": "res://assets/ui/icons/elements/earth.svg"},
	Element.Type.VENTO: {"name": "Wind", "bg": Color("#4ff7ba"), "fg": Color.BLACK, "sub": Color("#064e3b"), "icon": "res://assets/ui/icons/elements/wind.svg"},
	Element.Type.LUZ: {"name": "Light", "bg": Color("#fbbf24"), "fg": Color.BLACK, "sub": Color("#451a03"), "icon": "res://assets/ui/icons/elements/light.svg"},
	Element.Type.TREVAS: {"name": "Dark", "bg": Color("#1e293b"), "fg": Color.WHITE, "sub": Color("#94a3b8"), "icon": "res://assets/ui/icons/elements/dark.svg"},
	Element.Type.MYSTIC: {"name": "Mystic", "bg": Color("#65b5b3"), "fg": Color.BLACK, "sub": Color("#042f2e"), "icon": "res://assets/ui/icons/elements/mystic.svg"},
}

var _skill: Skill
var _caster: Combatant
var _is_empty: bool = true

@onready var bg_panel: SlantedPanel = $BgPanel
@onready var watermark_icon: TextureRect = $WatermarkIcon
@onready var content_margin: MarginContainer = $ContentMargin
@onready var empty_label: Label = $EmptyLabel

@onready var type_icon: TextureRect = $ContentMargin/VBox/TopRow/BadgesRow/TypeBadge/Icon
@onready var type_badge: PanelContainer = $ContentMargin/VBox/TopRow/BadgesRow/TypeBadge
@onready var range_icon: TextureRect = $ContentMargin/VBox/TopRow/BadgesRow/RangeBadge/Icon
@onready var range_badge: PanelContainer = $ContentMargin/VBox/TopRow/BadgesRow/RangeBadge

@onready var atb_label: Label = $ContentMargin/VBox/TopRow/ChipsRow/AtbChip/Label
@onready var mp_label: Label = $ContentMargin/VBox/TopRow/ChipsRow/MpChip/Label
@onready var dmg_chip: Control = $ContentMargin/VBox/TopRow/ChipsRow/DmgChip
@onready var dmg_label: Label = $ContentMargin/VBox/TopRow/ChipsRow/DmgChip/Label

@onready var title_label: Label = $ContentMargin/VBox/TitleLabel
@onready var desc_label: Label = $ContentMargin/VBox/DescLabel


func _ready() -> void:
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	if not _is_empty:
		modulate = Color(1.1, 1.1, 1.1, 1.0)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE


func setup(skill: Skill, caster: Combatant = null, slot_index: int = 1) -> void:
	_skill = skill
	_caster = caster

	if _skill == null:
		_is_empty = true
		content_margin.visible = false
		watermark_icon.visible = false
		empty_label.visible = true
		empty_label.text = "-- Empty Slot %d --" % slot_index
		bg_panel.bg_color = Color(0.045, 0.075, 0.115, 0.45)
		bg_panel.border_color = Color(0.12, 0.18, 0.25, 0.6)
		bg_panel.border_width = 1.0
		bg_panel.shadow_offset = Vector2.ZERO
		return

	_is_empty = false
	content_margin.visible = true
	watermark_icon.visible = true
	empty_label.visible = false

	var el_info = ELEMENT_DATA.get(_skill.element, ELEMENT_DATA[Element.Type.FISICO])
	var bg_col: Color = el_info["bg"]
	var fg_col: Color = el_info["fg"]
	var sub_col: Color = el_info["sub"]

	bg_panel.bg_color = bg_col
	bg_panel.border_color = Color.BLACK
	bg_panel.border_width = 1.5
	bg_panel.shadow_offset = Vector2(3, 3)

	# Watermark
	if ResourceLoader.exists(el_info["icon"]):
		watermark_icon.texture = load(el_info["icon"])
	watermark_icon.modulate = Color(fg_col.r, fg_col.g, fg_col.b, 0.22)

	# Title & description
	title_label.text = _skill.display_name.to_upper()
	title_label.add_theme_color_override("font_color", fg_col)

	var move_name = _skill.display_name.to_upper()
	desc_label.text = _get_move_desc(move_name)
	desc_label.add_theme_color_override("font_color", sub_col)

	# Badges (Type, Range, Element)
	var type_name := _skill.type_icon_name()
	type_badge.visible = not type_name.is_empty()
	if not type_name.is_empty():
		var type_tex_path = "res://assets/ui/icons/move_types/%s.svg" % type_name
		if ResourceLoader.exists(type_tex_path):
			type_icon.texture = load(type_tex_path)
		var tb_style = StyleBoxFlat.new()
		tb_style.bg_color = _get_type_bg(type_name)
		tb_style.set_corner_radius_all(2)
		tb_style.border_width_left = 1
		tb_style.border_width_top = 1
		tb_style.border_width_right = 1
		tb_style.border_width_bottom = 1
		tb_style.border_color = Color.BLACK
		type_badge.add_theme_stylebox_override("panel", tb_style)

	var range_tex_path = "res://assets/ui/icons/range/%s.svg" % _get_range_file(_skill)
	range_badge.visible = _skill.kind != Skill.Kind.STATUS
	if range_badge.visible and ResourceLoader.exists(range_tex_path):
		range_icon.texture = load(range_tex_path)
		range_icon.modulate = Color.BLACK


	# Chips
	atb_label.text = "%d ATB" % _skill.cost
	mp_label.text = "%d MP" % _skill.mp_cost

	if _skill.power > 0:
		dmg_chip.visible = true
		var stat_val = 1
		if _caster:
			stat_val = _caster.mag if _skill.is_magical() else _caster.attack
		var live_dmg = DamageMath.base_damage(stat_val, _skill.power, true)
		dmg_label.text = "%d DMG" % live_dmg
	else:
		dmg_chip.visible = false


func _get_type_bg(type_name: String) -> Color:
	match type_name:
		"magical": return Color("#00d8f6")
		"guard": return Color("#64748b")
		"dodge": return Color("#fcb900")
	return Color("#ef4444")


func _get_range_file(skill: Skill) -> String:
	if skill.kind == Skill.Kind.MELEE:
		return "melee"
	elif skill.is_aoe:
		return "area"
	elif skill.kind == Skill.Kind.PROJECTILE:
		return "mid"
	return "long"


func _get_move_desc(name_upper: String) -> String:
	match name_upper:
		"TACKLE": return "Charges headfirst into the opponent with full bodily force."
		"CONFUSION": return "Fires telekinetic shockwaves that disorient and damage the mind."
		"PSYBEAM": return "Projects a concentrated psychic laser beam piercing barriers."
		"SHOCK WAVE": return "Zaps target with undodgeable crackling arcs of rapid electricity."
		"KARATE CHOP": return "Delivers a sharp, precise chop with high critical rate."
		"DARK FLING": return "Hurls an infused dark rock through the shadows."
		"GUARD": return "Braces for impact, mitigating incoming damage."
		"TAUNT": return "Enrages the target, lowering defense by 1 stage (-25%)."
	return "Tactical combat action executed with concentrated bodily force."


func _gui_input(event: InputEvent) -> void:
	if _is_empty or _skill == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		move_inspect_requested.emit(_skill)
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_Z):
		accept_event()
		move_inspect_requested.emit(_skill)
