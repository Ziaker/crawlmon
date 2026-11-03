shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Multi-frame sprite-sheet (flipbook) billboard shader for impacts, fire, lightning and smoke.

uniform sampler2D sheet_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 2.0;
uniform int h_frames = 4;
uniform int v_frames = 4;
uniform float roll_rad = 0.0;

void vertex() {
	// Camera-facing billboard with custom roll angle and object scale preserved.
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float c = cos(roll_rad);
	float s = sin(roll_rad);
	mat2 rot = mat2(vec2(c, s), vec2(-s, c));
	vec2 rv = rot * VERTEX.xy;
	vec3 cam_right = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_up = INV_VIEW_MATRIX[1].xyz;
	vec3 world_pos = MODEL_MATRIX[3].xyz + cam_right * (rv.x * scale_v.x) + cam_up * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
}

void fragment() {
	int total = max(h_frames * v_frames, 1);
	int frame = clamp(int(floor(progress * float(total))), 0, total - 1);
	int col = frame % h_frames;
	int row = frame / h_frames;
	vec2 cell_size = vec2(1.0 / float(h_frames), 1.0 / float(v_frames));
	vec2 uv = (UV + vec2(float(col), float(row))) * cell_size;
	vec4 tex = texture(sheet_tex, uv);
	float a = clamp(tex.a * color.a, 0.0, 1.0);
	if (a < 0.02) {
		discard;
	}
	float core = smoothstep(0.55, 0.98, tex.r);
	ALBEDO = mix(tex.rgb * color.rgb, vec3(1.0), core * 0.45) * energy;
	ALPHA = a;
}
