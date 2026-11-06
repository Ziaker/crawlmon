shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): Pilar Volumétrico de Cura do Media (spawnVolumetricHealPillar do Atelier HTML).

uniform vec4 c_bottom : source_color = vec4(0.0, 1.0, 0.616, 1.0);  // #00ff9d
uniform vec4 c_top : source_color = vec4(0.847, 1.0, 0.0, 1.0);     // #d8ff00
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;

void fragment() {
	float h = 1.0 - UV.y;
	float vFade = pow(1.0 - h, 1.65) * smoothstep(0.0, 0.08, h);
	float fresnel = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float streaks = 0.55 + 0.45 * sin(UV.x * 37.699 + tt * 6.0 - h * 8.0);
	vec3 col = mix(c_bottom.rgb, c_top.rgb, h * 0.7);
	float envelope = sin(clamp(progress, 0.0, 1.0) * 3.14159);
	float alpha = vFade * fresnel * streaks * envelope * 0.82;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * 2.2;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
