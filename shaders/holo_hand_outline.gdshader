shader_type spatial;
render_mode unshaded, blend_mix, cull_front, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
// White ink contour for the holo hand (D-1209): inverted hull, so every finger, the palm and
// the thumb get their own line, including the creases between them. `width` is in local space
// (the mesh is 1 unit long and `unit` scales the instance) and the form/dissolve masks are
// copied from holo_hand.gdshader so the line materialises and dissolves together with the fill.

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // white ink (D-1209)
uniform float width : hint_range(0.001, 0.2) = 0.03;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float form : hint_range(0.0, 1.0) = 1.0;

varying vec3 v_local;


void vertex() {
	v_local = VERTEX;
	VERTEX += NORMAL * width;
}


// Stable 3D cell hash (same as the fill): whole chunks of the hand vanish, not a soft noise mask.
float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.37, 0.71));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}


void fragment() {
	// materialisation: vertical sweep, wrist (y=0) towards the fingers (y=1), same cut as the fill
	float sweep = clamp(v_local.y, 0.0, 1.0);
	float m_form = clamp((form * 1.08 - sweep) / 0.08, 0.0, 1.0);

	// dissolve: the same hash cells drop out, so the line never outlives its hand
	float h = hash3(floor(v_local * 9.0));
	float m_keep = step(dissolve, h);

	ALBEDO = tint.rgb;
	ALPHA = clamp(tint.a * m_form * m_keep * fade, 0.0, 1.0);
}
