shader_type spatial;
// D-1170 Bubble Shot: toon Hydro water for jets, geyser crests, drops, rings and the
// guide dashes. Two flat colour bands scroll along UV.y, with hard white foam lines
// and a bright rim. `time_s` comes from the battle clock (D-019), not TIME.
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec3 deep_color : source_color = vec3(0.04, 0.30, 0.95);
uniform vec3 mid_color : source_color = vec3(0.14, 0.62, 1.0);
uniform vec3 light_color : source_color = vec3(0.66, 0.93, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float flow_speed = 6.0;
uniform float band_scale = 9.0;
uniform float foam : hint_range(0.0, 1.0) = 0.6;
uniform float tip_fade : hint_range(0.0, 1.0) = 0.0;  // 1 = fades toward both UV.y ends
uniform float time_s = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float edge = 1.0 - clamp(abs(dot(n, v)), 0.0, 1.0);

	float swirl = sin(UV.x * 12.566 + seed) * 1.4;
	float flow = sin(UV.y * band_scale - time_s * flow_speed + swirl + seed);
	vec3 col = mix(deep_color, mid_color, smoothstep(-0.08, 0.08, flow));

	float foam_wave = sin(UV.y * band_scale * 0.5 - time_s * flow_speed * 0.7 + UV.x * 18.85 + seed * 2.0);
	float foam_line = smoothstep(0.86, 0.92, foam_wave) * foam;
	col = mix(col, vec3(1.0), foam_line);

	float rim = smoothstep(0.55, 0.62, edge);
	col = mix(col, light_color, rim * 0.8);

	float ends = 1.0;
	if (tip_fade > 0.0) {
		float e = smoothstep(0.0, 0.22, UV.y) * smoothstep(1.0, 0.72, UV.y);
		ends = mix(1.0, e, tip_fade);
	}
	ALBEDO = col * 1.15;
	ALPHA = clamp(alpha * ends * (0.72 + 0.28 * max(rim, foam_line)), 0.0, 1.0);
}
