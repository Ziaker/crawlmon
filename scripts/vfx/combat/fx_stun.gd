class_name FxStun
extends RefCounted
## D-979: what a STUN looks like on any character (any cause): a ring of yellow stars spinning above the head and a
## dizzy body that sways in a circle, sags at the knees and now and then almost falls. Only visual: it reads
## Combatant.stun_timer and never touches the combat. Sizes come from the real model (D-235).

const SWAY_DEG := 10.0  ## circular tilt, 8-12 degrees
const SWAY_HZ := 0.9
const SAG := 0.9  ## height scale while dizzy ("knees give in")
const NEAR_FALL_EVERY := 1.3  ## s
const NEAR_FALL_LEN := 0.3  ## s
const NEAR_FALL_DEG := 9.0  ## extra tilt at the dip
const STARS := 5
const STAR_SIZE := 0.65  ## m (D-980: a bit bigger so the far enemy's stars read)
const STAR_SIZES := [1.0, 0.7, 1.25, 0.85, 1.1]  ## D-980: each star its own size
const STAR_SPINS := [3.0, -5.0, 1.8, -2.6, 4.2]  ## D-980: rad/s, each star its own spin and direction
const STAR_SPIN := 2.2  ## turns per second
const STAR_COLOR := Color(1.0, 0.86, 0.15)
const BLEND_IN := 0.15  ## s to ease in and out (no pop)

var fx: BattleFx
var _state: Dictionary = {}  ## Combatant -> {t, k, base_scale, top, r, ring}
static var _star_mesh: ArrayMesh


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func update(delta: float) -> void:
	for c in fx._models:
		var m: Node3D = fx._models[c]
		if m == null or not is_instance_valid(m):
			continue
		var on: bool = (c as Combatant).is_stunned() and (c as Combatant).is_alive() and m.visible
		var st: Dictionary = _state.get(c, {})
		if on and st.is_empty():
			st = _begin(m)
			_spawn_text(m, float(st["top"]))  # D-980: "STUN!" falls on the head for 1.5 s
			st["base_scale"] = fx._base_scale.get(c, m.scale)  # the registered size, never a mid-tween squash
			_state[c] = st
		if st.is_empty():
			continue
		st["k"] = clampf(float(st["k"]) + (delta if on else -delta) / BLEND_IN, 0.0, 1.0)
		st["t"] = float(st["t"]) + delta
		var k: float = st["k"]
		if k <= 0.0 and not on:
			_end(m, st)
			_state.erase(c)
			continue
		_apply(m, st, k)


func _begin(m: Node3D) -> Dictionary:
	var top := 1.6
	var r := 0.5
	var inv := m.global_transform.affine_inverse()
	var first := true
	var box := AABB()
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or String(mi.name) in ["BurstRing", "ReadyRing"] or String(mi.name).begins_with("Stun"):
			continue
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if not first:
		top = box.end.y
		r = maxf(box.size.x, box.size.z) * 0.5
	var ring := Node3D.new()
	ring.name = "StunStars"
	ring.top_level = true
	m.add_child(ring)
	for i in STARS:
		var s := MeshInstance3D.new()
		s.name = "StunStar%d" % i
		s.mesh = _star()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# D-980: faced to the camera by code (a billboard material cannot spin each star on its own)
		mat.albedo_color = STAR_COLOR
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.material_override = mat
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(s)
	return {"t": 0.0, "k": 0.0, "base_scale": m.scale, "base_rx": m.rotation.x, "base_rz": m.rotation.z, "top": top, "r": r, "ring": ring}


func _apply(m: Node3D, st: Dictionary, k: float) -> void:
	var t: float = st["t"]
	var ph := t * TAU * SWAY_HZ
	var dip := 0.0
	var fk := fmod(t, NEAR_FALL_EVERY)
	if fk < NEAR_FALL_LEN:
		dip = sin(fk / NEAR_FALL_LEN * PI)
	var tilt := deg_to_rad(SWAY_DEG + NEAR_FALL_DEG * dip) * k
	m.rotation.x = float(st["base_rx"]) + sin(ph) * tilt
	m.rotation.z = float(st["base_rz"]) + cos(ph) * tilt
	var bs: Vector3 = st["base_scale"]
	var sag := lerpf(1.0, SAG - 0.05 * dip, k)
	m.scale = Vector3(bs.x * lerpf(1.0, 1.04, k), bs.y * sag, bs.z * lerpf(1.0, 1.04, k))
	var ring := st["ring"] as Node3D
	var head := m.global_position + Vector3.UP * (float(st["top"]) * m.scale.y + 0.2)
	var rr := clampf(float(st["r"]) * 0.9, 0.45, 0.9) * absf(m.scale.x)
	for i in ring.get_child_count():
		var s := ring.get_child(i) as MeshInstance3D
		var a := TAU * (float(i) / float(STARS) + t * STAR_SPIN * 0.25)
		s.global_position = head + Vector3(cos(a) * rr, sin(a * 2.0) * 0.05, sin(a) * rr)
		# D-980: each star has its own size and its own spin (speed and direction) around its centre.
		var own: float = STAR_SIZES[i % STAR_SIZES.size()]
		# Face the camera, then turn around the view axis by the star's own spin.
		var cb := _cam_basis()
		var sc := STAR_SIZE * own * (0.9 + 0.1 * sin(t * 9.0 + float(i))) * maxf(k, 0.001)
		s.global_transform = Transform3D((cb * Basis(Vector3.BACK, t * float(STAR_SPINS[i % STAR_SPINS.size()]))).scaled_local(Vector3.ONE * sc), s.global_position)
		(s.material_override as StandardMaterial3D).albedo_color = Color(STAR_COLOR, k)


