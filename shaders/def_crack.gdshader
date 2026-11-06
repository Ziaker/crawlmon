shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;
// Cracks over a model with lowered defense (D-167), used as a pass after its outline.
// `amount` 0..1 opens more cells of a Voronoi pattern over the model's UVs.

uniform vec4 color : source_color = vec4(0.13, 0.02, 0.03, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float density = 14.0;

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * density;
	vec2 cell = floor(uv);
	vec2 local = fract(uv);
	float first = 8.0;
	float second = 8.0;
	vec2 owner = cell;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 n = vec2(float(x), float(y));
			float d = length(n + hash2(cell + n) - local);
			if (d < first) {
				second = first;
				first = d;
				owner = cell + n;
			} else if (d < second) {
				second = d;
			}
		}
	}
	float line = 1.0 - smoothstep(0.015, 0.06, second - first);
	float open = step(hash2(owner).x, amount);
	ALBEDO = color.rgb;
	ALPHA = line * open * 0.85;
}
