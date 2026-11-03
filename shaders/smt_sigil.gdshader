shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 sigil_color : source_color = vec4(0.84, 0.99, 0.41, 1.0);
uniform float rotation_speed : hint_range(-10.0, 10.0) = 1.5;
uniform float alpha_mult : hint_range(0.0, 2.0) = 1.0;
uniform int sigil_type : hint_range(0, 2) = 0; // 0 = Tarukaja, 1 = Rakunda, 2 = Sukunda
uniform float jam_factor : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv) * 2.0;
	if (r > 1.0) {
		ALPHA = 0.0;
		discard;
	}
	float theta = atan(uv.y, uv.x);
	float rot_effective = rotation_speed * (1.0 - jam_factor * 0.95);
	float t_rot = theta + TIME * rot_effective;

	// Aneis concentricos basicos
	float ring1 = smoothstep(0.025, 0.0, abs(r - 0.95)); // Anel externo
	float ring2 = smoothstep(0.018, 0.0, abs(r - 0.88)); // Segundo anel
	float ring3 = smoothstep(0.018, 0.0, abs(r - 0.65)); // Anel intermediario
	float ring4 = smoothstep(0.020, 0.0, abs(r - 0.35)); // Anel central

	// Marcadores de borda
	float ticks = 0.0;
	if (r > 0.88 && r < 0.95) {
		ticks = smoothstep(0.4, 0.8, sin(t_rot * 24.0));
	}

	float shape = 0.0;
	if (sigil_type == 0) {
		// TARUKAJA: Estrela de 8 pontas e raios solares ascendentes
		float spoke = smoothstep(0.035, 0.0, abs(sin(t_rot * 4.0))) * step(r, 0.88) * step(0.12, r);
		float spoke_diag = smoothstep(0.028, 0.0, abs(cos(t_rot * 4.0))) * step(r, 0.75) * step(0.15, r);
		float star = smoothstep(0.03, 0.0, abs(abs(cos(t_rot * 3.0)) * r - 0.42)) * step(r, 0.65);
		shape = spoke + spoke_diag * 0.7 + star;
	} else if (sigil_type == 1) {
		// RAKUNDA: Selo hexagonal de maldição e fraturas gravitacionais
		float hex_val = max(abs(cos(t_rot) * uv.x - sin(t_rot) * uv.y) * 1.73205 + abs(sin(t_rot) * uv.x + cos(t_rot) * uv.y), abs(sin(t_rot) * uv.x + cos(t_rot) * uv.y) * 2.0);
		float hex = smoothstep(0.025, 0.0, abs(hex_val * 2.0 - 0.72));
		float cracks = smoothstep(0.035, 0.0, abs(sin(theta * 6.0 + sin(r * 12.0)))) * step(r, 0.88) * step(0.1, r);
		shape = hex + cracks * 0.85;
	} else {
		// SUKUNDA: Relógio / Engrenagem de estase com ponteiro emperrado
		float hour_ticks = smoothstep(0.15, 0.0, abs(sin(t_rot * 6.0))) * step(r, 0.88) * step(0.72, r);
		float hand_angle = (1.0 - jam_factor) * TIME * 8.0 + jam_factor * (sin(TIME * 45.0) * 0.15 + 1.2);
		float hand_diff = abs(mod(theta - hand_angle + 3.14159, 6.28318) - 3.14159);
		float hand = smoothstep(0.04, 0.0, hand_diff) * step(r, 0.68);
		float gear = smoothstep(0.35, 0.75, sin(t_rot * 16.0)) * smoothstep(0.025, 0.0, abs(r - 0.50));
		shape = hour_ticks + hand * 1.2 + gear;
	}

	float pattern = ring1 + ring2 + ring3 + ring4 + ticks * 0.6 + shape;
	float edge_fade = smoothstep(1.0, 0.82, r);

	ALBEDO = sigil_color.rgb * 1.6;
	ALPHA = clamp(pattern * edge_fade * sigil_color.a * alpha_mult, 0.0, 1.0);
}
