shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Cratera Sísmica do Dig (spawnSeismicCraterDecal do Atelier HTML).

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	vec2 vUv = UV * 2.0 - 1.0;
	float r = length(vUv);
	if (r > 1.0) {
		discard;
	}
	float a = atan(vUv.y, vUv.x);
	float abyss = smoothstep(0.55, 0.15, r);
	float cracks = smoothstep(0.12, 0.0, abs(sin(a * 7.0 + r * 6.0))) * smoothstep(0.95, 0.2, r);
	vec3 magma = mix(vec3(0.95, 0.45, 0.05), vec3(1.0, 0.85, 0.2), cracks);
	vec3 col = mix(magma * cracks * 1.6, vec3(0.05, 0.03, 0.02), abyss);
	float fade = 1.0 - smoothstep(0.75, 1.0, progress);
	float alpha = (abyss * 0.9 + cracks * 0.85) * fade;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
