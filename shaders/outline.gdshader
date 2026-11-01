shader_type spatial;
render_mode unshaded, cull_front;
// Inverted-hull outline, used as `next_pass` of a model's material. The width
// scales with distance so far characters keep a readable outline.

uniform vec4 color : source_color = vec4(0.02, 0.04, 0.08, 1.0);
uniform float width = 0.0016;

void vertex() {
	float dist = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
	float s = length(MODEL_MATRIX[0].xyz);
	VERTEX += NORMAL * width * dist / max(s, 0.001);
}

void fragment() {
	ALBEDO = color.rgb;
}
