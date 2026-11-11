extends SceneTree
## Diagnóstico da câmera do overworld 3D perto de paredes e portas.
## Roda SEM --headless (precisa desenhar as capturas), com a janela fora da tela:
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --script res://tests/overworld/diagnose_camera_wall.gd
##
## Mede, por quadro: distância da câmera ao jogador, se o ponto da câmera
## cruzou o pivô (dot < -0.5 => mais de 60° à frente; o bug antigo dava ~-1),
## se a sonda está dentro de parede, o pitch do look e o deslocamento da câmera
## entre quadros. Salva capturas em docs/referencias/exploracao/3d/camera_fix_*.png.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT_DIR := "res://docs/referencias/exploracao/3d"
const WALL_MASK := 1
## -0.5 = câmera mais de 60° à frente da posição "atrás". Uma câmera lateral
## (~90°, dot 0) não é inversão de yaw; o bug antigo dava dot ~-1.
const FLIP_DOT := -0.5
const MAX_PITCH_DEG := 65.0

var _lab: Node3D
var _player: CharacterBody3D
var _camera: Camera3D
var _failures := 0
var _max_step := 0.0
var _max_step_label := ""
var _min_dist := 999.0
var _min_dist_label := ""
var _worst_pitch := 0.0
var _worst_pitch_label := ""
var _flip_frames := 0
var _wall_frames := 0
var _last_cam := Vector3.ZERO


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	_lab = packed.instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(40)
	_player = _lab.get("player")
	_camera = _lab.get("_camera")

	print("== camera wall diagnostic (solo) ==")
	await _static_case("solo_sul_parede", Vector3(-2.0, 0.0, -13.65), 0.0, 0.0, false, true)
	await _static_case("solo_sul_porta_centro", Vector3(0.0, 0.0, -13.65), 0.0, 0.0, false, true)
	await _static_case("solo_sul_porta_borda", Vector3(1.05, 0.0, -13.65), 0.0, 0.0, false, true)
	await _static_case("solo_sul_porta_borda2", Vector3(5.95, 0.0, -13.65), 0.0, 0.0, false, true)
	await _static_case("solo_interna_porta_borda", Vector3(7.90, 0.0, -5.20), 0.0, 0.0, false, true)
	await _static_case("solo_interna_porta_centro", Vector3(9.50, 0.0, -5.20), 0.0, 0.0, false, true)
	await _static_case("solo_sul_sala_baixa", Vector3(7.0, 0.0, -21.60), 0.0, 0.0, false, true)

	print("== camera wall diagnostic (party) ==")
	await _static_case("party_sul_parede", Vector3(-2.0, 0.0, -13.65), 0.0, 0.0, true, true)
	await _static_case("party_sul_porta_borda", Vector3(1.05, 0.0, -13.65), 0.0, 0.0, true, true)
	await _static_case("party_interna_porta_borda", Vector3(7.90, 0.0, -5.20), 0.0, 0.0, true, true)

	print("== sweep parede sul (solo) ==")
	await _sweep_x(-3.5, 3.5, 0.05, -13.65, false)
	await _sweep_x(3.5, -3.5, 0.05, -13.65, false)
	print("== sweep aproximando/afastando da parede sul (solo) ==")
	await _sweep_z(-9.0, -13.65, -2.0, false)
	await _sweep_z(-13.65, -9.0, -2.0, false)
	print("== sweep parede sul (party) ==")
	await _sweep_x(-3.5, 3.5, 0.05, -13.65, true)

	print("== sweep corredor aberto (sem parede) ==")
	await _sweep_open(0.0, -8.0, false)
	await _sweep_open(0.0, -8.0, true)

	print("== tecla 1 (party) ==")
	await _party_toggle_case()

	print("== diálogo ==")
	await _dialogue_case()

	print("CAMERA_DIAG max_step=%.3f (%s) min_dist=%.3f (%s) max_pitch=%.1f (%s) flips=%d wall_frames=%d" % [
		_max_step, _max_step_label, _min_dist, _min_dist_label,
		_worst_pitch, _worst_pitch_label, _flip_frames, _wall_frames])
	print("CAMERA_DIAG_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(0 if _failures == 0 else 1)


func _static_case(label: String, pos: Vector3, cam_yaw: float, player_yaw: float, party: bool, capture: bool) -> void:
	_set_party(party)
	_reset_camera_state()
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	_player.rotation.y = player_yaw
	_lab.set("player_yaw", player_yaw)
	_lab.set("_cam_yaw", cam_yaw)
	await _physics(4)
	await _frames(18)
	var m := _metrics()
	print("%s dist=%.2f pivot=%.2f dot=%.2f pitch=%.1f wall=%s hide=%s cam=%s" % [
		label, m["dist"], m["pivot_dist"], m["dot"], m["pitch_deg"], m["wall"], m["hide"], m["cam"]])
	if absf(m["pitch_deg"]) > _worst_pitch:
		_worst_pitch = absf(m["pitch_deg"])
		_worst_pitch_label = label
	_check(m["dot"] >= FLIP_DOT, "%s: câmera não cruzou o pivô" % label)
	_check(not m["wall"], "%s: câmera fora da parede" % label)
	_check(absf(m["pitch_deg"]) <= MAX_PITCH_DEG, "%s: look não quase vertical" % label)
	if capture:
		_save("camera_fix_%s.png" % label)


func _sweep_x(x0: float, x1: float, step: float, z: float, party: bool) -> void:
	_set_party(party)
	_reset_camera_state()
	_player.global_position = Vector3(x0, 0.0, z)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = 0.0
	_lab.set("player_yaw", 0.0)
	_lab.set("_cam_yaw", 0.0)
	await _physics(4)
	await _frames(20)
	var n := int(absf(x1 - x0) / step) + 1
	var dir := signf(x1 - x0)
	var label := "sweep_x_party" if party else "sweep_x_solo"
	var max_step := 0.0
	var max_out_step := 0.0
	var max_in_step := 0.0
	var min_dist := 999.0
	var max_pitch := 0.0
	var flips := 0
	var walls := 0
	var prev_pivot_dist := float(_metrics()["pivot_dist"])
	for i in n:
		_player.global_position.x = x0 + dir * step * float(i)
		_last_cam = _camera.global_position
		await physics_frame
		var m := _metrics()
		var step_moved := _last_cam.distance_to(m["cam"])
		max_step = maxf(max_step, step_moved)
		var outward: bool = float(m["pivot_dist"]) >= prev_pivot_dist
		if outward:
			max_out_step = maxf(max_out_step, step_moved)
		else:
			max_in_step = maxf(max_in_step, step_moved)
		prev_pivot_dist = float(m["pivot_dist"])
		min_dist = minf(min_dist, float(m["pivot_dist"]))
		max_pitch = maxf(max_pitch, absf(m["pitch_deg"]))
		if step_moved > 0.8:
			print("  step=%.2f i=%d x=%.2f dist=%.2f out=%s dot=%.2f side=%.1f cam=%s prev=%s" % [
				step_moved, i, _player.global_position.x, m["dist"],
				str(outward), m["dot"],
				rad_to_deg(float(_lab.get("_cam_side_angle"))), m["cam"], _last_cam])
		if m["dot"] < FLIP_DOT:
			flips += 1
		if m["wall"]:
			walls += 1
	print("%s max_step=%.3f out=%.3f in=%.3f min_dist=%.3f max_pitch=%.1f flips=%d walls=%d" % [
		label, max_step, max_out_step, max_in_step, min_dist, max_pitch, flips, walls])
	_record_global(label, max_step, min_dist, max_pitch, flips, walls)
	_check(max_out_step < 0.5, "%s: saída sem teleporte" % label)
	_check(max_in_step < 1.2, "%s: entrada sem teleporte grande" % label)
	_check(min_dist >= 0.85, "%s: distância mínima perto de 1 m" % label)
	_check(max_pitch <= MAX_PITCH_DEG, "%s: look não quase vertical" % label)
	_check(flips == 0, "%s: sem inversão de yaw" % label)
	_check(walls == 0, "%s: câmera nunca dentro de parede" % label)


func _sweep_z(z0: float, z1: float, x: float, party: bool) -> void:
	_set_party(party)
	_reset_camera_state()
	_player.global_position = Vector3(x, 0.0, z0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = 0.0
	_lab.set("player_yaw", 0.0)
	_lab.set("_cam_yaw", 0.0)
	await _physics(4)
	await _frames(20)
	var n := int(absf(z1 - z0) / 0.05) + 1
	var dir := signf(z1 - z0)
	var label := "sweep_z_%s_%s" % ["party" if party else "solo", "ida" if z1 < z0 else "volta"]
	var max_step := 0.0
	var max_out_step := 0.0
	var max_in_step := 0.0
	var min_dist := 999.0
	var max_pitch := 0.0
	var flips := 0
	var walls := 0
	var prev_pivot_dist := float(_metrics()["pivot_dist"])
	for i in n:
		_player.global_position.z = z0 + dir * 0.05 * float(i)
		_last_cam = _camera.global_position
		await physics_frame
		var m := _metrics()
		var step_moved := _last_cam.distance_to(m["cam"])
		max_step = maxf(max_step, step_moved)
		var outward: bool = float(m["pivot_dist"]) >= prev_pivot_dist
		if outward:
			max_out_step = maxf(max_out_step, step_moved)
		else:
			max_in_step = maxf(max_in_step, step_moved)
		prev_pivot_dist = float(m["pivot_dist"])
		min_dist = minf(min_dist, float(m["pivot_dist"]))
		max_pitch = maxf(max_pitch, absf(m["pitch_deg"]))
		if m["dot"] < FLIP_DOT:
			flips += 1
		if m["wall"]:
			walls += 1
	print("%s max_step=%.3f out=%.3f in=%.3f min_dist=%.3f max_pitch=%.1f flips=%d walls=%d" % [
		label, max_step, max_out_step, max_in_step, min_dist, max_pitch, flips, walls])
	_record_global(label, max_step, min_dist, max_pitch, flips, walls)
	_check(max_out_step < 0.5, "%s: saída sem teleporte" % label)
	_check(max_in_step < 1.2, "%s: entrada sem teleporte grande" % label)
	_check(min_dist >= 0.85, "%s: distância mínima perto de 1 m" % label)
	_check(max_pitch <= MAX_PITCH_DEG, "%s: look não quase vertical" % label)
	_check(flips == 0, "%s: sem inversão de yaw" % label)
	_check(walls == 0, "%s: câmera nunca dentro de parede" % label)


func _sweep_open(z0: float, z1: float, party: bool) -> void:
	_set_party(party)
	_reset_camera_state()
	_player.global_position = Vector3(0.0, 0.0, z0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = PI
	_lab.set("player_yaw", PI)
	_lab.set("_cam_yaw", PI)
	await _physics(4)
	await _frames(20)
	var n := int(absf(z1 - z0) / 0.08) + 1
	var dir := signf(z1 - z0)
	var label := "open_%s" % ("party" if party else "solo")
	var min_dist := 999.0
	var max_dist := 0.0
	var max_step := 0.0
	var max_pitch := 0.0
	var flips := 0
	var walls := 0
	for i in n:
		_player.global_position.z = z0 + dir * 0.08 * float(i)
		_last_cam = _camera.global_position
		await physics_frame
		var m := _metrics()
		var step_moved := _last_cam.distance_to(m["cam"])
		max_step = maxf(max_step, step_moved)
		min_dist = minf(min_dist, float(m["pivot_dist"]))
		max_dist = maxf(max_dist, float(m["pivot_dist"]))
		max_pitch = maxf(max_pitch, absf(m["pitch_deg"]))
		if m["dot"] < FLIP_DOT:
			flips += 1
		if m["wall"]:
			walls += 1
	print("%s max_step=%.3f dist=[%.2f..%.2f] max_pitch=%.1f flips=%d walls=%d" % [
		label, max_step, min_dist, max_dist, max_pitch, flips, walls])
	_record_global(label, max_step, min_dist, max_pitch, flips, walls)
	_check(flips == 0, "%s: sem inversão de yaw" % label)
	_check(walls == 0, "%s: câmera nunca dentro de parede" % label)
	_check(max_step < 0.25, "%s: sem tranco no movimento normal" % label)
	if party:
		_check(min_dist > 5.8 and max_dist < 6.6, "%s: distância party preservada" % label)
	else:
		_check(min_dist > 3.1 and max_dist < 3.7, "%s: distância solo preservada" % label)


func _party_toggle_case() -> void:
	_set_party(false)
	_reset_camera_state()
	_player.global_position = Vector3(0.0, 0.0, -2.0)
	_player.velocity = Vector3.ZERO
	_lab.set("player_yaw", PI)
	_lab.set("_cam_yaw", PI)
	await _physics(4)
	await _frames(20)
	var ev := InputEventKey.new()
	ev.keycode = KEY_1
	ev.pressed = true
	_lab.call("_unhandled_input", ev)
	await _frames(40)
	var on: bool = _lab.get("_party_visible")
	var on_metrics := _metrics()
	var followers_visible := true
	for f in _lab.get("_followers"):
		if not (f["node"] as Node3D).visible:
			followers_visible = false
	print("party_on=%s followers=%s dist=%.2f" % [on, followers_visible, on_metrics["pivot_dist"]])
	_check(on and followers_visible, "tecla 1 liga a party e mostra os aliados")
	_check(float(on_metrics["pivot_dist"]) > 5.8, "tecla 1 mantém a distância party")
	_lab.call("_unhandled_input", ev)
	await _frames(40)
	var off: bool = _lab.get("_party_visible")
	var off_metrics := _metrics()
	print("party_off=%s dist=%.2f" % [off, off_metrics["pivot_dist"]])
	_check(not off, "tecla 1 desliga a party")
	_check(float(off_metrics["pivot_dist"]) < 3.7, "tecla 1 volta à distância solo")


func _dialogue_case() -> void:
	_set_party(false)
	_reset_camera_state()
	var npcs: Array = _lab.get("_npcs")
	if npcs.is_empty():
		print("dialogo: sem NPC")
		return
	var npc := npcs[0]["node"] as Node3D
	_player.global_position = npc.global_position + Vector3(0.0, 0.0, 1.5)
	_player.velocity = Vector3.ZERO
	_lab.set("player_yaw", PI)
	_lab.set("_cam_yaw", 0.0)
	await _physics(4)
	await _frames(20)
	_lab.call("set_dialogue_focus", npc)
	await _frames(40)
	var m := _metrics()
	print("dialogo_open fov=%.1f dist=%.2f pitch=%.1f wall=%s" % [
		_camera.fov, m["dist"], m["pitch_deg"], m["wall"]])
	_check(absf(_camera.fov - 45.0) < 1.0, "diálogo: FOV vai a 45")
	_check(m["dist"] > 2.0, "diálogo: câmera não fica dentro do jogador")
	_save("camera_fix_dialogo.png")
	_lab.call("clear_dialogue_focus")
	await _frames(40)
	print("dialogo_close fov=%.1f dist=%.2f" % [_camera.fov, _metrics()["dist"]])
	_check(absf(_camera.fov - 55.0) < 1.0, "diálogo: FOV volta a 55")


func _metrics() -> Dictionary:
	var pivot: Vector3 = _lab.get("_cam_pivot")
	var cam_yaw: float = _lab.get("_cam_yaw")
	var back := -Vector3(sin(cam_yaw), 0.0, cos(cam_yaw))
	var offset := _camera.global_position - pivot
	var look := -_camera.global_transform.basis.z
	var pitch := rad_to_deg(asin(clampf(look.y, -1.0, 1.0)))
	var player_center := _player.global_position + Vector3(0.0, 0.8, 0.0)
	var dist := _camera.global_position.distance_to(player_center)
	var wall := _probe_blocked(_camera.global_position)
	var hidden := true
	for node in _player.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).visible:
			hidden = false
			break
	return {
		"cam": _camera.global_position,
		"dist": dist,
		"pivot_dist": _camera.global_position.distance_to(pivot),
		"dot": offset.dot(back),
		"pitch_deg": pitch,
		"wall": wall,
		"hide": hidden,
	}


func _probe_blocked(point: Vector3) -> bool:
	var probe := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.17
	probe.shape = shape
	probe.collision_mask = WALL_MASK
	probe.collide_with_bodies = true
	probe.collide_with_areas = false
	probe.transform = Transform3D(Basis(), point)
	return not _lab.get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty()


func _record_global(label: String, max_step: float, min_dist: float, max_pitch: float, flips: int, walls: int) -> void:
	_flip_frames += flips
	_wall_frames += walls
	if max_step > _max_step:
		_max_step = max_step
		_max_step_label = label
	if min_dist < _min_dist:
		_min_dist = min_dist
		_min_dist_label = label
	if max_pitch > _worst_pitch:
		_worst_pitch = max_pitch
		_worst_pitch_label = label


func _set_party(enabled: bool) -> void:
	_lab.set("_party_visible", enabled)
	_lab.set("_cam_pitch", 22.0 if enabled else 8.0)
	for f in _lab.get("_followers"):
		(f["node"] as Node3D).visible = enabled


func _reset_camera_state() -> void:
	_lab.set("_cam_smooth_ready", false)
	_lab.set("_cam_hold_left", 0.0)
	_lab.set("_cam_held_dist", 0.0)
	_lab.set("_cam_side_angle", 0.0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		print("FAIL: %s" % message)
	else:
		print("OK: %s" % message)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _physics(count: int) -> void:
	for i in count:
		await physics_frame
