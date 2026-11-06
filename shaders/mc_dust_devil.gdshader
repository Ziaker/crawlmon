shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Funil de Redemoinho (Dust Devil) do Sand Attack (spawnDustDevilFunnel do Atelier HTML).

uniform vec4 c_sand : source_color = vec4(0.918, 0.702, 0.031, 1.0); // #eab308
uniform vec4 c_dark : source_color = vec4(0.471, 0.208, 0.059, 1.0); // #78350f
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	float h = 1.0 - UV.y;
	float bands = sin(h * 18.0 - tt * 12.0 + UV.x * 12.566);
	float mask = smoothstep(-0.2, 0.8, bands);
	float vFade = sin(h * 3.14159);
	float env = sin(clamp(progress, 0.0, 1.0) * 3.14159);
	vec3 col = mix(c_dark.rgb, c_sand.rgb, mask);
	float alpha = (0.35 + mask * 0.5) * vFade * env;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * 1.25;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
