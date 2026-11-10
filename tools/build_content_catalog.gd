extends SceneTree
## Migração única da Etapa 1 (D-1079): gera os pacotes .tres a partir das
## definições legadas, sem alterar nenhum valor de jogo. Rodar com:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/build_content_catalog.gd

const MOVE_ROOT := "res://content/moves"
const CHARACTER_ROOT := "res://content/characters"
const CATALOG_ROOT := "res://content/catalogs"

const RAW_STATS := {
	"gible": {"STR": 70, "MAG": 40, "VIT": 45, "WIS": 45, "AGI": 42, "LUK": 48},
	"abra": {"STR": 20, "MAG": 105, "VIT": 15, "WIS": 55, "AGI": 90, "LUK": 57},
	"pancham": {"STR": 82, "MAG": 46, "VIT": 62, "WIS": 48, "AGI": 43, "LUK": 56},
	"dqt_orc": {"STR": 95, "MAG": 30, "VIT": 85, "WIS": 35, "AGI": 60, "LUK": 61},
	"dqt_cyclops": {"STR": 110, "MAG": 20, "VIT": 75, "WIS": 25, "AGI": 40, "LUK": 54},
	"dqt_slime": {"STR": 25, "MAG": 25, "VIT": 25, "WIS": 20, "AGI": 35, "LUK": 26},
}


func _init() -> void:
	var moves := _build_moves()
	var characters := _build_characters()
	print("[CONTENT] %d Moves, %d personagens" % [moves, characters])
	quit(0)


