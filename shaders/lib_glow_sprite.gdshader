shader_type spatial;
// D-966: fake glow for the projectile library (no Glow post-process, D-957): soft additive camera-facing sprites
// placed along the beam, on the charge, the shot and the impact. Per-instance colour (alpha = strength) and size
// come from the MultiMesh instance. Works in GL Compatibility.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float intensity = 1.0;
uniform float falloff = 2.2;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = pow(clamp(1.0 - d, 0.0, 1.0), falloff);
	ALBEDO = COLOR.rgb * intensity;
	ALPHA = a * COLOR.a;
}
