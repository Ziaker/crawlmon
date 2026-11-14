shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0);
uniform float alpha = 1.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float arm = abs(sin(a * 3.0));
	float shape = (1.0 - smoothstep(0.05, 0.20, arm * max(r, 0.1))) * (1.0 - smoothstep(0.4, 0.9, r));
	ALBEDO = tint.rgb * color.rgb;
	ALPHA = shape * tint.a * alpha;
}
