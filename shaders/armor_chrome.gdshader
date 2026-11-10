shader_type spatial;
render_mode blend_mix, unshaded, cull_back, depth_draw_never;
// D-1026: the ARMOR badge on a model. A low-opacity chrome film laid over the real textures (material_overlay), so the model
// stays readable. `reveal` (0..1) is the wave of chrome that climbs from the feet to the head, in WORLD height between
// base_y and top_y, with a bright frontier; at 1 the film is complete. Nothing here knows the character, team or side (D-235).

uniform float base_y = 0.0;
uniform float top_y = 2.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.30;
uniform float band : hint_range(0.02, 0.6) = 0.16;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float push = 0.012;
uniform vec3 shadow_col : source_color = vec3(0.05, 0.06, 0.09);
uniform vec3 mid_col : source_color = vec3(0.60, 0.67, 0.78);
uniform vec3 light_col : source_color = vec3(0.96, 0.98, 1.0);

varying float v_wy;

void vertex() {
	float s = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += NORMAL * (push / s);  // lifts the film just above the skin so it does not z-fight
	v_wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	// A procedural studio "environment" reflected on the surface: dark floor, bright horizon, soft stripes.
	vec3 r = reflect(-VIEW, NORMAL);
	vec3 wr = (INV_VIEW_MATRIX * vec4(r, 0.0)).xyz;
	float h = wr.y * 0.5 + 0.5;
	float env = smoothstep(0.42, 0.56, h);  // a hard horizon line, like a mirror
	// The reflection slides slowly over the body like light on polished metal, with a sharp white glint on top.
	float sweep = sin(wr.x * 3.2 + wr.y * 5.5 + 1.1 + TIME * 1.1) * 0.5 + 0.5;
	float stripes = smoothstep(0.55, 0.9, sweep) * smoothstep(0.3, 0.7, h);
	float glint = smoothstep(0.93, 0.99, sweep) * smoothstep(0.35, 0.8, h);
	vec3 c = mix(shadow_col, mid_col, env);
	c = mix(c, light_col, stripes * 0.85);
	c = pow(c, vec3(1.5));  // more contrast between the dark floor reflection and the bright horizon
	c += light_col * glint * 0.9;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	c += light_col * fres * 0.35;

	float y = (v_wy - base_y) / max(top_y - base_y, 0.01);
	float front = reveal * (1.0 + band);
	float mask = 1.0 - smoothstep(front - band, front, y);
	float frontier = pow(clamp(1.0 - abs(y - (front - band * 0.5)) / (band * 0.5), 0.0, 1.0), 2.0) * step(reveal, 0.999);

	ALBEDO = c * 0.8 + light_col * (frontier * 1.2 + flash * 0.6);
	ALPHA = clamp(alpha * mask + frontier * 0.45 + flash * 0.3 * mask, 0.0, 0.75);
}
