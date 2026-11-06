shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// D-274: fire body on a ribbon (ElementShapes.ribbon_mesh). Cel-shaded bands in the game's style (yellow core,
// orange body, red edge), a wobbling silhouette and an erosion that eats the tail and, when `erode` rises,
// the whole flame. Driven only by `time` and `erode` (explicit time, no TIME).
#include "res://shaders/el_common.gdshaderinc"

uniform float time = 0.0;
uniform float seed = 0.0;
uniform float erode : hint_range(0.0, 1.0) = 0.0;
uniform float flow = 3.5;
uniform float wobble = 0.5;
uniform bool flat_mode = false;
uniform vec3 c_core : source_color = vec3(1.0, 0.95, 0.55);
uniform vec3 c_mid : source_color = vec3(1.0, 0.62, 0.12);
uniform vec3 c_edge : source_color = vec3(0.9, 0.2, 0.04);
uniform float energy = 1.35;

varying vec2 v_uv;

void vertex() {
	vec3 pos_w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tan_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 side = el_ribbon_side(pos_w, tan_w, flat_mode, INV_VIEW_MATRIX[3].xyz);
	float wob = (el_noise(vec2(UV.x * 3.0 - time * flow * 0.5, seed)) - 0.5) * wobble * COLOR.r;
	pos_w += side * (UV.y * COLOR.r * 0.5 + wob);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(pos_w, 1.0)).xyz;
	v_uv = UV;
}

void fragment() {
	float u = v_uv.x;
	float v = v_uv.y;
	float body = 1.0 - pow(abs(v), 1.7);
	float n = el_fbm(vec2(u * 5.0 - time * flow + seed, v * 2.2 + seed * 1.7));
	float tail = pow(1.0 - u, 1.3);
	float heat = body - (n * 1.0 + tail * 0.5 + erode * 1.2) + 0.7;
	if (heat < 0.02) {
		discard;
	}
	vec3 col = heat > 0.62 ? c_core : (heat > 0.32 ? c_mid : c_edge);
	ALBEDO = col * energy;
	ALPHA = smoothstep(0.02, 0.07, heat);
}
