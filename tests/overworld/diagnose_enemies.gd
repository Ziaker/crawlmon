extends SceneTree
## Diagnóstico: os inimigos do lab 3D estão visíveis?
## Rodar SEM --headless (precisa renderizar):
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/diagnose_enemies.gd
## Gera docs/referencias/exploracao/3d/diag_enemies_player.png e _top.png.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT_DIR := "res://docs/referencias/exploracao/3d"

var _lab: Node3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	_lab = packed.instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(40)

	var player: Node3D = _lab.get("player")
	var enemy: Node3D = _lab.get("_enemy")
	var second: Node3D = _lab.get("_second_enemy")
	_print_body("player", player)
	_print_body("enemy", enemy)
	_print_body("second", second)
	var cam: Camera3D = _lab.get("_camera")
	if cam != null:
		print("camera current=%s cull_mask=0x%08X pos=%s" % [cam.current, cam.cull_mask, cam.global_position])
	print("hud_layers:")
	for child in _lab.get_children():
		if child is CanvasLayer:
			print("  CanvasLayer %s visible=%s" % [child.name, child.visible])

	_hide_hud()
	await _frames(3)

	# 1) Câmera de cima, lab inteiro.
	var top := Camera3D.new()
	top.fov = 55.0
	_lab.add_child(top)
	top.global_position = Vector3(7.5, 20.0, -5.0)
	top.look_at(Vector3(7.5, 0.0, -6.0), Vector3.UP)
	top.current = true
	await _frames(4)
	_save("diag_enemies_top.png")

	# 2) Câmera atrás do jogador, como no jogo.
	var pcam := Camera3D.new()
	pcam.fov = 60.0
	_lab.add_child(pcam)
	var yaw := float(_lab.get("player_yaw"))
	var back := Vector3(-sin(yaw), 0.0, -cos(yaw))
	pcam.global_position = player.global_position + back * 5.0 + Vector3(0.0, 2.2, 0.0)
	pcam.look_at(player.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	pcam.current = true
	await _frames(4)
	_save("diag_enemies_player.png")

	quit(0)


func _print_body(label: String, body: Node3D) -> void:
	if body == null:
		print("%s: NULL" % label)
		return
	print("%s: name=%s pos=%s visible=%s in_tree=%s scale=%s" % [
		label, body.name, body.global_position, body.visible,
		body.is_visible_in_tree(), body.scale])
	var meshes: Array[Node] = body.find_children("*", "MeshInstance3D", true, false)
	print("  meshes=%d" % meshes.size())
	for node in meshes:
		var mi := node as MeshInstance3D
		var aabb := AABB()
		if mi.mesh != null:
			aabb = mi.global_transform * mi.mesh.get_aabb()
		print("  - %s visible=%s in_tree=%s layers=0x%08X aabb_pos=%s aabb_size=%s mat=%s" % [
			mi.name, mi.visible, mi.is_visible_in_tree(), mi.layers,
			aabb.position, aabb.size, mi.material_override != null])


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
