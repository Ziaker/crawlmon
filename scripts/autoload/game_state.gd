extends Node
## Shared state between the 2D exploration and the 3D battle scenes.

const EXPLORATION := "res://scenes/exploration.tscn"
const BATTLE := "res://scenes/battle.tscn"

var player_pos := Vector2.INF  ## INF = use the map's spawn point.
var encounter_id := ""
var defeated: Array[String] = []


func start_battle(id: String, pos: Vector2) -> void:
	encounter_id = id
	player_pos = pos
	get_tree().change_scene_to_file.call_deferred(BATTLE)


func end_battle(player_won: bool) -> void:
	if player_won:
		defeated.append(encounter_id)
	encounter_id = ""
	get_tree().change_scene_to_file.call_deferred(EXPLORATION)
