shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Glowing hexagon plate on a quad: bright edge, a thin inner hexagon and a faint pulsing fill.

uniform vec4 color : source_color = vec4(1.0, 0.4, 0.7, 1.0);
uniform vec4 color2 : source_color = vec4(0.71, 0.4, 1.0, 1.0);
uniform float intensity = 1.0;
uniform float tt = 0.0;

void fragment() {
	vec2 p = abs((UV - 0.5) * 2.0);
	float d = max(p.x * 0.8660254 + p.y * 0.5, p.y);  // regular hexagon, flat top and bottom
	if (d > 1.0) {
		discard;
	}
	float edge = smoothstep(0.80, 0.96, d);
	float inner = smoothstep(0.035, 0.0, abs(d - 0.55)) * 0.55;
	float fill = 0.12 + 0.08 * sin(tt * 8.0 + p.y * 6.0);
	float a = clamp((edge * 0.95 + inner + fill) * intensity, 0.0, 1.0);
	vec3 col = mix(color2.rgb, color.rgb, edge);
	ALBEDO = col * (1.0 + edge * 0.7);
	ALPHA = a;
}
