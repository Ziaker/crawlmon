class_name SwingTrail
extends Node3D
## D-990: the melee trail of the Swing / Hit-windup (the blow coming down to the contact). It replaces the flat arc
## that was spawned at a fixed point 1 m above the floor. It follows the real hand/weapon of the model in 3D: a ribbon
## swept between the forearm and just past the hand, so its angle and orientation are the limb's own.
## Never by character (D-235): it watches every hand/weapon-like bone (generic name parts) and draws the one that
## comes closest to the target during the swing; a model with none of them (e.g. a slime) checks every bone the same way.
## Only visual: it never touches the combat (D-019).

const LIFE := 0.65  ## D-993: the whole arc, from behind the back to the contact ## s: lives through the last part of the swing and fades just after the contact
const KEEP := 0.65  ## D-992: the whole swing stays drawn (a complete arc), then it fades
const EXTEND := 0.35  ## m past the hand (the "blade" edge)
const INNER := 0.45  ## 0..1 from the forearm toward the hand: the inner edge of the ribbon
const COL_EDGE := Color(1.0, 0.98, 0.9)
const COL_INNER := Color(1.0, 0.85, 0.55)
const HAND_PARTS := ["hand", "weapon", "_te_", "hte", "wrist"]

var _skel: Skeleton3D
var _cands: Array = []  ## bone indices watched
var _hist: Dictionary = {}  ## bone -> Array of [t, tip, base]
var _travel: Dictionary = {}  ## bone -> metres travelled
var _t := 0.0
var _locked := -1  ## D-995
var _style := ""  ## D-1010: "" automatic, "arc" the authored arc
const HAND_FROM := 0.2  ## D-1001: hand mode starts 0.3 s before the contact, as approved (spawn is 0.5 s before)
const HAND_KEEP := 0.16  ## D-1001: the approved trail length
var _arc_mode := -1  ## D-1000: -1 undecided, 0 follow the hand, 1 authored arc (the hand barely travels)
static var DEBUG_FULL := OS.get_cmdline_user_args().has("--swing-full")
var _arc_side := 1.0  ## D-1001: +1/-1, the side where the striking hand is
const ARC_LOCAL_MOVE := 0.8  ## D-1009: m in the model's frame; measured Pancham 0.38-0.60 (arc), Abra 1.00 (hand)
const ARC_TILT_DEG := 20.0  ## D-1009: the arc leans 20 degrees to the screen-left (creator)
const ARC_DECIDE_T := 0.2  ## s: by now a real swing has moved the hand a lot
const ARC_REACH := 0.5  ## s: the arc reaches the contact this long after spawning (spawned 0.5 s before it)
var _model: Node3D
var _speed_mode := false
var _weapon: Dictionary = {}  ## D-991: {mesh, bone, bind, center, axis, half}
var _wpn_hist: Array = []  ## [t, a, b] weapon ends
var _body_hist: Array = []  ## [t, centre] of the body (speed-lines mode)
var _bh := -1.0
const LINES := 7
var _target := Vector3.ZERO  ## the blow's target: the drawn limb is the one that gets closest to it
var _closest: Dictionary = {}  ## bone -> smallest distance to the target so far
var _mi: MeshInstance3D
static var _mat: StandardMaterial3D


## D-1010: each character keeps ITS OWN trail style (the creator approves them one by one; changing one must not move
## another). Characters not listed use the automatic style (hand, weapon or speed lines). Keys: species ids.
const STYLE_BY_SPECIES := {
	"pancham": "arc",  # D-1009: open arc over the head, tilted 20 degrees
}


static func spawn(parent: Node, model: Node3D, target_pos: Vector3, species := "") -> SwingTrail:
	if model == null or not is_instance_valid(model):
		return null
	var found := model.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return null
	var s := SwingTrail.new()
	s._target = target_pos
	s._style = String(STYLE_BY_SPECIES.get(species.to_lower(), ""))
	s._skel = found[0] as Skeleton3D
	for i in s._skel.get_bone_count():
		var n := s._skel.get_bone_name(i).to_lower()
		for part in HAND_PARTS:
			if part in n:
				s._cands.append(i)
				break
	# D-990: no hand/weapon (it hits with the body, e.g. a slime): speed lines behind the body on the blow's axis.
	s._model = model
	s._weapon = weapon_of(model)  # D-991: a held weapon mesh: the trail spans the weapon itself
	s._speed_mode = s._cands.is_empty() and s._weapon.is_empty()
	s.name = "SwingTrail"
	s.top_level = true
	parent.add_child(s)
	return s


