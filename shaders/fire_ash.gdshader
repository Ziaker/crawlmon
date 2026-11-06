shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Soft grey ash puff, camera-facing (D-236): what the leftover flames turn into before they vanish.

uniform vec4 color : source_color = vec4(0.36, 0.33, 0.36, 1.0);
uniform float alpha = 0.6;
uniform float tt = 0.0;
uniform float seed = 0.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 world_pos = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (VERTEX.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (VERTEX.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = vnoise(p * 3.0 + vec2(seed, tt * 0.6));
	float d = 0.95 - length(p) + (n - 0.5) * 0.7;
	float a = smoothstep(0.0, 0.4, d) * alpha;
	if (a < 0.01) {
		discard;
	}
	ALBEDO = color.rgb * (0.8 + n * 0.4);
	ALPHA = a;
}
