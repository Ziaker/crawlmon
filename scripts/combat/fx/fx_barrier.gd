class_name FxBarrier
extends RefCounted
## D-196: the dome barrier, kept for a future "Protect" move. NOT wired into the game yet (Guard uses the
## shield in fx_guard.gd). The upper half of a round dome standing in front of the character: seen from
## behind it is one big circular arch over the body, with both legs on the floor. It is ONE smooth shell
## drawn by a shader (hexagon cells, a plain glass bubble or ribs). It rises when started, fades when the
## time runs out, and when contact destroys it the shell breaks into patches that fly apart.
## API (same shape as FxGuard): `start(c)` and `stop(c, reason)`, reason "hit" / "broken" / "expired" /
## "battle_end". Approved look (2026-11-04): the hexagon shell, cyan lines, translucent blue body.
## Part of BattleFx (see battle_fx.gd): when it is used, create it there like the other FX parts.

const AZIMUTH_SEGMENTS := 8  ## Break patches across the arch (left leg, over the top, right leg).
const RINGS := 4  ## Break patches from the front pole to the rim at the character.
const GAP := 0.05  ## Fraction trimmed from each break patch edge.
const SIZE_MULT := 1.25  ## Radius relative to the body.
const SHARD_SECONDS := 0.6
const REAR_SHIFT := 0.3  ## Where the rim stands, as a fraction of how far the chest reaches forward (1 = at the chest).
const COLOR_BOOST := 1.5  ## The arena's tone mapping dulls flat colors; this brings them back.
const FILL := Color(0.10, 0.45, 1.0, 0.30)  ## Translucent body of the shell.
const LINE := Color(0.70, 0.96, 1.0)  ## Bright lines, rim and floor glow.

## style: "hex" = smooth shell with a hexagon-cell pattern (the approved one); "bubble" = plain glass bubble
## with a bright rim; "ribs" = a membrane with a few bright ribs.
static var style := "hex"

const DOME_SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform int style = 0;
uniform vec4 fill : source_color = vec4(0.1, 0.45, 1.0, 0.3);
uniform vec3 line : source_color = vec3(0.7, 0.96, 1.0);
uniform float alpha = 1.0;
uniform float boost = 1.0;
varying vec3 dir;
float hex_dist(vec2 p) {
	p = abs(p);
	float c = dot(p, normalize(vec2(1.0, 1.73)));
	return max(c, p.x);
}
float hex_edge(vec2 uv) {
	vec2 r = vec2(1.0, 1.73);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return 0.5 - hex_dist(gv);
}
void vertex() {
	dir = normalize(VERTEX);
}
void fragment() {
	vec3 d = normalize(dir);
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	float floor_glow = smoothstep(0.22, 0.0, d.y);
	float pattern = 0.0;
	if (style == 0) {
		vec3 w = pow(abs(d), vec3(6.0));
		w /= (w.x + w.y + w.z);
		float e = w.z * hex_edge(d.xy * 3.2) + w.y * hex_edge(d.xz * 3.2) + w.x * hex_edge(d.yz * 3.2);
		pattern = smoothstep(0.07, 0.0, e);
	} else if (style == 2) {
		float ang = atan(d.y, d.x) / 3.14159265;
		float phi = acos(clamp(d.z, -1.0, 1.0)) / 1.5707963;
		float rib = smoothstep(0.035, 0.0, abs(fract(ang * 6.0 + 0.5) - 0.5));
		float ring = smoothstep(0.03, 0.0, abs(fract(phi * 4.0 + 0.5) - 0.5));
		pattern = max(rib, ring);
	}
	float a = fill.a + fres * 0.45 + floor_glow * 0.5 + pattern * 0.6;
	vec3 col = mix(fill.rgb, line, clamp(fres * 0.9 + floor_glow + pattern, 0.0, 1.0));
	ALBEDO = col * boost;
	ALPHA = clamp(a, 0.0, 1.0) * alpha;
}
"

