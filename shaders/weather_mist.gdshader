shader_type canvas_item;
render_mode blend_mix, unshaded;

// Névoa de clima (D-381/D-382/D-383), densidade maior em D-385: bancos largos,
// véu base mais forte e borda fechada para piorar a leitura visual. Continua
// sendo uma camada 2D de ambiente, fora do Motion Composer.
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 mist_color : source_color = vec4(0.72, 0.78, 0.84, 1.0);
uniform float mist : hint_range(0.0, 1.0) = 0.0;
uniform float max_alpha : hint_range(0.0, 0.8) = 0.40;
uniform float density : hint_range(0.0, 1.0) = 0.85;
uniform float drift : hint_range(0.0, 0.02) = 0.006;
uniform float noise_scale : hint_range(0.5, 8.0) = 1.7;
uniform float edge_mist : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 uv = UV;
	float n1 = texture(noise_tex, uv * noise_scale + vec2(TIME * drift, TIME * drift * 0.6)).r;
	float n2 = texture(noise_tex, uv * noise_scale * 1.8 - vec2(TIME * drift * 0.8, TIME * drift * 0.4)).r;
	float veil = smoothstep(0.18, 0.82, n1 * 0.55 + n2 * 0.45);
	float d = distance(uv, vec2(0.5));
	float edge = smoothstep(0.24, 0.80, d) * edge_mist;
	float base = mix(1.0 - density * 0.65, 1.0, veil);
	float a = mist * max_alpha * (base + edge);
	COLOR = vec4(mist_color.rgb, clamp(a, 0.0, 1.0));
}
