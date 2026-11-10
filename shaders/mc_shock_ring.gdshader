shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// D-377: anel de choque da Drain Spear. Mesmo desenho de arcos do fire_ring, mas em ciano/branco (não é fogo).
// Fica num quad virado para a câmera; `fade` apaga, `intensity` brilha, `thick` controla a espessura.

uniform vec4 core_col : source_color = vec4(0.85, 1.0, 1.0, 1.0);
uniform vec4 edge_col : source_color = vec4(0.18, 0.72, 1.0, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float thick = 0.06;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float dashes = 22.0;

float hash11(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
	float seg = floor(ang * dashes + seed);
	float on = step(0.25, hash11(seg + seed));
	float within = fract(ang * dashes + seed);
	float dash = smoothstep(0.0, 0.10, within) * smoothstep(1.0, 0.55, within);
	float line = 1.0 - smoothstep(thick * 0.55, thick, abs(r - 0.78 - (hash11(seg) - 0.5) * 0.05));
	float a = line * dash * on * (1.0 - fade);
	if (a < 0.03) {
		discard;
	}
	vec3 c = mix(edge_col.rgb, core_col.rgb, hash11(seg * 3.1 + seed));
	ALBEDO = c * intensity;
	ALPHA = a;
}
