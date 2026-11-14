class_name MoveBehaviorRegistry
extends RefCounted
## Mapa `move_id` -> regra própria (D-1079, Etapa 2). Moves sem entrada usam a
## base (hit/interrupção padrão); o catálogo continua sendo a fonte dos dados.

const MoveBehaviorsScript = preload("res://scripts/combat/moves/move_behaviors.gd")

const BEHAVIORS := {
	&"drain_spear": MoveBehaviorsScript.DrainSpear,
	&"tidal_surge": MoveBehaviorsScript.TidalSurge,
	&"tiro_areia": MoveBehaviorsScript.SandAttack,
	&"sand_attack": MoveBehaviorsScript.SandAttack,
	&"golpe_carate": MoveBehaviorsScript.KarateChop,
	&"karate_chop": MoveBehaviorsScript.KarateChop,
	&"mordida": MoveBehaviorsScript.Bite,
	&"bite": MoveBehaviorsScript.Bite,
	&"boulder_smash": MoveBehaviorsScript.BoulderSmash,
	&"electric_beam": MoveBehaviorsScript.ElectricBeam,
	&"fire_bullet": MoveBehaviorsScript.FireBullet,
	&"tarukaja": MoveBehaviorsScript.Tarukaja,
	&"rakunda": MoveBehaviorsScript.Rakunda,
	&"sukunda": MoveBehaviorsScript.Sukunda,
	&"sukukaja": MoveBehaviorsScript.Sukukaja,
	&"armored_bulk": MoveBehaviorsScript.ArmoredBulk,
	&"war_cry": MoveBehaviorsScript.WarCry,
	&"provocacao": MoveBehaviorsScript.Taunt,
	&"taunt": MoveBehaviorsScript.Taunt,
}

static var _cache: Dictionary = {}


static func get_behavior(move_id: StringName) -> MoveBehavior:
	var key := StringName(move_id)
	if _cache.has(key):
		return _cache[key]
	var move := MoveCatalog.get_move(key)
	var behavior: MoveBehavior = null
	# D-1079: a Move package may point to its own behavior script. No current
	# .tres uses it, so the explicit map below remains the compatibility path.
	if move != null and move.behavior_script != null:
		var custom: Variant = move.behavior_script.new()
		if custom is MoveBehavior:
			behavior = custom as MoveBehavior
	if behavior == null:
		var behavior_class: Variant = BEHAVIORS.get(key, null)
		behavior = MoveBehavior.new()
		if behavior_class != null:
			behavior = behavior_class.new() as MoveBehavior
	if move != null or behavior.data == null:
		behavior.setup(move)  # re-setup if the catalog loaded after the first call
	_cache[key] = behavior
	return behavior


static func for_skill(skill: Skill) -> MoveBehavior:
	if skill == null:
		return get_behavior(&"")
	if skill.data != null and not skill.data.id.is_empty():
		return get_behavior(skill.data.id)
	return get_behavior(StringName(BattleSpace.move_id(skill.display_name)))
