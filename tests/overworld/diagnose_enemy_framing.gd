extends SceneTree
## Enquadramento de diagnóstico: jogador + cada inimigo, câmera de lado.
## Rodar SEM --headless:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/diagnose_enemy_framing.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT_DIR := "res://docs/referencias/exploracao/3d"

var _lab: Node3D
var _player: CharacterBody3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	_lab = packed.instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(30)
	_player = _lab.get("player")
	_hide_hud()

	var first: Node3D = _lab.get("_enemy")
	var second: Node3D = _lab.get("_second_enemy")
	await _frame_side("slime", first, "diag_enemy_slime_side.png")
	await _frame_side("gible", second, "diag_enemy_gible_side.png")
	quit(0)


func _frame_side(label: String, target: Node3D, file_name: String) -> void:
	if target == null:
		print("%s: NULL" % label)
		return
	_player.global_position = target.global_position + Vector3(0.0, 0.0, 3.0)
	_player.velocity = Vector3.ZERO
	var to_target := target.global_position - _player.global_position
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	_lab.set("player_yaw", yaw)
	_player.rotation.y = yaw
	var cam := Camera3D.new()
	cam.fov = 55.0
	_lab.add_child(cam)
	var mid := (_player.global_position + target.global_position) * 0.5
	var flat := to_target.normalized()
	var side := Vector3(-flat.z, 0.0, flat.x)
	cam.global_position = mid + side * 5.5 + Vector3(0.0, 2.4, 0.0)
	cam.look_at(mid + Vector3(0.0, 0.8, 0.0), Vector3.UP)
	cam.current = true
	await _frames(5)
	_print_target(label, target)
	_save(file_name)
	cam.queue_free()


func _print_target(label: String, target: Node3D) -> void:
	print("%s: pos=%s visible=%s in_tree=%s" % [
		label, target.global_position, target.visible, target.is_visible_in_tree()])
	for node in target.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var aabb := AABB()
		if mi.mesh != null:
			aabb = mi.global_transform * mi.mesh.get_aabb()
		print("  mesh %s visible=%s in_tree=%s layers=0x%08X aabb=%s size=%s" % [
			mi.name, mi.visible, mi.is_visible_in_tree(), mi.layers, aabb.position, aabb.size])


func _hide_hud() -> void:
	for child in _lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
