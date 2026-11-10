class_name MpEcho
extends Node3D
## D-1062: the eco textual "+N MP" shown when a unit recovers MP. MP blue, very saturated, flat, no borders, Impact, facing the
## camera and over everything (like "ARMOR!", D-1061). It stamps in over the real body, rises a little and fades out in ~0.6 s.
## The place and size come from the measured body (D-235), so it is the same for any character, team or side.

const FONT_NAMES := ["Impact", "Arial Black"]
const COLOR := Color("38bdf8")  ## the MP bar's blue
const STAMP := 0.10
const RISE := 0.55  ## seconds of the rise; the fade takes the last 0.2 s
const RISE_FRACTION := 0.9  ## how far it climbs, in glyph heights
const MAX_SCREEN := 0.06
const MIN_SCREEN := 0.028
const GLYPH := 0.79
const TOP_MARGIN := 0.05

const SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;
uniform vec4 tint : source_color = vec4(0.22, 0.74, 0.97, 1.0);
uniform float alpha = 1.0;
uniform float boost = 1.7;  // the arena's tone mapping dulls flat colours (same boost as the GUARD letters)
void vertex() {
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc.x, INV_VIEW_MATRIX[1] * sc.y, INV_VIEW_MATRIX[2] * sc.z, MODEL_MATRIX[3]);
}
void fragment() {
	ALBEDO = tint.rgb * boost;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"

static var _shader: Shader
static var _font: Font


## `amount` is what was really recovered. Spawned above the head of `model`; `body_top` / `body_h` are measured from it.
static func spawn(fx: BattleFx, model: Node3D, body_top: float, body_h: float, amount: int) -> void:
	if amount <= 0:
		return
	var e := MpEcho.new()
	e.name = "MpEcho"
	fx.add_child(e)
	e._build(fx, model, body_top, body_h, "+%d MP" % amount)


func _build(fx: BattleFx, model: Node3D, body_top: float, body_h: float, text: String) -> void:
	var camera := fx.get_viewport().get_camera_3d() if fx.is_inside_tree() else null
	var center := Vector3(model.global_position.x, body_top, model.global_position.z)
	var size := body_h * 0.16
	if camera != null:
		var view_h := 2.0 * camera.global_position.distance_to(center) * tan(deg_to_rad(camera.fov) * 0.5)
		size = clampf(size, MIN_SCREEN * view_h / GLYPH, MAX_SCREEN * view_h / GLYPH)
	var base := center + Vector3.UP * (size * 0.7)
	if camera != null:  # never above the screen: lower it onto the head
		var screen_h := float(fx.get_viewport().get_visible_rect().size.y)
		var steps := 0
		while steps < 60 and not camera.is_position_behind(base) and camera.unproject_position(base + Vector3.UP * GLYPH * size * 2.0).y < TOP_MARGIN * screen_h and base.y > center.y - body_h * 0.4:
			base.y -= GLYPH * size * 0.1
			steps += 1
	var tm := TextMesh.new()
	tm.text = text
	tm.font = _text_font()
	tm.font_size = 110
	tm.pixel_size = 0.01
	tm.depth = 0.0
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var mat := ShaderMaterial.new()
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	mat.shader = _shader
	mat.set_shader_parameter("tint", COLOR)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = base
	mi.scale = Vector3.ONE * size * 1.7
	var rise_to := base + Vector3.UP * (GLYPH * size * RISE_FRACTION)
	var tw := create_tween()
	# STAMP: it lands from a larger size with a little overshoot, then RISES and fades out in its last 0.2 s.
	tw.tween_property(mi, "scale", Vector3(1.12, 0.86, 1.0) * size, STAMP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(mi, "scale", Vector3.ONE * size, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "global_position", rise_to, RISE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), 1.0, 0.0, 0.2).set_delay(0.17 + RISE - 0.2)
	tw.tween_callback(queue_free)


static func _text_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(FONT_NAMES)
		_font = f
	return _font
