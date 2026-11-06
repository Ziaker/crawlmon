shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://shaders/mc_common.gdshaderinc"
// Motion Composer V1.2 (D-323): nuvem estilizada (fumaça, cinza, vapor, poeira, névoa) num quad voltado para a câmera.
// Silhueta de couve-flor feita por ruído, 3 degraus de tom duros (claro, médio, sombra do lado oposto à luz) e erosão
// por `fade`. Alfa misturado (não aditivo), então o cinza lê como cinza.

uniform vec4 light_col : source_color = vec4(0.62, 0.6, 0.6, 1.0);
uniform vec4 mid_col : source_color = vec4(0.42, 0.4, 0.42, 1.0);
uniform vec4 dark_col : source_color = vec4(0.26, 0.25, 0.28, 1.0);
uniform vec2 light_2d = vec2(-0.5, 0.8);     // para onde está a luz, no plano da tela
uniform float alpha = 0.8;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float churn = 0.6;                    // quanto a borda borbulha
uniform float roll = 0.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float n = mc_fbm3(vec3(p * 2.2 + seed, tt * 0.35 + seed));
	float d = 0.85 - r + (n - 0.5) * churn - fade * 0.9;
	if (d < 0.0) {
		discard;
	}
	// degraus: o lado da luz é claro, o centro médio, o lado oposto escuro
	float side = dot(normalize(p + vec2(0.0001)), normalize(light_2d)) * smoothstep(0.0, 0.7, r);
	float tone = 0.62 + side * 0.4 + (n - 0.5) * 0.5 - d * 0.0;
	vec3 col = dark_col.rgb;
	col = mix(col, mid_col.rgb, step(0.4, tone));
	col = mix(col, light_col.rgb, step(0.72, tone));
	ALBEDO = col;
	ALPHA = alpha * (1.0 - fade) * smoothstep(0.0, 0.06, d);
}
