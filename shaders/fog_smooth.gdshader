shader_type canvas_item;
render_mode blend_mix;

// Névoa contínua sobre a máscara de visibilidade. O domain warp com duas
// camadas de ruído quebra a borda do tile: o limite vira uma linha orgânica,
// com névoa azul-escura em movimento em vez de bloco preto.
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 fog_color : source_color = vec4(0.035, 0.055, 0.085, 1.0);
uniform float warp : hint_range(0.0, 0.2) = 0.04;
uniform float density : hint_range(0.0, 1.0) = 0.86;
uniform float drift : hint_range(0.0, 0.02) = 0.004;
uniform float dither_strength : hint_range(0.0, 0.05) = 0.008;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 n1 = texture(noise_tex, uv * 2.2 + vec2(TIME * drift, TIME * drift * 0.7)).rg;
	vec2 n2 = texture(noise_tex, uv * 4.7 - vec2(TIME * drift * 0.6, TIME * drift * 0.9)).rg;
	vec2 warped = clamp(uv + (n1 - 0.5) * warp + (n2 - 0.5) * warp * 0.55,
		vec2(0.001), vec2(0.999));
	float mask = texture(TEXTURE, warped).a;
	float fog = smoothstep(0.15, 0.85, mask);
	float pattern = 0.85 + 0.15 * n1.r;
	float a = fog * density;
	a += (hash(FRAGCOORD.xy) - 0.5) * dither_strength;
	COLOR = vec4(fog_color.rgb * pattern, clamp(a, 0.0, 1.0));
}
