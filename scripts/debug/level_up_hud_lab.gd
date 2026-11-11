class_name LevelUpHUDLab
extends Control

## Standalone debug bench to verify LevelUpHUD visual and behavioral parity.

const LevelUpHUD = preload("res://scripts/ui/level_up_hud.gd")

@onready var hud: LevelUpHUD = $LevelUpHUD
@onready var replay_btn: Button = $DebugControls/ReplayBtn
@onready var milestone_btn: Button = $DebugControls/MilestoneBtn

var _is_milestone: bool = false
var _abra: Combatant
var _pancham: Combatant


func _ready() -> void:
	replay_btn.pressed.connect(_on_replay_pressed)
	milestone_btn.pressed.connect(_on_milestone_pressed)

	_setup_mock_party()


func _setup_mock_party() -> void:
	# 1. Abra (Leader)
	_abra = Combatant.new("Abra", 34, 4, 0.65, true)
	_abra.species_id = "abra"
	_abra.level = 2
	_abra.max_hp = 34
	_abra.hp = 34
	_abra.max_mp = 22
	_abra.mp = 22
	_abra.distributable_points = 3 if _is_milestone else 1
	_abra.innate_stats = {"STR": 1, "MAG": 8, "VIT": 2, "WIS": 5, "AGI": 4, "LUK": 2}
	_abra.progression_points = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	_abra.nature_id = "modest"
	_abra.sync_effective_stats()

	var tackle = Skill.new("Tackle", 20.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.4)
	tackle.mp_cost = 0
	var confusion = Skill.new("Confusion", 25.0, 2, Element.Type.PSIQUICO, Skill.Kind.CAST, false, false, false, 1.6)
	confusion.mp_cost = 3
	var psybeam = Skill.new("Psybeam", 40.0, 3, Element.Type.PSIQUICO, Skill.Kind.CAST, false, false, false, 2.1)
	psybeam.mp_cost = 5
	var shock_wave = Skill.new("Shock Wave", 30.0, 2, Element.Type.RAIO, Skill.Kind.CAST, false, false, false, 1.2)
	shock_wave.mp_cost = 4

	_abra.skills.assign([tackle, confusion, psybeam, shock_wave])

	# 2. Pancham (Ally)
	_pancham = Combatant.new("Pancham", 42, 7, 0.50, true)
	_pancham.species_id = "pancham"
	_pancham.level = 2
	_pancham.max_hp = 42
	_pancham.hp = 42
	_pancham.max_mp = 15
	_pancham.mp = 15
	_pancham.distributable_points = 0
	_pancham.innate_stats = {"STR": 6, "MAG": 1, "VIT": 5, "WIS": 2, "AGI": 3, "LUK": 2}
	_pancham.progression_points = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	_pancham.nature_id = "adamant"
	_pancham.sync_effective_stats()

	var karate_chop = Skill.new("Karate Chop", 25.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.3)
	karate_chop.mp_cost = 0
	var dark_fling = Skill.new("Dark Fling", 32.0, 2, Element.Type.TREVAS, Skill.Kind.PROJECTILE, false, false, false, 1.5)
	dark_fling.mp_cost = 3
	var guard = Skill.new("Guard", 0.0, 1, Element.Type.FISICO, Skill.Kind.STATUS, false, false, false, 0.8)
	guard.mp_cost = 0
	var taunt = Skill.new("Taunt", 0.0, 1, Element.Type.FISICO, Skill.Kind.STATUS, false, false, false, 0.8)
	taunt.mp_cost = 2

	_pancham.skills.assign([karate_chop, dark_fling, guard, taunt])

	var summaries: Array[Dictionary] = [
		{
			"combatant": _abra,
			"is_alive": true,
			"old_level": 1,
			"new_level": 2,
			"levels_gained": 1,
			"points_gained": 3 if _is_milestone else 1,
			"old_xp": 75,
			"current_xp": 140,
			"xp_required": 140,
		},
		{
			"combatant": _pancham,
			"is_alive": true,
			"old_level": 1,
			"new_level": 2,
			"levels_gained": 1,
			"points_gained": 0,
			"old_xp": 80,
			"current_xp": 140,
			"xp_required": 140,
		}
	]

	hud.open(summaries, 65)


func _on_replay_pressed() -> void:
	_setup_mock_party()


func _on_milestone_pressed() -> void:
	_is_milestone = not _is_milestone
	milestone_btn.text = "MILESTONE MODE: %s (D-394)" % ("ON (3 PTS)" if _is_milestone else "OFF (1 PT)")
	_setup_mock_party()
