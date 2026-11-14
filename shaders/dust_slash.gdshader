shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
// Corte em faixa do release do Sand Attack (D-1196), etéreo: a faixa é varrida em u_sweep segundos e
// cada ponto, depois de nascer, perde opacidade e se desfaz em grãos durante u_life segundos.
uniform float u_age = 0.0;
uniform float u_sweep = 0.35;
uniform float u_life = 0.7;
uniform float u_drift = 1.5;  // metros que a dissipação avança para a frente (eixo local +Z)
uniform vec4 u_core : source_color = vec4(1.0, 0.95, 0.2, 1.0);
uniform vec4 u_edge : source_color = vec4(1.0, 0.82, 0.05, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	float age_v = u_age - UV.x * u_sweep;
	float kv = clamp(age_v / u_life, 0.0, 1.0);
	VERTEX += vec3(0.0, 0.0, 1.0) * u_drift * kv;
}

void fragment() {
	float along = UV.x;
	float across = abs(UV.y - 0.5) * 2.0;
	float age = u_age - along * u_sweep;
	float born = smoothstep(0.0, 0.05, age);
	float k = clamp(age / u_life, 0.0, 1.0);
	float fade = 1.0 - k;
	float grain = vnoise(vec2(along * 30.0, UV.y * 12.0 + u_age * 3.0)) * 0.6 + hash(floor(vec2(along * 90.0, UV.y * 30.0))) * 0.4;
	float dissolve = smoothstep(k * 1.1 - 0.15, k * 1.1, grain + 0.0) ;
	float body = 1.0 - smoothstep(0.55, 1.0, across + k * 0.25);
	ALBEDO = mix(u_core.rgb, u_edge.rgb, smoothstep(0.2, 1.0, across));
	ALPHA = 0.8075 * born * fade * dissolve * body;
}
