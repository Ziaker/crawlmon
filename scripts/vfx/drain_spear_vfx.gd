class_name DrainSpearVfx
extends Node3D
## D-377: a Drain Spear no Motion Composer. Esta classe NÃO tem aparência: ela só recebe posições, eixos, relógios e a
## câmera, e repassa ao `MotionEffect`. Nada de personagem, time, lado ou coordenada fixa (D-235). O efeito em si vive
## em `MotionPresets.drain_spear_effect`; a malha/shaders vivem no Motion Composer.

var painter: MotionPainter
var effect: MotionEffect
var seed_value := 0
var steal_distance := 16.3
var crown := true  ## false in battle: the eight blue lights replace the crown/orbit (request)


func setup(cam: Camera3D, p_seed := 0) -> void:
	seed_value = p_seed
	painter = MotionPainter.new()
	painter.name = "MotionPainter"
	painter.cam_pos_fn = func() -> Vector3: return cam.global_position if cam != null and cam.is_inside_tree() else Vector3(0, 3, 8)
	painter.cam_basis_fn = func() -> Basis: return cam.global_transform.basis if cam != null and cam.is_inside_tree() else Basis.IDENTITY
	add_child(painter)
	rebuild(steal_distance)


func rebuild(p_steal_distance: float) -> void:
	steal_distance = maxf(p_steal_distance, 0.5)
	effect = MotionPresets.drain_spear_effect(seed_value, {"steal_distance": steal_distance, "crown": crown})


func begin(total_time: float) -> void:
	if painter == null:
		return
	painter.time = total_time
	painter.begin_frame()


func end() -> void:
	if painter != null:
		painter.end_frame()


func draw_phase(phase: String, t: float, origin: Vector3, dest: Vector3, head: Vector3, axis: Vector3,
		k: float, p := 0.0, landed := false, scale := 1.0) -> void:
	if effect == null or painter == null:
		return
	var geo := {
		"origin": origin,
		"dest": dest,
		"head": head,
		"axis": axis.normalized() if axis.length() > 0.001 else Vector3.UP,
		"k": clampf(k, 0.0, 1.0),
		"p": clampf(p, 0.0, 1.0),
		"scale": scale,
		"landed": landed,
	}
	effect.draw(painter, phase, t, geo)


func stats() -> Dictionary:
	return painter.stats() if painter != null else {}
