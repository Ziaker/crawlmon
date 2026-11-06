shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Soft golden-orange halo on a camera-facing quad (D-236): the glow that sells the fire.

uniform vec4 inner : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform vec4 outer : source_color = vec4(1.0, 0.4, 0.05, 1.0);
uniform float intensity = 0.6;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 world_pos = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (VERTEX.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (VERTEX.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = pow(clamp(1.0 - r, 0.0, 1.0), 2.4);
	if (a < 0.01) {
		discard;
	}
	ALBEDO = mix(outer.rgb, inner.rgb, a) * intensity;
	ALPHA = a;
}
