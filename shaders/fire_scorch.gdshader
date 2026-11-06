shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Scorched floor mark (D-236), Infernal-skin mood: a dark burn with radial glowing cracks that cool and fade.
// Lies on a quad turned to the floor.

uniform vec4 glow : source_color = vec4(1.0, 0.42, 0.07, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;

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
	float r = length(p);
	float ang = atan(p.y, p.x);
	float n = vnoise(vec2(ang * 3.0 + seed, r * 5.0)) * 0.6 + vnoise(vec2(ang * 7.0 - seed, r * 9.0 + 2.0)) * 0.4;
	float edge = 0.95 - r + (n - 0.5) * 0.45;                       // ragged outline of the burn
	if (edge < 0.0) {
		discard;
	}
	float crack = 1.0 - smoothstep(0.0, 0.1, abs(vnoise(vec2(ang * 5.0 + seed * 2.0, r * 3.0)) - 0.5));
	float heat = clamp(crack * (1.0 - r * 0.6) * 1.3 + (1.0 - r) * 0.25, 0.0, 1.0) * (1.0 - fade);
	vec3 burn = vec3(0.04, 0.02, 0.02);
	ALBEDO = mix(burn, glow.rgb * intensity, heat);
	ALPHA = smoothstep(0.0, 0.15, edge) * (0.78 * (1.0 - fade) + 0.0) ;
}
