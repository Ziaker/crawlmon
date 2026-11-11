import os

hud_gd = '''class_name LevelUpHUD
extends Control

## SMT III Unified Level Up HUD & Progression Screen (D-400, D-401, D-418, D-420, D-433).
## 1:1 Parity with prototypes/hud_post_combat.html.

const CharacterModelLoader = preload("res://scripts/combat/character_model_loader.gd")
const SlantedButton = preload("res://scripts/ui/components/slanted_button.gd")
const StatPipsStrip = preload("res://scripts/ui/components/stat_pips_strip.gd")
const MoveCard = preload("res://scripts/ui/components/move_card.gd")
const MoveInspectionModal = preload("res://scripts/ui/components/move_inspection_modal.gd")

signal completed

const STAT_KEYS := ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]

var _party_summaries: Array[Dictionary] = []
var _total_xp: int = 0
var _current_hero_index: int = 0

# Local session transaction dictionary keyed by combatant instance id (D-401)
var _hero_sessions: Dictionary = {}  # int -> Dictionary[String, int]

# Top Header Nodes
@onready var tabs_container: HBoxContainer = $MainVBox/HeaderBar/Margin/HBox/TabsContainer
@onready var replay_btn: Button = $MainVBox/HeaderBar/Margin/HBox/HeaderControls/ReplayBtn
@onready var milestone_btn: Button = $MainVBox/HeaderBar/Margin/HBox/HeaderControls/MilestoneBtn

# Left Column - Hero Identification Card
@onready var role_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/RoleBadge/Margin/RoleLabel
@onready var hero_species_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/SpeciesLabel
@onready var hero_level_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox/HeroLevel
@onready var next_exp_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox/NextExp
@onready var hero_name_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/HeroName
@onready var hero_nature_label: Label = $MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/NatureBadge/Margin/Label

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
@onready var points_available_pill: PanelContainer = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill
@onready var points_available_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill/Margin/Label
@onready var nature_name_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureName
@onready var nature_mods_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureMods
@onready var nature_tactic_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox/NatureTactic
@onready var stats_vbox: VBoxContainer = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox
@onready var ally_prof_panel: PanelContainer = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/AllyProfPanel
@onready var ally_prof_label: Label = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/AllyProfPanel/Label
@onready var reset_btn: Button = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls/ResetBtn
@onready var confirm_alloc_btn: Button = $MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls/ConfirmAllocBtn
@onready var advance_lock_notice: PanelContainer = $MainVBox/ContentArea/LeftCol/AdvanceLockNotice

# Center Column - 3D Character Viewport
@onready var model_mount: Node3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ModelMount
@onready var aura_cylinder: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/AuraCylinder
@onready var shock_ring1: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ShockRing1
@onready var shock_ring2: MeshInstance3D = $MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport/ShockRing2

# Right Column - Moves Grid & Spoils
@onready var moves_grid: GridContainer = $MainVBox/ContentArea/RightCol/Margin/VBox/MovesGrid
@onready var loot_panel: PanelContainer = $MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel
@onready var gold_val_label: Label = $MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem/VBox/Val
@onready var potion_val_label: Label = $MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem/VBox/Val

# Footer Bar
@onready var return_btn: Button = $MainVBox/FooterBar/Margin/HBox/ReturnBtn

# Technical Move Inspection Modal
@onready var inspection_modal: MoveInspectionModal = $InspectionModal


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

	# Initialize local session allocations
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

		var tab = Button.new()
		tab.text = "• %s" % hero.name.to_upper()
		tab.custom_minimum_size = Vector2(130, 32)
		tab.focus_mode = FOCUS_ALL

		var is_selected = (idx == _current_hero_index)
		_style_tab_button(tab, is_selected, s.get("levels_gained", 0) > 0)

		tab.pressed.connect(func():
			_current_hero_index = idx
			_render_party_tabs()
			_sync_hero_view(_current_hero_index, false)
			_update_exit_lock()
		)
		tabs_container.add_child(tab)


func _style_tab_button(btn: Button, is_selected: bool, has_lvup: bool) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if is_selected:
		style.bg_color = Color("#f5f6f8")
		style.border_color = Color.BLACK
		btn.add_theme_color_override("font_color", Color.BLACK)
	else:
		style.bg_color = Color("#142334")
		style.border_color = Color("#1e3a5f")
		btn.add_theme_color_override("font_color", Color("#94a3b8"))

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)


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

	var nature_data: Dictionary = NatureData.NATURES.get(hero.nature_id, NatureData.NATURES["hardy"]) if ResourceLoader.exists("res://scripts/data/nature_data.gd") else {"name": "Hardy", "mods": {}}
	hero_nature_label.text = str(nature_data.get("name", "HARDY")).to_upper()

	# 2. EXP bar
	var old_xp = summary.get("old_xp", hero.xp)
	var current_xp = summary.get("current_xp", hero.xp)
	var req_xp = summary.get("xp_required", 100)
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

	nature_name_label.text = "NATURE: %s" % str(nature_data.get("name", "MODEST")).to_upper()
	var mods = nature_data.get("mods", {})
	var mod_strs: Array[String] = []
	for k in mods:
		var v = mods[k]
		mod_strs.append("%s%d %s" % ["+" if v > 0 else "", v, k])
	nature_mods_label.text = "(%s)" % ", ".join(mod_strs) if not mod_strs.is_empty() else "(NEUTRAL)"
	nature_tactic_label.text = "Ranged Spellcaster (D-393) ℹ" if hero.species_id == "abra" else "Direct Offensive (D-393) ℹ"

	ally_prof_panel.visible = not is_leader
	if not is_leader:
		ally_prof_label.text = "AUTOMATIC LEVEL UP (D-394):\n+1 STR GRANTED (Combat Proficiency)\nAllies advance automatically."

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

	# 10 Crawlmon elements
	var elements_info = [
		{"name": "PHYS", "bg": Color("#94a3b8"), "aff": "-"},
		{"name": "FIRE", "bg": Color("#f97316"), "aff": "-"},
		{"name": "WTR",  "bg": Color("#38bdf8"), "aff": "-"},
		{"name": "ELEC", "bg": Color("#facc15"), "aff": "-"},
		{"name": "GRAS", "bg": Color("#22c55e"), "aff": "-"},
		{"name": "ICE",  "bg": Color("#06b6d4"), "aff": "-"},
		{"name": "WIND", "bg": Color("#14b8a6"), "aff": "-"},
		{"name": "ERTH", "bg": Color("#a16207"), "aff": "-"},
		{"name": "PSYC", "bg": Color("#ec4899"), "aff": "Res" if hero.species_id == "abra" else "-"},
		{"name": "DARK", "bg": Color("#1e293b"), "aff": "Wk" if hero.species_id == "abra" else "-"},
		{"name": "LGHT", "bg": Color("#fbbf24"), "aff": "-"},
	]

	for el in elements_info:
		var box = VBoxContainer.new()
		box.custom_minimum_size = Vector2(28, 38)
		box.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon_panel = PanelContainer.new()
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = el["bg"]
		pstyle.corner_radius_top_left = 2
		pstyle.corner_radius_top_right = 2
		pstyle.corner_radius_bottom_right = 2
		pstyle.corner_radius_bottom_left = 2
		icon_panel.add_theme_stylebox_override("panel", pstyle)
		icon_panel.custom_minimum_size = Vector2(22, 16)

		var ilbl = Label.new()
		ilbl.text = el["name"]
		ilbl.add_theme_font_size_override("font_size", 7)
		ilbl.add_theme_color_override("font_color", Color.BLACK if el["bg"].get_luminance() > 0.5 else Color.WHITE)
		ilbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_panel.add_child(ilbl)
		box.add_child(icon_panel)

		var aff_lbl = Label.new()
		aff_lbl.text = el["aff"]
		aff_lbl.add_theme_font_size_override("font_size", 9)
		if el["aff"] == "Res":
			aff_lbl.add_theme_color_override("font_color", Color("#22d3ee"))
		elif el["aff"] == "Wk":
			aff_lbl.add_theme_color_override("font_color", Color("#fb7185"))
		else:
			aff_lbl.add_theme_color_override("font_color", Color("#64748b"))
		aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(aff_lbl)

		affinities_row.add_child(box)


func _render_stat_rows(hero: Combatant, alloc: Dictionary, rem_pts: int, is_leader: bool) -> void:
	for stat_name in STAT_KEYS:
		var row = stats_vbox.get_node_or_null(stat_name)
		if row == null:
			continue

		var base_val: int = hero.innate_stats.get(stat_name, 1)
		var allocated: int = alloc.get(stat_name, 0)
		var nature_mod: int = 0
		if ResourceLoader.exists("res://scripts/data/nature_data.gd") and hero.nature_id != "":
			nature_mod = NatureData.get_stat_modifier(hero.nature_id, stat_name)

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

		var minus_btn = row.get_node_or_null("MinusBtn") as Button
		var plus_btn = row.get_node_or_null("PlusBtn") as Button

		if minus_btn and plus_btn:
			minus_btn.visible = is_leader
			plus_btn.visible = is_leader

			minus_btn.disabled = allocated <= 0
			plus_btn.disabled = rem_pts <= 0

			if plus_btn is SlantedButton:
				(plus_btn as SlantedButton).is_pulsing = rem_pts > 0

			if plus_btn.material is ShaderMaterial:
				plus_btn.material = plus_btn.material.duplicate()
				var pcol = Color(0, 0.847, 0.965, 1) if rem_pts > 0 else Color(0.12, 0.16, 0.22, 0.6)
				(plus_btn.material as ShaderMaterial).set_shader_parameter("bg_color", pcol)
			if minus_btn.material is ShaderMaterial:
				minus_btn.material = minus_btn.material.duplicate()
				var mcol = Color(0.35, 0.4, 0.5, 0.9) if allocated > 0 else Color(0.12, 0.16, 0.22, 0.4)
				(minus_btn.material as ShaderMaterial).set_shader_parameter("bg_color", mcol)

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

	_sync_hero_view(_current_hero_index, false)


func _mount_3d_character(hero: Combatant) -> void:
	for child in model_mount.get_children():
		child.queue_free()

	var species = hero.species_id if hero.species_id != "" else hero.name.to_lower()
	var char_node: Node3D = CharacterModelLoader.create_model(species)
	model_mount.add_child(char_node)
	char_node.position = Vector3(0, 0, 0)


func _play_celebration_sequence(hero: Combatant, old_xp: int, new_xp: int) -> void:
	aura_cylinder.visible = true
	shock_ring1.visible = true

	var char_node = model_mount.get_child(0) if model_mount.get_child_count() > 0 else null
	if char_node:
		CharacterModelLoader.play_victory_jump(char_node, 0.55)

	var tween = create_tween()
	tween.tween_property(exp_bar, "value", new_xp, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var aura_mat = aura_cylinder.get_active_material(0) as ShaderMaterial
	if aura_mat:
		aura_mat.set_shader_parameter("alpha_fade", 0.18)
		tween.parallel().tween_property(aura_mat, "shader_parameter/alpha_fade", 0.0, 0.55)\
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
	for s in _party_summaries:
		var c = s.get("combatant") as Combatant
		if _is_party_leader(c):
			var alloc: Dictionary = _hero_sessions.get(c.get_instance_id(), {})
			var spent: int = 0
			for k in STAT_KEYS:
				spent += alloc.get(k, 0)
			if (c.distributable_points - spent) > 0:
				has_pending_leader_points = true
			break

	advance_lock_notice.visible = has_pending_leader_points
	return_btn.disabled = has_pending_leader_points

	if has_pending_leader_points:
		return_btn.text = "RETURN TO DUNGEON (LOCKED)"
		if return_btn.material is ShaderMaterial:
			(return_btn.material as ShaderMaterial).set_shader_parameter("bg_color", Color(0.32, 0.35, 0.4, 1))
	else:
		return_btn.text = "RETURN TO DUNGEON"
		if return_btn.material is ShaderMaterial:
			(return_btn.material as ShaderMaterial).set_shader_parameter("bg_color", Color(0.831, 1, 0.196, 1))


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
'''

with open('scripts/ui/level_up_hud.gd', 'w', encoding='utf-8') as f:
    f.write(hud_gd.strip() + '\n')
print('DONE')
