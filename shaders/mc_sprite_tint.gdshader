shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// D-953 (Composer de Fases): sprite de FLIPBOOK com TINTE. Mesmo quadro/loop do mc_sprite, mas a textura é
// multiplicada por `color`; assim uma folha branca de fumaça vira poeira quente sem mexer nos efeitos que já
// usam o mc_sprite (D-020). Só a opção `tint` da representação `flipbook` usa este shader.

uniform sampler2D sheet_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float frame_pos : hint_range(0.0, 1.0) = 0.0;
uniform int h_frames = 4;
uniform int v_frames = 4;
uniform float energy = 1.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float roll = 0.0;
uniform vec4 color : source_color = vec4(1.0);

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

void fragment() {
	int total = max(h_frames * v_frames, 1);
	int frame = clamp(int(floor(frame_pos * float(total))), 0, total - 1);
	vec2 cell = vec2(1.0 / float(h_frames), 1.0 / float(v_frames));
	vec2 uv = (UV + vec2(float(frame % h_frames), float(frame / h_frames))) * cell;
	vec4 tex = texture(sheet_tex, uv);
	float a = tex.a * color.a * (1.0 - fade);
	if (a < 0.02) {
		discard;
	}
	ALBEDO = tex.rgb * color.rgb * energy;
	ALPHA = a;
}
