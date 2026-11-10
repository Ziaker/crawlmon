shader_type spatial;
// D-1077: a soft puff of water mist (Tidal Surge impact / post-impact). Camera-facing quad in a MultiMesh;
// INSTANCE_CUSTOM = (seed, fade, -, alpha). The body is the soft noise of `water_flow.png` inside a round falloff,
// eroded as it evaporates. Kept faint on purpose: it must never cover the target (D-1033) nor flash (D-418).
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform sampler2D flow_tex : repeat_enable, filter_linear_mipmap;
uniform vec4 mist_color : source_color = vec4(0.80, 0.96, 1.0, 1.0);
uniform vec4 shade_color : source_color = vec4(0.30, 0.70, 0.98, 1.0);
uniform float alpha = 0.4;

varying vec4 inst;

void vertex() {
	inst = INSTANCE_CUSTOM;
	// Billboard that keeps the instance scale.
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * sc.x, INV_VIEW_MATRIX[1] * sc.y, INV_VIEW_MATRIX[2] * sc.z, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 uv = UV * 0.7 + vec2(inst.x * 0.37, inst.x * 0.61 - TIME * 0.08);
	float n = texture(flow_tex, uv).g;
	float fb = texture(flow_tex, uv * 2.0).b;
	float body = (1.0 - smoothstep(0.35, 1.0, r + (n - 0.5) * 0.45));
	float er = clamp(inst.y, 0.0, 1.0) * 1.15;
	float a = alpha * inst.w * body * smoothstep(er - 0.25, er, n * 0.7 + fb * 0.3);
	ALBEDO = mix(shade_color.rgb, mist_color.rgb, smoothstep(0.35, 0.65, n));
	ALPHA = clamp(a, 0.0, 1.0);
}
