shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque, shadows_disabled;
// Motion Composer V1.8 (D-337): Bola de Fogo Dracônica Monstruosa do Dragon Rage (createMonstrousDragonRageFireball do Atelier HTML).
// Deslocamento de vértices por espinhos de chama e alongamento traseiro de cometa; 4 cores com crosta abissal por Fresnel.

uniform vec4 c_core : source_color = vec4(1.0, 0.918, 0.475, 1.0);   // #ffea79
uniform vec4 c_rage : source_color = vec4(1.0, 0.0, 0.333, 1.0);     // #ff0055
uniform vec4 c_pink : source_color = vec4(1.0, 0.2, 0.522, 1.0);     // #ff3385
uniform vec4 c_abyss : source_color = vec4(0.141, 0.0, 0.18, 1.0);   // #24002e
uniform float tt = 0.0;

varying float v_spike;

void vertex() {
	vec3 pos = VERTEX * 2.24; // escala da esfera de raio 0.5 para o raio 1.12 do HTML
	float f1 = sin(pos.x * 5.5 - tt * 18.0) * cos(pos.y * 5.5 + tt * 16.0);
	float f2 = sin(pos.z * 7.5 - tt * 22.0) * sin(pos.x * 8.0 + tt * 14.0);
	float spike = pow(abs(f1 * f2), 0.65) * sign(f1 + 0.2);
	v_spike = spike;
	vec3 displaced = VERTEX + NORMAL * (spike * 0.15);
	if (VERTEX.z > 0.0) {
		displaced.z *= 1.32;
	}
	VERTEX = displaced;
}

void fragment() {
	float fresnel = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 fireCol = mix(c_rage.rgb, c_pink.rgb, smoothstep(-0.2, 0.45, v_spike));
	fireCol = mix(fireCol, c_core.rgb, smoothstep(0.35, 0.85, v_spike) * (1.0 - fresnel * 0.6));
	vec3 finalCol = mix(fireCol * 1.95, c_abyss.rgb, pow(fresnel, 1.75) * 0.72);
	ALBEDO = finalCol;
	ALPHA = 0.96;
}
