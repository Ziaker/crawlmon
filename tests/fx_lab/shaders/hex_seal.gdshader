shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Electro seal on the floor: rotating hexagon rings with notches, hard-edged.
uniform vec3 col : source_color = vec3(0.72, 0.4, 1.0);
uniform float spin = 0.9;
uniform float fade = 1.0;

float hex(vec2 p) {
	p = abs(p);
	return max(dot(p, vec2(0.8660254, 0.5)), p.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float ca = cos(TIME * spin);
	float sa = sin(TIME * spin);
	vec2 q = vec2(p.x * ca - p.y * sa, p.x * sa + p.y * ca);
	float h = hex(q);
	float ring1 = step(0.86, h) * step(h, 0.92);
	float ring2 = step(0.62, h) * step(h, 0.655);
	float h2 = hex(vec2(p.x * ca + p.y * sa, -p.x * sa + p.y * ca));
	float ring3 = step(0.40, h2) * step(h2, 0.43);
	float ang = atan(q.y, q.x);
	float notch = step(0.5, fract(ang / 6.2831853 * 12.0));
	float m = max(ring1 * notch, max(ring2, ring3));
	ALBEDO = mix(col, vec3(1.0), 0.55) * 1.6;
	ALPHA = m * fade;
}
