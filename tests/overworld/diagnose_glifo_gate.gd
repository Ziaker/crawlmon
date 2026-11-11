extends SceneTree
## Prova visual: com inimigo perto a HUD aparece; longe, desaparece por completo.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/diagnose_glifo_gate.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://docs/referencias/ui/attack_hud_lab"

var _lab: Node3D
var _player: CharacterBody3D
var _enemy: Node3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(40)
	_player = _lab.get("player")
	_enemy = _lab.get("_enemy")
	var hud = _lab.get("_attack_hud")
	# Esconde só o HUD de debug; a camada da HUD de ataque fica.
	for child in _lab.get_children():
		if child is CanvasLayer and child != hud.get_parent():
			(child as CanvasLayer).visible = false
	_hide_world_labels()

	# Perto: a HUD tem de aparecer.
	_place(_enemy.global_position + Vector3(0.0, 0.0, 3.0))
	await _frames(20)
	print("NEAR target=%s state=%s visible=%s" % [
		str(hud.get("target_name")), str(hud.get("state")), str(hud.visible)])
	_save("glifo_gate_near.png")

	# Longe de todos: nada de Z fantasma.
	var far := Vector3(0.0, 0.0, 9.0)
	var second = _lab.get("_second_enemy")
	_place(far)
	await _frames(20)
	print("FAR dist_slime=%.2f dist_gible=%.2f" % [
		_player.global_position.distance_to(_enemy.global_position),
		_player.global_position.distance_to(second.global_position)])
	print("FAR target=%s state=%s visible=%s" % [
		str(hud.get("target_name")), str(hud.get("state")), str(hud.visible)])
	_save("glifo_gate_far.png")
	quit(0)


func _place(pos: Vector3) -> void:
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	var to_target := _enemy.global_position - pos
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	_lab.set("player_yaw", yaw)
	_lab.set("_cam_yaw", yaw)
	_player.rotation.y = yaw


func _hide_world_labels() -> void:
	for entry in _lab.get("_name_labels"):
		var plate := entry.get("node") as Node3D
		if plate != null:
			plate.visible = false
	for entry in _lab.get("_state_icons"):
		var icon := entry.get("sprite") as Node3D
		if icon != null:
			icon.visible = false


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var path := abs_dir.path_join(file_name)
	img.save_png(path)
	print("saved %s" % path)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
