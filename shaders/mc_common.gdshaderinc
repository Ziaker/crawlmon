// Motion Composer V1.2 (D-323): funções compartilhadas pela biblioteca de materiais estilizados (mc_*).
// Ruído, bandas duras (cel), coordenada de padrão sem costura e ruído de erosão. Sem TIME: o tempo é sempre explícito.

float mc_hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float mc_vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(mc_hash31(i), mc_hash31(i + vec3(1, 0, 0)), f.x), mix(mc_hash31(i + vec3(0, 1, 0)), mc_hash31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(mc_hash31(i + vec3(0, 0, 1)), mc_hash31(i + vec3(1, 0, 1)), f.x), mix(mc_hash31(i + vec3(0, 1, 1)), mc_hash31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

float mc_fbm3(vec3 p) {
	return mc_vnoise3(p) * 0.6 + mc_vnoise3(p * 2.07 + 5.3) * 0.4;
}

// Quantiza `x` (0..1) em `steps` degraus duros (bandas de cel-shading).
float mc_band(float x, float steps) {
	return floor(clamp(x, 0.0, 0.9999) * steps) / max(steps - 1.0, 1.0);
}

// Cor de uma rampa de 5 paradas (0 = borda/frio ... 1 = núcleo/quente), com degraus duros.
vec3 mc_ramp5(float t, vec3 c0, vec3 c1, vec3 c2, vec3 c3, vec3 c4) {
	vec3 c = c0;
	c = mix(c, c1, step(0.16, t));
	c = mix(c, c2, step(0.36, t));
	c = mix(c, c3, step(0.6, t));
	c = mix(c, c4, step(0.82, t));
	return c;
}

// Coordenada de padrão cilíndrica (sem costura): `across` 0..1 dá a volta, `along` em metros escorre com o tempo.
vec3 mc_pattern(float across, float along_m, float density, float swirl, float flow, float tt, float seed) {
	float a = across * 6.2831853;
	float along = along_m * density;
	float tw = a + along * swirl;
	return vec3(cos(tw) * 0.9, sin(tw) * 0.9, along - tt * flow + seed);
}
