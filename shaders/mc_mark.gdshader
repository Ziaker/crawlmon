shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://shaders/mc_common.gdshaderinc"
// Motion Composer V1.2 (D-323): marca decorativa no chão (GL Compatibility não tem Decal): queimado, poça, rachadura,
// arrasto de vento. Um quad deitado no chão; borda irregular por ruído, degraus duros, `fade` apaga. Só desenho:
// nunca decide colisão nem acerto.

uniform vec4 base_col : source_color = vec4(0.04, 0.03, 0.03, 1.0);
uniform vec4 line_col : source_color = vec4(1.0, 0.45, 0.1, 1.0);     // brasas / brilho molhado / luz na rachadura
uniform vec4 rim_col : source_color = vec4(0.2, 0.12, 0.08, 1.0);
uniform float line_amount = 0.8;
uniform float rim_amount = 0.5;
uniform float alpha = 0.85;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float cracks = 5.0;        // quantas linhas radiais/rachaduras
uniform float radial = 1.0;        // 1 = linhas saem do centro; 0 = manchas

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float n = mc_fbm3(vec3(p * 2.4 + seed, seed));
	float edge = 0.92 - r + (n - 0.5) * 0.6 - fade * 0.95;
	if (edge < 0.0) {
		discard;
	}
	float ray = abs(sin(ang * cracks + n * 3.0));
	float line = mix(step(0.9, mc_fbm3(vec3(p * 5.0 + seed, 1.0))), step(0.93, ray) * (1.0 - r), radial);
	line *= (0.7 + 0.3 * sin(tt * 3.0 + seed + r * 8.0));
	vec3 col = base_col.rgb;
	col = mix(col, rim_col.rgb, step(edge, 0.12) * rim_amount);
	col = mix(col, line_col.rgb, line * line_amount * (1.0 - fade));
	ALBEDO = col;
	ALPHA = alpha * (1.0 - fade) * smoothstep(0.0, 0.05, edge);
}
