shader_type spatial;
// Motion Composer — representação "Fitas" (D-044), modo neutro (§8.3): sem iluminação, sem brilho aditivo,
// sem partículas auxiliares. A cor e o alfa vêm dos vértices (matiz por ramo, alfa = opacidade da amostra,
// brilho = intensidade). UV.y vai de 0 a 1 através da fita: a borda é suavizada, sem depender de textura.
// Sem escrita de profundidade: fitas translúcidas sobrepostas se misturam sem cortar umas às outras
// (a ordenação de fitas sobrepostas ainda não foi medida, §19.5). Compatível com GL Compatibility.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

// 0 = borda dura, 1 = esmaece desde o centro.
uniform float edge_softness : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	float across = abs(UV.y * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(1.0 - edge_softness, 1.0, across);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * edge;
}
