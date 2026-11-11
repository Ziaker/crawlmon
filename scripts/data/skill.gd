class_name Skill
extends RefCounted
## A Fight-menu move. `cost` is in ATB blocks (normally 2). `kind` is how the move reaches
## its target and is separate from its element: MELEE runs at the target, PROJECTILE flies
## to it (`ground`: along the floor), CAST strikes from where the caster stands, STATUS
## deals no damage.

enum Kind { MELEE, PROJECTILE, CAST, STATUS }

var display_name: String
var power: float
var cost: int
var element: Element.Type
var kind: Kind
var ground := false  ## A projectile that travels along the floor.
var is_aoe := false  ## Hits all targets on the opposing team (or all allies if friendly).
var is_friendly := false  ## Targets self/allies (healing/buffs).
var windup: float = -1.0  ## Individual windup in seconds (-1.0 uses default).
var aoe_on_contact := false  ## Single target projectile that explodes AoE upon hitting main target (D-032).
var mp_cost: int = 0  ## MP cost consumed when cast (D-413).
var visual_push := -1  ## D-1073: -1 = by kind (projectile no; melee/CAST yes); 0 = never; 1 = always.
var damage_type: int = MoveData.DamageType.PHYSICAL  ## D-1140: STR or MAG scaling, declared by the Move.
var data: MoveData = null  ## D-1079: definição canônica no catálogo; null em Skills avulsos de teste.


## D-1140: the Move deals magic damage and scales with MAG (D-122).
func is_magical() -> bool:
	return damage_type == MoveData.DamageType.MAGICAL


## D-1145/D-395/D-396: UI type badge. The damage type decides Magical/Physical;
## Guard and Dodge are special categories; pure status has no type icon.
func type_icon_name() -> String:
	var id := BattleSpace.move_id(display_name)
	if id == "teleporte_rapido" or id == "evade":
		return "dodge"
	if id == "guard":
		return "guard"
	if kind == Kind.STATUS:
		return ""
	return "magical" if is_magical() else "physical"


## D-1073: whether the target is pushed visually on contact. A Move may override this at creation.
func pushes_visually() -> bool:
	if visual_push >= 0:
		return visual_push == 1
	return kind == Kind.MELEE or kind == Kind.CAST


func _init(p_name: String, p_power: float, p_cost := 2, p_element := Element.Type.FISICO, p_kind := -1, p_ground := false, p_aoe := false, p_friendly := false, p_windup := -1.0, p_aoe_contact := false, p_mp_cost := -1) -> void:
	display_name = p_name
	power = p_power
	cost = p_cost
	element = p_element
	ground = p_ground
	is_aoe = p_aoe
	is_friendly = p_friendly
	windup = p_windup
	aoe_on_contact = p_aoe_contact
	kind = (p_kind if p_kind >= 0 else default_kind(p_element)) as Kind
	mp_cost = (p_mp_cost if p_mp_cost >= 0 else get_mp_cost_for(p_name))


## D-1079: cria o Skill de runtime a partir da definição canônica do catálogo.
static func from_data(move: MoveData) -> Skill:
	if move == null:
		return null
	var skill := Skill.new(
		move.display_name, move.power, move.atb_cost, move.element, move.kind,
		move.ground, move.is_aoe, move.is_friendly, move.windup,
		move.aoe_on_contact, move.mp_cost
	)
	skill.data = move
	skill.visual_push = move.visual_push
	skill.damage_type = move.damage_type
	return skill


static func from_id(move_id: StringName) -> Skill:
	return from_data(MoveCatalog.get_move(move_id))


## Moves that do not say how they travel behave like their element used to.
## Calibrated MP costs for all moves (D-413).
static func get_mp_cost_for(move_name: String) -> int:
	var id := BattleSpace.move_id(move_name)
	var table := SkillLegacyData.mp_costs()
	if table.has(id):
		return int(table[id])
	return 3


static func default_kind(e: Element.Type) -> Kind:
	if e == Element.Type.FISICO:
		return Kind.MELEE
	if e in [Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA]:
		return Kind.CAST
	return Kind.PROJECTILE


