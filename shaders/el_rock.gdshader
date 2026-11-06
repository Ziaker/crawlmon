shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
// D-274: flat-shaded rock shards for MultiMesh instances (instance colour = tint). Three cel bands from a fixed
// light so the faces read as cut stone from any side; no scene lights needed.

uniform vec3 light_dir = vec3(-0.4, 0.9, 0.5);

varying vec3 v_normal;
varying vec4 v_color;

void vertex() {
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_color = COLOR;
}

void fragment() {
	float l = dot(normalize(v_normal), normalize(light_dir));
	float band = l > 0.55 ? 1.0 : (l > 0.05 ? 0.72 : 0.45);
	ALBEDO = v_color.rgb * band;
	ALPHA = v_color.a;
}
