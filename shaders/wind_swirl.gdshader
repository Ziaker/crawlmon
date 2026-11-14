shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Anel de vento do Knock-up (D-1205): faixas cilindricas com riscos de vento que varrem a volta toda, rapidos.
// Criacao da IA a pedido do criador (ventos em forma de circulo rapidamente animados); sem equivalente no HTML.

uniform vec4 u_color : source_color = vec4(0.91, 0.96, 1.0, 1.0);
uniform float u_time = 0.0;
uniform float u_alpha = 1.0;
uniform float u_speed = 14.0;
uniform float u_streaks = 7.0;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
}

void fragment() {
	float a = v_uv.x * 6.2831853;
	float s1 = sin(a * u_streaks - u_time * u_speed + v_uv.y * 5.0);
	float s2 = sin(a * (u_streaks * 2.0 + 3.0) + u_time * u_speed * 1.7);
	float streak = smoothstep(0.55, 1.0, s1) + smoothstep(0.72, 1.0, s2) * 0.55;
	float vprof = pow(sin(clamp(v_uv.y, 0.0, 1.0) * 3.14159), 1.3);
	float alpha = clamp(streak, 0.0, 1.0) * vprof * u_alpha;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = u_color.rgb * 1.25;
	ALPHA = alpha;
}
