shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Alpha is per-instance, and bounded by the authored low-opacity layer.
uniform float phase_time = 0.0;
varying vec4 tint;
varying float seed;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
void vertex() { tint = COLOR; seed = INSTANCE_CUSTOM.x; }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec2 drift = vec2(phase_time * 0.13, -phase_time * 0.09) + vec2(seed * 13.1);
	float n = noise2(p * 2.8 + drift) * 0.65 + noise2(p * 6.8 - drift) * 0.35;
	float soft = 1.0 - smoothstep(0.12, 1.0, length(p) + (n - 0.5) * 0.25);
	ALBEDO = tint.rgb * mix(0.70, 1.0, n);
	ALPHA = soft * smoothstep(0.12, 0.7, n) * tint.a;
}
