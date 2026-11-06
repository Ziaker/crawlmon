shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.6 (D-332): o MATERIAL de uma chama que é uma FITA conduzida pelo Composer. A forma (curva em S, balanço, gancho,
// largura, nascimento e morte) vem da COMPOSIÇÃO (M03, M09, M24, M17, M18...) e da geometria (MotionShapes.ribbon); este shader só
// pinta: degraus chapados de amarelo, laranja, vermelho, vermelho queimado e PRETO de fuligem, opacidade muito variável, mordidas em
// C na borda (sorteadas por `seed`) e tempo quantizado (cada chama tem seu FPS). Vértice: UV.x através (0..1), UV.y metros ao longo,
// COLOR r = posição ao longo (0 base .. 1 ponta), g = intensidade, b = dissolução 0..1 (M18), a = meia-largura (m). Tempo explícito.

uniform vec4 c_yellow : source_color = vec4(1.0, 0.9, 0.42, 1.0);
uniform vec4 c_orange : source_color = vec4(1.0, 0.52, 0.07, 1.0);
uniform vec4 c_red : source_color = vec4(0.86, 0.16, 0.04, 1.0);
uniform vec4 c_burnt : source_color = vec4(0.36, 0.07, 0.04, 1.0);
uniform vec4 c_soot : source_color = vec4(0.04, 0.03, 0.035, 1.0);
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float energy = 1.2;
uniform float soot = 1.0;
uniform float bite = 1.0;      // quanto as mordidas em C cortam a borda
uniform float age_cool = 0.8;  // quanto a dissolução esfria o tom

varying vec4 vc;
varying vec2 vuv;

float hs(float n) {
	return fract(sin(n * 91.7 + seed * 37.13) * 43758.5453);
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

void vertex() {
	vc = COLOR;
	vuv = UV;
}

void fragment() {
	float a = abs(vuv.x - 0.5) * 2.0;     // 0 no eixo, 1 na borda
	float u = vc.r;                        // 0 base .. 1 ponta
	float dis = vc.b;
	float fps = mix(7.0, 13.0, hs(5.0));
	float spd = mix(0.7, 1.9, hs(6.0));
	float tq = floor(tt * fps) / fps;      // tempo em degraus: movimento de desenho à mão
	// mordidas em C: o ruído (preso à chama pela semente) corta a borda em línguas diferentes em cada chama
	float bn = vnoise(vec2(u * mix(2.5, 6.0, hs(10.0)) + seed * 3.1, tq * spd * 0.8 + seed));
	float cut = 1.0 - bite * 0.55 * smoothstep(0.35, 0.8, bn) * smoothstep(0.12, 0.35, u);
	if (a > cut) {
		discard;
	}
	float n = vnoise(vec2(vuv.x * 3.0 + seed * 5.0, u * 6.0 - tq * spd * 2.2));  // coordenada relativa: o padrão não estica quando a chama é grande
	float heat = pow(1.0 - a, 1.5) * 0.55 + (1.0 - u) * 0.45 + (n - 0.5) * 0.4 - dis * age_cool;
	vec3 col = c_soot.rgb;
	float alpha = 0.0;
	if (heat > 0.62) {
		col = c_yellow.rgb;
		alpha = 1.0;
	} else if (heat > 0.42) {
		col = c_orange.rgb;
		alpha = 1.0;
	} else if (heat > 0.26) {
		col = c_red.rgb;
		alpha = 0.97;
	} else if (heat > 0.12) {
		col = c_burnt.rgb;
		alpha = 0.86;
	} else if (heat > 0.0) {
		col = c_soot.rgb;
		alpha = 0.55 * soot;
	}
	alpha *= (1.0 - smoothstep(0.7, 1.0, dis)) * clamp(vc.g, 0.0, 1.0);
	if (alpha < 0.03) {
		discard;
	}
	ALBEDO = col * energy;
	ALPHA = alpha;
}
