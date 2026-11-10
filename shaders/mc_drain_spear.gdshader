shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
// D-377 / V1.10: lança mágica da Drain Spear. O comprimento local é 0..1 (UV.y); `reveal` cresce do cabo à ponta e
// `dissolve` apaga do cabo à ponta. Núcleo azul-cobalto com ponta ciano/branca, facetas duras e halo de borda. O
// tamanho em metros vem do pincel (MotionPainter.spear); o efeito não depende de personagem, time, lado nem câmera.

uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float energy = 2.0;
uniform vec4 tint : source_color = vec4(0.20, 0.62, 1.0, 1.0);
uniform vec4 tip_color : source_color = vec4(0.48, 0.92, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.62, 0.96, 1.0, 1.0);
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float rim = 1.0;
uniform float reveal_soft = 0.018;
uniform float dissolve_soft = 0.018;

void fragment() {
	float y = clamp(UV.y, 0.0, 1.0);
	float ripple = sin(y * 43.0 + UV.x * 31.0 - tt * 9.0 + seed * 0.37) * 0.005;
	float cut = y + ripple;
	if (cut > reveal) {
		discard;
	}
	if (cut < dissolve) {
		discard;
	}
	float blade = smoothstep(0.60, 0.675, y);
	float tip = smoothstep(0.70, 0.99, y);
	// Facetas duras: 8 bandas ao redor do eixo, alternando claro/escuro. O núcleo é escuro e a borda acende.
	float band = mod(floor(UV.x * 8.0), 2.0);
	float facet = mix(0.58, 1.22, band);
	float ridge = pow(1.0 - abs(fract(UV.x * 2.0) - 0.5) * 2.0, 7.0);
	float flow = 0.5 + 0.5 * sin(y * 78.0 - tt * 17.0 + UV.x * 19.0 + seed);
	vec3 deep = vec3(0.006, 0.035, 0.20);
	vec3 mid = vec3(0.035, 0.40, 0.98);
	vec3 hi = tip_color.rgb;
	vec3 shaft = mix(deep, mid, smoothstep(0.0, 0.62, y));
	shaft *= facet;
	shaft += edge_color.rgb * ridge * (0.18 + 0.30 * blade);
	shaft += edge_color.rgb * flow * 0.055;
	vec3 col = mix(shaft, hi, blade);
	col += edge_color.rgb * ridge * tip * 0.45;
	float edge_reveal = 1.0 - smoothstep(0.0, reveal_soft, reveal - cut);
	float edge_dissolve = 1.0 - smoothstep(0.0, dissolve_soft, cut - dissolve);
	float edge = max(edge_reveal * step(0.0005, reveal), edge_dissolve * step(0.0005, dissolve));
	col += edge_color.rgb * edge * 2.1;
	float fres = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 2.2);
	col += tint.rgb * fres * rim;
	float pulse = 0.92 + 0.08 * sin(tt * 13.0 + seed * 0.7);
	ALBEDO = col * energy * pulse;
	ALPHA = clamp(opacity * (0.88 + 0.12 * fres + 0.18 * edge), 0.0, 1.0);
}
