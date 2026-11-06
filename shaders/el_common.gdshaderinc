// D-274: shared pieces of the element effects (fire, water, earth, air).

float el_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float el_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = el_hash(i);
	float b = el_hash(i + vec2(1.0, 0.0));
	float c = el_hash(i + vec2(0.0, 1.0));
	float d = el_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float el_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * el_noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// Ribbon meshes (ElementShapes.ribbon_mesh) store the CENTER line: VERTEX = point, NORMAL = tangent,
// UV = (u along the ribbon 0..1, side -1/+1), COLOR.r = width. This expands a vertex sideways, facing the
// camera (or lying flat on the ground), so one mesh works from any side and any camera.
vec3 el_ribbon_side(vec3 pos_w, vec3 tan_w, bool flat_mode, vec3 cam_pos) {
	if (flat_mode) {
		return normalize(cross(tan_w, vec3(0.0, 1.0, 0.0)) + vec3(0.00001, 0.0, 0.0));
	}
	vec3 view_dir = normalize(pos_w - cam_pos);
	return normalize(cross(tan_w, view_dir) + vec3(0.00001, 0.0, 0.0));
}
