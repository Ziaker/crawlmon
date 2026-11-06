shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): 10 formas procedurais do Atelier HTML (modo NormalBlending / blend_mix):
// Usado por rochas, fumaça densa e flocos de cinza/carvão para preservar cores escuras sem somar luz.

uniform int shape_id = 5;
uniform vec4 col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float angle = 0.0;
uniform float energy = 1.0;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	vec3 wp = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (VERTEX.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (VERTEX.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

float cross2d(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

float poly_mask(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3, vec2 v4, vec2 v5, int n) {
	vec2 v[6] = vec2[6](v0, v1, v2, v3, v4, v5);
	float min_d = 1e5;
	float s = 1.0;
	for (int i = 0; i < 6; i++) {
		if (i >= n) break;
		int j = (i + 1 == n) ? 0 : i + 1;
		vec2 e = v[j] - v[i];
		vec2 w = p - v[i];
		float d = sd_segment(p, v[i], v[j]);
		min_d = min(min_d, d);
		if (cross2d(e, w) < 0.0) {
			s = -1.0;
		}
	}
	return smoothstep(0.04, -0.02, min_d * s);
}

void fragment() {
	vec2 uv0 = UV - vec2(0.5);
	float c = cos(angle);
	float s = sin(angle);
	vec2 p = vec2(uv0.x * c - uv0.y * s, uv0.x * s + uv0.y * c) * 2.0;
	float r = length(p);
	float mask = 0.0;

	if (shape_id == 5) {
		// rock: 6-sided boulder polygon
		mask = poly_mask(p,
			vec2(-0.5625, -0.65625),
			vec2(0.375, -0.78125),
			vec2(0.78125, -0.09375),
			vec2(0.4375, 0.6875),
			vec2(-0.40625, 0.75),
			vec2(-0.78125, 0.0625), 6);
	} else if (shape_id == 6) {
		// smoke: soft radial puff
		mask = pow(clamp(1.0 - r / 0.91, 0.0, 1.0), 1.45) * 0.85;
	} else if (shape_id == 7) {
		// flame-to-ash trail
		vec2 fp = vec2(p.x, -p.y);
		float t_y = clamp((fp.y + 0.85) / 1.75, 0.0, 1.0);
		float half_w = sin(pow(1.0 - t_y, 0.75) * 3.14159) * 0.58;
		float d_flame = abs(fp.x) - half_w;
		float shape_f = smoothstep(0.06, -0.06, d_flame) * step(-0.85, fp.y) * step(fp.y, 0.90);
		float grad_f = clamp(1.0 - length(p - vec2(0.0, 0.12)) / 0.88, 0.0, 1.0);
		mask = shape_f * pow(grad_f, 0.7);
	} else if (shape_id == 8) {
		// ash: 5-sided irregular charred flake
		mask = poly_mask(p,
			vec2(-0.4375, -0.5625),
			vec2(0.3125, -0.625),
			vec2(0.59375, 0.03125),
			vec2(0.15625, 0.53125),
			vec2(-0.5625, 0.34375),
			vec2(0.0), 5);
	} else {
		mask = smoothstep(1.0, 0.0, r);
	}

	float a_out = mask * alpha * col.a;
	if (a_out < 0.015) {
		discard;
	}
	ALBEDO = col.rgb * energy;
	ALPHA = clamp(a_out, 0.0, 1.0);
}
