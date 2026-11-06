shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.5 (D-332): UMA chama, com ciclo de vida. Aprendido de tutoriais de fogo estilizado (vfxapprentice "how to draw
// stylized fire", Mirza Beig, partículas procedurais do godotshaders): (1) cada chama nasce de uma SEMENTE nova a cada ciclo e tem
// forma própria: curva em S (rumo do vento), base grossa e pontas finas, MORDIDAS em C no contorno que viram línguas, balanço e
// ponta em gancho diferentes; (2) o tempo é QUANTIZADO (7 a 13 quadros por segundo, diferente em cada chama): movimento de
// desenho à mão; (3) a cor depende da IDADE: amarelo, laranja, vermelho, vermelho queimado e preto de fuligem; (4) a chama cresce,
// sobe e encolhe/se apaga pelas pontas. `age` 0..1 é o ciclo de vida inteiro; `tt` explícito (D-019).

uniform vec4 c_yellow : source_color = vec4(1.0, 0.9, 0.42, 1.0);
uniform vec4 c_orange : source_color = vec4(1.0, 0.52, 0.07, 1.0);
uniform vec4 c_red : source_color = vec4(0.86, 0.16, 0.04, 1.0);
uniform vec4 c_burnt : source_color = vec4(0.36, 0.07, 0.04, 1.0);
uniform vec4 c_soot : source_color = vec4(0.04, 0.03, 0.035, 1.0);
uniform float age : hint_range(0.0, 1.0) = 0.3;
uniform float seed = 0.0;
uniform float tt = 0.0;
uniform float energy = 1.2;
uniform float soot = 1.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (VERTEX.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (VERTEX.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

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

// linha central: curva em S + ponta em gancho
float cx(float u, float lean, float swf, float ph, float amp, float hook) {
	return lean * u * u + sin(u * swf + ph) * amp * u + sign(lean) * hook * pow(u, 4.0);
}

// meia largura: base redonda e grossa, afina até a ponta
float hw(float u, float W, float g) {
	float rb = u < 0.2 ? sqrt(max(1.0 - pow(1.0 - u / 0.2, 2.0), 0.0)) : 1.0;
	return W * g * pow(max(1.0 - u, 0.0), 0.72) * rb;
}

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * 2.0, 1.0 - UV.y);
	// --- identidade desta chama (muda a cada ciclo, pois a semente muda)
	float H = mix(0.6, 0.98, hs(1.0));
	float W = mix(0.3, 0.55, hs(2.0));
	float lean = (hs(3.0) - 0.5) * 1.0;
	float swf = mix(2.0, 6.0, hs(4.0));
	float fps = mix(7.0, 13.0, hs(5.0));
	float spd = mix(0.7, 1.9, hs(6.0));
	float amp = mix(0.04, 0.16, hs(8.0));
	float hook = mix(0.0, 0.3, hs(9.0));
	float tq = floor(tt * fps) / fps;   // tempo em degraus: movimento de desenho à mão
	float ph = tq * spd * 3.0 + hs(7.0) * 6.2831853;
	// --- ciclo de vida: cresce, sobe (feito fora), encolhe e se apaga
	float g = smoothstep(0.0, 0.16, age) * (1.0 - 0.7 * smoothstep(0.5, 1.0, age));
	float h = max(H * g, 0.001);
	float u = clamp(p.y / h, 0.0, 1.0);
	float xc = cx(u, lean, swf, ph, amp, hook);
	float w = hw(u, W, g);
	float d = max(max(abs(p.x - xc) - w, (p.y - h) * 0.5), -p.y);
	// --- mordidas em C no contorno: cortam a chama em línguas diferentes em cada uma
	float nb = 1.0 + floor(hs(10.0) * 3.0);
	for (int k = 0; k < 3; k++) {
		if (float(k) >= nb) {
			break;
		}
		float fk = float(k);
		float uk = 0.3 + 0.5 * hs(11.0 + fk);
		float sk = hs(14.0 + fk) > 0.5 ? 1.0 : -1.0;
		vec2 c = vec2(cx(uk, lean, swf, ph, amp, hook) + sk * hw(uk, W, g) * 1.02, uk * h);
		float rk = W * g * mix(0.2, 0.42, hs(17.0 + fk));
		d = max(d, rk - length(p - c));
	}
	float aa = max(fwidth(d), 0.0006);
	float cover = smoothstep(aa, -aa, d);
	if (cover < 0.02) {
		discard;
	}
	// --- calor: centro quente, esfria com a altura e com a IDADE; o ruído (em degraus de tempo) quebra as faixas
	float a_in = 1.0 - clamp(abs(p.x - xc) / max(w, 0.001), 0.0, 1.0);
	float n = vnoise(vec2(p.x * 3.0 + seed * 5.0, p.y * 3.2 - tq * spd * 2.2));
	float heat = pow(a_in, 1.5) * 0.55 + (1.0 - u) * 0.42 + (n - 0.5) * 0.4 - age * 0.78 + 0.0;
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
	alpha *= cover * (1.0 - smoothstep(0.82, 1.0, age));
	if (alpha < 0.03) {
		discard;
	}
	ALBEDO = col * energy;
	ALPHA = alpha;
}