func _ready() -> void:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.vertex_color_use_as_albedo = true
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.no_depth_test = true  # D-994: the arc reads over the body (a hand swung behind the back was hidden by it)
	_mi = MeshInstance3D.new()
	_mi.mesh = ImmediateMesh.new()
	_mi.material_override = _mat
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	global_transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	_t += delta
	if _t > LIFE + KEEP or _skel == null or not is_instance_valid(_skel):
		queue_free()
		return
	if _speed_mode:
		if _t <= LIFE and is_instance_valid(_model):
			_body_hist.append([_t, _model.global_position + Vector3.UP * _body_h() * 0.5])
		_draw_lines()
		return
	if not _weapon.is_empty() and bool(_weapon.get("thin", false)):
		_draw_tip()  # D-992: a long thin weapon (spear) gets no trail, only a glowing tip
		return
	if not _weapon.is_empty():
		if _t <= LIFE:
			var seg := weapon_segment(_weapon)
			if not seg.is_empty():
				_wpn_hist.append([_t, seg[0], seg[1]])
		_draw_weapon()
		return
	if _t <= LIFE:
		for b in _cands:
			var tip := _skel.global_transform * _skel.get_bone_global_pose(b).origin
			var par := _skel.get_bone_parent(b)
			var base := _skel.global_transform * _skel.get_bone_global_pose(par).origin if par >= 0 else tip
			var h: Array = _hist.get(b, [])
			if not h.is_empty():
				_travel[b] = float(_travel.get(b, 0.0)) + (tip - (h[h.size() - 1][1] as Vector3)).length()
			h.append([_t, tip, base, _model.global_transform.affine_inverse() * tip if is_instance_valid(_model) else tip])
			_closest[b] = minf(float(_closest.get(b, 1e9)), tip.distance_to(_target))
			_hist[b] = h
	if _arc_mode < 0:
		_arc_mode = 1 if _style == "arc" else 0  # D-1010: per character, never guessed
	if false:
		var moved := 0.0
		for b in _hist:
			var h: Array = _hist[b]
			if h.size() > 1:
				for smp in h:
					# D-1009: relative to the body (the body itself now advances during the blow, D-999)
					# D-1009: in the model's own frame (unaffected by its run, jump, turn or scale)
					moved = maxf(moved, (smp[3] as Vector3).distance_to(h[0][3] as Vector3))
		_arc_mode = 1 if moved < ARC_LOCAL_MOVE else 0
		if _arc_mode == 1 and is_instance_valid(_model):
			# The side of the hand that comes closest to the target (the striking one).
			var best_b := -1
			var best_c := 1e9
			for b in _closest:
				if float(_closest[b]) < best_c:
					best_c = float(_closest[b])
					best_b = b
			if best_b >= 0:
				var hc: Vector3 = _hist[best_b][0][1]
				var to2 := Vector3(_target.x - _model.global_position.x, 0.0, _target.z - _model.global_position.z).normalized()
				var sd := Vector3.UP.cross(to2)
				_arc_side = -1.0 if (hc - _model.global_position).dot(sd) >= 0.0 else 1.0  # D-1002: measured on the wrong side; flipped
	if _arc_mode == 1:
		_draw_arc()
		return
	_draw()


