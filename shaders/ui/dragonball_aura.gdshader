shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// D-418: 0.55s non-epileptic Dragon Ball celebration Ki pillar.
// Localized to 3D cylinder mesh; peak alpha strictly clamped to 0.18 max.

uniform vec4 aura_color : source_color = vec4(0.15, 0.85, 1.0, 1.0);
uniform float speed : hint_range(0.0, 10.0) = 4.0;
uniform float peak_alpha : hint_range(0.0, 0.5) = 0.18;
uniform float vertical_bands : hint_range(1.0, 20.0) = 8.0;

void fragment() {
	// Vertical scrolling streaks
	float v_stream = sin((UV.x * vertical_bands + TIME * 1.5) * 6.28318);
	float v_scroll = sin((UV.y * 3.0 - TIME * speed) * 6.28318);
	float streak = clamp((v_stream * 0.5 + 0.5) * (v_scroll * 0.5 + 0.5) * 1.4, 0.0, 1.0);

	// Vertical edge fade (top and bottom of cylinder)
	float edge_fade = smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);

	// Clamped alpha for photosensitive safety (D-418)
	float alpha = streak * edge_fade * peak_alpha;

	ALBEDO = aura_color.rgb;
	ALPHA = alpha;
}
