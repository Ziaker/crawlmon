shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Laser beam on a quad (UV.y runs from the muzzle, 0, to the target, 1): a hot core, a soft body that
// pulses along its length, and three twisted strands. `reveal` makes the shot travel out of the muzzle.

uniform vec4 color : source_color = vec4(1.0, 0.4, 0.7, 1.0);
uniform vec4 color2 : source_color = vec4(0.71, 0.4, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.97, 1.0);
uniform float tt = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float intensity = 1.0;
uniform float beam_len = 20.0;  // world length, so pulses and strands keep their size
uniform float twist = 0.2;      // strand amplitude (fraction of the quad width)
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;  // 0 = solid, 1 = gone: the beam frays and dissipates

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float v = UV.y;
	float u = UV.x - 0.5;
	if (v > reveal) {
		discard;
	}
	// Dissipation: the beam narrows and is eaten away by noise, from the muzzle towards the target.
	float width_k = mix(1.0, 0.35, dissolve);
	u = u / width_k;
	float grain = noise2(vec2(v * beam_len * 0.9, u * 7.0 + tt * 3.0));
	float eat = smoothstep(0.0, 0.18, v - dissolve * 1.2 + (grain - 0.5) * 0.45 + 0.1);
	float keep = dissolve <= 0.0 ? 1.0 : eat * (1.0 - dissolve * 0.6);
	// Tip at the target: no flat cut. The beam narrows into a rounded point and fades over the last ~1.4 world units.
	float to_end = (reveal - v) * beam_len;  // distance to the leading tip (the target once fully revealed)
	float tip = clamp(to_end / 1.4, 0.0, 1.0);
	u = u / mix(0.12, 1.0, sqrt(tip));
	float taper = smoothstep(0.0, 0.025, v) * smoothstep(0.0, 0.5, tip);
	float au = abs(u);
	float core = smoothstep(0.07, 0.0, au);
	float body = smoothstep(0.30, 0.03, au);
	float pulse = 0.72 + 0.28 * sin(v * beam_len * 1.6 - tt * 38.0);
	float ph = v * beam_len * 0.7 - tt * 16.0;
	float s1 = abs(u - twist * sin(ph));
	float s2 = abs(u - twist * sin(ph + 2.094));
	float s3 = abs(u - twist * sin(ph + 4.188));
	float strands = max(max(smoothstep(0.03, 0.0, s1), smoothstep(0.03, 0.0, s2)), smoothstep(0.03, 0.0, s3));
	float front = smoothstep(reveal - 0.05, reveal, v);
	float a = clamp((body * 0.6 * pulse + core + strands * 0.85) * intensity * taper * keep, 0.0, 1.0);
	a *= smoothstep(0.5, 0.38, au);
	if (a < 0.02) {
		discard;
	}
	vec3 col = mix(color.rgb, color2.rgb, clamp(strands, 0.0, 1.0));
	col = mix(col, core_color.rgb, clamp(core * 1.1, 0.0, 1.0));
	ALBEDO = col * (1.0 + front * 1.4);
	ALPHA = a;
}
