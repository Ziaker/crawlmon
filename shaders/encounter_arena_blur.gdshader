shader_type canvas_item;
// D-1172: the live battle behind the falling shards. 10-tap radial blur, chromatic
// aberration and a tinted vignette, all fading out as the arena is revealed.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec3 u_primary_color : source_color = vec3(1.0);
uniform float u_blur_strength = 0.0;
uniform float u_chroma_shift = 0.0;
uniform float u_vignette_danger = 0.0;
uniform float u_amount = 0.0;  // 0 = untouched screen

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 rel = uv - vec2(0.5);
	float dist = length(rel);
	vec3 col = vec3(0.0);
	const int SAMPLES = 10;
	for (int i = 0; i < SAMPLES; i++) {
		float f = float(i) / float(SAMPLES - 1);
		vec2 sample_uv = vec2(0.5) + rel * (1.0 - f * u_blur_strength * 0.18);
		vec2 c_off = rel * (u_chroma_shift * 0.014 * f);
		col.r += texture(screen_tex, clamp(sample_uv + c_off, vec2(0.002), vec2(0.998))).r;
		col.g += texture(screen_tex, clamp(sample_uv, vec2(0.002), vec2(0.998))).g;
		col.b += texture(screen_tex, clamp(sample_uv - c_off, vec2(0.002), vec2(0.998))).b;
	}
	col /= float(SAMPLES);
	float vig = smoothstep(0.35, 0.85, dist);
	col = mix(col, u_primary_color * 0.35, vig * u_vignette_danger * u_amount);
	COLOR = vec4(col, 1.0);
}
