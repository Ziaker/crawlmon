shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Onda Crescente de Areia do Sand Attack (spawnSandCrescentWave do Atelier HTML).

uniform vec4 col : source_color = vec4(0.98, 0.8, 0.082, 1.0); // #facc15
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 vUv = UV * 2.0 - 1.0;
	float r = length(vUv);
	if (r < 0.41 || r > 1.0) {
		discard;
	}
	float ang = atan(vUv.y, vUv.x);
	// Arco crescente frontal (-0.45*PI .. +0.45*PI)
	if (abs(ang) > 1.4137) {
		discard;
	}
	float rim = smoothstep(0.41, 0.55, r) * smoothstep(1.0, 0.82, r);
	float tip = smoothstep(1.4137, 0.9, abs(ang));
	float fade = sin(clamp(progress, 0.0, 1.0) * 3.14159);
	float alpha = rim * tip * fade * 0.85;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col.rgb * 1.35;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
