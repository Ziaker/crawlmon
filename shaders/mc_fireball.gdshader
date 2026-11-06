shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque, shadows_disabled;
// Motion Composer V1.7 (D-332, atelier.html / Splitter Flames): a BOLA DE FOGO do atelier, portada para o Godot. Esfera cuja
// superfície ondula por seno (deslocamento de vértice) e cuja cor vem do fresnel: núcleo claro, miolo laranja, borda laranja-escura.
// Melhoria sem mudar o visual: `bands` > 0 quantiza o tom em degraus (cel-shading do jogo); `flicker` dá uma pulsação própria.
// Tempo explícito `tt` (D-019).

uniform vec4 c_core : source_color = vec4(1.0, 0.984, 0.922, 1.0);   // #fffbeb
uniform vec4 c_mid : source_color = vec4(1.0, 0.596, 0.0, 1.0);      // #ff9800
uniform vec4 c_rim : source_color = vec4(0.902, 0.318, 0.0, 1.0);    // #e65100
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float energy = 1.65;
uniform float bands = 0.0;
uniform float wobble = 0.19;      // deslocamento do vértice (fração do raio); o atelier usa 0.08 / 0.42

varying float vn;

void vertex() {
	vec3 p = VERTEX * 0.84;   // o raio do atelier é 0.42; a malha do Godot tem raio 0.5
	float n = sin(p.x * 6.0 + tt * 14.0 + seed) * cos(p.y * 6.0 - tt * 12.0 + seed);
	vn = n;
	VERTEX += NORMAL * (n * wobble * 0.5);
}

void fragment() {
	float fres = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float t = clamp(fres * 1.3 + vn * 0.3, 0.0, 1.0);
	if (bands > 0.5) {
		t = floor(t * bands) / bands;
	}
	vec3 col = mix(c_core.rgb, c_mid.rgb, t);
	col = mix(col, c_rim.rgb, pow(fres, 2.0));
	ALBEDO = col * energy;
	ALPHA = 0.96;
}