## The pieces the shell breaks into: a translucent fill with a bright edge on each.
const PATCH_SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 fill : source_color = vec4(0.5, 0.8, 1.0, 0.25);
uniform vec3 rim : source_color = vec3(1.0);
uniform float alpha = 1.0;
uniform float boost = 1.0;
void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float glow = smoothstep(0.17, 0.0, edge);
	ALBEDO = mix(fill.rgb, rim, glow) * boost;
	ALPHA = mix(fill.a + 0.25, 1.0, glow) * alpha;
}
"

var fx: BattleFx
var _domes: Dictionary = {}  ## Combatant -> Node3D (child of the model)
var _dome_shader: Shader
var _patch_shader: Shader


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func start(c: Combatant) -> void:
	var model: Node3D = fx._models.get(c)
	if model == null or not is_instance_valid(model):
		return
	_clear(c)
	var b := _bounds(model)
	var radius: float = maxf(b.height * 0.95, b.width * 1.1) * SIZE_MULT
	var root := Node3D.new()
	root.name = "ProtectDome"
	root.position = Vector3(0.0, 0.0, b.front * REAR_SHIFT)  # The rim is pulled in close to the body.
	root.scale = Vector3.ONE * 0.55
	root.set_meta("radius", radius)
	model.add_child(root)
	var shell := _shell(radius)
	root.add_child(shell)
	_domes[c] = root
	var tw := root.create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_alpha_tween(tw, shell.material_override as ShaderMaterial, 0.0, 1.0, 0.22)


## reason: "hit" / "broken" shatter it where it stands; "expired" / "battle_end" fade it out.
func stop(c: Combatant, reason: String) -> void:
	var root: Node3D = _domes.get(c)
	_domes.erase(c)
	if root == null or not is_instance_valid(root):
		return
	if reason == "hit" or reason == "broken":
		_break_into_patches(root)
		_shatter(root, reason == "broken")
	else:
		var tw := root.create_tween().set_parallel(true)
		for p in root.get_children():
			_alpha_tween(tw, (p as MeshInstance3D).material_override as ShaderMaterial, 1.0, 0.0, 0.3)
		tw.chain().tween_callback(root.queue_free)


func _clear(c: Combatant) -> void:
	var old: Node3D = _domes.get(c)
	if old != null and is_instance_valid(old):
		old.queue_free()
	_domes.erase(c)


func _alpha_tween(tw: Tween, mat: ShaderMaterial, from: float, to: float, dur: float, delay := 0.0) -> void:
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), from, to, dur).set_delay(delay)


## The body's size in the model's own space: height, width (X) and how far the chest reaches forward
## (+Z). The rings and the dome itself are not part of the body; the tail, which trails backward, does
## not matter here.
func _bounds(model: Node3D) -> Dictionary:
	var inv := model.global_transform.affine_inverse()
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if not (n is MeshInstance3D) or n.name.contains("Ring") or n.name.contains("Guard") or n.name.contains("Protect") or n.name.contains("Shield"):
			continue
		var mi := n as MeshInstance3D
		var t: Transform3D = inv * mi.global_transform
		for k in 8:
			var p: Vector3 = t * mi.get_aabb().get_endpoint(k)
			mn = mn.min(p)
			mx = mx.max(p)
	if mn.x == INF:
		return {"height": 2.2, "width": 1.8, "front": 0.5}
	return {"height": maxf(mx.y - mn.y, 0.8), "width": maxf(mx.x - mn.x, 0.6), "front": maxf(mx.z, 0.2)}


