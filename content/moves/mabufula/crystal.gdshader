shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled;
// D-1191: layered veins inside translucent, faceted ice. No wall-clock TIME.
uniform vec4 deep_color : source_color = vec4(0.0, 0.4, 0.8, 1.0);
uniform vec4 ice_color : source_color = vec4(0.22, 0.72, 0.92, 1.0);
uniform vec4 edge_color : source_color = vec4(0.7215686, 1.0, 1.0, 1.0);
uniform float phase_time = 0.0;
uniform float opacity = 0.68;
uniform float fracture = 0.0;
uniform float fade = 1.0;
varying vec3 local_pos;
varying vec4 instance_color;

float vein(vec3 p) {
	float warp = sin(p.y * 13.0 + sin(p.z * 8.0)) * 0.22;
	float a = abs(sin(p.x * 21.0 + p.y * 8.0 + warp));
	float b = abs(sin(p.z * 17.0 - p.y * 11.0 + sin(p.x * 9.0) * 0.3));
	return 1.0 - smoothstep(0.018, 0.07, min(a, b));
}

void vertex() {
	local_pos = VERTEX;
	instance_color = COLOR;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
	float edge = 1.0 - smoothstep(0.012, 0.055, min(UV.x, 1.0 - UV.x));
	float tip = smoothstep(0.70, 1.0, UV.y);
	vec3 p = local_pos + vec3(0.0, phase_time * 0.014, 0.0);
	float inner = vein(p + vec3(0.09, -0.08, 0.11));
	float outer = vein(p) * (0.18 + fracture * 0.60);
	float bands = 0.5 + 0.5 * sin(p.y * 23.0 + p.x * 7.0);
	vec3 col = mix(deep_color.rgb, ice_color.rgb, 0.35 + 0.32 * UV.y + 0.12 * bands);
	col = mix(col, edge_color.rgb, clamp(rim * 0.66 + edge * 0.7 + tip * 0.3, 0.0, 1.0));
	col += edge_color.rgb * (inner * 0.12 + outer * 0.35);
	ALBEDO = col * instance_color.rgb;
	ALPHA = clamp((opacity + rim * 0.18 + edge * 0.14) * fade * instance_color.a, 0.0, 0.95);
}
