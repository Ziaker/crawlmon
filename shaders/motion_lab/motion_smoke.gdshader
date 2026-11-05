shader_type spatial;
// Motion Composer — representação "Fumaça/billboards" (D-044), modo neutro (§8.3). Baforada de ruído suave
// (atlas 2 x 2 gerado por MotionSmokeView.make_puff_atlas, o mesmo cálculo do VfxLib.smoke_tex do jogo).
// Mistura por alfa, sem somar luz (§19.5). Por instância (MultiMesh): COLOR = cor/brilho/opacidade;
// INSTANCE_CUSTOM.x = giro (rad), INSTANCE_CUSTOM.y = variação 0..3 do atlas. Sem tempo próprio.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform sampler2D puff_tex : source_color, filter_linear, repeat_disable;
uniform int h_frames = 2;
uniform int v_frames = 2;
// Opacidade máxima da textura; o pico real (0,75) vem da rampa de vida calculada em MotionSmokeView.
uniform float max_alpha : hint_range(0.0, 1.0) = 1.0;

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
	// Recuo de meio texel por borda: o filtro linear não sangra para a baforada vizinha do atlas.
	vec2 inner = clamp(UV, vec2(0.01), vec2(0.99));
	vec2 uv = (inner + vec2(float(frame % h_frames), float(frame / h_frames))) * cell;
	float t = texture(puff_tex, uv).a;
	float a = t * COLOR.a * max_alpha;
	if (a < 0.005) {
		discard;
	}
	ALBEDO = COLOR.rgb;
	ALPHA = a;
}