func _ensure_dir(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var err := DirAccess.make_dir_recursive_absolute(absolute)
	if err != OK:
		push_error("Falha ao criar %s (erro %d)" % [path, err])


func _save(resource: Resource, path: String) -> Resource:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Falha ao salvar %s (erro %d)" % [path, err])
		return null
	return load(path)


func _build_moves() -> int:
	_ensure_dir(MOVE_ROOT)
	_ensure_dir(CATALOG_ROOT)
	var catalog := MoveCatalog.new()
	var seen: Dictionary = {}
	var skills := Skill.legacy_catalog_skills()
	var duplicates: Array[String] = []

	for skill in skills:
		if skill == null:
			continue
		var move_id := StringName(BattleSpace.move_id(skill.display_name))
		if seen.has(move_id):
			duplicates.append(String(move_id))
			continue
		seen[move_id] = true

		var data := MoveData.new()
		data.id = move_id
		data.display_name = skill.display_name
		data.kind = int(skill.kind)
		data.element = skill.element
		data.power = skill.power
		data.atb_cost = skill.cost
		data.mp_cost = skill.mp_cost
		data.windup = skill.windup
		data.ground = skill.ground
		data.is_aoe = skill.is_aoe
		data.is_friendly = skill.is_friendly
		data.aoe_on_contact = skill.aoe_on_contact
		data.visual_push = skill.visual_push
		data.effect_line_text = skill.effect_line()
		data.short_effect_text = skill.short_effect()
		data.description_text = skill.description()
		data.mechanics_text = skill.mechanics_description()
		data.visual_text = skill.visual_description()
		data.motion_text = skill.motion_description()
		data.windup_text = skill.windup_description()
		data.tactical_text = skill.tactical_summary()
		data.visual_motion_text = skill.visual_motion_summary()
		data.phase_visuals = skill.visual_phases()
		data.tags = _tags_for(move_id)
		data.vfx_key = _vfx_key_for(move_id)
		# D-1079: optional per-Move scripts live beside move.tres and survive a
		# catalog rebuild. This is an edit-time check, not a runtime folder scan.
		var move_dir := "%s/%s" % [MOVE_ROOT, move_id]
		var behavior_path := "%s/behavior.gd" % move_dir
		if ResourceLoader.exists(behavior_path):
			data.behavior_script = load(behavior_path) as Script
		var vfx_path := "%s/vfx.gd" % move_dir
		if ResourceLoader.exists(vfx_path):
			data.vfx_script = load(vfx_path) as Script
		_apply_move_rules(data, move_id)

		var dir_path := "%s/%s" % [MOVE_ROOT, move_id]
		_ensure_dir(dir_path)
		var loaded := _save(data, "%s/move.tres" % dir_path)
		if loaded != null:
			catalog.moves.append(loaded)

	_ensure_dir(CATALOG_ROOT)
	var catalog_loaded := _save(catalog, "%s/move_catalog.tres" % CATALOG_ROOT)
	print("[CONTENT] Moves: %d no catálogo, %d duplicatas ignoradas" % [catalog.moves.size(), duplicates.size()])
	if catalog_loaded == null:
		push_error("Catálogo de Moves não foi salvo")
	return catalog.moves.size()


func _tags_for(move_id: StringName) -> Array[StringName]:
	var tags: Array[StringName] = []
	match String(move_id):
		"tackle", "spear_thrust", "boulder_smash":
			tags.append(&"basic_variant")
		"drain_spear":
			tags.append(&"badge_steal")
		"tidal_surge":
			tags.append(&"bounce")
		"electric_beam":
			tags.append(&"stun")
		"fire_bullet":
			tags.append(&"interrupt")
			tags.append(&"burn")
		"brick_break":
			tags.append(&"guard_break")
		"armored_bulk":
			tags.append(&"self_status")
			tags.append(&"armor")
			tags.append(&"stage_vfx")
		"media", "tarukaja", "rakunda", "sukunda":
			tags.append(&"stage_vfx")
		"onda_choque":
			tags.append(&"impact_on_miss")
		"soco_rapido":
			tags.append(&"no_bw_pulse")
		"investida_escavadora", "teleporte_rapido":
			tags.append(&"untargetable")
	# D-1026/D-1005/D-977/D-238: contact effects that ARMOR can cancel.
	for armor_move in ["mordida", "golpe_carate", "boulder_smash", "electric_beam", "fire_bullet"]:
		if String(move_id) == armor_move:
			tags.append(&"armor_worthy")
	return tags


## VFX family of the Move (D-1079, Etapa 3). Unknown Moves use the generic fallback.
func _vfx_key_for(move_id: StringName) -> StringName:
	match String(move_id):
		"confusao", "raio_psiquico", "onda_choque", "teleporte_rapido":
			return &"abra"
		"electric_beam":
			return &"electric"
		"tidal_surge":
			return &"tidal"
		"flame_stream", "splitter_flames":
			return &"element"
		"fire_bullet":
			return &"fire"
		"media":
			return &"media"
		"quebra_telha":
			return &"brick_break"
		"tiro_areia":
			return &"sand_attack"
		"furia_dragao":
			return &"dragon_rage"
		"provocacao":
			return &"taunt"
		"drain_spear":
			return &"drain_spear"
		"armored_bulk":
			return &"armored_bulk"
	return &"generic"


## Move-specific planning values, moved out of BattleSpace/AttackPlanner without
## changing the numbers. The planner reads these fields instead of matching ids.
func _apply_move_rules(data: MoveData, move_id: StringName) -> void:
	var id := String(move_id)
	data.stand_gap = BattleSpace.STAND_GAP
	data.hold = float(BattleSpace.RETURN_HOLD.get(id, BattleSpace.RETURN_HOLD_DEFAULT))
	data.plan_profile = &"melee" if data.kind == 0 else (&"projectile" if data.kind == 1 else &"cast")

	match id:
		"drain_spear":
			data.stand_gap = 16.3
			data.run_fixed = 0.35
			data.strike_time = 0.45
			data.hold = 0.75
			data.magic_flat = 5
			data.bypass_def = true
			data.transfer_time = 0.30
		"spear_thrust":
			data.stand_gap = BattleSpace.STAND_GAP + BattleSpace.SPEAR_EXTRA_GAP
		"soco_rapido":
			data.run_base = 0.18
			data.strike_time = 0.20
		"golpe_carate":
			data.run_base = 0.45
			data.strike_time = 0.45
		"quebra_telha":
			data.run_base = 0.24
			data.strike_time = 0.45
		"garra_dragao":
			data.run_base = 0.45
		"investida_escavadora":
			data.run_base = 0.26
			data.untargetable = true
		"hassou_tobi":
			data.run_base = 0.18
		"titanomachia":
			data.run_base = 0.24
		"boulder_smash":
			data.hit_offset = 0.15
		"furia_dragao":
			data.plan_profile = &"cast_strike_travel"
			data.plan_fly = 0.30
			data.plan_return = 0.16
			data.redirectable = false
		"teleporte_rapido":
			data.plan_profile = &"teleport"
			data.teleport = true
			data.untargetable = true
			data.redirectable = false
			data.blink_distance = 1.35
		"provocacao":
			data.plan_profile = &"cast_strike_travel"
			data.plan_fly = 0.28
			data.plan_return = 0.17
			data.redirectable = false
		"onda_choque":
			data.plan_profile = &"cast_travel_strike"
			data.plan_fly = 0.24
			data.plan_return = 0.20
			data.redirectable = false
		"armored_bulk":
			data.status_pause = 1.5

	data.ai_profile = {}
	if id == "mordida":
		data.ai_profile["contact_bonus"] = 8.0
	elif id == "golpe_carate":
		data.ai_profile["contact_bonus"] = 6.0
	if &"armor_worthy" in data.tags:
		data.ai_profile["armor_worthy"] = true

	# VFX timing values (D-1079/Etapa 3), copied from the old BattleFx tables.
	data.hit_stop_duration = {
		"tackle": 0.075, "investida": 0.075, "soco_rapido": 0.075,
		"golpe_carate": 0.095, "quebra_telha": 0.110, "confusao": 0.085,
		"raio_psiquico": 0.095, "onda_choque": 0.100, "teleporte_rapido": 0.065,
		"mordida": 0.095, "tiro_areia": 0.085, "garra_dragao": 0.105,
		"furia_dragao": 0.115, "investida_escavadora": 0.120,
		"investida_subterranea": 0.120, "drain_spear": 0.100,
	}.get(id, -1.0)
	data.bw_pulse = id in [
		"golpe_carate", "quebra_telha", "onda_choque", "garra_dragao", "furia_dragao",
		"investida_subterranea", "investida_escavadora", "megido", "titanomachia", "hassou_tobi",
	]


func _build_characters() -> int:
	_ensure_dir(CHARACTER_ROOT)
	_ensure_dir(CATALOG_ROOT)
	var catalog := CharacterCatalog.new()
	var entries := [
		_character(
			"gible", "Gible", "gible", 39, 9, 0.425,
			[int(Element.Type.AGUA_GELO)],
			[&"mordida", &"tiro_areia", &"furia_dragao", &"investida_escavadora", &"garra_dragao", &"rakunda", &"mabufula", &"titanomachia"],
			{"potion": 1}, 0.0, 0, 0
		),
		_character(
			"abra", "Abra", "abra", 39, 9, 0.425,
			[int(Element.Type.TREVAS), int(Element.Type.SOM)],
			[&"confusao", &"raio_psiquico", &"onda_choque", &"teleporte_rapido", &"media", &"sukunda", &"megido"],
			{}, 0.0, 0, 0
		),
		_character(
			"pancham", "Pancham", "pancham", 39, 9, 0.425,
			[int(Element.Type.PSIQUICO), int(Element.Type.VENTO)],
			[&"soco_rapido", &"golpe_carate", &"quebra_telha", &"provocacao", &"tarukaja", &"hassou_tobi"],
			{}, 0.0, 0, 0
		),
		_character(
			"dqt_slime", "Slime", "dqt_slime", 39, 9, 0.425,
			[int(Element.Type.FOGO)],
			[&"tackle", &"bubble_shot", &"heal", &"electric_beam", &"tidal_surge"],  # D-1080
			{}, 0.0, 0, 0
		),
		_character(
			"dqt_orc", "Orc", "dqt_orc", 39, 9, 0.425,
			[int(Element.Type.RAIO)],
			[&"spear_thrust", &"drain_spear", &"javelin_throw", &"war_cry", &"armored_bulk"],
			{}, 0.45, 0, 0
		),
		_character(
			"dqt_cyclops", "Cyclops", "dqt_cyclops", 39, 9, 0.425,
			[int(Element.Type.PSIQUICO)],
			[&"boulder_smash", &"rock_throw", &"glare", &"armored_bulk"],
			{}, 0.8, 0, 0
		),
	]

	for entry in entries:
		var dir_path := "%s/%s" % [CHARACTER_ROOT, entry.id]
		_ensure_dir(dir_path)
		var loadout_loaded := _save(entry.loadout, "%s/loadout.tres" % dir_path)
		var profile_loaded := _save(entry.model_profile, "%s/model_profile.tres" % dir_path)
		if loadout_loaded != null:
			entry.loadout = loadout_loaded
		if profile_loaded != null:
			entry.model_profile = profile_loaded
		var loaded := _save(entry, "%s/species.tres" % dir_path)
		if loaded != null:
			catalog.characters.append(loaded)

	var catalog_loaded := _save(catalog, "%s/character_catalog.tres" % CATALOG_ROOT)
	print("[CONTENT] Personagens: %d no catálogo" % [catalog.characters.size()])
	if catalog_loaded == null:
		push_error("Catálogo de personagens não foi salvo")
	return catalog.characters.size()


func _character(
	id: String,
	display_name: String,
	species_id: String,
	hp: int,
	attack: int,
	speed: float,
	weaknesses: Array[int],
	skills: Array[StringName],
	inventory: Dictionary,
	travel_extra: float,
	act_policy: int,
	react_policy: int
) -> CharacterData:
	var data := CharacterData.new()
	data.id = StringName(id)
	data.display_name = display_name
	data.species_id = species_id
	data.hp = hp
	data.attack = attack
	data.speed = speed
	data.raw_stats = RAW_STATS.get(species_id, {}).duplicate(true)
	data.weaknesses = weaknesses
	var loadout := CharacterLoadout.new()
	loadout.skills = skills
	loadout.inventory = inventory.duplicate(true)
	data.loadout = loadout
	data.travel_extra = travel_extra
	data.act_policy = act_policy
	data.react_policy = react_policy
	data.base_experience = 30
	var model_profile := CharacterModelProfile.new()
	model_profile.profile = DqtModelProfiles.PROFILES.get(species_id, {}).duplicate(true)
	data.model_profile = model_profile
	return data
