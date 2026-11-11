class_name LevelUpHUD
extends Control

## SMT III Unified Level Up HUD & Progression Screen (D-400, D-401, D-418, D-420, D-433).
## 100% Visual and Structural Parity with prototypes/hud_post_combat.html.

const CharacterModelLoader = preload("res://scripts/combat/character_model_loader.gd")
const SlantedPanel = preload("res://scripts/ui/components/slanted_panel.gd")
const SlantedButton = preload("res://scripts/ui/components/slanted_button.gd")
const StatPipsStrip = preload("res://scripts/ui/components/stat_pips_strip.gd")
const MoveCard = preload("res://scripts/ui/components/move_card.gd")
const MoveInspectionModal = preload("res://scripts/ui/components/move_inspection_modal.gd")

signal completed

const STAT_KEYS := ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]

var _party_summaries: Array[Dictionary] = []
var _total_xp: int = 0
var _current_hero_index: int = 0
var _hero_sessions: Dictionary = {}  # instance_id -> Dictionary[String, int]

# Top Header Nodes
@onready var tabs_container: HBoxContainer = $MainVBox/HeaderBar/Margin/HBox/TabsContainer
@onready var replay_btn: SlantedButton = $MainVBox/HeaderBar/Margin/HBox/HeaderControls/ReplayBtn
@onready var milestone_btn: SlantedButton = $MainVBox/HeaderBar/Margin/HBox/HeaderControls/MilestoneBtn

# Left Column - Hero Identification Card
@onready var role_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/RoleBadge/Margin/RoleLabel
@onready var hero_species_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/SpeciesLabel
@onready var hero_level_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox/HeroLevel
@onready var next_exp_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox/NextExp
@onready var hero_name_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/HeroName
@onready var hero_element_pill: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/ElementBadge/Margin/Label
@onready var hero_element_badge: PanelContainer = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/ElementBadge

@onready var exp_earned_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox/ExpTextRow/ExpEarnedLabel
@onready var exp_bar: ProgressBar = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox/ExpProgressBar

@onready var hp_bar: ProgressBar = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/ProgressBar
@onready var hp_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/TextRow/ValLabel
@onready var hp_formula_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/FormulaHint

@onready var mp_bar: ProgressBar = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/ProgressBar
@onready var mp_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/TextRow/ValLabel
@onready var mp_regen_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/RegenHint

# Left Column - Affinities Card
@onready var affinities_row: HBoxContainer = $MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox/AffinitiesRow

# Left Column - Attributes Card
@onready var points_available_pill: SlantedPanel = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill
@onready var points_available_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill/Margin/Label
@onready var nature_name_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureName
@onready var nature_mods_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureMods
@onready var nature_tactic_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureTactic
@onready var stats_vbox: VBoxContainer = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox
@onready var ally_prof_panel: PanelContainer = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/AllyProfPanel
@onready var ally_prof_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/AllyProfPanel/Label
@onready var reset_btn: SlantedButton = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls/ResetBtn
@onready var confirm_alloc_btn: SlantedButton = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls/ConfirmAllocBtn
@onready var advance_lock_notice: SlantedPanel = $MainVBox/ContentArea/LeftCol/AdvanceLockNotice

# Center Column - 3D Character Viewport
@onready var camera: Camera3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/Camera3D
@onready var model_mount: Node3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ModelMount
@onready var aura_cylinder: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/AuraCylinder
@onready var shock_ring1: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ShockRing1
@onready var shock_ring2: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ShockRing2

# Right Column - Moves Grid & Spoils
@onready var moves_grid: GridContainer = $MainVBox/ContentArea/RightCol/Margin/VBox/MovesGrid
@onready var loot_panel: SlantedPanel = $MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel

# Footer Bar
@onready var return_btn: SlantedButton = $MainVBox/FooterBar/Margin/HBox/ReturnBtn

