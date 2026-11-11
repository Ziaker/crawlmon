shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled;

// Glass barrier panel for the shield value (option C).
uniform vec3 col : source_color = vec3(0.04, 0.20, 0.38);
uniform float alpha = 0.28;
uniform float pulse = 0.0;

void fragment() {
	vec2 uv = UV;
	float border = smoothstep(0.025, 0.0, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	vec3 c = mix(col, vec3(0.55, 0.90, 1.0), border);
	c += vec3(0.25, 0.70, 1.0) * pulse * 0.2;
	ALBEDO = c;
	ALPHA = clamp(alpha + border * 0.55, 0.0, 1.0);
}
