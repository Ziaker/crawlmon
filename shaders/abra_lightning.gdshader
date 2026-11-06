shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Jagged fractal lightning on a quad (local Y runs from the top, UV.y = 0, to the bottom).
// The path is re-rolled `fps` times per second (the prototype redraws its storm every frame).
// Trunk + a spiralling filament + side branches in one pass; `reveal` makes it strike downward.

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.1, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.97, 0.8, 1.0);
uniform float tt = 0.0;          // game-time seconds (so slow motion slows the flicker)
uniform float seed = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float intensity = 1.0;
uniform float amp = 0.30;        // lateral wiggle, fraction of the quad width
uniform float thick = 0.040;     // core half width, fraction of the quad width
uniform float halo = 7.0;        // halo falloff (bigger = tighter)
uniform float fps = 24.0;
uniform float branches : hint_range(0.0, 3.0) = 2.0;
uniform float spiral = 0.0;      // amplitude of the twisted filament

float hash(float n) {
	return fract(sin(n * 127.1 + seed * 17.3) * 43758.5453);
}

float vnoise(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

float path(float y, float t) {
	float v = vnoise(y * 6.0 + t * 7.31) + 0.5 * vnoise(y * 13.0 + t * 3.7) + 0.25 * vnoise(y * 29.0 + t * 1.9);
	v /= 1.75;
	float ends = pow(sin(clamp(y, 0.0, 1.0) * 3.14159265), 0.55);
	return (v - 0.5) * 2.0 * amp * ends;
}

void fragment() {
	float y = UV.y;
	float x = UV.x - 0.5;
	if (y > reveal) {
		discard;
	}
	float t = floor(tt * fps);
	float xc = path(y, t);
	float d = abs(x - xc);
	float body = smoothstep(thick, 0.0, d);
	float glow = exp(-d * halo * 8.0) * 0.55;
	if (spiral > 0.0) {
		float xs = xc + sin(y * 38.0 + seed + t * 0.7) * spiral * (1.0 - y * 0.5);
		float ds = abs(x - xs);
		body = max(body, smoothstep(thick * 0.8, 0.0, ds) * 0.9);
		glow += exp(-ds * halo * 9.0) * 0.3;
	}
	for (int i = 0; i < 3; i++) {
		if (float(i) < branches) {
			float y0 = 0.12 + 0.24 * float(i) + hash(float(i) + 3.0) * 0.1;
			if (y > y0) {
				float run = (y - y0);
				float fade = 1.0 - run / 0.42;
				if (fade > 0.0) {
					float dir = (hash(float(i) + 11.0) * 2.0 - 1.0) * 1.1;
					float xb = path(y0, t) + run * dir + (vnoise(y * 21.0 + float(i) * 5.0 + t) - 0.5) * 0.07;
					float db = abs(x - xb);
					body = max(body, smoothstep(thick * 0.75, 0.0, db) * fade);
					glow += exp(-db * halo * 9.0) * 0.28 * fade;
				}
			}
		}
	}
	float front = smoothstep(reveal - 0.05, reveal, y) * 0.9;  // hot tip while it strikes
	float flick = 0.78 + 0.22 * hash(t * 1.37);
	float edge = smoothstep(0.5, 0.35, abs(x));
	float a = clamp((body + glow + front * body) * edge * flick * intensity, 0.0, 1.0);
	if (a < 0.02) {
		discard;
	}
	vec3 col = mix(color.rgb, core_color.rgb, clamp(body * 1.2, 0.0, 1.0));
	ALBEDO = col * (1.0 + front);
	ALPHA = a;
}
