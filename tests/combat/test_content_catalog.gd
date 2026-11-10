extends SceneTree
## Contrato da Etapa 1 (D-1079): o catálogo novo deve reproduzir exatamente as
## definições legadas e a ficha canônica dos 6 personagens. Nenhuma regra muda.

const MoveCatalog = preload("res://scripts/data/move_catalog.gd")
const CharacterCatalog = preload("res://scripts/data/character_catalog.gd")
const CharacterFactory = preload("res://scripts/combat/character_factory.gd")
const DqtTestParty = preload("res://scripts/combat/dqt_test_party.gd")
const Skill = preload("res://scripts/data/skill.gd")
const BattleSpace = preload("res://scripts/combat/battle_space.gd")
const Element = preload("res://scripts/data/element.gd")
const MediaBehaviorScript = preload("res://content/moves/media/behavior.gd")

var _failures := 0


func _init() -> void:
	_test_move_catalog_matches_legacy()
	_test_character_catalog()
	_test_factory_skills_and_slime()
	_test_test_party_overrides()
	_test_all_catalog_skills()
	_test_behavior_dispatch()
	_test_vfx_registry()
	if _failures == 0:
		print("[TEST SUCCESS] Etapas 1, 2 e 3: catálogo, fábrica, dispatcher e VFX registry batem com as definições atuais.")
		quit(0)
	else:
		push_error("[TEST FAILURE] Etapa 1: %d falhas." % _failures)
		quit(1)


func ok(condition: bool, message: String) -> void:
	if condition:
		print("  OK  ", message)
	else:
		_failures += 1
		push_error("  FAIL " + message)


func _legacy_by_id() -> Dictionary:
	var out: Dictionary = {}
	for skill in Skill.legacy_catalog_skills():
		if skill == null:
			continue
		var id := StringName(BattleSpace.move_id(skill.display_name))
		if not out.has(id):
			out[id] = skill
	return out


func _test_move_catalog_matches_legacy() -> void:
	print("[TEST] Move catalog 1:1")
	var catalog := MoveCatalog.load_default()
	ok(catalog != null, "move_catalog.tres carregou")
	if catalog == null:
		return
	ok(catalog.moves.size() == 38, "38 Moves no catálogo (encontrado %d)" % catalog.moves.size())

	var seen: Dictionary = {}
	for move in catalog.moves:
		ok(move != null and not move.id.is_empty(), "Move com id")
		if move == null:
			continue
		ok(not seen.has(move.id), "id único: %s" % move.id)
		seen[move.id] = true

	var legacy := _legacy_by_id()
	for move_id in legacy:
		var old: Skill = legacy[move_id]
		var data := catalog.find_move(move_id)
		ok(data != null, "Move legado presente no catálogo: %s" % move_id)
		if data == null:
			continue
		ok(data.display_name == old.display_name, "%s: display_name" % move_id)
		ok(is_equal_approx(data.power, old.power), "%s: power" % move_id)
		ok(data.atb_cost == old.cost, "%s: ATB" % move_id)
		ok(data.mp_cost == old.mp_cost, "%s: MP" % move_id)
		ok(data.element == old.element, "%s: elemento" % move_id)
		ok(data.kind == int(old.kind), "%s: kind" % move_id)
		ok(is_equal_approx(data.windup, old.windup), "%s: windup" % move_id)
		ok(data.ground == old.ground, "%s: ground" % move_id)
		ok(data.is_aoe == old.is_aoe, "%s: AoE" % move_id)
		ok(data.is_friendly == old.is_friendly, "%s: friendly" % move_id)
		ok(data.aoe_on_contact == old.aoe_on_contact, "%s: AoE on contact" % move_id)
		ok(data.visual_push == old.visual_push, "%s: visual_push" % move_id)
		ok(data.mechanics_text == old.mechanics_description(), "%s: mechanics" % move_id)
		ok(data.visual_text == old.visual_description(), "%s: visual" % move_id)
		ok(data.motion_text == old.motion_description(), "%s: motion" % move_id)
		ok(data.windup_text == old.windup_description(), "%s: windup text" % move_id)
		ok(data.tactical_text == old.tactical_summary(), "%s: tactical" % move_id)
		ok(data.visual_motion_text == old.visual_motion_summary(), "%s: visual motion" % move_id)
		ok(data.phase_visuals == old.visual_phases(), "%s: fichas por fase" % move_id)


