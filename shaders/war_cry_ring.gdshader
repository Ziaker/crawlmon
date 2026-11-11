shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// D-1106: War Cry pressure ring. Torus UV.x runs around the ring, UV.y around the tube.
// The tube centre is white-hot; the rim breaks into angular noise (sonic pressure).

uniform vec4 ring_color : source_color = vec4(1.0, 0.12, 0.08, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.82, 0.70, 1.0);
uniform float alpha = 1.0;
uniform float energy = 2.0;
uniform float noise_amount = 0.35;
uniform float seed = 0.0;

float hash11(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	float n = hash11(floor(UV.x * 64.0) + seed);
	float breakup = mix(1.0, 0.45 + 0.55 * n, noise_amount);
	float tube = 1.0 - abs(UV.y * 2.0 - 1.0);
	tube = smoothstep(0.0, 0.55, tube);
	float a = alpha * tube * breakup;
	if (a < 0.02) {
		discard;
	}
	vec3 c = mix(ring_color.rgb, core_color.rgb, tube * 0.78);
	ALBEDO = c * energy;
	ALPHA = a;
}
