shader_type canvas_item;
render_mode blend_mix;

// Névoa contínua sobre a máscara de visibilidade. O domain warp quebra a borda
// do tile; a cor esquerda/direita e o tipo de ruído mudam por bioma (D-360).
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 fog_color : source_color = vec4(0.035, 0.055, 0.085, 1.0);
uniform vec4 fog_color_b : source_color = vec4(0.100, 0.160, 0.260, 1.0);
uniform float side_mix : hint_range(0.0, 1.0) = 0.85;
uniform float warp : hint_range(0.0, 0.2) = 0.04;
uniform float density : hint_range(0.0, 1.0) = 0.86;
uniform float drift : hint_range(0.0, 0.02) = 0.004;
uniform float dither_strength : hint_range(0.0, 0.05) = 0.008;
uniform float noise_scale : hint_range(0.5, 8.0) = 2.2;
uniform float noise_scale_b : hint_range(0.5, 12.0) = 4.7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 n1 = texture(noise_tex, uv * noise_scale + vec2(TIME * drift, TIME * drift * 0.7)).rg;
	vec2 n2 = texture(noise_tex, uv * noise_scale_b - vec2(TIME * drift * 0.6, TIME * drift * 0.9)).rg;
	vec2 warped = clamp(uv + (n1 - 0.5) * warp + (n2 - 0.5) * warp * 0.55,
		vec2(0.001), vec2(0.999));
	float mask = texture(TEXTURE, warped).a;
	float fog = smoothstep(0.15, 0.85, mask);
	float pattern = 0.85 + 0.15 * n1.r;
	float a = fog * density;
	a += (hash(FRAGCOORD.xy) - 0.5) * dither_strength;
	float side = smoothstep(0.15, 0.85, uv.x);
	float t = mix(0.5, side, side_mix);
	vec3 base = mix(fog_color.rgb, fog_color_b.rgb, t);
	COLOR = vec4(base * pattern, clamp(a, 0.0, 1.0));
}
