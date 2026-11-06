shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.4 (D-332): FOGO como efeito visual, não modelo. Um campo de calor turbulento que sobe (ruído fractal levado
// para cima), cortado em degraus CHAPADOS de cor: amarelo, laranja, vermelho, vermelho queimado e PRETO de fuligem. As bordas
// se rompem em lambidas soltas e a opacidade varia muito: o núcleo é sólido, a periferia vai ficando translúcida até a fuligem.
// Cada instância tem semente, velocidade e escala próprias (nenhuma chama é igual a outra). Tempo explícito `tt` (D-019).
// `fade` 0..1 esfria o fogo de cima para baixo até apagar.

uniform vec4 c_yellow : source_color = vec4(1.0, 0.9, 0.42, 1.0);
uniform vec4 c_orange : source_color = vec4(1.0, 0.52, 0.07, 1.0);
uniform vec4 c_red : source_color = vec4(0.86, 0.16, 0.04, 1.0);
uniform vec4 c_burnt : source_color = vec4(0.36, 0.07, 0.04, 1.0);
uniform vec4 c_soot : source_color = vec4(0.04, 0.03, 0.035, 1.0);
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float speed = 1.0;          // quão rápido o fogo sobe
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float width = 1.0;          // largura do corpo
uniform float turbulence = 1.0;     // quanto o corpo ondula e se rompe
uniform float soot = 1.0;           // quanto de fuligem preta
uniform float energy = 1.2;
uniform float roll = 0.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * 2.0, (1.0 - UV.y) * 1.04 - 0.02);
	float y = clamp(p.y, 0.0, 1.0);
	float t = tt * speed;
	vec2 so = vec2(seed * 3.17, seed * 1.91);
	// o corpo ondula e é arrastado para cima: duas oitavas de ruído deslocam a posição lateral
	float sway = (fbm(vec2(y * 1.7 + so.x, -t * 0.9 + so.y)) - 0.5) * 0.9 * turbulence * (0.2 + y);
	float x = (p.x - sway) / max(width, 0.05);
	// envelope: base larga e arredondada, afina até uma ponta
	float round_base = sqrt(max(1.0 - pow(1.0 - clamp(y / 0.2, 0.0, 1.0), 2.0), 0.0));
	float w = 0.62 * pow(max(1.0 - y, 0.0), 0.85) * round_base;
	float a = abs(x) / max(w, 0.02);
	// campo de ruído que sobe
	float n = fbm(vec2(x * 2.4 + so.x, y * 2.6 - t * 1.6 + so.y));
	float n2 = fbm(vec2(x * 5.0 + so.y, y * 5.5 - t * 2.4 + so.x));
	float heat = (1.0 - a) * (1.05 - y * 0.85) + (n - 0.5) * (0.35 + 0.85 * y) * turbulence + (n2 - 0.5) * 0.25 * y;
	heat -= fade * (0.35 + 0.9 * y);
	heat *= smoothstep(-0.015, 0.0, p.y);
	// degraus chapados; a opacidade varia bastante entre eles
	vec3 col = c_soot.rgb;
	float alpha = 0.0;
	float wisp = 0.55 + 0.45 * fbm(vec2(x * 3.0 - so.y, y * 3.0 - t * 1.1));
	if (heat > 0.72) {
		col = c_yellow.rgb;
		alpha = 1.0;
	} else if (heat > 0.5) {
		col = c_orange.rgb;
		alpha = 1.0;
	} else if (heat > 0.33) {
		col = c_red.rgb;
		alpha = 0.97;
	} else if (heat > 0.19) {
		col = c_burnt.rgb;
		alpha = 0.86 * (0.7 + 0.3 * wisp);
	} else if (heat > 0.07) {
		col = c_soot.rgb;
		alpha = 0.55 * wisp * soot;
	}
	if (alpha < 0.03) {
		discard;
	}
	ALBEDO = col * energy;
	ALPHA = alpha;
}
