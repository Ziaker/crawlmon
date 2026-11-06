shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Motion Composer V1.8 (D-337): 10 formas procedurais do Atelier HTML (modo aditivo):
// 0=glow, 1=sparkle, 2=cross, 3=shard, 4=snowflake, 5=rock, 6=smoke, 7=flame, 8=ash, 9=xmark.
// Rotaciona o UV por `angle` e aplica cor/alfa calculados pelo Motion Composer (tempo explícito, D-019).

uniform int shape_id = 0;
uniform vec4 col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float angle = 0.0;
uniform float energy = 1.35;

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

// Distância com sinal a um polígono convexo (vértices em sentido horário no espaço -1..1)
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
	vec2 p = vec2(uv0.x * c - uv0.y * s, uv0.x * s + uv0.y * c) * 2.0; // -1..1
	float r = length(p);
	float mask = 0.0;

	if (shape_id == 0) {
		// glow: radial gradient (0 -> 1, 0.3 -> 0.85, 0.7 -> 0.22, 1.0 -> 0)
		mask = smoothstep(1.0, 0.0, r);
		mask = pow(mask, 1.55);
	} else if (shape_id == 1) {
		// sparkle: 4-pointed curved diamond star + radial falloff
		vec2 ap = abs(p);
		float star = max(0.0, 1.0 - (ap.x + ap.y + 3.2 * ap.x * ap.y));
		float rays = smoothstep(0.14, 0.0, min(ap.x, ap.y) + r * 0.12) * smoothstep(0.96, 0.0, r);
		float radial = pow(clamp(1.0 - r, 0.0, 1.0), 1.4);
		mask = clamp((star * 1.2 + rays * 0.95) * radial, 0.0, 1.0);
	} else if (shape_id == 2) {
		// cross: radial glow + crisp vertical & horizontal bars
		float glow_bg = pow(clamp(1.0 - r, 0.0, 1.0), 1.6) * 0.55;
		float vbar = step(abs(p.x), 0.16) * step(abs(p.y), 0.72);
		float hbar = step(abs(p.y), 0.16) * step(abs(p.x), 0.72);
		mask = clamp(glow_bg + max(vbar, hbar), 0.0, 1.0);
	} else if (shape_id == 3) {
		// shard: asymmetric ice crystal (cx,8)->(cx+28,cy-8)->(cx+16,120)->(cx-22,cy+18)
		mask = poly_mask(p,
			vec2(0.0, -0.875),
			vec2(0.4375, -0.125),
			vec2(0.25, 0.875),
			vec2(-0.34375, 0.28125),
			vec2(0.0), vec2(0.0), 4);
	} else if (shape_id == 4) {
		// snowflake: 6-branched snowflake with side twigs
		float d = 1e5;
		for (int i = 0; i < 6; i++) {
			float a = float(i) * 1.04719755;
			float ca = cos(a), sa = sin(a);
			vec2 q = vec2(p.x * ca - p.y * sa, p.x * sa + p.y * ca);
			d = min(d, sd_segment(q, vec2(0.0, 0.0), vec2(0.0, -0.78)));
			d = min(d, sd_segment(q, vec2(0.0, -0.4375), vec2(-0.21875, -0.625)));
			d = min(d, sd_segment(q, vec2(0.0, -0.4375), vec2(0.21875, -0.625)));
		}
		mask = smoothstep(0.085, 0.03, d);
	} else if (shape_id == 5) {
		// rock: 6-sided polygon
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
		// flame: teardrop tongue of fire
		vec2 fp = vec2(p.x, -p.y); // tip at top
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
	} else if (shape_id == 9) {
		// xmark: thick rounded X
		float d1 = sd_segment(p, vec2(-0.59375, -0.59375), vec2(0.59375, 0.59375));
		float d2 = sd_segment(p, vec2(0.59375, -0.59375), vec2(-0.59375, 0.59375));
		mask = smoothstep(0.22, 0.10, min(d1, d2));
	}

	float a_out = mask * alpha * col.a;
	if (a_out < 0.015) {
		discard;
	}
	ALBEDO = col.rgb * energy;
	ALPHA = clamp(a_out, 0.0, 1.0);
}
