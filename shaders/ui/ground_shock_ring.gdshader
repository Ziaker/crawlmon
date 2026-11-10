shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// D-418: Planar ground shock ring for Dragon Ball celebration.
// Expanding concentric circle on floor plane (QuadMesh facing up, Y = 0.02).

uniform vec4 ring_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform float ring_radius : hint_range(0.0, 1.0) = 0.0;
uniform float ring_thickness : hint_range(0.001, 0.2) = 0.035;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	// Radius maps 0.0..1.0 to 0.0..0.48 UV distance
	float target_r = ring_radius * 0.48;
	float diff = abs(dist - target_r);
	float ring = 1.0 - smoothstep(0.0, ring_thickness, diff);

	ALBEDO = ring_color.rgb;
	ALPHA = clamp(ring * opacity * ring_color.a, 0.0, 1.0);
}
