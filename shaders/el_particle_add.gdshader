shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
// D-274: same as el_particle but additive (embers, flashes, glints).

uniform int kind = 0;
uniform float energy = 1.0;

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
	float sc = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc, INV_VIEW_MATRIX[1] * sc, INV_VIEW_MATRIX[2] * sc, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a;
	if (kind == 1) {
		a = smoothstep(1.0, 0.85, r);
	} else if (kind == 2) {
		float arms = max(1.0 - abs(p.x) * 5.0, 0.0) * max(1.0 - abs(p.y), 0.0) + max(1.0 - abs(p.y) * 5.0, 0.0) * max(1.0 - abs(p.x), 0.0);
		a = clamp(arms + smoothstep(0.45, 0.0, r), 0.0, 1.0);
	} else {
		a = smoothstep(1.0, 0.0, r);
		a *= a;
	}
	ALBEDO = v_color.rgb * energy * a * v_color.a;
	ALPHA = 1.0;
}