# Technical Move Inspection Modal
@onready var inspection_modal: MoveInspectionModal = $InspectionModal

const AFFINITIES_LIST = [
	{"id": "NEUTRAL",  "name": "NEU", "bg": Color("#cbd5e1"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/neutral.svg"},
	{"id": "FIRE",     "name": "FIR", "bg": Color("#f97316"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/fire.svg"},
	{"id": "WATER",    "name": "WTR", "bg": Color("#38bdf8"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/water.svg"},
	{"id": "ELECTRIC", "name": "ELE", "bg": Color("#fde047"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/electric.svg"},
	{"id": "WIND",     "name": "WND", "bg": Color("#4ff7ba"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/wind.svg"},
	{"id": "EARTH",    "name": "ERT", "bg": Color("#78350f"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/earth.svg"},
	{"id": "NATURE",   "name": "NAT", "bg": Color("#22c55e"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/nature.svg"},
	{"id": "ICE",      "name": "ICE", "bg": Color("#06b6d4"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/water_ice.svg"},
	{"id": "PSYCHIC",  "name": "PSY", "bg": Color("#ec4899"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/psychic.svg"},
	{"id": "DARK",     "name": "DRK", "bg": Color("#1e293b"), "fg": Color.WHITE, "icon": "res://assets/ui/icons/elements/dark.svg"},
	{"id": "LIGHT",    "name": "LGT", "bg": Color("#fbbf24"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/light.svg"},
	{"id": "MYSTIC",   "name": "MYS", "bg": Color("#65b5b3"), "fg": Color.BLACK, "icon": "res://assets/ui/icons/elements/mystic.svg"},
]


const AFFINITY_ELEMENT_BY_ID = {
	"NEUTRAL": Element.Type.FISICO,
	"FIRE": Element.Type.FOGO,
	"WATER": Element.Type.AGUA_GELO,
	"ICE": Element.Type.AGUA_GELO,
	"ELECTRIC": Element.Type.RAIO,
	"WIND": Element.Type.VENTO,
	"EARTH": Element.Type.TERRA,
	"NATURE": Element.Type.VENENO,
	"PSYCHIC": Element.Type.PSIQUICO,
	"DARK": Element.Type.TREVAS,
	"LIGHT": Element.Type.LUZ,
	"MYSTIC": Element.Type.MYSTIC,
}


func _ready() -> void:
	if return_btn:
		return_btn.pressed.connect(_on_return_pressed)
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	if confirm_alloc_btn:
		confirm_alloc_btn.pressed.connect(_on_confirm_alloc_pressed)
	if replay_btn:
		replay_btn.pressed.connect(func():
			var hero = _get_current_hero()
			if hero:
				_play_celebration_sequence(hero, max(0, hero.xp - 60), hero.xp)
		)


func open(party_summaries: Array[Dictionary], total_xp: int) -> void:
	_party_summaries = party_summaries
	_total_xp = total_xp
	_current_hero_index = 0

	_hero_sessions.clear()
	for s in _party_summaries:
		var c = s.get("combatant") as Combatant
		if c:
			_hero_sessions[c.get_instance_id()] = {}
			for k in STAT_KEYS:
				_hero_sessions[c.get_instance_id()][k] = 0

	visible = true
	_render_party_tabs()
	_sync_hero_view(_current_hero_index, true)
	_update_exit_lock()


func _render_party_tabs() -> void:
	for c in tabs_container.get_children():
		c.queue_free()

	for idx in range(_party_summaries.size()):
		var s = _party_summaries[idx]
		var hero = s.get("combatant") as Combatant
		if hero == null:
			continue

		var is_selected = (idx == _current_hero_index)
		var has_lvup = s.get("levels_gained", 0) > 0

		var btn = SlantedButton.new()
		btn.custom_minimum_size = Vector2(116, 28)
		btn.skew_deg = -9.0

		if is_selected:
			btn.bg_color = Color("#f5f6f8")
			btn.border_color = Color("#00d8f6")
			btn.border_width = 2.0
			btn.shadow_offset = Vector2(3, 3)
		else:
			btn.bg_color = Color("#142334")
			btn.border_color = Color.BLACK
			btn.border_width = 1.5
			btn.shadow_offset = Vector2(2, 2)

		var el_short = "PSY" if hero.species_id == "abra" else "PHY"
		var el_bg = Color("#ec4899") if hero.species_id == "abra" else Color("#ef4444")

		var h = HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 5)
		btn.add_child(h)

		var dot = Label.new()
		dot.text = "•"
		dot.add_theme_color_override("font_color", Color("#00d8f6") if is_selected else Color("#f59e0b"))
		dot.add_theme_font_size_override("font_size", 13)
		h.add_child(dot)

		var name_lbl = Label.new()
		name_lbl.text = hero.name.to_upper()
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color.BLACK if is_selected else Color.WHITE)
		h.add_child(name_lbl)

		var el_panel = PanelContainer.new()
		var el_sb = StyleBoxFlat.new()
		el_sb.bg_color = el_bg
		el_sb.set_corner_radius_all(2)
		el_panel.add_theme_stylebox_override("panel", el_sb)
		var el_margin = MarginContainer.new()
		el_margin.add_theme_constant_override("margin_left", 3)
		el_margin.add_theme_constant_override("margin_right", 3)
		el_panel.add_child(el_margin)
		var el_lbl = Label.new()
		el_lbl.text = el_short
		el_lbl.add_theme_font_size_override("font_size", 8)
		el_lbl.add_theme_color_override("font_color", Color.WHITE)
		el_margin.add_child(el_lbl)
		h.add_child(el_panel)

		if has_lvup:
			var lv_panel = PanelContainer.new()
			var lv_sb = StyleBoxFlat.new()
			lv_sb.bg_color = Color("#d4ff32")
			lv_sb.set_corner_radius_all(2)
			lv_sb.border_width_left = 1
			lv_sb.border_width_top = 1
			lv_sb.border_width_right = 1
			lv_sb.border_width_bottom = 1
			lv_sb.border_color = Color.BLACK
			lv_panel.add_theme_stylebox_override("panel", lv_sb)
			var lv_margin = MarginContainer.new()
			lv_margin.add_theme_constant_override("margin_left", 3)
			lv_margin.add_theme_constant_override("margin_right", 3)
			lv_panel.add_child(lv_margin)
			var lv_lbl = Label.new()
			lv_lbl.text = "LV UP!"
			lv_lbl.add_theme_font_size_override("font_size", 8)
			lv_lbl.add_theme_color_override("font_color", Color.BLACK)
			lv_margin.add_child(lv_lbl)
			h.add_child(lv_panel)

		btn.pressed.connect(func():
			_current_hero_index = idx
			_render_party_tabs()
			_sync_hero_view(_current_hero_index, false)
			_update_exit_lock()
		)
		tabs_container.add_child(btn)


func _sync_hero_view(index: int, is_initial: bool = false) -> void:
	if index < 0 or index >= _party_summaries.size():
		return

	var summary = _party_summaries[index]
	var hero = summary.get("combatant") as Combatant
	if hero == null:
		return

	var is_leader = _is_party_leader(hero)

	# 1. Identity & Level
	role_label.text = "PROTAGONIST / LEADER" if is_leader else "TACTICAL ALLY"
	hero_name_label.text = hero.name.to_upper()
	hero_species_label.text = (hero.species_id.to_upper() if hero.species_id != "" else "POKÉMON")
	hero_level_label.text = str(hero.level)

	var next_xp = CrawlmonAttributeMath.get_xp_for_level_transition(hero.level)
	next_exp_label.text = "NEXT %d EXP" % next_xp

	# Element Badge next to name (Pink PSYCHIC for Abra, Red PHYSICAL for Pancham)
	var el_name = "PSYCHIC" if hero.species_id == "abra" else "PHYSICAL"
	var el_bg = Color("#ec4899") if hero.species_id == "abra" else Color("#ef4444")
	hero_element_pill.text = el_name
	var el_sb = StyleBoxFlat.new()
	el_sb.bg_color = el_bg
	el_sb.set_corner_radius_all(3)
	el_sb.border_width_left = 1
	el_sb.border_width_top = 1
	el_sb.border_width_right = 1
	el_sb.border_width_bottom = 1
	el_sb.border_color = Color.BLACK
	hero_element_badge.add_theme_stylebox_override("panel", el_sb)

	# 2. EXP bar
	var old_xp = summary.get("old_xp", hero.xp)
	var current_xp = summary.get("current_xp", hero.xp)
	var req_xp = summary.get("xp_required", 140)
	exp_bar.max_value = req_xp
	exp_bar.value = current_xp
	exp_earned_label.text = "+%d EXP EARNED" % (current_xp - old_xp if current_xp >= old_xp else _total_xp)

	# 3. Gauges
	hp_bar.max_value = hero.max_hp
	hp_bar.value = hero.hp
	hp_label.text = "%d / %d" % [hero.hp, hero.max_hp]
	hp_formula_label.text = "25 + 10L + 25[L/10] + 2VIT (D-392)"

	mp_bar.max_value = hero.max_mp
	mp_bar.value = hero.mp
	mp_label.text = "%d / %d" % [hero.mp, hero.max_mp]
	var regen_rate = 4
	mp_regen_label.text = "REGEN: +%d MP / 8s • FLOOR: 20 MP" % regen_rate

	# 4. Affinities Strip
	_render_affinities_strip(hero)

	# 5. Attributes & Pips
	var alloc_dict: Dictionary = _hero_sessions.get(hero.get_instance_id(), {})
	var spent_pts: int = 0
	for k in STAT_KEYS:
		spent_pts += alloc_dict.get(k, 0)
	var remaining_pts = maxi(0, hero.distributable_points - spent_pts)

	points_available_pill.visible = is_leader
	points_available_label.text = "AVAILABLE: %d PT%s" % [remaining_pts, "S" if remaining_pts != 1 else ""]

	var nature_data: Dictionary = NatureData.get_nature(hero.nature_id) if ResourceLoader.exists("res://scripts/data/nature_data.gd") and hero.nature_id != "" else {"name": "Modest", "mods": {}}
	nature_name_label.text = "NATURE: %s" % str(nature_data.get("name", "MODEST")).to_upper()
	var mods = nature_data.get("mods", {})
	var mod_strs: Array[String] = []
	for k in mods:
		var v = mods[k]
		if v != 0:
			mod_strs.append("%s%d %s" % ["+" if v > 0 else "", v, k])
	nature_mods_label.text = "(%s)" % ", ".join(mod_strs) if not mod_strs.is_empty() else "(NEUTRAL)"
	nature_tactic_label.text = "Ranged Spellcaster (D-393) ℹ" if hero.species_id == "abra" else "Direct Offensive (D-393) ℹ"

	ally_prof_panel.visible = not is_leader

	_render_stat_rows(hero, alloc_dict, remaining_pts, is_leader)

	# 6. 3D Model Mount
	_mount_3d_character(hero)

	# 7. Celebration
	if summary.get("levels_gained", 0) > 0 and is_initial:
		_play_celebration_sequence(hero, old_xp, current_xp)

	# 8. Moves Grid
	_render_moves_grid(hero)

	# 9. Exit lock check
	_update_exit_lock()


func _render_affinities_strip(hero: Combatant) -> void:
	for child in affinities_row.get_children():
		child.queue_free()

	for el in AFFINITIES_LIST:
		var slot_box = VBoxContainer.new()
		slot_box.custom_minimum_size = Vector2(24, 38)
		slot_box.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_box.add_theme_constant_override("separation", 2)

		var icon_panel = PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(20, 20)
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = el["bg"]
		pstyle.set_corner_radius_all(2)
		pstyle.border_width_left = 1
		pstyle.border_width_top = 1
		pstyle.border_width_right = 1
		pstyle.border_width_bottom = 1
		pstyle.border_color = Color.BLACK
		icon_panel.add_theme_stylebox_override("panel", pstyle)

		var icon_tex = TextureRect.new()
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(el["icon"]):
			icon_tex.texture = load(el["icon"])
		icon_tex.modulate = el["fg"]
		icon_panel.add_child(icon_tex)
		slot_box.add_child(icon_panel)

		# Affinity value for current hero, from the D-1157 table.
		var aff = "-"
		var elem: int = AFFINITY_ELEMENT_BY_ID.get(el["id"], -1)
		if elem >= 0:
			match hero.affinity_for(elem):
				Affinity.Type.WEAK:
					aff = "Wk"
				Affinity.Type.RESIST:
					aff = "Res"

		var aff_panel = PanelContainer.new()
		var aff_sb = StyleBoxFlat.new()
		aff_sb.set_corner_radius_all(2)

		var aff_lbl = Label.new()
		aff_lbl.text = aff
		aff_lbl.add_theme_font_size_override("font_size", 8)
		aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if aff == "Res":
			aff_sb.bg_color = Color("#082f49")
			aff_lbl.add_theme_color_override("font_color", Color("#22d3ee"))
		elif aff == "Wk":
			aff_sb.bg_color = Color("#4c0519")
			aff_lbl.add_theme_color_override("font_color", Color("#fb7185"))
		else:
			aff_sb.bg_color = Color("#111827")
			aff_lbl.add_theme_color_override("font_color", Color("#64748b"))

		aff_panel.add_theme_stylebox_override("panel", aff_sb)
		aff_panel.add_child(aff_lbl)
		slot_box.add_child(aff_panel)

		affinities_row.add_child(slot_box)


func _render_stat_rows(hero: Combatant, alloc: Dictionary, rem_pts: int, is_leader: bool) -> void:
	for stat_name in STAT_KEYS:
		var row = stats_vbox.get_node_or_null(stat_name)
		if row == null:
			continue

		var base_val: int = hero.innate_stats.get(stat_name, 1)
		var allocated: int = alloc.get(stat_name, 0)
		var nature_mod: int = 0
		if ResourceLoader.exists("res://scripts/data/nature_data.gd") and hero.nature_id != "":
			var nd: Dictionary = NatureData.get_nature(hero.nature_id)
			nature_mod = int(nd.get("mods", {}).get(stat_name, 0))

		var final_val = base_val + nature_mod + allocated

		var val_lbl = row.get_node_or_null("ValLabel") as Label
		if val_lbl:
			val_lbl.text = str(final_val)

		var mod_lbl = row.get_node_or_null("NatModLabel") as Label
		if mod_lbl:
			if nature_mod > 0:
				mod_lbl.text = "+%d" % nature_mod
				mod_lbl.add_theme_color_override("font_color", Color("#34d399"))
			elif nature_mod < 0:
				mod_lbl.text = "%d" % nature_mod
				mod_lbl.add_theme_color_override("font_color", Color("#f87171"))
			else:
				mod_lbl.text = ""

		var pips_strip = row.get_node_or_null("StatPipsStrip") as StatPipsStrip
		if pips_strip:
			pips_strip.setup(base_val, nature_mod, allocated, 0)

		var minus_btn = row.get_node_or_null("MinusBtn") as SlantedButton
		var plus_btn = row.get_node_or_null("PlusBtn") as SlantedButton

		if minus_btn and plus_btn:
			minus_btn.visible = is_leader
			plus_btn.visible = is_leader

			minus_btn.disabled = allocated <= 0
			plus_btn.disabled = rem_pts <= 0

			# User Rule: Shining plus button when points available!
			plus_btn.is_pulsing = rem_pts > 0
			plus_btn.bg_color = Color("#00d8f6") if rem_pts > 0 else Color("#142334")
			minus_btn.bg_color = Color("#1e293b") if allocated > 0 else Color("#0f172a")

			if not minus_btn.pressed.is_connected(_on_stat_minus.bind(stat_name)):
				minus_btn.pressed.connect(_on_stat_minus.bind(stat_name))
			if not plus_btn.pressed.is_connected(_on_stat_plus.bind(stat_name)):
				plus_btn.pressed.connect(_on_stat_plus.bind(stat_name))


func _on_stat_plus(stat_name: String) -> void:
	var hero = _get_current_hero()
	if hero == null or not _is_party_leader(hero):
		return
	var alloc = _hero_sessions.get(hero.get_instance_id(), {})
	var spent: int = 0
	for k in STAT_KEYS:
		spent += alloc.get(k, 0)
	if spent < hero.distributable_points:
		alloc[stat_name] = alloc.get(stat_name, 0) + 1
		_sync_hero_view(_current_hero_index, false)


func _on_stat_minus(stat_name: String) -> void:
	var hero = _get_current_hero()
	if hero == null:
		return
	var alloc = _hero_sessions.get(hero.get_instance_id(), {})
	if alloc.get(stat_name, 0) > 0:
		alloc[stat_name] -= 1
		_sync_hero_view(_current_hero_index, false)


func _on_reset_pressed() -> void:
	var hero = _get_current_hero()
	if hero == null:
		return
	var alloc = _hero_sessions.get(hero.get_instance_id(), {})
	for k in STAT_KEYS:
		alloc[k] = 0
	_sync_hero_view(_current_hero_index, false)


func _on_confirm_alloc_pressed() -> void:
	var hero = _get_current_hero()
	if hero == null or not _is_party_leader(hero):
		return

	var alloc = _hero_sessions.get(hero.get_instance_id(), {})
	var total_committing: int = 0
	for stat_name in alloc:
		var delta: int = alloc[stat_name]
		if delta > 0:
			hero.progression_points[stat_name] = int(hero.progression_points.get(stat_name, 0)) + delta
			total_committing += delta

	hero.distributable_points = maxi(0, hero.distributable_points - total_committing)
	_hero_sessions[hero.get_instance_id()] = {}
	for k in STAT_KEYS:
		_hero_sessions[hero.get_instance_id()][k] = 0
	hero.sync_effective_stats()
	hero.update_resource_maximums()

	_sync_hero_view(_current_hero_index, false)


func _mount_3d_character(hero: Combatant) -> void:
	for child in model_mount.get_children():
		child.queue_free()

	var char_node: Node3D = CharacterModelLoader.create_character_model(hero)
	model_mount.add_child(char_node)
	char_node.position = Vector3(0, 0, 0)
	CharacterModelLoader.frame_model_camera(char_node, camera)


func _play_celebration_sequence(hero: Combatant, old_xp: int, new_xp: int) -> void:
	aura_cylinder.visible = true
	shock_ring1.visible = true

	var tween = create_tween()
	var char_node = model_mount.get_child(0) if model_mount.get_child_count() > 0 else null
	if char_node:
		CharacterModelLoader.play_victory_jump(char_node, tween)
	tween.tween_property(exp_bar, "value", new_xp, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var aura_mat = aura_cylinder.get_active_material(0) as ShaderMaterial
	if aura_mat:
		aura_mat.set_shader_parameter("peak_alpha", 0.18)
		tween.parallel().tween_property(aura_mat, "shader_parameter/peak_alpha", 0.0, 0.55)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var ring_mat = shock_ring1.get_active_material(0) as ShaderMaterial
	if ring_mat:
		ring_mat.set_shader_parameter("ring_radius", 0.05)
		ring_mat.set_shader_parameter("opacity", 0.9)
		tween.parallel().tween_property(ring_mat, "shader_parameter/ring_radius", 1.8, 0.55)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ring_mat, "shader_parameter/opacity", 0.0, 0.55)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		aura_cylinder.visible = false
		shock_ring1.visible = false
	)


func _render_moves_grid(hero: Combatant) -> void:
	for child in moves_grid.get_children():
		child.queue_free()

	var moves: Array = []
	if hero:
		if "skills" in hero and hero.skills != null:
			moves = hero.skills
		elif "moves" in hero and hero.moves != null:
			moves = hero.moves

	for idx in range(8):
		var card_scene: PackedScene = load("res://scenes/ui/components/move_card.tscn")
		var card = card_scene.instantiate() as MoveCard
		moves_grid.add_child(card)

		var skill = moves[idx] if idx < moves.size() else null
		card.setup(skill, hero, idx + 1)
		card.move_inspect_requested.connect(_on_move_inspect_requested)


func _on_move_inspect_requested(skill: Skill) -> void:
	var hero = _get_current_hero()
	inspection_modal.open(skill, hero)


func _update_exit_lock() -> void:
	var has_pending_leader_points := false
	var leader_rem_points: int = 0
	for s in _party_summaries:
		var c = s.get("combatant") as Combatant
		if _is_party_leader(c):
			var alloc: Dictionary = _hero_sessions.get(c.get_instance_id(), {})
			var spent: int = 0
			for k in STAT_KEYS:
				spent += alloc.get(k, 0)
			leader_rem_points = maxi(0, c.distributable_points - spent)
			if leader_rem_points > 0:
				has_pending_leader_points = true
			break

	advance_lock_notice.visible = has_pending_leader_points
	return_btn.disabled = has_pending_leader_points

	if has_pending_leader_points:
		return_btn.text = "RETURN TO DUNGEON (LOCKED)"
		return_btn.bg_color = Color(0.25, 0.28, 0.35, 1)
		return_btn.border_color = Color.BLACK
		return_btn.add_theme_color_override("font_color", Color("#94a3b8"))

		confirm_alloc_btn.disabled = true
		confirm_alloc_btn.text = "ALLOCATE ALL POINTS (%d REMAINING)" % leader_rem_points
		confirm_alloc_btn.bg_color = Color("#1e293b")
		confirm_alloc_btn.add_theme_color_override("font_color", Color("#64748b"))
	else:
		return_btn.text = "RETURN TO DUNGEON"
		return_btn.bg_color = Color("#d4ff32")
		return_btn.border_color = Color.BLACK
		return_btn.add_theme_color_override("font_color", Color.BLACK)

		confirm_alloc_btn.disabled = false
		confirm_alloc_btn.text = "CONFIRM ALLOCATION (D-401)"
		confirm_alloc_btn.bg_color = Color("#d4ff32")
		confirm_alloc_btn.add_theme_color_override("font_color", Color.BLACK)


func _on_return_pressed() -> void:
	for s in _party_summaries:
		var c = s.get("combatant") as Combatant
		if c:
			var alloc: Dictionary = _hero_sessions.get(c.get_instance_id(), {})
			for stat_key in STAT_KEYS:
				var pts: int = alloc.get(stat_key, 0)
				if pts > 0:
					c.progression_points[stat_key] = c.progression_points.get(stat_key, 0) + pts
					c.distributable_points = max(0, c.distributable_points - pts)
			c.sync_effective_stats()
			c.update_resource_maximums()
	completed.emit()
	queue_free()


func _get_current_hero() -> Combatant:
	if _current_hero_index >= 0 and _current_hero_index < _party_summaries.size():
		return _party_summaries[_current_hero_index].get("combatant") as Combatant
	return null


func _is_party_leader(hero: Combatant) -> bool:
	if hero == null:
		return false
	if hero.is_party_leader():
		return true
	if not _party_summaries.is_empty() and _party_summaries[0].get("combatant") == hero and hero.is_player:
		return true
	return false
