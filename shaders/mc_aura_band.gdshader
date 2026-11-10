shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// D-378: faixa espiral de aura da Drain Spear. Recebe uma fita construída em volta de +Y (UV.x = ao longo da
// faixa, UV.y = através da largura). A normal aponta para fora do eixo, então a luz direcional e o fresnel dão
// volume à fita; `opacity` é baixa de propósito. Não depende de personagem, time, lado nem câmera (D-235).

uniform vec4 color : source_color = vec4(0.32, 0.82, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.72, 1.0, 1.0, 1.0);
uniform vec3 light_dir = vec3(-0.35, 0.85, 0.42);   // direção PARA a luz, no mundo
uniform float opacity : hint_range(0.0, 1.0) = 0.18;
uniform float energy = 1.2;
uniform float flow_speed = 0.8;
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float rim_power = 1.7;
uniform float edge_soft = 0.30;

void fragment() {
	// Borda suave através da largura: a fita não tem serrilhado nem corte duro.
	float edge = smoothstep(0.0, edge_soft, UV.y) * smoothstep(1.0, 1.0 - edge_soft, UV.y);
	if (edge < 0.01) {
		discard;
	}
	// Fluxo ao longo da fita: a energia corre da base para a ponta.
	float flow = 0.62 + 0.38 * sin((UV.x * 9.0 - tt * flow_speed) * 6.2831853 + seed);
	// Iluminação: metade da fita voltada para a luz acende; o fresnel acende a borda rasante.
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float ndl = 0.45 + 0.55 * clamp(dot(wn, normalize(light_dir)), 0.0, 1.0);
	float fres = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), rim_power);
	vec3 col = color.rgb * energy * (ndl * 0.85 + 0.15) + rim_color.rgb * fres * 0.55;
	ALBEDO = col;
	ALPHA = clamp(opacity * edge * flow, 0.0, 1.0);
}
