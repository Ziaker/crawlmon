shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
// V1.13 (D-1026): a flat chrome PLATE: one straight-edged triangle on a quad, shaded by the same procedural studio reflection as the
// ARMOR film (shaders/armor_chrome.gdshader), so a plate that leaves the body looks like the chrome it came from. Turning plates flash
// as their normal sweeps the reflection. `fade` (0..1) dissolves it. No character, team or side (D-235).

uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform vec3 shadow_col : source_color = vec3(0.30, 0.34, 0.42);
uniform vec3 mid_col : source_color = vec3(0.72, 0.78, 0.88);
uniform vec3 light_col : source_color = vec3(1.0, 1.0, 1.0);

float edge_fn(vec2 a, vec2 b, vec2 p) {
	return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

void fragment() {
	vec2 p = UV;
	vec2 a = vec2(0.5, 0.03);
	vec2 b = vec2(0.97, 0.97);
	vec2 c = vec2(0.03, 0.97);
	float e0 = edge_fn(a, b, p);
	float e1 = edge_fn(b, c, p);
	float e2 = edge_fn(c, a, p);
	bool inside = (e0 >= 0.0 && e1 >= 0.0 && e2 >= 0.0) || (e0 <= 0.0 && e1 <= 0.0 && e2 <= 0.0);
	if (!inside) {
		discard;
	}
	vec3 n = NORMAL;
	if (!FRONT_FACING) {
		n = -n;
	}
	vec3 wr = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, n), 0.0)).xyz;
	float h = wr.y * 0.5 + 0.5;
	float env = smoothstep(0.40, 0.58, h);
	float stripes = smoothstep(0.55, 0.9, sin(wr.x * 3.2 + wr.y * 5.5 + seed) * 0.5 + 0.5);
	vec3 col = mix(shadow_col, mid_col, env);
	col = mix(col, light_col, stripes * 0.8);
	float d = min(min(abs(e0) / length(b - a), abs(e1) / length(c - b)), abs(e2) / length(a - c));
	col += light_col * smoothstep(0.06, 0.0, d) * 0.7;
	ALBEDO = col * 1.3;
	ALPHA = 1.0 - fade;
}
