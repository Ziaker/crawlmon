shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.2 (D-323): halo de luz estilizado (brilho em torno de uma fonte). Em degraus duros (`bands`) para
// combinar com o cel-shading do jogo; `bands` = 0 dá um brilho suave. Voltado para a câmera.

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float intensity = 0.8;
uniform float bands = 3.0;
uniform float falloff = 2.2;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (VERTEX.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (VERTEX.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

void fragment() {
	float r = length((UV - 0.5) * 2.0);
	float g = pow(clamp(1.0 - r, 0.0, 1.0), falloff);
	if (bands > 0.5) {
		g = floor(g * bands + 0.5) / bands;
	}
	if (g < 0.01) {
		discard;
	}
	ALBEDO = color.rgb * intensity;
	ALPHA = g * 0.5;
}