func _test_character_catalog() -> void:
	print("[TEST] Character catalog")
	var catalog := CharacterCatalog.load_default()
	ok(catalog != null, "character_catalog.tres carregou")
	if catalog == null:
		return
	ok(catalog.characters.size() == 6, "6 personagens no catálogo (encontrado %d)" % catalog.characters.size())
	for id in ["gible", "abra", "pancham", "dqt_slime", "dqt_orc", "dqt_cyclops"]:
		var data := CharacterCatalog.get_character(StringName(id))
		ok(data != null, "personagem presente: %s" % id)
		if data != null:
			ok(data.species_id == id, "%s: species_id" % id)
			ok(is_equal_approx(data.speed, 0.425), "%s: velocidade canônica" % id)
			ok(data.loadout != null, "%s: loadout presente" % id)
			ok(data.model_profile != null, "%s: model_profile presente" % id)
			ok(data.raw_stats.size() == 6, "%s: seis atributos brutos" % id)
			ok(data.skill_ids().size() > 0, "%s: leque base não vazio" % id)
	var move_catalog := MoveCatalog.load_default()
	for move in move_catalog.moves:
		if move.plan_profile in [&"cast_strike_travel", &"cast_travel_strike"]:
			ok(move.plan_fly >= 0.0 and move.plan_return >= 0.0, "%s: plano cast com fly/return" % move.id)
		elif move.plan_profile == &"teleport":
			ok(move.blink_distance > 0.0 and move.untargetable, "%s: plano de teleporte válido" % move.id)
		elif move.plan_profile == &"melee":
			ok(move.stand_gap > 0.0 and move.hold >= 0.0, "%s: plano melee válido" % move.id)


func _test_factory_skills_and_slime() -> void:
	print("[TEST] CharacterFactory + Slime")
	var slime := CharacterFactory.create("dqt_slime", {"is_player": false})
	ok(slime != null, "Slime criado")
	if slime == null:
		return
	var names := slime.skills.map(func(s): return s.display_name)
	ok("Tidal Surge" in names, "Slime inimigo tem Tidal Surge (D-1080)")
	ok("Electric Beam" in names, "Slime mantém Electric Beam")
	ok(slime.weaknesses == [Element.Type.FOGO], "Slime tem fraqueza FOGO")
	ok(slime.skills.all(func(s): return s.data != null), "todos os Skills do Slime vêm do catálogo")

	var orc := CharacterFactory.create("dqt_orc", {"is_player": false})
	ok(orc != null and is_equal_approx(orc.travel_extra, 0.45), "Orc: travel_extra 0.45")
	var cyclops := CharacterFactory.create("dqt_cyclops", {"is_player": false})
	ok(cyclops != null and is_equal_approx(cyclops.travel_extra, 0.8), "Cyclops: travel_extra 0.8")
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest"})
	ok(abra != null and abra.nature_id == "modest", "Abra: Nature Modest forçada")
	ok(abra != null and abra.skills.size() == 7, "Abra: 7 Moves")
	var pancham := CharacterFactory.create("pancham", {"is_player": true, "forced_nature": "brave"})
	ok(pancham != null and pancham.nature_id == "brave", "Pancham: Nature Brave forçada")
	ok(pancham != null and pancham.skills.size() == 6, "Pancham: 6 Moves")


func _test_test_party_overrides() -> void:
	print("[TEST] DqtTestParty: overrides só de teste")
	var party := DqtTestParty.build(true)
	ok(party.size() == 3, "party de teste tem 3 personagens")
	ok(party[0].name == "Orc" and party[1].name == "Slime" and party[2].name == "Cyclops", "ordem Orc/Slime/Cyclops")
	ok(party[0].max_hp == 52 and party[0].base_attack == 13 and is_equal_approx(party[0].base_speed, 0.45), "Orc: overrides 52/13/0.45")
	ok(party[1].max_hp == 34 and party[1].base_attack == 9 and is_equal_approx(party[1].base_speed, 0.55), "Slime: overrides 34/9/0.55")
	ok(party[2].max_hp == 64 and party[2].base_attack == 16 and is_equal_approx(party[2].base_speed, 0.35), "Cyclops: overrides 64/16/0.35")
	for c in party:
		ok(c.max_mp == 20, "%s: MP de teste 20" % c.name)
	ok(party[1].skills.any(func(s): return s.display_name == "Tidal Surge"), "Slime de teste também tem Tidal Surge")