## Full mechanical line for the detail panels. " | " separates the sheet bullets.
func effect_line() -> String:
	if data != null and not data.effect_line_text.is_empty():
		return data.effect_line_text
	var id := BattleSpace.move_id(display_name)
	return String(_effects().get(id, "%s damage x%s ATK | %s | %d ATB" % [
		Element.name_of(element), String.num(power, 2), kind_name(kind), cost]))


## Bullet list for the battle sheet: one idea per line, cost moved to the header.
func sheet_bullets() -> Array[String]:
	var out: Array[String] = []
	for part in effect_line().split(" | "):
		var text := part.strip_edges()
		if text == "" or text.to_lower().ends_with("atb"):
			continue
		for sub in text.split(": "):
			var line := sub.strip_edges()
			if line == "":
				continue
			line = line.substr(0, 1).to_upper() + line.substr(1)
			out.append(line)
	return out


## One-line version for the compact Status card.
func short_effect() -> String:
	if data != null and not data.short_effect_text.is_empty():
		return data.short_effect_text
	var id := BattleSpace.move_id(display_name)
	var table := SkillLegacyData.short_effects()
	if table.has(id):
		return String(table[id])
	return "x%s %s" % [String.num(power, 2), Element.name_of(element)]


## Flavor/mechanics paragraph for the Status detail overlay.
func description() -> String:
	if data != null and not data.description_text.is_empty():
		return data.description_text
	var id := BattleSpace.move_id(display_name)
	var text := String(_descriptions().get(id, ""))
	if text != "":
		return text
	return "A %s %s move. Deals x%s ATK damage." % [
		Element.name_of(element).to_lower(), kind_name(kind), String.num(power, 2)]


## What a status move will do right now, using the caster's real stats.
static func status_forecast(skill: Skill, caster: Combatant) -> String:
	var id := BattleSpace.move_id(skill.display_name)
	match id:
		"media":
			return "Heals %d on each living ally (capped by missing HP)" % (10 + caster.mag)
		"bubble_shield":
			return "%d shield on each ally | 8 s | reapplication resets" % (25 + caster.mag)
		"tarukaja":
			return "+1 ATK to each ally (max +5) | lasts the battle"
		"rakunda":
			return "-1 DEF to the target (min -5) | lasts the battle"
		"sukunda":
			return "-1 SPD to the target (min -5) | lasts the battle"
		"taunt", "provocacao":
			return "Forces the target to attack the user"
		"sand_attack", "tiro_areia":
			return "Blinds the target for 4 s (35% miss)"
		"armored_bulk":
			return "ARMOR on the user for 8 s (a recast adds 8 s) | first Move contact: no interruption, no contact effects"
	return skill.effect_line()


static func _effects() -> Dictionary:
	return SkillLegacyData.effects()


static func _descriptions() -> Dictionary:
	return SkillLegacyData.descriptions()


static func kind_name(k: Kind) -> String:
	return ["melee", "projectile", "ranged", "status"][k]


## The generic physical attack always shown first in the Fight menu.
static func basic() -> Skill:
	return Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.5)


## Fire Moves of D-236. Basic Skills only: element, how they travel, ATB cost and wind-up from the sheet.
## `power` is PROVISIONAL (1.0, like Tackle): the sheet's `10 + MAG` formula, MP, Burn and the Burn chances
## are not implemented yet (creator's choice, D-236). Nobody in the party owns them: only the VFX room lists them.
static func fire_skills() -> Array[Skill]:
	var fb := Skill.new("Fire Bullet", 1.0, 2, Element.Type.FOGO, Kind.PROJECTILE, false, false, false, 0.5)
	fb.visual_push = 1  # D-1073: an explicit Move exception (D-236/D-1051) — the interrupting shot keeps its shove.
	return [fb]


## Element Moves of D-308 (reference VFX). Basic Skills only, like the fire Moves: nobody in the party owns them,
## only the VFX room lists them. `power` is PROVISIONAL (1.0, like Tackle); no damage formula is approved for them.
## D-956/D-957: projectile VFX library Moves. Visual reference only, like the element Moves: nobody owns them, only the
## VFX room lists them; `power` is PROVISIONAL (1.0). Wind-up 0.5 as the measured projectile Moves.
static func library_skills() -> Array[Skill]:
	return [
		Skill.new("Electric Beam", 1.0, 2, Element.Type.RAIO, Kind.PROJECTILE, false, false, false, 0.5),
		Skill.new("Tidal Surge", 1.0, 2, Element.Type.AGUA_GELO, Kind.PROJECTILE, false, false, false, 0.8),  # D-1021/D-1025
	]


