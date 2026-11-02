shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Comic halftone burst (ZZZ-style hit dots): dots shrink towards the rim.
uniform vec3 col : source_color = vec3(0.72, 0.4, 1.0);
uniform float dots = 16.0;
uniform float fade = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 cell = fract(UV * dots) - 0.5;
	float size = (1.0 - r) * 0.62;
	float m = step(length(cell), size) * step(r, 1.0);
	ALBEDO = col * 1.4;
	ALPHA = m * fade;
}
