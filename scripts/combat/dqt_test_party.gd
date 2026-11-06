class_name DqtTestParty
extends RefCounted
## Temporary crossover roster: one Slime, one spear Orc and one Cyclops.
## They are built only for the `--dqt` / `--dqt-mirror` battle tests and never
## replace GameState.party, so exploration keeps its Pokemon sprites.

static var enabled := false

static func build(is_player := true, inventory := {}) -> Array[Combatant]:
	var slime := Combatant.new("Slime", 34, 9, 0.55, is_player)
	slime.species_id = "dqt_slime"
	slime.weaknesses.assign([Element.Type.FOGO])
	slime.skills.assign([
		Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5),
		Skill.new("Bubble Shot", 1.3, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE, false, false, false, 1.0),
		Skill.new("Heal", 0.0, 2, Element.Type.LUZ, Skill.Kind.STATUS, false, true, true, 0.5),
	])
	if is_player:
		slime.inventory = inventory

	var orc := Combatant.new("Orc", 52, 13, 0.45, is_player)
	orc.species_id = "dqt_orc"
	orc.travel_extra = 0.45  # D-341 PROVISIONAL: a bit slow (low AGI, to come)
	orc.weaknesses.assign([Element.Type.RAIO])
	orc.skills.assign([
		Skill.new("Spear Thrust", 1.3, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.2),
		Skill.new("Javelin Throw", 1.2, 2, Element.Type.FISICO, Skill.Kind.PROJECTILE, false, false, false, 1.0),
		Skill.new("War Cry", 0.0, 1, Element.Type.FISICO, Skill.Kind.STATUS, false, false, false, 0.5),
	])

	var cyclops := Combatant.new("Cyclops", 64, 16, 0.35, is_player)
	cyclops.species_id = "dqt_cyclops"
	cyclops.travel_extra = 0.8  # D-341 PROVISIONAL: slow (low AGI, to come)
	cyclops.weaknesses.assign([Element.Type.PSIQUICO])
	cyclops.skills.assign([
		Skill.new("Boulder Smash", 1.5, 2, Element.Type.TERRA, Skill.Kind.MELEE, false, false, false, 1.5),
		Skill.new("Rock Throw", 1.3, 2, Element.Type.TERRA, Skill.Kind.PROJECTILE, true, false, false, 1.0),
		Skill.new("Glare", 0.0, 1, Element.Type.TREVAS, Skill.Kind.STATUS, false, false, false, 0.5),
	])

	var out: Array[Combatant] = [slime, orc, cyclops]
	return out
