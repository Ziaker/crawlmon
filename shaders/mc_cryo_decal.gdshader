shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Decalque Criogênico do Mabufula (spawnCryoFrostDecal do Atelier HTML).

uniform vec4 c_core : source_color = vec4(0.502, 0.973, 1.0, 1.0);  // #80f8ff
uniform vec4 c_edge : source_color = vec4(0.0, 0.467, 1.0, 1.0);    // #0077ff
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	vec2 vUv = UV * 2.0 - 1.0;
	float d = length(vUv * vec2(0.85, 1.15));
	if (d > 1.0) {
		discard;
	}
	float spread = smoothstep(0.0, 0.25, progress);
	if (d > spread) {
		discard;
	}
	float a = atan(vUv.y, vUv.x);
	float crystal = abs(sin(a * 6.0 + d * 10.0)) * abs(cos(a * 12.0 - d * 8.0));
	float veins = smoothstep(0.35, 0.85, crystal) * (1.0 - d * 0.7);
	float rim = smoothstep(0.08, 0.0, abs(d - spread * 0.95));
	vec3 col = mix(c_edge.rgb, c_core.rgb, clamp(veins + rim, 0.0, 1.0));
	float fadeOut = 1.0 - smoothstep(0.72, 1.0, progress);
	float alpha = (veins * 0.65 + rim * 0.9 + 0.15) * (1.0 - d) * fadeOut;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * 1.4;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
