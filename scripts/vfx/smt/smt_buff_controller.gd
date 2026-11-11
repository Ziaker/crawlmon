extends Node3D
class_name SmtBuffController

enum MoveType { TARUKAJA, RAKUNDA, SUKUNDA }

const SmtStageVfxScript = preload("res://scripts/vfx/smt/smt_stage_vfx.gd")
const STAGE_SCENE: PackedScene = preload("res://scenes/vfx/smt/smt_stage_vfx.tscn")

var models: Dictionary = {}

func register_model(c: Object, model: Node3D) -> void:
	models[c] = model

func register_models(p_models: Dictionary) -> void:
	models = p_models

## Debug aid: a combatant that left the field (test spawns only).
func unregister_model(c: Object) -> void:
	models.erase(c)

func play_stage_move(move: int, target_node: Node3D, duration: float = 1.0) -> Node3D:
	if not is_instance_valid(target_node):
		return null
	var vfx: Node3D = STAGE_SCENE.instantiate()
	add_child(vfx)
	vfx.setup(move, target_node, duration)
	return vfx

func play_move_by_id(move_id: String, target_node: Node3D, duration: float = 1.0) -> bool:
	var mid := _normalize(move_id)
	match mid:
		"tarukaja":
			play_stage_move(MoveType.TARUKAJA, target_node, duration)
			return true
		"rakunda":
			play_stage_move(MoveType.RAKUNDA, target_node, duration)
			return true
		"sukunda":
			play_stage_move(MoveType.SUKUNDA, target_node, duration)
			return true
	return false

func on_hit_resolved(_attacker: Object, target: Object, _element: int, info: Dictionary) -> void:
	if info.get("capped", false):
		return  # Already at the limit: nothing changed, so nothing to show (D-167).
	var move_name: String = str(info.get("skill_name", ""))
	var mid := _normalize(move_name)
	if info.get("def_down_proc", false):
		mid = "rakunda"  # D-1005: Boulder Smash's DEF-1 shows the Rakunda visual on the impact
	if mid.is_empty():
		if info.get("buff") == "atk":
			mid = "tarukaja"
		elif info.get("debuff") == "def":
			mid = "rakunda"
		elif info.get("debuff") == "spd":
			mid = "sukunda"

	if mid in ["tarukaja", "rakunda", "sukunda"]:
		var node: Node3D = models.get(target, null)
		if node != null:
			play_move_by_id(mid, node, 1.0)

func _normalize(raw: String) -> String:
	var s := raw.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match s:
		"tarukaja": return "tarukaja"
		"rakunda": return "rakunda"
		"sukunda": return "sukunda"
	return s
