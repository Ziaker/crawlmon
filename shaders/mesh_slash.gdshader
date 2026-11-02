shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// 3D curved mesh slash / ribbon shader: scrolls & distorts `trail_tex` along UV.x
// with a white-hot leading tip and eroded tail.

uniform sampler2D trail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 color : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 2.6;

void fragment() {
	float head = progress * 1.45;
	float u_arc = UV.x;
	// Active window sweeping from 0 to 1 along the curved 3D mesh
	float dist_behind = head - u_arc;
	float window = smoothstep(0.72, 0.0, dist_behind) * smoothstep(-0.04, 0.02, dist_behind);

	// Slight UV distortion for anime speed-streak feel
	float wave = sin(u_arc * 18.0 - progress * 24.0) * 0.025 * (1.0 - progress);
	vec2 sample_uv = vec2(clamp(1.0 - dist_behind * 1.35, 0.02, 0.98), clamp(UV.y + wave, 0.02, 0.98));
	vec4 tex = texture(trail_tex, sample_uv);

	float fade = 1.0 - smoothstep(0.68, 1.0, progress);
	float a = tex.a * window * fade;
	float hot_tip = smoothstep(0.18, 0.0, abs(dist_behind - 0.06)) * tex.r;
	ALBEDO = mix(color.rgb * tex.rgb, vec3(1.0), clamp(hot_tip + tex.r * 0.45, 0.0, 1.0)) * energy;
	ALPHA = clamp(a * color.a, 0.0, 1.0);
}
