extends Node

## Species-independent blink for any GLB whose eyes are `*_eye` surfaces (Pikachu, Eevee, Charmander,
## Bulbasaur, Gible and any new Pokémon model exported the same way). The GLBs have no authored
## blink and the eyelid bones cannot cover the eye, so the lids are drawn on the eye surface itself:
## a fragment shader wipes skin color over it from top and bottom (UV v axis = face vertical),
## meeting at the middle with a dark lash line. Skin color is MEASURED per model: the average
## albedo of the body vertices nearest to the eye. Nothing is per species.

const SHADER_CODE := """
shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 skin : source_color = vec3(0.8, 0.6, 0.4);
uniform float closed : hint_range(0.0, 1.0) = 0.0;
uniform vec2 v_range = vec2(0.0, 1.0);  // eye surface UV v extent (atlas-safe)
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float e = abs((UV.y - v_range.x) / max(v_range.y - v_range.x, 0.0001) - 0.5) * 2.0;
	float open = 1.0 - closed;
	float lash = 1.0 - smoothstep(0.0, 0.07, abs(e - open));
	if (closed > 0.001) {
		if (e > open) { c = skin; }
		c = mix(c, skin * 0.35, lash * step(0.001, closed));
	}
	ALBEDO = c;
	ROUGHNESS = 0.8;
}
"""

const OPEN_MIN := 2.4
const OPEN_MAX := 5.2
const CLOSE_T := 0.06
const HOLD_T := 0.05
const OPEN_T := 0.09

static var _shader: Shader
static var _img_cache := {}

var _mats: Array[ShaderMaterial] = []
var _t := 0.0
var _next := 0.0


static func attach(root: Node) -> Node:
	if root.has_meta("eye_blink_attached"):
		return null
	var surfaces: Array = []   # [MeshInstance3D, surface, material]
	var bodies: Array = []     # [MeshInstance3D, surface, material]
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name.contains("_lod"):
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat == null:
				continue
			if str(mat.resource_name).ends_with("_eye") and mat.albedo_texture != null:
				surfaces.append([mi, s, mat])
			elif mat.albedo_texture != null:
				bodies.append([mi, s, mat])
	if surfaces.is_empty() or bodies.is_empty():
		return null
	root.set_meta("eye_blink_attached", true)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var blink := (load("res://scripts/common/eye_blink.gd") as GDScript).new() as Node
	blink.name = "EyeBlink"
	for e in surfaces:
		var mi: MeshInstance3D = e[0]
		var c := _centroid(mi.mesh, e[1])
		var sm := ShaderMaterial.new()
		sm.shader = _shader
		sm.set_shader_parameter("tex", (e[2] as BaseMaterial3D).albedo_texture)
		sm.set_shader_parameter("v_range", _v_range(mi.mesh, e[1]))
		sm.set_shader_parameter("skin", _skin_near(c, bodies) * 0.89)
		mi.set_surface_override_material(e[1], sm)
		blink._mats.append(sm)
	blink._next = randf_range(0.5, OPEN_MAX)
	root.add_child(blink)
	return blink


static func _v_range(mesh: Mesh, s: int) -> Vector2:
	var uvs: PackedVector2Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV]
	var lo := 1e9
	var hi := -1e9
	for uv in uvs:
		lo = minf(lo, uv.y)
		hi = maxf(hi, uv.y)
	return Vector2(lo, hi) if hi > lo else Vector2(0.0, 1.0)


static func _centroid(mesh: Mesh, s: int) -> Vector3:
	var vs: PackedVector3Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
	var c := Vector3.ZERO
	for v in vs:
		c += v
	return c / maxi(vs.size(), 1)


## Average body color of the 14 body vertices closest to the eye center.
static func _skin_near(center: Vector3, bodies: Array) -> Color:
	var best: Array = []  # [dist, Color]
	for b in bodies:
		var mesh: Mesh = (b[0] as MeshInstance3D).mesh
		var mat: BaseMaterial3D = b[2]
		var arr := mesh.surface_get_arrays(b[1])
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		if uvs.size() != vs.size():
			continue
		var img := _image_of(mat.albedo_texture)
		if img == null:
			continue
		var cand: Array = []
		for i in vs.size():
			var d := vs[i].distance_squared_to(center)
			if best.size() < 14 or d < (best[best.size() - 1][0] as float):
				cand.append([d, i])
		cand.sort_custom(func(a, bb): return a[0] < bb[0])
		for k in mini(cand.size(), 14):
			var uv: Vector2 = uvs[cand[k][1]]
			var px := img.get_pixel(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1),
				clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1))
			best.append([cand[k][0], px * mat.albedo_color])
		best.sort_custom(func(a, bb): return a[0] < bb[0])
		if best.size() > 14:
			best.resize(14)
	var sum := Color(0, 0, 0, 1)
	for e in best:
		var col: Color = e[1]
		sum.r += col.r; sum.g += col.g; sum.b += col.b
	var n := maxi(best.size(), 1)
	return Color(sum.r / n, sum.g / n, sum.b / n, 1.0)


static func _image_of(tex: Texture2D) -> Image:
	if _img_cache.has(tex):
		return _img_cache[tex]
	var img := tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	_img_cache[tex] = img
	return img


func set_closed(amount: float) -> void:
	for m in _mats:
		m.set_shader_parameter("closed", amount)


## Status hold (e.g. BLIND): eyelids stay shut while true; ramps in/out smoothly.
var hold_closed := false
var squeeze_left := 0.0  ## hit/impact: eyes shut for this many more seconds
var _hold_k := 0.0
var _last := -1.0
const HOLD_IN := 0.12
const HOLD_OUT := 0.22


func squeeze(seconds: float) -> void:
	squeeze_left = maxf(squeeze_left, seconds)


func _process(delta: float) -> void:
	_t += delta
	squeeze_left = maxf(squeeze_left - delta, 0.0)
	var b := 0.0
	if _t >= _next:
		var k := _t - _next
		if k >= CLOSE_T + HOLD_T + OPEN_T:
			_t = 0.0
			_next = randf_range(OPEN_MIN, OPEN_MAX)
		elif k < CLOSE_T:
			b = k / CLOSE_T
		elif k < CLOSE_T + HOLD_T:
			b = 1.0
		else:
			b = 1.0 - (k - CLOSE_T - HOLD_T) / OPEN_T
	var shut := hold_closed or squeeze_left > 0.0
	_hold_k = move_toward(_hold_k, 1.0 if shut else 0.0, delta / (HOLD_IN if shut else HOLD_OUT))
	var v := maxf(b, _hold_k)
	if not is_equal_approx(v, _last):
		_last = v
		set_closed(v)
