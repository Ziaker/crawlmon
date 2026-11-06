shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.7 (D-332, atelier.html / Splitter Flames): o VÓRTICE DE FOGO do release, portado. Uma espiral achatada, parada na
// origem do tiro, que expande, gira e some suave em 0,30 s. A espiral, a máscara e a curva de opacidade (1 - p^1.4) são as do atelier;
// o ruído simplex foi trocado por ruído de valor com fbm (mais detalhe, mesmo visual). `progress` 0..1 vem do relógio do efeito.

uniform vec4 c_inner : source_color = vec4(1.0, 0.922, 0.231, 1.0);   // #ffeb3b
uniform vec4 c_outer : source_color = vec4(1.0, 0.239, 0.0, 1.0);     // #ff3d00
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;
uniform float energy = 1.75;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.6 + vnoise(p * 2.1 + 5.3) * 0.4;
}

void fragment() {
	vec2 v = UV * 2.0 - 1.0;
	float r = length(v);
	float a = atan(v.y, v.x);
	float spiral = sin(a * 6.0 - r * 10.0 + tt * 22.0);
	float mask = smoothstep(-0.2, 0.7, spiral);
	vec3 col = mix(c_outer.rgb, c_inner.rgb, mask * (1.0 - r * 0.4));
	float turb = (fbm(v * 4.0 + vec2(tt * 3.0, 0.0)) - 0.5) * 2.0;
	float alpha = (1.0 - pow(progress, 1.4)) * smoothstep(0.05, 0.6, mask + turb * 0.35) * smoothstep(0.15, 0.3, r) * (1.0 - smoothstep(0.65, 1.0, r));
	float detail = (fbm(v * vec2(4.0, 7.0) + vec2(0.0, tt * 0.7)) - 0.5) * 2.0;
	col *= 0.9 + 0.18 * detail;
	alpha *= 0.6 + 0.4 * smoothstep(-0.6, 0.4, detail);
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col * energy;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
