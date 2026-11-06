shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.3 (D-332): chama estilizada de CONTORNO NÍTIDO (referências: Persona, Genshin Impact, Pokémon). Um quad voltado
// para a câmera onde a chama é desenhada por funções de distância: um feixe de línguas pontudas que balançam e se curvam, em
// 3 camadas de cor CHAPADA (casca, miolo, núcleo) e um contorno escuro e grosso. Sem ruído de textura: a forma é gráfica,
// legível de longe. O movimento é PERIÓDICO em `phase` (0..1 = um ciclo): serve ao vivo e para assar um flipbook que repete
// sem salto. Tempo explícito, nunca TIME (D-019). `fade` 0..1 encolhe as línguas pelas pontas até sumir.

uniform vec4 c_outline : source_color = vec4(0.42, 0.06, 0.04, 1.0);
uniform vec4 c_outer : source_color = vec4(0.95, 0.22, 0.05, 1.0);
uniform vec4 c_mid : source_color = vec4(1.0, 0.55, 0.08, 1.0);
uniform vec4 c_core : source_color = vec4(1.0, 0.93, 0.5, 1.0);
uniform float phase = 0.0;          // 0..1 = um ciclo de balanço (periódico)
uniform float seed = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float outline = 0.045;      // espessura do contorno (fração da largura do quad)
uniform float tongues = 5.0;        // 3..5 línguas
uniform float sway = 1.0;           // quanto as línguas balançam
uniform float gradient = 0.18;      // clareia o miolo para baixo (0 = totalmente chapado)
uniform float energy = 1.25;
uniform float roll = 0.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

float h1(float n) {
	return fract(sin(n * 127.1 + seed * 17.3) * 43758.5453);
}

// distância assinada (negativa dentro) do feixe de línguas; ws/hs encolhem as línguas para as camadas internas.
// Cada língua é uma gota de chama: base redonda, barriga larga e ponta fina que se curva.
float flame_d(vec2 p, float ws, float hs) {
	float d = 1.0;
	float f = 1.0 - fade;
	for (int i = 0; i < 5; i++) {
		if (float(i) >= tongues) {
			break;
		}
		float fi = float(i);
		float side = (i % 2 == 1) ? -1.0 : 1.0;
		float outer = i >= 3 ? 1.0 : 0.0;
		float x0 = i == 0 ? 0.0 : side * (0.2 + 0.1 * outer + 0.16 * h1(fi + 1.0));
		float h = (i == 0 ? 0.94 : (0.64 - 0.2 * outer) + 0.16 * h1(fi + 9.0)) * hs * (1.0 - 0.55 * fade);
		float w = (i == 0 ? 0.32 : 0.23 - 0.03 * outer + 0.05 * h1(fi + 3.0)) * ws * f;
		float amp = (0.04 + 0.05 * h1(fi + 5.0)) * sway;
		float k = 1.0 + floor(h1(fi + 11.0) * 3.0);
		float curl = i == 0 ? (h1(21.0) - 0.5) * 0.3 : sign(x0) * (0.1 + 0.2 * h1(fi + 7.0));
		float u = clamp(p.y / max(h, 0.001), 0.0, 1.0);
		float center = x0 + amp * sin(6.2831853 * (phase * k + h1(fi + 13.0))) * pow(u, 1.2) + curl * u * u * u;
		float round_base = u < 0.2 ? sqrt(max(1.0 - pow(1.0 - u / 0.2, 2.0), 0.0)) : 1.0;
		float hw = w * pow(1.0 - u, 0.72) * round_base;
		float di = max(max(abs(p.x - center) - hw, (p.y - h) * 0.5), -p.y);
		d = min(d, di);
	}
	return d;
}

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * 2.0, (1.0 - UV.y) * 1.08 - 0.04);
	p.x *= 1.0;
	float d0 = flame_d(p, 1.0, 1.0);
	float aa = max(fwidth(d0), 0.0008);
	float cover = smoothstep(aa, -aa, d0);
	if (cover < 0.01) {
		discard;
	}
	float d1 = flame_d(p, 0.62, 0.8);
	float d2 = flame_d(p, 0.32, 0.58);
	vec3 col = c_outline.rgb;
	col = mix(col, c_outer.rgb, smoothstep(aa, -aa, d0 + outline));
	col = mix(col, c_mid.rgb, smoothstep(aa, -aa, d1));
	col = mix(col, c_core.rgb, smoothstep(aa, -aa, d2));
	// um leve gradiente: mais claro perto da base de cada camada (sem perder o aspecto chapado)
	col = mix(col, vec3(1.0, 0.95, 0.7), gradient * (1.0 - clamp(p.y, 0.0, 1.0)) * (1.0 - smoothstep(aa, -aa, d0 + outline)) * 0.0);
	col += gradient * (1.0 - clamp(p.y * 1.1, 0.0, 1.0)) * vec3(0.12, 0.08, 0.0) * smoothstep(aa, -aa, d1);
	ALBEDO = col * energy;
	ALPHA = cover;
}