func _end(m: Node3D, st: Dictionary) -> void:
	m.rotation.x = float(st["base_rx"])
	m.rotation.z = float(st["base_rz"])
	m.scale = st["base_scale"]
	var ring: Node = st["ring"]
	if is_instance_valid(ring):
		ring.queue_free()


func _cam_basis() -> Basis:
	if fx.cam != null and fx.cam.camera != null:
		return fx.cam.camera.global_transform.basis.orthonormalized()
	return Basis.IDENTITY


# --- D-980: animated "STUN!" text ("Pancada que racha") -------------------------------------
const TEXT_LEN := 1.5
const TEXT_COLOR := Color(1.0, 0.86, 0.15)  ## flat yellow, no outline
const TEXT_LETTER_H := 0.55  ## m, letter height
const TEXT_DROP := 2.2  ## m it falls from
const T_FALL := 0.18
const T_RING := 0.42  ## the bell-like shake after the bang ends here
const T_DROP_OUT := 1.1  ## the letters start to fall apart


func _spawn_text(m: Node3D, top: float) -> void:
	var root := Node3D.new()
	root.name = "StunText"
	root.top_level = true
	fx.add_child(root)
	var letters := "STUN!"
	for i in letters.length():
		var l := Label3D.new()
		l.text = letters[i]
		l.font = FanMenu.title_font()
		l.font_size = 128
		l.pixel_size = TEXT_LETTER_H / 128.0
		l.outline_size = 0  # flat, no border
		l.modulate = TEXT_COLOR
		l.shaded = false
		l.no_depth_test = true
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # faced to the camera by code (each letter tilts on its own)
		root.add_child(l)
	var tw := root.create_tween()
	tw.tween_method(func(tt: float) -> void: _text_frame(root, m, top, tt), 0.0, TEXT_LEN, TEXT_LEN)
	tw.tween_callback(root.queue_free)


func _text_frame(root: Node3D, m: Node3D, top: float, tt: float) -> void:
	if not is_instance_valid(m):
		return
	var cb := _cam_basis()
	var right := cb.x
	var head := m.global_position + Vector3.UP * (top * absf(m.scale.y) + 0.75)
	var n := root.get_child_count()
	var gap := TEXT_LETTER_H * 0.62
	# Whole-word motion: the drop, the squash at the bang and the bell-like ringing.
	var y_off := 0.0
	var sq := Vector2.ONE
	var ring := 0.0
	if tt < T_FALL:
		var f := tt / T_FALL
		y_off = TEXT_DROP * (1.0 - f * f)
		sq = Vector2(0.85, 1.25)
	elif tt < T_RING:
		var r := (tt - T_FALL) / (T_RING - T_FALL)
		var damp := 1.0 - r
		sq = Vector2(1.0 + 0.35 * damp * cos(r * 18.0), 1.0 - 0.4 * damp * cos(r * 18.0))
		ring = deg_to_rad(14.0) * damp * sin(r * 26.0)
	for i in n:
		var l := root.get_child(i) as Label3D
		var x := (float(i) - float(n - 1) * 0.5) * gap * sq.x
		var p := head + right * x + Vector3.UP * y_off
		var tilt := ring
		var a := 1.0
		if tt >= T_RING:
			# Dizzy letters: each one crooked and swaying on its own.
			var w := tt - T_RING
			tilt = deg_to_rad(12.0) * sin(w * 7.0 + float(i) * 1.7) + deg_to_rad(6.0) * (1.0 if i % 2 == 0 else -1.0)
			p += Vector3.UP * 0.05 * sin(w * 9.0 + float(i))
		if tt >= T_DROP_OUT:
			# They fall apart, each at its own speed.
			var d := tt - T_DROP_OUT
			var g := 9.0 + 5.0 * float((i * 7) % 5)
			p += Vector3.DOWN * 0.5 * g * d * d
			tilt += d * (3.0 if i % 2 == 0 else -4.0)
			a = 1.0 - clampf(d / (TEXT_LEN - T_DROP_OUT), 0.0, 1.0)
		l.global_transform = Transform3D((cb * Basis(Vector3.BACK, tilt)).scaled_local(Vector3(sq.x, sq.y, 1.0)), p)
		l.modulate = Color(TEXT_COLOR, a)


## A flat five-point star (unit size), drawn as a billboard.
static func _star() -> ArrayMesh:
	if _star_mesh != null:
		return _star_mesh
	var v := PackedVector3Array()
	var pts: Array[Vector3] = []
	for i in 10:
		var a := PI * 0.5 + float(i) * PI / 5.0
		var rad := 0.5 if i % 2 == 0 else 0.21
		pts.append(Vector3(cos(a) * rad, sin(a) * rad, 0.0))
	for i in 10:
		v.append(Vector3.ZERO)
		v.append(pts[i])
		v.append(pts[(i + 1) % 10])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	_star_mesh = ArrayMesh.new()
	_star_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _star_mesh