static func element_skills() -> Array[Skill]:
	return [
		Skill.new("Flame Stream", 1.0, 2, Element.Type.FOGO, Kind.PROJECTILE, false, false, false, 0.5),
		Skill.new("Splitter Flames", 1.0, 2, Element.Type.FOGO, Kind.PROJECTILE, false, false, false, 0.7),
	]


## 8 Shin Megami Tensei inspired moves (4 Status, 2 AoE Projectile, 2 AoE Physical).
static func smt_skills() -> Array[Skill]:
	return [
		# 4 Status (1 Heal/Support, Buffs, Debuffs)
		Skill.new("Media", 0.0, 2, Element.Type.LUZ, Kind.STATUS, false, true, true, 0.5),
		Skill.new("Tarukaja", 0.0, 2, Element.Type.FOGO, Kind.STATUS, false, true, true, 0.5),
		Skill.new("Rakunda", 0.0, 1, Element.Type.TREVAS, Kind.STATUS, false, false, false, 0.5),
		Skill.new("Sukunda", 0.0, 1, Element.Type.VENTO, Kind.STATUS, false, false, false, 0.5),
		# 2 AoE Projectiles
		Skill.new("Mabufula", 1.35, 2, Element.Type.AGUA_GELO, Kind.PROJECTILE, false, true, false, 1.5),
		Skill.new("Megido", 1.6, 3, Element.Type.MYSTIC, Kind.PROJECTILE, false, true, false, 1.5),
		# 2 AoE Physical
		Skill.new("Hassou Tobi", 1.4, 3, Element.Type.FISICO, Kind.MELEE, false, true, false, 1.5),
		Skill.new("Titanomachia", 1.5, 3, Element.Type.TERRA, Kind.MELEE, false, true, false, 1.5),
	]


## Deep mechanical breakdown for the expanded inspection modal (D-420).
func mechanics_description() -> String:
	if data != null and not data.mechanics_text.is_empty():
		return data.mechanics_text
	var id := BattleSpace.move_id(display_name)
	return String(_mechanics_descriptions().get(id, effect_line()))


## Aesthetic and visual VFX description for the expanded inspection modal (D-420).
func visual_description() -> String:
	if data != null and not data.visual_text.is_empty():
		return data.visual_text
	var id := BattleSpace.move_id(display_name)
	return String(_visual_descriptions().get(id, "Vibrant elemental VFX manifestation with light emission and impact shockwaves."))


## Spatial kinematics and displacement description for the expanded inspection modal (D-420).
func motion_description() -> String:
	if data != null and not data.motion_text.is_empty():
		return data.motion_text
	var id := BattleSpace.move_id(display_name)
	return String(_motion_descriptions().get(id, ("Rushes forward into melee contact range and returns." if kind == Kind.MELEE else "Stationary stance; fires projectile along a direct trajectory toward the target.")))


## Wind-up timing and telegraph behavior for the expanded inspection modal (D-420).
func windup_description() -> String:
	if data != null and not data.windup_text.is_empty():
		return data.windup_text
	var id := BattleSpace.move_id(display_name)
	var w := windup if windup >= 0.0 else 1.0
	return String(_windup_descriptions().get(id, "%.2fs preparation stance. Vulnerable to interruption by heavy hits." % w))


## Compact, non-redundant tactical summary for the standard card (D-420).
func tactical_summary() -> String:
	if data != null and not data.tactical_text.is_empty():
		return data.tactical_text
	var id := BattleSpace.move_id(display_name)
	return String(_tactical_summaries().get(id, ("Hits all enemies in area." if is_aoe else "Direct strike on single target.")))


