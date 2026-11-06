shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// D-274: a thin tapered line on a ribbon (ElementShapes.ribbon_mesh): the air gust's streamers and the dark
// cracks on the ground. `gaps` > 0 breaks the line into pieces that run along it (intermittent wind).
#include "res://shaders/el_common.gdshaderinc"

uniform float time = 0.0;
uniform float seed = 0.0;
uniform float flow = 8.0;
uniform float gaps = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform bool flat_mode = false;
uniform vec3 c_core : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 c_edge : source_color = vec3(0.7, 0.95, 1.0);
uniform float energy = 1.1;

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
	float v = abs(v_uv.y);
	float a = smoothstep(1.0, 0.55, v);
	if (gaps > 0.0) {
		float g = sin(u * gaps - time * flow + seed * 6.2831) * 0.5 + 0.5;
		a *= smoothstep(0.32, 0.5, g);
	}
	a *= (1.0 - fade);
	if (a < 0.02) {
		discard;
	}
	vec3 col = v < 0.4 ? c_core : c_edge;
	ALBEDO = col * energy;
	ALPHA = a;
}
