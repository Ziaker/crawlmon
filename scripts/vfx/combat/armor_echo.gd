class_name ArmorEcho
extends Node3D
## D-1061: the eco textual "ARMOR!" of Armored Bulk. Very saturated, flat, no borders (like the GUARD letters, D-272), Impact,
## facing the camera and drawn over everything. It sits above the REAL body (height measured from the model), so it is the same
## for any character, team or side (D-235). Animation, from the release (the chrome wave reaching the head):
##   1. STAMP   each letter drops in at 2.4x and slams to a squashed 1.1 x 0.78, then settles to 1.0 (0.04 s between letters);
##              the "!" comes last with an extra hop.
##   2. PRESS   it holds, with a flat white sweep passing over the letters from left to right, once.
##   3. EXIT    every letter is cut by a straight slanted line: the two plates fly apart and fall, fading in the last 0.2 s.

const WORD := "ARMOR!"
const FONT_NAMES := ["Impact", "Arial Black"]
const COLOR := Color(0.60, 0.62, 0.66)  ## light grey, flat (creator: "ao invés de amarelo, seja cinza claro"); the 1.7 boost below lifts it to the tone the arena shows
const STAGGER := 0.04
const HOLD_UNTIL := 0.62  ## seconds after the first letter when the exit starts
const EXIT_SECONDS := 0.32
const FADE_SECONDS := 0.2
const GRAVITY := 11.0
## On-screen size of the word, as for GUARD (D-274): a share of the screen height, so far bodies stay legible.
const MAX_SCREEN := 0.0733
const MIN_SCREEN := 0.032
const GLYPH := 0.79  ## glyph height per unit of letter scale (font_size 110 x pixel_size 0.01 x cap height)
const TOP_MARGIN := 0.05

const SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;
uniform vec4 tint : source_color = vec4(0.60, 0.62, 0.66, 1.0);
uniform float alpha = 1.0;
uniform float boost = 1.7;  // the arena's tone mapping dulls flat colours (same boost as the GUARD letters)
uniform float flash = 0.0;
uniform float half_sign = 1.0;
uniform float cut_y = 0.0;
varying vec3 lp;
void vertex() {
	lp = VERTEX;
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc.x, INV_VIEW_MATRIX[1] * sc.y, INV_VIEW_MATRIX[2] * sc.z, MODEL_MATRIX[3]);
}
void fragment() {
	float side = (lp.y + lp.x * 0.35) - cut_y;  // a straight, slanted cut through the middle of the letter
	if (side * half_sign < 0.0) {
		discard;
	}
	ALBEDO = mix(tint.rgb, vec3(1.0), clamp(flash, 0.0, 1.0)) * boost;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"

static var _shader: Shader
static var _font: Font

var fx: BattleFx
var _letters: Array[Dictionary] = []  ## {up, low, i, size, base}


## Spawns the word above the body of `model`. `body_top` / `body_h` are measured from the real model.
static func spawn(p_fx: BattleFx, model: Node3D, body_top: float, body_h: float) -> ArmorEcho:
	var e := ArmorEcho.new()
	e.name = "ArmorEcho"
	e.fx = p_fx
	p_fx.add_child(e)
	e._build(model, body_top, body_h)
	return e


func _build(model: Node3D, body_top: float, body_h: float) -> void:
	var camera := fx.get_viewport().get_camera_3d() if fx.is_inside_tree() else null
	var center := Vector3(model.global_position.x, body_top, model.global_position.z)
	var size := body_h * 0.22
	if camera != null:
		var view_h := 2.0 * camera.global_position.distance_to(center) * tan(deg_to_rad(camera.fov) * 0.5)
		size = clampf(size, MIN_SCREEN * view_h / GLYPH, MAX_SCREEN * view_h / GLYPH)
	var base := center + Vector3.UP * (size * 0.8)
	if camera != null:  # never above the screen: lower the word onto the head
		var screen_h := float(fx.get_viewport().get_visible_rect().size.y)
		var steps := 0
		while steps < 60 and not camera.is_position_behind(base) and camera.unproject_position(base + Vector3.UP * GLYPH * size).y < TOP_MARGIN * screen_h and base.y > center.y - body_h * 0.4:
			base.y -= GLYPH * size * 0.1
			steps += 1
	var cam_pos := fx._cam_pos()
	var yaw := atan2(cam_pos.x - base.x, cam_pos.z - base.z)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var gap := 0.56 * size
	for i in WORD.length():
		var tm := TextMesh.new()
		tm.text = WORD[i]
		tm.font = _text_font()
		tm.font_size = 110
		tm.pixel_size = 0.01
		tm.depth = 0.0
		var aabb := tm.get_aabb()
		var cut := aabb.position.y + aabb.size.y * 0.5
		var pair: Array[MeshInstance3D] = []
		for sgn in [1.0, -1.0]:
			var mi := MeshInstance3D.new()
			mi.mesh = tm
			mi.material_override = _material(sgn, cut)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visible = false
			add_child(mi)
			mi.global_position = base + right * ((float(i) - (WORD.length() - 1) * 0.5) * gap)
			mi.scale = Vector3.ONE * size
			pair.append(mi)
		_letters.append({"up": pair[0], "low": pair[1], "i": i, "size": size, "pos": pair[0].global_position, "right": right})
	_animate()


func _animate() -> void:
	var tw := create_tween().set_parallel(true)
	for L in _letters:
		var i: int = L["i"]
		var d := float(i) * STAGGER
		var size: float = L["size"]
		for key in ["up", "low"]:
			var mi: MeshInstance3D = L[key]
			var mat := mi.material_override as ShaderMaterial
			# 1. STAMP: appears at 2.4x, slams down squashed, settles.
			tw.tween_callback(func() -> void:
				mi.scale = Vector3.ONE * size * 2.4
				mi.visible = true).set_delay(d)
			tw.tween_property(mi, "scale", Vector3(1.1, 0.78, 1.0) * size, 0.09).set_delay(d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(mi, "scale", Vector3.ONE * size, 0.09).set_delay(d + 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			# the "!" hops once more
			if i == WORD.length() - 1:
				var p0: Vector3 = L["pos"]
				tw.tween_property(mi, "global_position:y", p0.y + size * 0.35, 0.09).set_delay(d + 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(mi, "global_position:y", p0.y, 0.10).set_delay(d + 0.27).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			# 2. PRESS: the white sweep passes over the letters, left to right, once.
			tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.14).set_delay(0.30 + d)
	# 3. EXIT: the two plates of every letter fly apart and fall.
	tw.tween_callback(_exit).set_delay(HOLD_UNTIL)


func _exit() -> void:
	var vel: Dictionary = {}
	for L in _letters:
		var r: Vector3 = L["right"]
		var side := 1.0 if int(L["i"]) % 2 == 0 else -1.0
		vel[L["up"]] = r * side * randf_range(1.6, 3.0) + Vector3.UP * randf_range(2.5, 4.0)
		vel[L["low"]] = -r * side * randf_range(1.0, 2.2) + Vector3.UP * randf_range(-0.5, 0.8)
	var last := [0.0]
	var fade_from := 1.0 - FADE_SECONDS / EXIT_SECONDS
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		var dt := (k - float(last[0])) * EXIT_SECONDS
		last[0] = k
		var a := 1.0 - clampf((k - fade_from) / (1.0 - fade_from), 0.0, 1.0)
		for mi in vel.keys():
			var v: Vector3 = vel[mi]
			v.y -= GRAVITY * dt
			vel[mi] = v
			(mi as MeshInstance3D).global_position += v * dt
			((mi as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("alpha", a),
		0.0, 1.0, EXIT_SECONDS)
	tw.tween_callback(queue_free)


func _material(half_sign: float, cut: float) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("tint", COLOR)
	mat.set_shader_parameter("alpha", 1.0)
	mat.set_shader_parameter("flash", 0.0)
	mat.set_shader_parameter("half_sign", half_sign)
	mat.set_shader_parameter("cut_y", cut)
	return mat


static func _text_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(FONT_NAMES)
		_font = f
	return _font
