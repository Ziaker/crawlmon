shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque, shadows_disabled;
// Stylised (cel-shaded) fire on a real 3D mesh (sphere / spindle), D-236. Hard colour bands: pale-yellow core,
// yellow-orange, orange, red-orange edge. The silhouette licks upwards along the mesh's +Y with scrolling noise,
// like a drawn flame. `fade` eats it away with noise. Used by the bullet, the fire hand and the Splitter orbs.

uniform vec4 core : source_color = vec4(1.0, 0.97, 0.72, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.5, 0.06, 1.0);
uniform vec4 edge : source_color = vec4(0.93, 0.24, 0.04, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float flow = 3.0;
uniform float bias = 0.0;     // shifts the bands: negative = more orange, less pale core
uniform float lick = 0.22;   // how far the silhouette licks out along the mesh

varying vec3 lpos;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), f.x), mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), f.x), mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

float fbm3(vec3 p) {
	return vnoise3(p) * 0.6 + vnoise3(p * 2.1 + 5.3) * 0.4;
}

void vertex() {
	lpos = VERTEX;
	// flame licks: push the surface out (more towards +Y) with noise that streams along +Y
	float d = fbm3(VERTEX * 2.2 + vec3(seed, -tt * flow, seed * 0.5)) - 0.4;
	VERTEX += NORMAL * d * lick + vec3(0.0, max(NORMAL.y, 0.0) * d * lick * 1.6, 0.0);
}

void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float n = fbm3(lpos * 2.6 + vec3(seed, -tt * flow * 0.7, 0.0));
	float heat = ndv * 0.75 + (n - 0.5) * 0.7 + 0.12 + bias;
	float erode = fbm3(lpos * 3.0 + vec3(seed, 0.0, tt * 0.6));
	if (erode < fade * 1.05) {
		discard;
	}
	vec3 c = edge.rgb;
	c = mix(c, mid.rgb, step(0.22, heat));
	c = mix(c, hot.rgb, step(0.46, heat));
	c = mix(c, core.rgb, step(0.78, heat));
	ALBEDO = c * intensity;
	ALPHA = 1.0 - fade * 0.4;
}