## Compact, non-redundant visual & displacement summary for the standard card (D-420).
func visual_motion_summary() -> String:
	if data != null and not data.visual_motion_text.is_empty():
		return data.visual_motion_text
	var id := BattleSpace.move_id(display_name)
	return String(_visual_motion_summaries().get(id, ("Forward melee sprint with elemental impact." if kind == Kind.MELEE else "Stationary launch of direct elemental energy.")))


## Attribute scaling summary (MAG vs STR) and wind-up for combat sheet (D-436).
func scaling_timing_summary() -> String:
	var stat_name := "MAG" if is_magical() else "STR"
	var w := windup if windup >= 0.0 else 1.0
	return "Scales with %s (%d%%) · Wind-up: %.2fs" % [stat_name, int(round(power * 100.0)), w]


static func _mechanics_descriptions() -> Dictionary:
	return SkillLegacyData.mechanics()


static func _visual_descriptions() -> Dictionary:
	return SkillLegacyData.visual()


static func _motion_descriptions() -> Dictionary:
	return SkillLegacyData.motion()


static func _windup_descriptions() -> Dictionary:
	return SkillLegacyData.windup()


static func _tactical_summaries() -> Dictionary:
	return SkillLegacyData.tactical()


static func _visual_motion_summaries() -> Dictionary:
	return SkillLegacyData.visual_motion()


## Ficha visual estruturada por fase (D-308 / D-1042 / D-1044): descreve o que deve ser visto em cada
## fase do Move (windup, release, travel, strike, impact, return) a partir de sua ficha visual.
func visual_phases() -> Dictionary:
	if data != null and not data.phase_visuals.is_empty():
		return data.phase_visuals
	var id := BattleSpace.move_id(display_name)
	var custom: Dictionary = _visual_phases_table().get(id, {})
	if not custom.is_empty():
		return custom
	var w_desc := windup_description()
	var m_desc := motion_description()
	var v_desc := visual_description()
	if kind == Kind.MELEE:
		return {
			"windup": "Preparo em posição base com loop contínuo de carga (D-163): %s" % w_desc,
			"release": "Partida física contínua a partir da carga rumo ao alvo: %s" % m_desc,
			"travel": "Corrida pelo eixo atacante->alvo com trilha no chão (D-1013): %s" % m_desc,
			"strike": "Prelúdio de golpe e arco de swing/arma com aviso Dread na janela de Evade (D-986/D-992).",
			"impact": "Contato direto no ponto zero do alvo com hit-stop, flash e reação: %s" % v_desc,
			"return": "Salto/corrida de recuo de volta à posição de origem e retomada de idle.",
		}
	elif kind == Kind.STATUS:
		return {
			"windup": "Canalização de status com motor pausado (D-031): %s" % w_desc,
			"release": "Liberação da invocação no próprio lançador/alvo: %s" % m_desc,
			"travel": "Manifestação direta no campo (sem deslocamento de corpo): %s" % m_desc,
			"strike": "Ativação do selo/aura de status sobre os alvos.",
			"impact": "Aplicação do efeito visual e badge de status: %s" % v_desc,
			"return": "Dissolução suave da cerimônia sem sobras e retomada do relógio do combate.",
		}
	return {
		"windup": "Carga elemental contínua à frente do lançador (D-308 Fase 1): %s" % w_desc,
		"release": "Transição contínua da carga para o disparo sem sumiço brusco (D-308 Fase 2): %s" % m_desc,
		"travel": "Voo do projétil/feixe ao longo do eixo atacante->alvo mantendo leitura de tela (D-308 Fase 3): %s" % m_desc,
		"strike": "Janela final de aproximação (últimos 0,25 s) antes do contato.",
		"impact": "Explosão/impacto no ponto de contato a 1,2 m de altura (D-1013 / D-308 Fase 4): %s" % v_desc,
		"return": "Dissipação completa de partículas/malhas (zero restos) e retorno do lançador ao idle.",
	}


func visual_phase_text(phase_key: String) -> String:
	var phases := visual_phases()
	var k := phase_key.to_lower()
	return String(phases.get(k, visual_description()))


func visual_phase_sheet() -> String:
	var p := visual_phases()
	return "\n".join([
		"1. WIND-UP: %s" % String(p.get("windup", "")),
		"2. RELEASE: %s" % String(p.get("release", "")),
		"3. TRAJETO: %s" % String(p.get("travel", "")),
		"4. GOLPE: %s" % String(p.get("strike", "")),
		"5. IMPACTO: %s" % String(p.get("impact", "")),
		"6. RETORNO: %s" % String(p.get("return", "")),
	])


