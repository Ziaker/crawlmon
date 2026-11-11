shader_type spatial;
// D-1170 Bubble Shot: hollow Hydro bubble. See-through centre, cel-banded rim,
// moving cel caustics and the two window highlights. Unshaded: the look does not
// depend on the arena lights. `time_s` comes from the battle clock (D-019), not TIME.
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec3 deep_color : source_color = vec3(0.04, 0.30, 0.95);
uniform vec3 mid_color : source_color = vec3(0.14, 0.62, 1.0);
uniform vec3 light_color : source_color = vec3(0.66, 0.93, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float wobble : hint_range(0.0, 0.2) = 0.03;
uniform float flare : hint_range(0.0, 2.0) = 0.0;
uniform float time_s = 0.0;
uniform float seed = 0.0;

void vertex() {
	float w = sin(VERTEX.x * 6.0 + time_s * 8.0 + seed) * cos(VERTEX.y * 5.0 - time_s * 7.0 + seed * 1.7);
	VERTEX += NORMAL * w * wobble;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float edge = 1.0 - clamp(abs(dot(n, v)), 0.0, 1.0);

	// Three cel bands from centre to rim: clear, mid Hydro, bright rim line.
	float band_mid = smoothstep(0.42, 0.47, edge);
	float band_rim = smoothstep(0.74, 0.78, edge);
	vec3 col = mix(deep_color, mid_color, band_mid);
	col = mix(col, light_color, band_rim);
	float a = 0.055 + band_mid * 0.26 + band_rim * 0.56;

	// Cel caustics: thin bright veins that drift over the film.
	vec2 p = n.xy * 3.2 + vec2(seed, -seed * 0.6);
	float c = sin(p.x * 4.0 + time_s * 2.1 + sin(p.y * 3.0 - time_s * 1.3))
		* sin(p.y * 4.0 - time_s * 1.7 + sin(p.x * 3.0 + time_s));
	float vein = smoothstep(0.80, 0.86, abs(c)) * (1.0 - band_rim);
	col = mix(col, light_color, vein * 0.85);
	a += vein * 0.22;

	// Window highlights: hard white on the front wall, softer echo on the back wall.
	float spec = 0.0;
	if (FRONT_FACING) {
		float s1 = dot(n, normalize(vec3(-0.48, 0.68, 0.55)));
		spec = smoothstep(0.86, 0.96, s1) * 0.95;
		float s1b = dot(n, normalize(vec3(-0.70, 0.40, 0.59)));
		spec = max(spec, smoothstep(0.985, 0.995, s1b) * 0.9);
	} else {
		float s2 = dot(n, normalize(vec3(0.45, -0.58, 0.65)));
		spec = smoothstep(0.88, 0.97, s2) * 0.55;
	}
	col = mix(col, vec3(1.0), spec);
	a = max(a, spec);

	col += light_color * flare * (0.35 + band_rim);
	ALBEDO = col * (1.0 + flare * 0.8);
	ALPHA = clamp(a * alpha + flare * band_mid * 0.35 * alpha, 0.0, 1.0);
}
