shader_type spatial;
// D-957: golden electric beam of the projectile library (Zeri-like), cel bands, no Glow (D-337). Used on the beam
// tubes, the filaments, the charge orb, the flashes and the impact arcs. Fresnel picks the band: pale core where
// the surface faces the camera, gold mid, dark-gold rim. `fade` dissolves it in blocky golden bits (Post-impact).
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.82, 1.0);  // D-967: bright core, a touch of yellow
uniform vec4 mid_color : source_color = vec4(1.0, 0.86, 0.0, 1.0);  // D-967: pure saturated electric yellow
uniform vec4 rim_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);  // D-967 saturated / D-960: thin rays are mostly rim at distance: keep it bright gold
uniform float core_cut = 0.72;  // fresnel above this = core
uniform float mid_cut = 0.38;   // fresnel above this = mid, else rim
uniform float alpha = 1.0;
uniform float fade = 0.0;       // 0 solid, 1 gone (Post-impact)
uniform float flicker = 0.0;    // 0..1 random brightness steps
uniform float seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 col = f > core_cut ? core_color.rgb : (f > mid_cut ? mid_color.rgb : rim_color.rgb);
	float step_t = floor(TIME * 24.0);
	col *= 1.0 - flicker * 0.15 * hash21(vec2(seed, step_t));  // D-965: flicker never darkens much
	// Post-impact: blocky dissolve along the beam (UV.x) and around it (UV.y).
	float bits = hash21(floor(UV * vec2(28.0, 4.0)) + seed);
	if (bits < fade) {
		discard;
	}
	ALBEDO = col;
	ALPHA = alpha;  // D-965: solid, no dim rim
}
