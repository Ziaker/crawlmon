shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.7 (D-332, atelier.html / Splitter Flames): o PILAR DE FOGO do impacto, portado. Cilindro aberto (1,1 a 1,45 m de
// raio, 6,8 m de altura) cujo fogo sobe em listras, com fresnel, e que esfria para cinza escuro nos últimos 35% da vida. A faixa de
// listras, o gradiente e o envelope sin(pi p) são os do atelier; o ruído simplex virou fbm. `progress` 0..1 vem do relógio do efeito.

uniform vec4 c_bottom : source_color = vec4(1.0, 0.922, 0.231, 1.0);  // #ffeb3b
uniform vec4 c_mid : source_color = vec4(1.0, 0.341, 0.133, 1.0);     // #ff5722
uniform vec4 c_ash : source_color = vec4(0.153, 0.153, 0.165, 1.0);   // #27272a
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float tt = 0.0;
uniform float energy = 1.6;

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
	float h = 1.0 - UV.y;   // 0 na base, 1 no topo (o cilindro do Godot tem v = 0 no topo)
	float vfade = pow(1.0 - h, 1.35) * smoothstep(0.0, 0.08, h);
	float fres = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float flames = 0.5 + 0.5 * sin(UV.x * 31.415 + tt * 14.0 - h * 12.0);
	vec3 fire = mix(c_bottom.rgb, c_mid.rgb, h * 0.8 + (1.0 - flames) * 0.3);
	vec3 col = mix(fire * energy, c_ash.rgb, smoothstep(0.6, 0.95, progress));
	float env = sin(progress * 3.14159);
	float alpha = vfade * fres * flames * env * 1.3;
	float detail = (fbm(vec2(UV.x * 4.0, h * 7.0) + vec2(0.0, tt * 0.7)) - 0.5) * 2.0;
	col *= 0.9 + 0.18 * detail;
	alpha *= 0.6 + 0.4 * smoothstep(-0.6, 0.4, detail);
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
