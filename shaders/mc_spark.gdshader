shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.2 (D-323): fagulha / brasa / gota brilhante. Núcleo quente pequeno dentro de um halo, esticado ao longo do
// movimento na tela (uma faísca que viaja, não um disco). Quad voltado para a câmera; `fade` esfria e apaga.

uniform vec4 hot : source_color = vec4(1.0, 0.85, 0.45, 1.0);
uniform vec4 cool : source_color = vec4(1.0, 0.28, 0.05, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float stretch = 1.0;   // 1 = redonda; >1 = longa ao longo do Y local do quad
uniform float roll = 0.0;
uniform float energy = 2.0;
uniform float flicker_seed = 0.0;
uniform float tt = 0.0;
uniform float hard = 0.0;      // 0 = brilho suave; 1 = discos duros (estilo cel)

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * (VERTEX.xy * vec2(1.0, stretch));
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y /= stretch;
	float r = length(p);
	float core = pow(clamp(1.0 - r * 2.2, 0.0, 1.0), 2.0);
	float halo = pow(clamp(1.0 - r, 0.0, 1.0), 2.6);
	core = mix(core, step(r, 0.28), hard);
	halo = mix(halo, step(r, 0.7) * 0.8, hard);
	float flick = 0.85 + 0.15 * sin(tt * 37.0 + flicker_seed * 13.0);
	vec3 col = cool.rgb * halo + hot.rgb * core * 1.6;
	float a = clamp(halo + core, 0.0, 1.0) * (1.0 - fade) * flick;
	if (a < 0.01) {
		discard;
	}
	ALBEDO = col * energy * (1.0 - fade);
	ALPHA = a;
}
