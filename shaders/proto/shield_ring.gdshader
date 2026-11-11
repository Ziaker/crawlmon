shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;

// Shield ring gauge: UV.x runs around the torus. The filled arc is bright blue.
// A highlight travels around the ring and the pulse flashes on value changes.
uniform float fill = 1.0;
uniform vec3 col_on : source_color = vec3(0.25, 0.72, 1.0);
uniform vec3 col_off : source_color = vec3(0.03, 0.10, 0.19);
uniform float pulse = 0.0;

void fragment() {
	float a = UV.x;
	vec3 c = a < fill ? col_on : col_off;
	float edge = smoothstep(fill - 0.018, fill, a) * (1.0 - smoothstep(fill, fill + 0.018, a));
	c += col_on * edge * 2.0;
	float glint = exp(-pow((a - fract(TIME * 0.30)) * 16.0, 2.0));
	c += col_on * glint * (a < fill ? 0.90 : 0.18);
	c += col_on * pulse * 0.55;
	ALBEDO = c;
	ALPHA = 1.0;
}
