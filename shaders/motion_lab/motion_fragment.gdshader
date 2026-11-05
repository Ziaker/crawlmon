shader_type spatial;
// Motion Composer — representação "Fragmentos" (D-044), modo neutro (§8.3): sem brilho aditivo nem partículas
// auxiliares. Cor e alfa vêm da instância (MultiMesh use_colors): matiz por ramo, alfa = opacidade,
// brilho = intensidade. As facetas são lidas por uma "luz de cabeça" fixa no espaço da câmera; não há
// iluminação da cena. Compatível com GL Compatibility.
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque;

// 0 = chapado, 1 = facetas bem marcadas.
uniform float facet_strength : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(vec3(0.3, 0.55, 0.78))), 0.0, 1.0);
	float shade = mix(1.0, 0.35 + 0.65 * facing, facet_strength);
	ALBEDO = COLOR.rgb * shade;
	ALPHA = COLOR.a;
}