func _draw() -> void:
	var im := _mi.mesh as ImmediateMesh
	im.clear_surfaces()
	# The striking limb: among bones that really moved, the one that came closest to the target.
	# D-995: once chosen, the limb is LOCKED (switching hands frame to frame made the trail blink on and off).
	var best := _locked
	if best < 0:
		var best_d := 1e9
		for b in _travel:
			if float(_travel[b]) > 0.05 and float(_closest.get(b, 1e9)) < best_d:
				best_d = float(_closest[b])
				best = b
		pass  # D-1011: no lock for the hand style (the approved Abra picks the closest limb every frame); D-995's lock
		# was for the Pancham blink, which now uses its own arc (D-1010)
	if best < 0:
		return
	var pts: Array = []
	for s in _hist[best]:
		# D-1001: the approved window: samples from HAND_FROM on, the last HAND_KEEP seconds only.
		if float(s[0]) >= HAND_FROM and _t - float(s[0]) <= HAND_KEEP:
			pts.append(s)
	if pts.size() < 2:
		return
	var fade := 1.0 - clampf((_t - LIFE) / HAND_KEEP, 0.0, 1.0)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var a0 := _edges(pts[i])
		var a1 := _edges(pts[i + 1])
		var k0 := float(i) / float(pts.size() - 1)
		var k1 := float(i + 1) / float(pts.size() - 1)
		var c_out0 := Color(COL_EDGE, k0 * 0.95 * fade)
		var c_out1 := Color(COL_EDGE, k1 * 0.95 * fade)
		var c_in0 := Color(COL_INNER, k0 * 0.25 * fade)
		var c_in1 := Color(COL_INNER, k1 * 0.25 * fade)
		for v in [[a0[0], c_in0], [a0[1], c_out0], [a1[1], c_out1], [a0[0], c_in0], [a1[1], c_out1], [a1[0], c_in1]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	im.surface_end()


## D-1001: hand mode restored to the approved D-990 look (Abra): along the real limb (forearm -> hand), past the hand.
func _edges(s: Array) -> Array:
	var tip: Vector3 = s[1]
	var base: Vector3 = s[2]
	var axis := tip - base
	axis = axis.normalized() if axis.length() > 0.001 else Vector3.UP
	return [base.lerp(tip, INNER), tip + axis * EXTEND]


func _body_h() -> float:
	if _bh > 0.0:
		return _bh
	var h := 0.8
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			h = maxf(h, (mi.global_transform * mi.get_aabb()).size.y)
	_bh = h
	return h


## D-990: thin streaks behind the body, along its motion, fading at the contact.
func _draw_lines() -> void:
	var im := _mi.mesh as ImmediateMesh
	im.clear_surfaces()
	if _body_hist.size() < 3:
		return
	var now: Vector3 = _body_hist[_body_hist.size() - 1][1]
	var past: Vector3 = _body_hist[maxi(_body_hist.size() - 4, 0)][1]
	var motion := now - past
	if motion.length() < 0.01:
		return
	var dir := motion.normalized()
	var cam := get_viewport().get_camera_3d()
	var view := (cam.global_position - now).normalized() if cam != null else Vector3.BACK
	var side := dir.cross(view).normalized()
	var up := side.cross(dir).normalized()
	var fade := 1.0 - clampf((_t - LIFE) / KEEP, 0.0, 1.0)
	var h := _body_h()
	var length := clampf(motion.length() * 6.0, 0.4, 1.6)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in LINES:
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 97 + int(_t * 20.0)
		var off := side * rng.randf_range(-0.5, 0.5) * h + up * rng.randf_range(-0.45, 0.45) * h
		var a := now - dir * h * 0.35 + off
		var b := a - dir * length * rng.randf_range(0.6, 1.0)
		var w := view.cross(dir).normalized() * 0.018
		var c0 := Color(COL_EDGE, 0.9 * fade)
		var c1 := Color(COL_EDGE, 0.0)
		for v in [[a + w, c0], [a - w, c0], [b, c1]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	im.surface_end()



## D-991: the weapon held by a model: a skinned mesh bound to a single bone whose name has a weapon part
## ("buki", "weapon", "wmodel", "sword", "club", "spear"). Generic names only (D-235). Empty when there is none.
static func weapon_of(model: Node3D) -> Dictionary:
	if model == null or not is_instance_valid(model):
		return {}
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.skin == null or mi.skin.get_bind_count() != 1:
			continue
		var nm := String(mi.name).to_lower() + " " + String(mi.skin.get_bind_name(0)).to_lower()
		var hit := false
		for part in ["buki", "weapon", "wmodel", "sword", "club", "spear", "axe"]:
			if part in nm:
				hit = true
		if not hit:
			continue
		var sk := mi.get_parent() as Skeleton3D
		if sk == null:
			continue
		var bone := sk.find_bone(String(mi.skin.get_bind_name(0)))
		if bone < 0:
			continue
		var box := mi.get_aabb()
		var ax := Vector3.RIGHT
		var half := box.size.x * 0.5
		if box.size.y * 0.5 > half:
			ax = Vector3.UP
			half = box.size.y * 0.5
		if box.size.z * 0.5 > half:
			ax = Vector3.BACK
			half = box.size.z * 0.5
		var sizes := [box.size.x, box.size.y, box.size.z]
		sizes.sort()
		var thick: float = sizes[1]  # the club's width across its length
		return {"mesh": mi, "skel": sk, "bone": bone, "bind": mi.skin.get_bind_pose(0), "center": box.get_center(), "axis": ax, "half": half, "thick": thick, "thin": thick < half * 0.2}
	return {}


## D-991: the weapon's two ends in world space this frame (its whole length, centred on it).
static func weapon_segment(w: Dictionary) -> Array:
	var sk := w.get("skel") as Skeleton3D
	if sk == null or not is_instance_valid(sk):
		return []
	var xf: Transform3D = sk.global_transform * sk.get_bone_global_pose(int(w["bone"])) * (w["bind"] as Transform3D)
	var c: Vector3 = w["center"]
	var ax: Vector3 = w["axis"]
	var h: float = w["half"]
	return [xf * (c - ax * h), xf * (c + ax * h)]


func _draw_weapon() -> void:
	var im := _mi.mesh as ImmediateMesh
	im.clear_surfaces()
	var pts: Array = []
	for s in _wpn_hist:
		# D-1003: the approved Cyclops window (D-992): from 0.3 s before the contact, the last 0.45 s.
		if float(s[0]) >= HAND_FROM and _t - float(s[0]) <= 0.45:
			pts.append(s)
	if pts.size() < 2:
		return
	var fade := 1.0 - clampf((_t - LIFE) / KEEP, 0.0, 1.0)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var k0 := float(i) / float(pts.size() - 1)
		var k1 := float(i + 1) / float(pts.size() - 1)
		var a0: Vector3 = pts[i][1]
		var b0: Vector3 = pts[i][2]
		var a1: Vector3 = pts[i + 1][1]
		var b1: Vector3 = pts[i + 1][2]
		# D-1003: a little less opaque (the sheet is drawn three times over).
		var ca0 := Color(COL_INNER, k0 * 0.2 * fade)
		var ca1 := Color(COL_INNER, k1 * 0.2 * fade)
		var cb0 := Color(COL_EDGE, k0 * 0.55 * fade)
		var cb1 := Color(COL_EDGE, k1 * 0.55 * fade)
		# D-992: as wide as the weapon itself: the swept sheet is drawn at both faces of the weapon.
		var n := ((b0 - a0).cross(a1 - a0)).normalized() * float(_weapon.get("thick", 0.0)) * 0.5
		for off in [n, -n, Vector3.ZERO]:
			for v in [[a0, ca0], [b0, cb0], [b1, cb1], [a0, ca0], [b1, cb1], [a1, ca1]]:
				im.surface_set_color(v[1])
				im.surface_add_vertex((v[0] as Vector3) + off)
	im.surface_end()



## D-992: the far end of a thin weapon (the spear's point) glows: a hot star facing the camera.
func _draw_tip() -> void:
	var im := _mi.mesh as ImmediateMesh
	im.clear_surfaces()
	var seg := weapon_segment(_weapon)
	if seg.is_empty() or _model == null:
		return
	# The point is the end farther from the body.
	var body := _model.global_position + Vector3.UP * 0.8
	var tip: Vector3 = seg[0] if (seg[0] as Vector3).distance_to(body) > (seg[1] as Vector3).distance_to(body) else seg[1]
	var cam := get_viewport().get_camera_3d()
	var b := cam.global_transform.basis if cam != null else Basis.IDENTITY
	var fade := 1.0 - clampf((_t - LIFE) / KEEP, 0.0, 1.0)
	var r := 0.35 * (0.85 + 0.15 * sin(_t * 50.0))
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var a0 := float(i) / 8.0 * TAU
		var d := b.x * cos(a0) + b.y * sin(a0)
		var sd := (b.x * -sin(a0) + b.y * cos(a0)) * r * 0.08
		var long := r * (1.6 if i % 2 == 0 else 0.9)
		for v in [[tip + sd, Color(1, 1, 0.9, fade)], [tip - sd, Color(1, 1, 0.9, fade)], [tip + d * long, Color(1, 0.9, 0.6, 0.0)]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	for i in 16:
		var a0 := float(i) / 16.0 * TAU
		var a1 := float(i + 1) / 16.0 * TAU
		for v in [[tip, Color(1, 1, 1, fade)], [tip + (b.x * cos(a0) + b.y * sin(a0)) * r * 0.5, Color(1, 0.9, 0.5, 0.0)], [tip + (b.x * cos(a1) + b.y * sin(a1)) * r * 0.5, Color(1, 0.9, 0.5, 0.0)]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	im.surface_end()



## D-1000: an authored, open swing arc for a limb that barely travels in its clip: from behind the shoulder, up over
## the head, down to the contact on the target. Sized by the attacker's body and aimed at the real target (D-235).
func _arc_point(u: float) -> Vector3:
	var h := _body_h()
	var c := _model.global_position + Vector3.UP * h * 0.5
	var to := Vector3(_target.x - c.x, 0.0, _target.z - c.z)
	var dir := to.normalized() if to.length() > 0.01 else Vector3.FORWARD
	# D-1009 (creator's white chalk, seen from the camera): starts at the screen-right of the head, behind it, climbs
	# over the top of the head and comes down the screen-left side, closing on the target below. "Screen right" is the
	# camera's right, so the arc reads the same in both views (D-235: no character or side rule).
	var cam := get_viewport().get_camera_3d()
	var right := cam.global_transform.basis.x if cam != null else Vector3.UP.cross(dir)
	right = Vector3(right.x, 0.0, right.z).normalized()
	var top := c + Vector3.UP * h * 0.5  # top of the head
	# D-1009: the body jumps during the blow; follow the real head bone (generic name), not the floor.
	var hb := _head_bone()
	if hb >= 0:
		var hp := _skel.global_transform * _skel.get_bone_global_pose(hb).origin
		top = hp + Vector3.UP * h * 0.45
		c = top - Vector3.UP * h * 0.5
	var p0 := top + right * h * 0.6 - Vector3.UP * h * 0.15 - dir * h * 0.2
	var p1 := top + right * h * 0.1 + Vector3.UP * h * 0.85 - dir * h * 0.15
	var p2 := top - right * h * 1.9 + Vector3.UP * h * 0.1
	var p3 := _target
	var v := 1.0 - u
	var q := p0 * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + p3 * u * u * u
	# D-1009: lean the whole arc 20 degrees to the screen-left, pivoting on the contact so it still lands on the target.
	if cam != null:
		var view := cam.global_transform.basis.z.normalized()  # toward the viewer: +angle reads counter-clockwise
		q = p3 + (q - p3).rotated(view, deg_to_rad(ARC_TILT_DEG))
	return q


func _draw_arc() -> void:
	var im := _mi.mesh as ImmediateMesh
	im.clear_surfaces()
	if not is_instance_valid(_model):
		return
	var head := clampf(_t / ARC_REACH, 0.0, 1.0)
	head = head * head * (3.0 - 2.0 * head)
	var fade := 1.0 - clampf((_t - ARC_REACH) / 0.3, 0.0, 1.0)
	if DEBUG_FULL:
		head = 1.0  # D-1009 step 1: the whole path, opaque, to compare its SHAPE with the creator's drawing
		fade = 1.0
	if head <= 0.01 or fade <= 0.0:
		return
	var tail := 0.0
	var n := 32
	var h := _body_h()
	var c := _model.global_position + Vector3.UP * h * 0.5
	var w := h * 0.11
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var u0 := lerpf(tail, head, float(i) / float(n))
		var u1 := lerpf(tail, head, float(i + 1) / float(n))
		var a := _arc_point(u0)
		var b := _arc_point(u1)
		var oa := (a - c).normalized()
		var ob := (b - c).normalized()
		var k0 := float(i) / float(n)
		var k1 := float(i + 1) / float(n)
		var ce0 := Color(COL_EDGE, k0 * 0.95 * fade)
		var ce1 := Color(COL_EDGE, k1 * 0.95 * fade)
		var ci0 := Color(COL_INNER, k0 * 0.3 * fade)
		var ci1 := Color(COL_INNER, k1 * 0.3 * fade)
		for v in [[a - oa * w * 0.4, ci0], [a + oa * w, ce0], [b + ob * w, ce1], [a - oa * w * 0.4, ci0], [b + ob * w, ce1], [b - ob * w * 0.4, ci1]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	im.surface_end()



var _head_idx := -2


func _head_bone() -> int:
	if _head_idx == -2:
		_head_idx = -1
		if _skel != null:
			for i in _skel.get_bone_count():
				var n := _skel.get_bone_name(i).to_lower()
				if n == "head" or n.ends_with("_head") or n == "j_kao":
					_head_idx = i
					break
	return _head_idx
