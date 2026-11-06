shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// D-274: water on a ribbon (ElementShapes.ribbon_mesh). Reads as a rounded stream: three cel bands from a fake
// light, bright streaks that run along the flow, and foam on the crests and the edges. Explicit `time`.
#include "res://shaders/el_common.gdshaderinc"

uniform float time = 0.0;
uniform float seed = 0.0;
uniform float flow = 6.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform bool flat_mode = false;
uniform vec3 c_deep : source_color = vec3(0.1, 0.38, 0.85);
uniform vec3 c_mid : source_color = vec3(0.25, 0.65, 1.0);
uniform vec3 c_light : source_color = vec3(0.7, 0.92, 1.0);
uniform vec3 c_foam : source_color = vec3(1.0, 1.0, 1.0);

varying vec2 v_uv;

void vertex() {
	vec3 pos_w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tan_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 side = el_ribbon_side(pos_w, tan_w, flat_mode, INV_VIEW_MATRIX[3].xyz);
	pos_w += side * (UV.y * COLOR.r * 0.5);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(pos_w, 1.0)).xyz;
	v_uv = UV;
}

void fragment() {
	float u = v_uv.x;
	float v = v_uv.y;
	float round_n = sqrt(max(1.0 - v * v, 0.0));
	float lit = round_n * 0.65 + (-v) * 0.35;
	vec3 col = lit > 0.78 ? c_light : (lit > 0.42 ? c_mid : c_deep);
	float streak = el_noise(vec2(u * 12.0 - time * flow + seed, v * 2.5 + seed * 3.1));
	if (streak > 0.78) {
		col = c_light;
	}
	float edge = abs(v) + (el_noise(vec2(u * 18.0 - time * flow * 1.3, v * 4.0 + seed)) - 0.5) * 0.45;
	if (edge > 0.74) {
		col = c_foam;
	}
	float a = smoothstep(1.0, 0.9, abs(v)) * (1.0 - fade);
	if (a < 0.02) {
		discard;
	}
	ALBEDO = col;
	ALPHA = a * 0.95;
}
