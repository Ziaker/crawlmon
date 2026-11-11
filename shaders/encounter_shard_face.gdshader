shader_type spatial;
// D-1172: front face of the 36 encounter shards. Shows the captured overworld frame
// with a 12-tap radial blur, chromatic aberration and one shockwave ring around the
// contact point. No full-screen flash (D-418). UVs are bottom-origin on the mesh.
render_mode unshaded, cull_disabled;

uniform sampler2D t_overworld : source_color, filter_linear, repeat_disable;
uniform vec2 u_impact_center = vec2(0.5, 0.5);  // top-origin, like the sampled UV
uniform vec3 u_primary_color : source_color = vec3(1.0);
uniform float u_blur_strength = 0.0;
uniform float u_chroma_shift = 0.0;
uniform float u_flash_amount = 0.0;
uniform float u_shockwave_progress = 0.0;
uniform float u_specular_glint = 0.0;

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec2 dir = uv - u_impact_center;
	float dist = length(dir);
	vec2 norm_dir = dist > 0.0001 ? dir / dist : vec2(0.0, 1.0);

	float wave_ring = 0.0;
	if (u_shockwave_progress > 0.0 && u_shockwave_progress < 1.0) {
		float radius = u_shockwave_progress * 0.95;
		float band = smoothstep(radius - 0.09, radius, dist) * (1.0 - smoothstep(radius, radius + 0.09, dist));
		wave_ring = band * (1.0 - u_shockwave_progress);
	}
	vec2 base_uv = uv + norm_dir * (wave_ring * 0.055);

	vec3 accum_r = vec3(0.0);
	vec3 accum_g = vec3(0.0);
	vec3 accum_b = vec3(0.0);
	const int SAMPLES = 12;
	for (int i = 0; i < SAMPLES; i++) {
		float f = float(i) / float(SAMPLES - 1);
		float scale = 1.0 - f * u_blur_strength * 0.14;
		vec2 sample_uv = u_impact_center + (base_uv - u_impact_center) * scale;
		vec2 chroma_offset = norm_dir * (u_chroma_shift * (0.006 + dist * 0.014) * (0.5 + 0.5 * f));
		accum_r += texture(t_overworld, clamp(sample_uv + chroma_offset, vec2(0.002), vec2(0.998))).rgb;
		accum_g += texture(t_overworld, clamp(sample_uv, vec2(0.002), vec2(0.998))).rgb;
		accum_b += texture(t_overworld, clamp(sample_uv - chroma_offset, vec2(0.002), vec2(0.998))).rgb;
	}
	vec3 col = vec3(accum_r.r, accum_g.g, accum_b.b) / float(SAMPLES);

	// Soft darkening at the centre during the crack, so the flat block reads on top.
	float center_dim = (1.0 - smoothstep(0.0, 0.55, dist)) * u_flash_amount * 0.45;
	col *= (1.0 - center_dim);
	col += u_primary_color * (wave_ring * 0.42 + u_specular_glint * 0.22);
	col = mix(col, u_primary_color, clamp(u_flash_amount * 0.16, 0.0, 0.25));
	ALBEDO = col;
}