func _test_all_catalog_skills() -> void:
	print("[TEST] Skill.all_catalog_skills usa o catálogo")
	var skills := Skill.all_catalog_skills()
	ok(skills.size() == 38, "38 Skills no catálogo universal (encontrado %d)" % skills.size())
	ok(skills.all(func(s): return s.data != null), "todos os Skills universais vêm do catálogo")


func _test_behavior_dispatch() -> void:
	print("[TEST] Dispatcher de comportamento (Etapa 2)")
	ok(MoveBehaviorRegistry.get_behavior(&"drain_spear") is MoveBehaviors.DrainSpear, "Drain Spear tem behavior próprio")
	ok(MoveBehaviorRegistry.get_behavior(&"tidal_surge") is MoveBehaviors.TidalSurge, "Tidal Surge tem behavior próprio")
	ok(MoveBehaviorRegistry.get_behavior(&"armored_bulk") is MoveBehaviors.ArmoredBulk, "Armored Bulk tem behavior próprio")
	var media_behavior := MoveBehaviorRegistry.get_behavior(&"media")
	ok(media_behavior.get_script() == MediaBehaviorScript, "Media tem behavior próprio no pacote")
	ok(media_behavior.data == MoveCatalog.get_move(&"media"), "Media behavior usa a ficha do catálogo")
	ok(MoveBehaviorRegistry.get_behavior(&"tackle") is MoveBehavior, "Tackle usa o behavior base")

	var drain := MoveCatalog.get_move(&"drain_spear")
	ok(drain.stand_gap == 16.3 and drain.run_fixed == 0.35 and drain.hold == 0.75, "Drain Spear: dados de planejamento")
	ok(drain.magic_flat == 5 and drain.bypass_def and drain.transfer_time == 0.30, "Drain Spear: regra mágica/roubo")
	var spear := MoveCatalog.get_move(&"spear_thrust")
	ok(spear.stand_gap == 7.0, "Spear Thrust: para a 7 unidades")
	var mach := MoveCatalog.get_move(&"soco_rapido")
	ok(mach.run_base == 0.18 and mach.strike_time == 0.20, "Mach Punch: run/hit próprios")
	var boulder := MoveCatalog.get_move(&"boulder_smash")
	ok(boulder.hit_offset == 0.15 and boulder.has_tag(&"armor_worthy"), "Boulder Smash: hit offset e tag ARMOR")
	var teleport := MoveCatalog.get_move(&"teleporte_rapido")
	ok(teleport.teleport and teleport.untargetable and not teleport.redirectable, "Teleport: flags de planejamento")
	var armored := MoveCatalog.get_move(&"armored_bulk")
	ok(armored.status_pause == 1.5, "Armored Bulk: pausa de 1,5 s")


func _test_vfx_registry() -> void:
	print("[TEST] Registro de VFX por Move (Etapa 3)")
	ok(MoveCatalog.get_move(&"confusao").vfx_key == &"abra", "Confusion: vfx_key abra")
	ok(MoveCatalog.get_move(&"electric_beam").vfx_key == &"electric", "Electric Beam: vfx_key electric")
	ok(MoveCatalog.get_move(&"tidal_surge").vfx_key == &"tidal", "Tidal Surge: vfx_key tidal")
	ok(MoveCatalog.get_move(&"fire_bullet").vfx_key == &"fire", "Fire Bullet: vfx_key fire")
	ok(MoveCatalog.get_move(&"tackle").vfx_key == &"generic", "Tackle: fallback genérico")
	ok(is_equal_approx(MoveCatalog.get_move(&"confusao").hit_stop_duration, 0.085), "Confusion: hit-stop 85 ms")
	ok(MoveCatalog.get_move(&"onda_choque").bw_pulse, "Shock Wave: bw_pulse")
	ok(MoveVfxRegistry.family(&"confusao") == &"abra", "registry: família abra")
	ok(MoveVfxRegistry.family(&"tackle") == &"generic", "registry: família genérica")
	ok(MoveVfxRegistry.travel_family(&"teleporte_rapido") == &"teleport", "registry: Teleport tem travel próprio")
	ok(MoveVfxRegistry.travel_family(&"confusao") == &"abra", "registry: Confusion usa travel abra")
	for move in MoveCatalog.all_moves():
		ok(not move.vfx_key.is_empty(), "%s: vfx_key preenchido" % move.id)
