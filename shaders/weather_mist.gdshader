shader_type canvas_item;
render_mode blend_mix, unshaded;

// Névoa de clima (D-381/D-382/D-383): véu 2D de ambiente, sem Motion Composer.
// Fica acima do mapa/névoa de guerra e abaixo da vinheta/UI. `mist` é animado
// de 0 a 1 pelo WeatherController; `noise_tex` reusa o ruído do bioma.
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 mist_color : source_color = vec4(0.72, 0.78, 0.84, 1.0);
uniform float mist : hint_range(0.0, 1.0) = 0.0;
uniform float max_alpha : hint_range(0.0, 0.5) = 0.22;
uniform float density : hint_range(0.0, 1.0) = 0.65;
uniform float drift : hint_range(0.0, 0.02) = 0.006;
uniform float noise_scale : hint_range(0.5, 8.0) = 2.6;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = UV;
	float n1 = texture(noise_tex, uv * noise_scale + vec2(TIME * drift, TIME * drift * 0.6)).r;
	float n2 = texture(noise_tex, uv * noise_scale * 2.1 - vec2(TIME * drift * 0.8, TIME * drift * 0.4)).r;
	float veil = smoothstep(0.20, 0.85, n1 * 0.65 + n2 * 0.35);
	float d = distance(uv, vec2(0.5));
	float vig = 1.0 - smoothstep(0.28, 0.78, d) * vignette_strength;
	float a = mist * max_alpha * mix(1.0, veil, density) * vig;
	COLOR = vec4(mist_color.rgb, clamp(a, 0.0, 1.0));
}
