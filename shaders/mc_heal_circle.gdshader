shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Círculo Sagrado de Cura do Media (spawnSacredHealCircle do Atelier HTML).
// 3 anéis concêntricos, banda rúnica giratória, estrela de 4 pontas e onda de ripple radial.

uniform vec4 c_primary : source_color = vec4(0.0, 1.0, 0.616, 1.0);    // #00ff9d
uniform vec4 c_secondary : source_color = vec4(0.847, 1.0, 0.0, 1.0);  // #d8ff00
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	vec2 vUv = UV * 2.0 - 1.0;
	float r = length(vUv);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(vUv.y, vUv.x);
	float ring1 = smoothstep(0.062, 0.0, abs(r - 0.92));
	float ring2 = smoothstep(0.048, 0.0, abs(r - 0.76));
	float ring3 = smoothstep(0.04, 0.0, abs(r - 0.45));
	float runeBand = step(0.77, r) * step(r, 0.90);
	float runes = step(0.2, sin(angle * 16.0 + tt * 3.5)) * runeBand * 0.75;
	float starWave = abs(cos(angle * 4.0 - tt * 2.0)) * 0.28 + 0.46;
	float starLine = smoothstep(0.045, 0.0, abs(r - starWave));
	float rippleRadius = fract(tt * 0.85);
	float ripple = smoothstep(0.075, 0.0, abs(r - rippleRadius)) * (1.0 - rippleRadius);
	float pattern = ring1 + ring2 + ring3 + runes + starLine + ripple * 0.8;
	float halo = smoothstep(0.16, 0.02, abs(r - 0.92)) * 0.20 + smoothstep(0.14, 0.02, abs(r - 0.76)) * 0.15;
	float softGlow = (1.0 - r) * 0.32;
	vec3 col = mix(c_primary.rgb, c_secondary.rgb, clamp(starLine + runes, 0.0, 1.0));
	float fade = sin(clamp(progress * 3.14159, 0.0, 3.14159));
	float scaleIn = smoothstep(0.0, 0.18, progress);
	float alpha = (pattern + halo + softGlow) * fade * scaleIn;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * (pattern * 2.8 + halo + softGlow);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
