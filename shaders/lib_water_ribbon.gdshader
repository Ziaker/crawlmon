shader_type spatial;
// D-1021: the water wave body. A continuous cresting surface with UV Panning (flow along the travel), a white
// superexposed core at the crest, blue-cyan aura and soft side edges that break into droplets. No texture needed:
// the flow is procedural, so the same material works on both views and at any distance (D-235/D-308).
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.35, 1.0);
uniform vec4 mid_color : source_color = vec4(0.10, 0.50, 0.95, 1.0);
uniform vec4 core_color : source_color = vec4(0.78, 0.98, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float flow_speed = 5.0;
uniform float seed = 0.0;

void fragment() {
	float h = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(deep_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, h));
	col = mix(col, core_color.rgb, smoothstep(0.68, 0.94, h));
	// UV Panning: bright bands run along the body, so the surface reads as flowing water even while it travels.
	float flow = sin(UV.x * 26.0 - TIME * flow_speed + sin(h * 9.0 + TIME * 1.4) * 1.5 + seed * 6.283);
	col += mid_color.rgb * smoothstep(0.62, 1.0, flow) * 0.30;
	// Broken foam at the crest.
	float foam = smoothstep(0.82, 0.98, h) * (0.55 + 0.45 * sin(UV.x * 44.0 - TIME * 3.4 + seed * 9.0));
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(alpha * COLOR.a, 0.0, 1.0);
}
