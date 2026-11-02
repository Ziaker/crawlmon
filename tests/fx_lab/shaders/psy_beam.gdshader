shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// EarthBound-style PSI beam: hard colour bands that scroll along the beam, a white-hot core.
uniform float speed = 1.8;
uniform float stripes = 10.0;
uniform float pulse = 0.0;
uniform float intensity = 1.7;
uniform float fade = 1.0;

const vec3 COLS[6] = vec3[](
	vec3(1.0, 0.18, 0.62), vec3(1.0, 0.55, 0.1), vec3(1.0, 0.95, 0.2),
	vec3(0.2, 1.0, 0.45), vec3(0.15, 0.85, 1.0), vec3(0.62, 0.35, 1.0));

void fragment() {
	float along = UV.x * stripes - TIME * speed;
	float edge = abs(UV.y - 0.5) * 2.0;
	float band = floor(along + UV.y * 1.4 + 100.0);
	vec3 c = COLS[int(mod(band, 6.0))];
	float wobble = pulse * 0.12 * sin(along * 3.0);
	float mask = smoothstep(1.0, 0.78, edge + wobble);
	float core = smoothstep(0.34, 0.0, edge);
	ALBEDO = mix(c, vec3(1.0), core) * intensity;
	ALPHA = mask * smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x) * fade;
}
