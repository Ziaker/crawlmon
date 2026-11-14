shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
// Faixa de vento no chão do Sand Attack (D-1196): rastro de queimado que nasce junto com o jato
// e perde opacidade ao longo do trajeto (mais velho = mais apagado).
uniform float u_age = 0.0;      // segundos desde o release
uniform float u_travel = 0.92;  // tempo que o jato leva do atacante ao alvo
uniform float u_life = 1.4;     // tempo que cada ponto do rastro leva para sumir
uniform float u_max_alpha = 0.8;
uniform vec4 u_color : source_color = vec4(0.62, 0.40, 0.16, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float along = UV.y;
	float across = abs(UV.x - 0.5) * 2.0;
	float age = u_age - along * u_travel;
	float born = smoothstep(0.0, 0.06, age);
	float fade = 1.0 - smoothstep(0.0, u_life, age);
	float rough = vnoise(vec2(UV.x * 9.0, along * 40.0 - u_age * 1.5));
	float edge = 1.0 - smoothstep(0.5, 1.0, across + (rough - 0.5) * 0.45);
	float streak = 0.45 + 0.55 * vnoise(vec2(UV.x * 22.0, along * 120.0));
	ALBEDO = u_color.rgb;
	ALPHA = u_max_alpha * born * fade * edge * streak;
}