static func _visual_phases_table() -> Dictionary:
	return SkillLegacyData.visual_phases()


## Catálogo mestre de todos os Moves do jogo para que qualquer combatente possa usar qualquer Move na sala de debug (D-235).
## D-1079: quando o catálogo existe, ele é a fonte única; a lista legada fica como fallback.
static func all_catalog_skills() -> Array[Skill]:
	var catalog := MoveCatalog.load_default()
	if catalog != null and not catalog.moves.is_empty():
		var out: Array[Skill] = []
		for move in catalog.moves:
			var skill := from_data(move)
			if skill != null:
				out.append(skill)
		return out
	return legacy_catalog_skills()


## Lista legada usada apenas para gerar/migrar o catálogo.
static func legacy_catalog_skills() -> Array[Skill]:
	var DrainSpear = load("res://scripts/data/drain_spear_move.gd")
	var list: Array[Skill] = [
		basic(),
		Skill.new("Confusion", 1.4, 2, Element.Type.PSIQUICO, Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Psybeam", 1.7, 3, Element.Type.PSIQUICO, Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Shock Wave", 1.3, 2, Element.Type.RAIO, Kind.CAST, false, false, false, 1.5),
		Skill.new("Teleport", 0.7, 1, Element.Type.PSIQUICO, Kind.MELEE, false, false, false, 0.5),
		Skill.new("Bubble Shield", 0.0, 3, Element.Type.AGUA_GELO, Kind.STATUS, false, true, true, 0.5),
		Skill.new("Mach Punch", 0.5, 1, Element.Type.FISICO, Kind.MELEE, false, false, false, 0.2),
		Skill.new("Karate Chop", 1.5, 2, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.0),
		Skill.new("Brick Break", 1.8, 3, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.5),
		Skill.new("Taunt", 0.0, 1, Element.Type.FISICO, Kind.STATUS, false, false, false, 0.5),
		Skill.new("Bite", 1.3, 2, Element.Type.TREVAS, Kind.MELEE, false, false, false, 1.2),
		Skill.new("Sand Attack", 0.0, 1, Element.Type.TERRA, Kind.PROJECTILE, true, false, false, 0.75),
		Skill.new("Dragon Rage", 1.6, 3, Element.Type.FISICO, Kind.PROJECTILE, false, false, false, 2.0, true),
		Skill.new("Dig", 1.5, 2, Element.Type.TERRA, Kind.MELEE, true, false, false, 1.0),
		Skill.new("Dragon Claw", 1.6, 3, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.5),
		Skill.new("Bubble Shot", 1.0, 2, Element.Type.AGUA_GELO, Kind.PROJECTILE, false, false, false, 0.7),  # D-1170
		Skill.new("Heal", 0.0, 2, Element.Type.LUZ, Kind.STATUS, false, true, true, 0.5),
		Skill.new("Spear Thrust", 1.3, 2, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.2),
		Skill.new("Javelin Throw", 1.2, 2, Element.Type.FISICO, Kind.PROJECTILE, false, false, false, 0.75),
		Skill.new("War Cry", 0.0, 3, Element.Type.FISICO, Kind.STATUS, false, true, false, 0.3),
		Skill.new("Armored Bulk", 0.0, 1, Element.Type.TERRA, Kind.STATUS, false, false, true, 0.0),
		Skill.new("Boulder Smash", 1.2, 2, Element.Type.FISICO, Kind.MELEE, false, false, false, 1.5),
		Skill.new("Rock Throw", 1.3, 2, Element.Type.TERRA, Kind.PROJECTILE, true, false, false, 1.0),
		Skill.new("Glare", 0.0, 1, Element.Type.TREVAS, Kind.STATUS, false, false, false, 0.5),
	]
	if DrainSpear != null:
		list.append(DrainSpear.make())
	list.append_array(fire_skills())
	list.append_array(library_skills())
	list.append_array(element_skills())
	list.append_array(smt_skills())
	return list
