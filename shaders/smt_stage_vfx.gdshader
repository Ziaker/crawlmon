shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 vfx_color : source_color = vec4(0.968, 0.796, 0.470, 1.0); // Padrão: Sukunda Amarelo (#F7CB78)
uniform float fresnel_power : hint_range(0.5, 5.0) = 1.8;
uniform float pulse_speed : hint_range(0.0, 15.0) = 4.5;
uniform float alpha_mult : hint_range(0.0, 3.0) = 1.0;
uniform float vertical_scroll : hint_range(-20.0, 20.0) = 0.0;
uniform float beam_frequency : hint_range(0.0, 50.0) = 8.0;
uniform float edge_fade_top : hint_range(0.0, 1.0) = 0.25;
uniform float edge_fade_bottom : hint_range(0.0, 1.0) = 0.15;
uniform float emissive_boost : hint_range(1.0, 5.0) = 1.5;

void fragment() {
	float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), fresnel_power);
	float scanline = 0.92 + 0.08 * sin(SCREEN_UV.y * 180.0 + TIME * pulse_speed);
	float beam_pattern = 0.50 + 0.50 * sin(UV.x * beam_frequency * 6.28318 + TIME * vertical_scroll);
	float fade_y = 1.0;
	if (edge_fade_top > 0.001 || edge_fade_bottom > 0.001) {
		float fade_bottom = smoothstep(0.0, max(edge_fade_bottom, 0.001), UV.y);
		float fade_top = 1.0 - smoothstep(1.0 - max(edge_fade_top, 0.001), 1.0, UV.y);
		fade_y = fade_bottom * fade_top;
	}
	ALBEDO = vfx_color.rgb * emissive_boost;
	ALPHA = clamp((0.08 + fresnel * 0.52 + beam_pattern * 0.28) * scanline * fade_y * vfx_color.a * alpha_mult, 0.0, 1.0);
}
