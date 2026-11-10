shader_type spatial;
// D-1021: the tall Nami-R wave wall of Tidal Surge. The colour follows the height (UV.y): deep blue at the base,
// blue in the body and a white/cyan foam crest. No Glow (D-337); the brightness comes from the bands.
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.35, 1.0);
uniform vec4 mid_color : source_color = vec4(0.10, 0.50, 0.95, 1.0);
uniform vec4 core_color : source_color = vec4(0.75, 0.97, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float fade = 0.0;
uniform float seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float h = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(deep_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, h));
	col = mix(col, core_color.rgb, smoothstep(0.72, 0.94, h));
	// Slow caustic bands on the body, never on the foam.
	float ripple = sin(UV.x * 22.0 - TIME * 1.6 + h * 12.0 + seed * 6.283);
	col += mid_color.rgb * smoothstep(0.70, 1.0, ripple) * 0.20 * (1.0 - h);
	// Broken foam lip at the top.
	float lip = smoothstep(0.86, 0.98, h);
	float foam = lip * (0.55 + 0.45 * sin(UV.x * 38.0 + TIME * 3.2 + seed * 9.0));
	foam *= step(0.18, hash21(vec2(floor(UV.x * 26.0), floor(UV.y * 3.0)) + seed));
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(alpha * (1.0 - fade), 0.0, 1.0);
}
