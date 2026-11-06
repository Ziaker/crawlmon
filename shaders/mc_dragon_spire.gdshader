shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Espirais 3D de Chamas Dracônicas no impacto do Dragon Rage (spireShaderMat do Atelier HTML).

uniform vec4 c_base : source_color = vec4(1.0, 0.918, 0.475, 1.0); // #ffea79
uniform vec4 c_mid : source_color = vec4(1.0, 0.0, 0.333, 1.0);    // #ff0055
uniform vec4 c_tip : source_color = vec4(0.122, 0.0, 0.141, 1.0);  // #1f0024
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float vY = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 col = mix(c_base.rgb, c_mid.rgb, smoothstep(0.0, 0.55, vY));
	col = mix(col, c_tip.rgb, smoothstep(0.55, 1.0, vY));
	float env = sin(clamp(progress, 0.0, 1.0) * 3.14159);
	float alpha = env * 0.92;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * 1.9;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
