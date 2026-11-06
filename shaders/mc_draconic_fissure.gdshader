shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Fissuras de Fúria Dracônica do Dragon Rage (spawnDraconicFissureDecal do Atelier HTML).

uniform vec4 c_hot : source_color = vec4(1.0, 0.918, 0.475, 1.0);   // #ffea79
uniform vec4 c_rage : source_color = vec4(1.0, 0.0, 0.333, 1.0);    // #ff0055
uniform vec4 c_char : source_color = vec4(0.078, 0.008, 0.047, 1.0);// #14020c
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	vec2 vUv = UV * 2.0 - 1.0;
	float r = length(vUv);
	if (r > 1.0) {
		discard;
	}
	float a = atan(vUv.y, vUv.x);
	float branch = abs(sin(a * 9.0 + sin(r * 14.0 - tt * 6.0) * 1.8));
	float crack = smoothstep(0.16, 0.0, branch) * smoothstep(0.98, 0.08, r);
	float charPool = smoothstep(0.85, 0.15, r);
	vec3 magma = mix(c_rage.rgb, c_hot.rgb, smoothstep(0.4, 0.95, crack) * (1.0 - r * 0.5));
	vec3 col = mix(c_char.rgb, magma * 2.1, crack);
	float fade = 1.0 - smoothstep(0.68, 1.0, progress);
	float alpha = (charPool * 0.78 + crack * 0.95) * fade;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
