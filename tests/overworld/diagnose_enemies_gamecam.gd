extends SceneTree
## Diagnóstico no overworld 3D com a câmera real do jogo (D-1125/D-1126).
## Coloca o jogador a 3 m de cada inimigo, deixa a câmera do lab seguir e
## captura a tela como o jogador vê (HUD incluso).
## Rodar SEM --headless:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/diagnose_enemies_gamecam.gd

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
	await _frames(40)
	_player = _lab.get("player")
	var first: Node3D = _lab.get("_enemy")
	var second: Node3D = _lab.get("_second_enemy")
	await _frame_from_game_cam("slime", first, "diag_gamecam_slime.png")
	await _frame_from_game_cam("gible", second, "diag_gamecam_gible.png")
	quit(0)


func _frame_from_game_cam(label: String, target: Node3D, file_name: String) -> void:
	if target == null:
		print("%s: NULL" % label)
		return
	_player.global_position = target.global_position + Vector3(0.0, 0.0, 3.0)
	_player.velocity = Vector3.ZERO
	var to_target := target.global_position - _player.global_position
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	_lab.set("player_yaw", yaw)
	_lab.set("_cam_yaw", yaw)
	_player.rotation.y = yaw
	await _frames(24)
	var cam: Camera3D = _lab.get("_camera")
	print("%s target=%s visible=%s in_tree=%s" % [
		label, target.global_position, target.visible, target.is_visible_in_tree()])
	if cam != null:
		print("  camera=%s current=%s player=%s dist_cam_enemy=%.2f" % [
			cam.global_position, cam.current, _player.global_position,
			cam.global_position.distance_to(target.global_position)])
	_save(file_name)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
