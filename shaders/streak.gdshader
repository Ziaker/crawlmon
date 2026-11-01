shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Speed streak on a QuadMesh whose local Y runs along the dash: tapered at both
// ends, hot white core, flickering edges. `progress` 0..1 fades it out.

uniform vec4 color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 2.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float taper = pow(sin(y * 3.14159265), 0.8);
	float flick = 0.75 + 0.25 * hash(vec2(floor(UV.y * 40.0), floor(TIME * 30.0)));
	float body = smoothstep(taper, taper * 0.15, x) * flick;
	float core = pow(smoothstep(taper * 0.45, 0.0, x), 2.0);
	float fade = 1.0 - smoothstep(0.1, 1.0, progress);
	ALBEDO = mix(color.rgb, vec3(1.0), core) * energy;
	ALPHA = clamp(body * fade, 0.0, 1.0);
}
