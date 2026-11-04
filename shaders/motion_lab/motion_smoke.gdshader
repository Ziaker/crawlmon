shader_type spatial;
// Motion Composer — representação "Fumaça/billboards" (D-044), modo neutro (§8.3). Usa a folha de fumaça
// do jogo (assets/vfx/flipbook_smoke.png, 4 x 4). Diferente de shaders/flipbook.gdshader, que soma luz aditiva
// no render, esta mistura por alfa (blend_mix): a fumaça se lê sem depender de adição luminosa (§19.5).
// Por instância (MultiMesh): COLOR = matiz/brilho/opacidade; INSTANCE_CUSTOM.x = giro (rad),
// INSTANCE_CUSTOM.y = quadro da folha. Sem tempo próprio: o quadro vem da idade da amostra.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform sampler2D sheet_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform int h_frames = 4;
uniform int v_frames = 4;
// Opacidade máxima de um puff (a folha já é translúcida).
uniform float max_alpha : hint_range(0.0, 1.0) = 0.9;

varying float v_frame;

void vertex() {
	// Quad voltado para a câmera, com giro por instância e a escala da instância preservada.
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float c = cos(INSTANCE_CUSTOM.x);
	float s = sin(INSTANCE_CUSTOM.x);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 cam_right = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_up = INV_VIEW_MATRIX[1].xyz;
	vec3 world_pos = MODEL_MATRIX[3].xyz + cam_right * (rv.x * scale_v.x) + cam_up * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
	v_frame = INSTANCE_CUSTOM.y;
}

void fragment() {
	int total = max(h_frames * v_frames, 1);
	int frame = clamp(int(floor(v_frame + 0.5)), 0, total - 1);
	vec2 cell = vec2(1.0 / float(h_frames), 1.0 / float(v_frames));
	vec2 uv = (UV + vec2(float(frame % h_frames), float(frame / h_frames))) * cell;
	vec4 tex = texture(sheet_tex, uv);
	float a = tex.a * COLOR.a * max_alpha;
	if (a < 0.01) {
		discard;
	}
	ALBEDO = COLOR.rgb * (0.45 + 0.9 * tex.r);
	ALPHA = a;
}
