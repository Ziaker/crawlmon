class_name FxLane
extends RefCounted
## D-1013/D-1019: the path drawn on the floor from the attacker to the target while the wind-up runs.
## It is a pure drawing of the rules (D-019): every frame it reads where the attacker and the target
## are DRAWN right now (steps, dodges, knock-backs, return jumps, a retarget), how far the wind-up
## is (the Battle clock, not a tween), and it spreads lanes that would overlap (head-on attacks,
## several attackers on one target) side by side. It depends on no character, team, side or move.
## Look (D-1019, chosen by the creator: "Opção 1: fluxo"): energy flow, chevrons streaming toward the target.

var fx: BattleFx
var _lanes: Dictionary = {}  ## Battle.Incoming -> Dictionary
var _time := 0.0
var _dt := 0.0
var _noise: NoiseTexture2D
var _marks: Dictionary = {}  ## pair key -> {root, mat, dust}

const BODY_Y := 0.03
const START_GAP := 0.95  ## From the attacker's centre to the start of the lane (its own ring).
const END_GAP := 1.25  ## From the target's centre to the end of the lane (its danger ring).

const SHADER_HEAD := "shader_type spatial;\nrender_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;\nuniform vec4 col : source_color = vec4(1.0, 0.3, 0.2, 1.0);\nuniform vec4 hot : source_color = vec4(1.0, 0.8, 0.5, 1.0);\nuniform float progress = 0.0;\nuniform float length_m = 10.0;\nuniform float time_s = 0.0;\nuniform float opacity = 0.7;\nuniform sampler2D noise_tex : repeat_enable, filter_linear;\n"

## Energy flow. Chevrons stream toward the target through the filled part; the front glows.
const SHADER_FLOW := SHADER_HEAD + """
void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y;
	float ax = abs(x);
	float body = smoothstep(1.0, 0.86, ax);
	float rail = smoothstep(0.80, 0.88, ax) * smoothstep(1.0, 0.94, ax);
	float filled = 1.0 - smoothstep(progress - 0.004, progress + 0.004, y);
	float cy = fract(y * length_m / 1.5 + ax * 0.6 - time_s * 1.4);
	float chev = smoothstep(0.0, 0.07, cy) * smoothstep(0.42, 0.30, cy);
	float front = exp(-pow((y - progress) * length_m * 1.6, 2.0));
	float n = texture(noise_tex, vec2(y * length_m * 0.05 - time_s * 0.35, x * 0.4)).r;
	float a = body * 0.10 + rail * 0.75 + filled * body * (chev * 0.95 + 0.20 + n * 0.25) + front * body * 1.2;
	vec3 c = mix(col.rgb, hot.rgb, clamp(front * 1.5 + chev * filled * 0.4, 0.0, 1.0)) * 1.8;
	ALBEDO = c;
	ALPHA = clamp(a, 0.0, 1.0) * opacity;
}
"""