## The smooth shell: the upper half (y >= 0) of the hemisphere around the +Z pole, one mesh.
func _shell(radius: float) -> MeshInstance3D:
	var rings := 18
	var segs := 36
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rings:
		for i in segs:
			var p00 := _dome_point(j, i, rings, segs)
			var p01 := _dome_point(j, i + 1, rings, segs)
			var p11 := _dome_point(j + 1, i + 1, rings, segs)
			var p10 := _dome_point(j + 1, i, rings, segs)
			for q in [p00, p01, p11, p00, p11, p10]:
				st.set_normal(q)
				st.add_vertex(q * radius)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.name = "Shell"
	if _dome_shader == null:
		_dome_shader = Shader.new()
		_dome_shader.code = DOME_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _dome_shader
	mat.set_shader_parameter("style", {"hex": 0, "bubble": 1, "ribs": 2}[style])
	mat.set_shader_parameter("fill", FILL)
	mat.set_shader_parameter("line", LINE)
	mat.set_shader_parameter("alpha", 1.0)
	mat.set_shader_parameter("boost", COLOR_BOOST)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _dome_point(j: int, i: int, rings: int, segs: int) -> Vector3:
	var phi := float(j) / float(rings) * (PI * 0.5)  # 0 = front pole, PI/2 = the rim at the character.
	var theta := float(i) / float(segs) * PI  # 0..PI keeps y >= 0: the dome stands on the floor.
	return Vector3(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi))


## One break piece of the dome, with UVs 0..1 so its edge can glow.
func _patch(i: int, j: int, radius: float) -> MeshInstance3D:
	var ph0 := (float(j) + GAP) / float(RINGS) * (PI * 0.5)
	var ph1 := (float(j + 1) - GAP) / float(RINGS) * (PI * 0.5)
	var th0 := (float(i) + GAP) / float(AZIMUTH_SEGMENTS) * PI
	var th1 := (float(i + 1) - GAP) / float(AZIMUTH_SEGMENTS) * PI
	var corners := [Vector2(ph0, th0), Vector2(ph0, th1), Vector2(ph1, th1), Vector2(ph1, th0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for k in corners:
		pts.append(Vector3(sin(k.x) * cos(k.y), sin(k.x) * sin(k.y), cos(k.x)) * radius)
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_uv(uvs[idx])
		st.add_vertex(pts[idx])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.name = "Patch_%d_%d" % [i, j]
	if _patch_shader == null:
		_patch_shader = Shader.new()
		_patch_shader.code = PATCH_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _patch_shader
	mat.set_shader_parameter("fill", FILL)
	mat.set_shader_parameter("rim", LINE)
	mat.set_shader_parameter("alpha", 1.0)
	mat.set_shader_parameter("boost", COLOR_BOOST)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Contact: the smooth shell is replaced, in the same place, by the pieces that will fly apart.
func _break_into_patches(root: Node3D) -> void:
	var radius: float = float(root.get_meta("radius", 2.5))
	for ch in root.get_children():
		ch.queue_free()
		root.remove_child(ch)
	for j in RINGS:
		for i in AZIMUTH_SEGMENTS:
			root.add_child(_patch(i, j, radius))


## The patches leave the dome in world space, fly outward and fade.
func _shatter(root: Node3D, big: bool) -> void:
	var center := root.global_position
	var holder := Node3D.new()
	holder.name = "ProtectShards"
	fx.add_child(holder)
	for p in root.get_children():
		var mi := p as MeshInstance3D
		var xf := mi.global_transform
		root.remove_child(mi)
		holder.add_child(mi)
		mi.global_transform = xf
		var from_center := (xf.origin - center).normalized()
		var out := from_center * (2.8 if big else 1.6) + Vector3.UP * (1.3 if big else 0.7)
		var mat := mi.material_override as ShaderMaterial
		var spin := Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		var start_pos := mi.position
		var tw := mi.create_tween().set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			mi.position = start_pos + out * k + Vector3.DOWN * 2.2 * k * k,
			0.0, 1.0, SHARD_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "rotation", mi.rotation + spin, SHARD_SECONDS)
		_alpha_tween(tw, mat, 1.0, 0.0, SHARD_SECONDS, 0.12)
	root.queue_free()
	var cleanup := holder.create_tween()
	cleanup.tween_interval(SHARD_SECONDS + 0.2)
	cleanup.tween_callback(holder.queue_free)
