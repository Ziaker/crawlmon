shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled;
#include "res://shaders/mc_common.gdshaderinc"
// Motion Composer V1.2 (D-323): material ESTILIZADO para qualquer forma do compositor (tubo, fita, arco, casca, fragmentos).
// Bandas duras de cel-shading, mas com VOLUME: lado sombreado, rampa de 5 cores, gradiente por idade, erosão da silhueta,
// borda/espuma, ondulação de vértices e detalhe de textura que escorre. Opaco (alpha-test), sem ordenação, GL Compatibility.
// Tempo explícito `tt`. Vértice (MotionMesh / MotionShapes): COLOR r = cabeça 0..1, g = intensidade, b = dissolução, a = raio (m);
// UV.x através da forma, UV.y metros ao longo.

// --- rampa de cores: 0 = borda / frio / velho ... 4 = núcleo / quente / novo
uniform vec4 c0 : source_color = vec4(0.62, 0.1, 0.03, 1.0);
uniform vec4 c1 : source_color = vec4(0.93, 0.24, 0.04, 1.0);
uniform vec4 c2 : source_color = vec4(1.0, 0.5, 0.06, 1.0);
uniform vec4 c3 : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 c4 : source_color = vec4(1.0, 0.97, 0.72, 1.0);
// --- volume: o lado oposto à luz escurece em degraus; borda clara por cima
uniform vec3 light_dir = vec3(-0.4, 0.8, 0.45);   // direção PARA a luz, no mundo
uniform vec4 shade_tint : source_color = vec4(0.55, 0.42, 0.5, 1.0);
uniform float shade_amount = 0.0;                // 0 = sem lado sombreado
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float rim_amount = 0.0;                  // 0 = sem borda clara (espuma, crista, brilho de aresta)
uniform float rim_width = 0.28;
// --- forma do calor / tom
uniform float bands = 5.0;                       // quantos degraus de tom (cel)
uniform float core_sharp = 2.0;                  // quão estreito é o centro quente (frente ao observador)
uniform float noise_amp = 0.7;                   // quanto o ruído quebra as bandas
uniform float age_cool = 0.6;                    // quanto a idade (dissolução + cauda) esfria o tom
uniform float tail_age = 0.5;                    // peso da cauda (1 - cabeça) na idade
uniform float bias = 0.0;
// --- movimento do padrão
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float flow = 3.0;
uniform float noise_scale = 2.2;
uniform float swirl = 0.5;
uniform float detail_strength = 0.0;
uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
// --- deformação de vértices (fração do raio)
uniform float lick = 0.5;                        // silhueta empurrada por ruído
uniform float rise = 0.0;                        // a cauda solta sobe
uniform float wave_amp = 0.0;                    // ondulação ao longo da forma
uniform float wave_freq = 3.0;
uniform float wave_speed = 4.0;
uniform float pulse_amp = 0.0;                   // pulsação do raio
uniform float pulse_hz = 3.0;
// --- erosão
uniform float tail_erode = 0.5;
uniform float erode_edge = 0.07;
uniform vec4 erode_edge_color : source_color = vec4(0.4, 0.07, 0.02, 1.0);
uniform float intensity = 1.0;
// --- malhas sem cor de vértice (esfera de gota, etc.): 0 = usar estes valores no lugar da COLOR
uniform float use_vcolor = 1.0;
uniform float u_head = 0.9;
uniform float u_dissolve = 0.0;
uniform float u_radius = 0.2;

varying vec3 pcoord;
varying vec4 vc;
varying vec3 wnormal;

void vertex() {
	vc = use_vcolor > 0.5 ? COLOR : vec4(u_head, 1.0, u_dissolve, u_radius);
	pcoord = mc_pattern(UV.x, UV.y, noise_scale, swirl, flow, tt, seed);
	float n = mc_fbm3(pcoord * 1.3) - 0.45;
	float k = vc.a * (0.45 + 0.55 * (1.0 - vc.r));
	VERTEX += NORMAL * (n * lick * k);
	VERTEX.y += max(n, 0.0) * lick * k * rise * (1.0 - vc.r);
	VERTEX += NORMAL * (sin(UV.y * wave_freq - tt * wave_speed + seed) * wave_amp * vc.a);
	VERTEX += NORMAL * (sin(tt * pulse_hz * 6.2831853 + seed) * pulse_amp * vc.a);
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 vn = normalize(NORMAL);
	float ndv = abs(dot(vn, normalize(VIEW)));
	float n = mc_fbm3(pcoord * 1.6);
	float detail = detail_strength > 0.0 ? texture(detail_tex, vec2(UV.x * 2.0 + seed, UV.y * noise_scale * 0.5 - tt * flow * 0.15)).r : 0.5;
	float age = clamp(vc.b + (1.0 - vc.r) * tail_age, 0.0, 1.0);
	float heat = pow(ndv, core_sharp) * 0.95 + (n - 0.5) * noise_amp + (detail - 0.5) * detail_strength + vc.r * 0.1 - age * age_cool + bias;
	float e = mc_fbm3(pcoord * 2.3 + vec3(3.7, 1.9, 0.0));
	float cut = vc.b * 1.06 + pow(1.0 - vc.r, 2.2) * tail_erode * (0.35 + 0.65 * e);
	if (e < cut) {
		discard;
	}
	vec3 col = mc_ramp5(mc_band(heat, bands), c0.rgb, c1.rgb, c2.rgb, c3.rgb, c4.rgb);
	// volume: lado sombreado em dois degraus
	float lit = dot(normalize(wnormal), normalize(light_dir)) * 0.5 + 0.5;
	float shade = 1.0 - step(0.35, lit) * 0.5 - step(0.62, lit) * 0.5;
	col = mix(col, col * shade_tint.rgb, shade * shade_amount);
	// borda clara (espuma / crista / aresta)
	float rim = step(1.0 - rim_width, 1.0 - ndv);
	col = mix(col, rim_color.rgb, rim * rim_amount);
	// beira de erosão
	col = mix(col, erode_edge_color.rgb, step(e, cut + erode_edge));
	ALBEDO = col * intensity * vc.g;
	ALPHA = 1.0;
}