## The clash marker (D-1024): pressure rings pulsing on the floor and an X where two opposing runs
## will meet. Additive, warm white; no jagged lines (it is not electric).
const SHADER_CLASH := "shader_type spatial;\nrender_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;\nuniform float intensity = 1.0;\nuniform float time_s = 0.0;\nuniform float rate = 1.0;\n" + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ph = fract(time_s * 0.9 * rate);
	float ring1 = smoothstep(0.14, 0.0, abs(r - ph * 0.9)) * (1.0 - ph);
	float ph2 = fract(time_s * 0.9 * rate + 0.5);
	float ring2 = smoothstep(0.14, 0.0, abs(r - ph2 * 0.9)) * (1.0 - ph2);
	float ang = atan(p.y, p.x) / 6.2831853;
	float dashed = smoothstep(0.09, 0.0, abs(r - 0.9)) * step(0.5, fract(ang * 10.0 + time_s * 0.12));
	float d1 = abs(p.x - p.y) * 0.7071;
	float d2 = abs(p.x + p.y) * 0.7071;
	float xm = (smoothstep(0.12, 0.04, d1) + smoothstep(0.12, 0.04, d2)) * smoothstep(0.58, 0.40, r);
	float core = smoothstep(0.24, 0.0, r);
	float a = ring1 + ring2 * 0.8 + dashed * 0.65 + xm * 0.95 + core * 0.45;
	vec3 c = mix(vec3(1.0, 0.72, 0.38), vec3(1.0, 0.96, 0.86), clamp(core + xm, 0.0, 1.0)) * 2.4;
	ALBEDO = c;
	ALPHA = clamp(a * intensity, 0.0, 1.0) * smoothstep(1.0, 0.88, r);
}
"""

func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func _get_noise() -> NoiseTexture2D:
	if _noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.04
		fn.seed = 7
		_noise = NoiseTexture2D.new()
		_noise.noise = fn
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
	return _noise


func _shader() -> Shader:
	var sh := Shader.new()
	sh.code = SHADER_FLOW
	return sh


## Creates the lane group of one attack and returns its container (the telegraph frees it with the
## other nodes). A single-target attack has one lane; an area attack (D-007: no main target, every
## opponent still standing is hit) gets one lane per opponent, made as they appear.
func add(inc, warn: Color, elem_col: Color, enemy_threat: bool) -> Node3D:
	var container := Node3D.new()
	fx.add_child(container)
	_lanes[inc] = {"root": container, "warn": warn, "elem": elem_col, "width": 1.45 if enemy_threat else 0.95, "subs": {}}
	return container


func _sub(d: Dictionary, target: Combatant) -> Dictionary:
	var subs: Dictionary = d["subs"]
	if subs.has(target):
		return subs[target]
	var sroot := Node3D.new()
	(d["root"] as Node3D).add_child(sroot)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = _shader()
	var warn: Color = d["warn"]
	var elem_col: Color = d["elem"]
	mat.set_shader_parameter("col", Color(warn.r, warn.g, warn.b, 1.0).lerp(elem_col, 0.35))
	mat.set_shader_parameter("hot", Color(1.0, 0.95, 0.8).lerp(elem_col, 0.25))
	mat.set_shader_parameter("noise_tex", _get_noise())
	mi.material_override = mat
	mi.position.y = BODY_Y
	sroot.add_child(mi)
	sroot.visible = false  # Shown by process() with the real geometry.
	var sub := {"root": sroot, "mi": mi, "mat": mat, "width": d["width"]}
	subs[target] = sub
	return sub


func _centre(c: Combatant) -> Vector3:
	var m: Node3D = fx._models.get(c)
	var home: Vector3 = fx._home.get(c, Vector3.ZERO)
	if m != null and is_instance_valid(m):
		return Vector3(m.position.x, home.y, m.position.z)
	return home


## Who this attack is crossing the floor to right now.
func _targets_of(inc) -> Array:
	var a: Combatant = inc.attacker
	if inc.is_aoe and not inc.is_friendly:
		var out: Array = []
		for c in fx._models:
			if c.is_player != a.is_player and c.is_alive():
				out.append(c)
		return out
	return [inc.target]


func process(delta: float) -> void:
	_time += delta
	_dt = delta
	var items: Array = []
	for inc in _lanes.keys():
		var d: Dictionary = _lanes[inc]
		var root_ref = d["root"]  # Untyped: a freed node cannot be assigned to a typed variable.
		if not is_instance_valid(root_ref):
			_lanes.erase(inc)
			continue
		var a: Combatant = inc.attacker
		var live: bool = a != null and a.is_alive() and not inc.dodged and not inc.interrupted
		var seen := {}
		if live:
			for t in _targets_of(inc):
				if t == null or not t.is_alive() or t == a:
					continue
				var sub := _sub(d, t)
				seen[t] = true
				var from := _centre(a)
				var to := _centre(t)
				var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
				if flat.length() < END_GAP + START_GAP + 0.5:
					continue  # On top of each other: nothing to cross.
				var dir := flat.normalized()
				var length := flat.length() - START_GAP - END_GAP
				var start := from + dir * START_GAP
				items.append({"inc": inc, "a": a, "t": t, "from": from, "to": to, "sub": sub, "dir": dir, "len": length, "progress": clampf(1.0 - float(inc.time_left) / maxf(float(inc.total_windup), 0.05), 0.0, 1.0), "mid": start + dir * (length * 0.5)})
				sub["used"] = true
		for t in d["subs"]:
			var sub: Dictionary = d["subs"][t]
			sub["root"].visible = false  # Re-shown below when it is used this frame.
	# Lanes that would lie on top of each other (head-on, or several attackers on one target)
	# are spread side by side, in a fixed order, along a basis that does not depend on direction.
	for i in items.size():
		var it: Dictionary = items[i]
		var rank := 0
		var n := 1
		for j in items.size():
			if j == i:
				continue
			if _overlaps(it, items[j]):
				n += 1
				if j < i:
					rank += 1
		var dd: Vector3 = it["dir"]
		var basis_dir := -dd if (dd.x < -0.001 or (absf(dd.x) <= 0.001 and dd.z < 0.0)) else dd
		var perp := Vector3(basis_dir.z, 0.0, -basis_dir.x)
		var width: float = it["sub"]["width"]
		var off := (float(rank) - float(n - 1) * 0.5) * (width + 0.2)
		it["off"] = perp * off
	for it in items:
		_apply(it)
	_update_marks(items)


func _overlaps(a: Dictionary, b: Dictionary) -> bool:
	var da: Vector3 = a["dir"]
	var db: Vector3 = b["dir"]
	if absf(da.dot(db)) < 0.92:
		return false
	var wa: float = a["sub"]["width"]
	var wb: float = b["sub"]["width"]
	var mid_delta: Vector3 = (b["mid"] as Vector3) - (a["mid"] as Vector3)
	var along := absf(mid_delta.dot(da))
	var across := absf(mid_delta.dot(Vector3(da.z, 0.0, -da.x)))
	return across < (wa + wb) * 0.5 + 0.1 and along < ((a["len"] as float) + (b["len"] as float)) * 0.5


func _apply(it: Dictionary) -> void:
	var sub: Dictionary = it["sub"]
	var root: Node3D = sub["root"]
	var dir: Vector3 = it["dir"]
	var length: float = it["len"]
	var p: float = it["progress"]
	var width: float = sub["width"]
	var mid: Vector3 = (it["mid"] as Vector3) + (it["off"] as Vector3)
	root.visible = true
	root.position = Vector3(mid.x, 0.0, mid.z)
	root.rotation.y = atan2(dir.x, dir.z)
	var mi: MeshInstance3D = sub["mi"]
	mi.scale = Vector3(width * 1.15, 1.0, length)
	var mat: ShaderMaterial = sub["mat"]
	mat.set_shader_parameter("progress", p)
	mat.set_shader_parameter("length_m", length)
	mat.set_shader_parameter("time_s", fx.clock)


# --- D-1024: where two opposing runs will meet ------------------------------------------------


func _pair_key(a: Dictionary, b: Dictionary) -> String:
	var ia: int = (a["inc"] as Object).get_instance_id()
	var ib: int = (b["inc"] as Object).get_instance_id()
	var ta: int = (a["t"] as Object).get_instance_id()
	var tb: int = (b["t"] as Object).get_instance_id()
	return "%d_%d_%d_%d" % [mini(ia, ib), maxi(ia, ib), ta, tb]


## The estimated meeting point of two runs, or Vector3.INF when they do not cross.
func _meeting(a: Dictionary, b: Dictionary) -> Vector3:
	var fa: Vector3 = a["from"]
	var ta: Vector3 = a["to"]
	var fb: Vector3 = b["from"]
	var tb: Vector3 = b["to"]
	var da := Vector2(ta.x - fa.x, ta.z - fa.z)
	var db := Vector2(tb.x - fb.x, tb.z - fb.z)
	var dist := Vector2(fb.x - fa.x, fb.z - fa.z).length()
	var facing: float = da.normalized().dot(db.normalized())
	var mutual: bool = a["t"] == b["a"] and b["t"] == a["a"]
	if mutual or facing < -0.97:
		# Head on: A and B run at each other; the one that starts first has a head start.
		var axis := Vector3(fb.x - fa.x, 0.0, fb.z - fa.z)
		if axis.length() < 0.5:
			return Vector3.INF
		axis = axis.normalized()
		var start_a: float = float((a["inc"] as Incoming).time_left) + AttackMotion.RUN_START
		var start_b: float = float((b["inc"] as Incoming).time_left) + AttackMotion.RUN_START
		var head_start := (start_b - start_a) * BattleSpace.RUN_SPEED  # > 0: A starts first and covers it alone.
		var gap := dist - absf(head_start)
		var closing := maxf(gap - BattleSpace.CLASH_DIST, 0.0) * 0.5
		var moved_a := clampf(maxf(head_start, 0.0) + closing, 0.0, dist)
		var moved_b := clampf(maxf(-head_start, 0.0) + closing, 0.0, dist)
		var pa := fa + axis * moved_a
		var pb := fb - axis * moved_b
		return (pa + pb) * 0.5
	# Different targets: where the two paths cross, if they do.
	var cross := da.x * db.y - da.y * db.x
	if absf(cross) < 0.0001:
		return Vector3.INF
	var w := Vector2(fb.x - fa.x, fb.z - fa.z)
	var tt := (w.x * db.y - w.y * db.x) / cross
	var uu := (w.x * da.y - w.y * da.x) / cross
	if tt < 0.0 or tt > 1.0 or uu < 0.0 or uu > 1.0:
		return Vector3.INF
	return Vector3(fa.x + da.x * tt, fa.y, fa.z + da.y * tt)


func _update_marks(items: Array) -> void:
	var seen := {}
	for i in items.size():
		for j in range(i + 1, items.size()):
			var a: Dictionary = items[i]
			var b: Dictionary = items[j]
			if (a["a"] as Combatant).is_player == (b["a"] as Combatant).is_player:
				continue  # Same team: they do not clash (D-279).
			var p := _meeting(a, b)
			if p == Vector3.INF:
				continue
			var key := _pair_key(a, b)
			seen[key] = true
			var m: Dictionary = _marks.get(key, {})
			if m.is_empty():
				m = _make_mark()
				_marks[key] = m
			var root: Node3D = m["root"]
			root.position = Vector3(p.x, p.y, p.z)
			var prog: float = (float(a["progress"]) + float(b["progress"])) * 0.5
			var mat: ShaderMaterial = m["mat"]
			mat.set_shader_parameter("intensity", lerpf(0.7, 1.0, prog))
			mat.set_shader_parameter("rate", lerpf(0.8, 1.8, prog))
			mat.set_shader_parameter("time_s", fx.clock)
			m["dust"] = float(m["dust"]) - _dt
			if float(m["dust"]) <= 0.0:
				m["dust"] = 0.4
				fx._glow(p + Vector3(0, 0.1, 0), Color(0.62, 0.58, 0.52), 3, Vector2(0.25, 0.5), 0.9, Vector2(0.3, 0.9), Vector3(0, 0.5, 0), 1.0, 0.9)
	for key in _marks.keys():
		if not seen.has(key):
			var m: Dictionary = _marks[key]
			var node_ref = m["root"]
			if is_instance_valid(node_ref):
				(node_ref as Node3D).queue_free()
			_marks.erase(key)


func _make_mark() -> Dictionary:
	var root := Node3D.new()
	fx.add_child(root)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	mi.mesh = pm
	mi.scale = Vector3(8.0, 1.0, 8.0)
	mi.position.y = BODY_Y + 0.01
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER_CLASH
	mat.shader = sh
	mi.material_override = mat
	root.add_child(mi)
	return {"root": root, "mat": mat, "dust": 0.0}
