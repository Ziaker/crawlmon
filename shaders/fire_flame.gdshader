shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Stylised (cel-shaded) flame on a camera-facing quad (D-236): hard colour bands, pale-yellow core, yellow-orange,
// orange, red-orange edge. `blob` = 0 is a teardrop flame whose tip points along +Y (turned by `roll`); `blob` = 1 is a
// round puff. Scrolling noise licks the outline; `fade` eats it away. Set hot/mid/edge to red and orange for sparks.

uniform vec4 core : source_color = vec4(1.0, 0.97, 0.72, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.5, 0.06, 1.0);
uniform vec4 edge : source_color = vec4(0.93, 0.24, 0.04, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float roll = 0.0;
uniform float seed = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float blob : hint_range(0.0, 1.0) = 0.0;
uniform float speed = 2.2;

void vertex() {
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float c = cos(roll);
	float s = sin(roll);
	vec2 rv = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	vec3 world_pos = MODEL_MATRIX[3].xyz + INV_VIEW_MATRIX[0].xyz * (rv.x * scale_v.x) + INV_VIEW_MATRIX[1].xyz * (rv.y * scale_v.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.6 + vnoise(p * 2.03 + 7.1) * 0.4;
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	float h = p.y * 0.5 + 0.5;
	float d_tear = 0.80 * pow(max(1.0 - h, 0.0), 0.55) * smoothstep(0.0, 0.14, h) - abs(p.x);
	float d_blob = 0.90 - length(p);
	float d = mix(d_tear, d_blob, blob);
	vec2 np = mix(vec2(p.x * 2.3 + seed, h * 2.6 - tt * speed), p * 2.6 + vec2(seed, -tt * speed * 0.55), blob);
	d += (fbm(np) - 0.5) * 0.55;
	d -= fade * 0.85;
	float a = smoothstep(0.0, 0.05, d);   // hard, cartoon edge
	if (a < 0.02) {
		discard;
	}
	float heat = clamp(d * 1.7 + (1.0 - h) * 0.1 * (1.0 - blob), 0.0, 1.0);
	vec3 c = edge.rgb;
	c = mix(c, mid.rgb, step(0.16, heat));
	c = mix(c, hot.rgb, step(0.4, heat));
	c = mix(c, core.rgb, step(0.72, heat));
	ALBEDO = c * intensity;
	ALPHA = a * (1.0 - fade * 0.4);
}
