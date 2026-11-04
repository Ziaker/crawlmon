shader_type spatial;
// Motion Composer — representação "Pontos" (D-044), modo neutro (§8.3): sem iluminação, sem brilho,
// sem partículas auxiliares. A cor vem da instância (MultiMesh use_colors): matiz por ramo, alfa =
// opacidade da amostra, brilho = intensidade. Compatível com GL Compatibility (sem recursos exclusivos).
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

// 0 = disco chapado, 1 = esfera com borda mais escura (ajuda a ler profundidade sem luz).
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float shade = mix(1.0, 0.55 + 0.45 * facing, rim_strength);
	ALBEDO = COLOR.rgb * shade;
	ALPHA = COLOR.a;
}
