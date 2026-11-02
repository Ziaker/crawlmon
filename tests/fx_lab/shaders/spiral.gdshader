shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Hypnosis spiral: two hard colours winding outwards, rotating.
uniform vec3 col_a : source_color = vec3(1.0, 0.2, 0.7);
uniform vec3 col_b : source_color = vec3(0.2, 0.9, 1.0);
uniform float turns = 2.5;
uniform float spin = 1.4;
uniform float fade = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float s = fract(a / 6.2831853 * 2.0 + r * turns - TIME * spin);
	vec3 c = s < 0.5 ? col_a : col_b;
	float ring = smoothstep(1.0, 0.9, r) * smoothstep(0.04, 0.12, r);
	ALBEDO = c * 1.5;
	ALPHA = ring * fade * 0.85;
}
