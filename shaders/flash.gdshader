shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
// Additive hit flash, used as `material_overlay` on a model's meshes.

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 1.5);
	ALBEDO = color.rgb;
	ALPHA = amount * (0.55 + 0.45 * f);
}
