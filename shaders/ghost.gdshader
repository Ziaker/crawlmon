shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
// Holographic afterimage: flat tint with a bright fresnel rim. Applied to a
// duplicate of a character model; `alpha` fades it out.

uniform vec4 color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float rim_power = 2.2;

void fragment() {
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	ALBEDO = color.rgb * (0.3 + f * 1.6);
	ALPHA = alpha * (0.25 + f);
}
