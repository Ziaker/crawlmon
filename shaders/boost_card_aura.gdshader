shader_type canvas_item;
render_mode blend_add;

// BOOST aura on the enemy card (D-1229, D-1241). HUD-only prototype: the aura comes OUT of the card (outside the outline),
// amber, additive. The draw rect is the card box grown by `margin` (l, t, r, b); p = card px (0,0 = card top-left).
// Info rects (portrait, name, bars, ATB, burst) are masked, so nothing on the card is hidden.
//   style 1 "Brasa": breathing halo around the card + embers rising out of it
//   style 2 "Chama": flame tongues licking out of the top and sides + base glow
//   style 3 "Aura": pulsing halo + energy wisps streaming up off the outline + rim light

uniform int style = 3;
uniform float t = 0.0;
uniform vec2 box_size = vec2(136.0, 44.0);
uniform vec4 margin = vec4(60.0, 120.0, 60.0, 24.0);
uniform float skew = 6.0;
uniform float opacity = 1.0;
uniform vec3 col_deep : source_color = vec3(1.0, 0.42, 0.04);
uniform vec3 col_core : source_color = vec3(1.0, 0.86, 0.38);
uniform vec4 m0 = vec4(0.0);
uniform vec4 m1 = vec4(0.0);
uniform vec4 m2 = vec4(0.0);
uniform vec4 m3 = vec4(0.0);
uniform vec4 m4 = vec4(0.0);

float hash11(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(7.3, 1.9);
		a *= 0.5;
	}
	return s;
}

float seg_d2(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	vec2 d = pa - ba * h;
	return dot(d, d);
}

// signed distance to the slanted card (px): negative inside
float card_sd(vec2 p) {
	vec2 a = vec2(skew, 0.0);
	vec2 b = vec2(box_size.x, 0.0);
	vec2 c = vec2(box_size.x - skew, box_size.y);
	vec2 d = vec2(0.0, box_size.y);
	float dd = min(min(seg_d2(p, a, b), seg_d2(p, b, c)), min(seg_d2(p, c, d), seg_d2(p, d, a)));
	float left = skew * (1.0 - p.y / box_size.y);
	float right = box_size.x - skew * p.y / box_size.y;
	bool inside = p.y >= 0.0 && p.y <= box_size.y && p.x >= left && p.x <= right;
	return (inside ? -1.0 : 1.0) * sqrt(dd);
}

float rect_mask(vec2 p, vec4 r) {
	if (r.z <= 0.0) {
		return 1.0;
	}
	vec2 q = abs(p - (r.xy + r.zw * 0.5)) - r.zw * 0.5;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
	return smoothstep(0.0, 2.5, d);
}

// Embers rising from the card out past its top: one per column per layer.
float sparks(vec2 p, float time, float density, float speed) {
	float acc = 0.0;
	float area_w = box_size.x + margin.x + margin.z;
	float top = -margin.y;
	float bot = box_size.y + margin.w * 0.3;
	float span = bot - top;
	for (int layer = 0; layer < 2; layer++) {
		float cols = density * (1.0 + float(layer) * 0.6);
		float cw = area_w / cols;
		float ci = floor((p.x + margin.x) / cw);
		for (int k = -1; k <= 1; k++) {
			float id = ci + float(k) + float(layer) * 91.0;
			float h1 = hash11(id);
			float h2 = hash11(id + 17.0);
			float sp = (0.3 + 0.7 * h1) * speed * (1.0 + float(layer) * 0.5);
			float life = fract(time * sp * 0.22 + h2);
			float y = bot - life * span;
			float x = (id - float(layer) * 91.0 + 0.5) * cw - margin.x + sin(time * (1.5 + h1 * 2.0) + h2 * 6.28) * (2.0 + life * 5.0) + (h1 - 0.5) * cw * 0.6;
			float d = length(p - vec2(x, y));
			float r = mix(1.0, 1.9, h1) * (1.0 - life * 0.55);
			float tw = 0.65 + 0.35 * sin(time * 9.0 + h2 * 40.0);
			acc += exp(-d * d / (r * r)) * (1.0 - life * life) * tw;
		}
	}
	return acc;
}

// Flame bits that BREAK OFF the aura and float up: teardrops of random size, speed, sway and opacity; each fades and shrinks.
// aspect = height/width of the teardrop, travel = how far it rises (px), sway = side wobble (px).
float detach(vec2 p, float time, float cols, float speed, float sz, float aspect, float travel, float sway) {
	float acc = 0.0;
	float area_w = box_size.x + margin.x + margin.z;
	float cw = area_w / cols;
	float ci = floor((p.x + margin.x) / cw);
	for (int k = -1; k <= 1; k++) {
		float id = ci + float(k);
		for (int l = 0; l < 2; l++) {
			float seed = id + float(l) * 53.0;
			float h1 = hash11(seed);
			float h2 = hash11(seed + 17.0);
			float h3 = hash11(seed + 31.0);
			float phase = time * speed * (0.5 + h1) * 0.35 + h2 + float(l) * 0.5;
			float life = fract(phase);
			float awake = step(0.45, hash11(seed + floor(phase) * 13.7));  // random moments: each ember only lights some of its cycles
			float x0 = (id + 0.5 + (h3 - 0.5) * 0.8) * cw - margin.x;
			float y0 = box_size.y * (0.15 + 0.5 * hash11(seed + 7.0));  // starts inside the card, shows once it crosses the outline
			float x = x0 + sin(time * (1.4 + h1 * 2.2) + h2 * 6.28) * sway * life;
			float y = y0 - life * travel;
			float size = sz * (0.6 + h3) * (1.0 - life * 0.7);
			vec2 q = (p - vec2(x, y)) / size;
			float wd = mix(1.0, 0.22, smoothstep(-1.0, 2.0 * aspect, -q.y));  // narrow tip pointing up
			float e = length(vec2(q.x / wd, q.y / aspect));
			float op = (0.35 + 0.65 * hash11(seed + 3.0)) * pow(1.0 - life, 1.4) * awake;
			acc += smoothstep(1.0, 0.45, e) * op;
		}
	}
	return acc;
}

void fragment() {
	vec2 total = box_size + vec2(margin.x + margin.z, margin.y + margin.w);
	vec2 p = UV * total - vec2(margin.x, margin.y);
	float sd = card_sd(p);
	float out_d = max(sd, 0.0);   // distance outside the outline
	float in_d = max(-sd, 0.0);   // depth inside the card
	float up = clamp(1.0 - p.y / box_size.y, 0.0, 1.0);
	float in_fade = exp(-in_d / 5.0);  // halo only hugs the outline from inside
	float breathe = 0.78 + 0.22 * sin(t * 2.3);
	float a = 0.0;
	vec3 col = col_deep;

	// Inside the card the effect is only a faint glow from the base (masked over info).
	float inner = pow(up, 2.0) * 0.4 * smoothstep(0.0, 2.0, in_d);

	// sky plume terms: the aura rises far above the card and fades slowly with height
	float Hup = max(-p.y, 0.0);
	float dxo = max(max(-p.x, p.x - box_size.x), 0.0);
	float taper = exp(-dxo / (10.0 + Hup * 0.14));
	float outside = smoothstep(0.0, 4.0, sd);
	vec2 cc = box_size * 0.5;
	float ang = atan(p.y - cc.y, (p.x - cc.x) / (box_size.x / box_size.y));
	float ny = clamp((cc.y - p.y) / (box_size.y * 0.5 + 12.0), -1.0, 1.0);
	if (style == 1) {
		// 1 "Saiyajin" (DBZ): cel-shaded golden flame spikes flaring mostly UPWARD, hard 2-layer edge, fast flicker, thin electric arcs
		float n = fbm(vec2(p.x * 0.11, p.y * 0.05 + t * 3.2));
		float spike = 1.0 - abs(2.0 * fbm(vec2(p.x * 0.2 + 4.0, t * 2.4 + p.y * 0.04)) - 1.0);
		float topw = 0.28 + 0.72 * max(ny, 0.0);
		float H = 50.0 * topw * (0.1 + 1.5 * pow(n, 1.6) * (0.4 + 0.9 * spike)) * (0.9 + 0.1 * sin(t * 18.0));
		float outer = smoothstep(0.6, -0.6, out_d - H) * step(0.0, sd);
		float inner_l = smoothstep(0.6, -0.6, out_d - H * 0.5) * step(0.0, sd);
		float arc_n = vnoise(vec2(ang * 5.0, floor(t * 14.0)));
		float arc_path = 3.0 + 9.0 * vnoise(vec2(ang * 9.0 + floor(t * 14.0), 2.0));
		float arcs = exp(-abs(out_d - arc_path) / 0.55) * step(0.62, arc_n) * step(0.0, sd);
		float pn = fbm(vec2(p.x * 0.07, p.y * 0.014 + t * 2.8));
		float pl1 = smoothstep(0.3, 0.7, pn * 1.35) * exp(-Hup / 130.0) * taper * outside;
		float pl2 = smoothstep(0.5, 0.85, pn * 1.4) * exp(-Hup / 70.0) * taper * outside;
		float shards = detach(p, t, 12.0, 0.7, 6.0, 3.2, 250.0, 4.0) * step(0.0, sd);
		a = exp(-out_d / 16.0) * 0.22 * in_fade + outer * 0.3 + inner_l * 0.22 + arcs * 1.0 + shards * 1.3 + pl1 * 0.3 + pl2 * 0.4;
		col = mix(vec3(1.0, 0.55, 0.04), vec3(1.0, 0.95, 0.55), clamp(inner_l + arcs + shards * 0.5 + pl2, 0.0, 1.0));
	} else if (style == 2) {
		// 2 "Chakra" (Naruto, Kurama cloak): translucent billowing orange cloak swirling out of the outline in cel bands + rising bubbles
		vec2 q = vec2(fbm(p * 0.05 + vec2(0.0, t * 0.5)), fbm(p * 0.05 + vec2(5.2, -t * 0.4)));
		float n = fbm(p * 0.05 + q * 2.2 - vec2(0.0, t * 0.9));
		float cloak = clamp(n * 1.7 - out_d / 11.0, 0.0, 1.0) * step(0.0, sd);
		float bands = cloak * cloak * (3.0 - 2.0 * cloak);
		vec2 pc = p + vec2(0.0, t * 11.0);
		vec2 cell = floor(pc / 13.0);
		float hh = hash21(cell);
		vec2 ctr = (cell + 0.25 + 0.5 * vec2(hh, fract(hh * 7.0))) * 13.0;
		float br = 2.0 + 3.0 * fract(hh * 13.0);
		float bub = smoothstep(0.9, 0.0, abs(length(pc - ctr) - br)) * step(0.55, hh) * step(0.0, sd) * smoothstep(26.0, 6.0, out_d);
		float pw = fbm(vec2(p.x * 0.05 + sin(p.y * 0.035 - t * 1.5) * 0.9, p.y * 0.02 + t * 1.1));
		float gate = smoothstep(0.35, 0.8, vnoise(vec2(p.x * 0.045, t * 0.8 + 3.0)));  // random patches flare in and out, like embers catching
		float plume = smoothstep(0.0, 1.0, clamp(pw * 1.5 - 0.35, 0.0, 1.0)) * exp(-Hup / (12.0 + 30.0 * gate)) * (0.2 + 0.8 * gate) * taper * outside;
		float blobs = detach(p, t, 11.0, 0.9, 7.0, 1.15, 95.0, 10.0) * step(0.0, sd);
		float flow = step(0.0, -sd) * (0.25 + 0.5 * n);
		a = flow * 0.3 + bands * 0.6 + plume * 0.5 + bub * 0.7 + blobs * 0.55 + exp(-out_d / 18.0) * 0.12 * in_fade + inner * 0.3;
		col = mix(vec3(0.3, 0.62, 1.0), vec3(0.8, 0.93, 1.0), clamp(bands * 0.6 + plume + bub + blobs * 0.5, 0.0, 1.0));  // light blue (D-1243); A and C keep amber, stored for later
	} else {
		// 3 "Nen / Reiatsu" (HxH, Bleach): smooth long wisps flowing up around the card + pressure rings expanding outward
		float w = vnoise(vec2(p.x * 0.07, p.y * 0.012 + t * 1.3)) * 0.6 + vnoise(vec2(p.x * 0.15 + 9.0, p.y * 0.02 + t * 2.0)) * 0.4;
		float wisp = smoothstep(0.42, 0.85, w) * exp(-out_d / 24.0) * step(0.0, sd) * (0.5 + 0.5 * max(ny, -0.2));
		float rings = 0.0;
		for (int k = 0; k < 2; k++) {
			float ph = fract(t * 0.45 + float(k) * 0.5);
			rings += exp(-pow(out_d - ph * 34.0, 2.0) / 1.6) * (1.0 - ph) * step(0.0, sd);
		}
		float wl = vnoise(vec2(p.x * 0.11, p.y * 0.006 + t * 1.7)) * 0.6 + vnoise(vec2(p.x * 0.27 + 3.0, p.y * 0.01 + t * 2.3)) * 0.4;
		float streaks = smoothstep(0.55, 0.85, wl) * exp(-Hup / 170.0) * taper * outside;
		float motes = detach(p, t, 18.0, 0.55, 3.4, 1.8, 270.0, 14.0) * step(0.0, sd);
		a = wisp * 0.55 + streaks * 0.5 + rings * 0.6 + exp(-abs(sd) / 1.2) * 0.3 + motes * 0.9 + exp(-out_d / 20.0) * 0.12 * in_fade + inner * 0.25;
		col = mix(vec3(1.0, 0.68, 0.12), vec3(1.0, 0.96, 0.75), clamp(rings + wisp * 0.4 + streaks * 0.5 + motes * 0.4, 0.0, 1.0));
	}

	float m = rect_mask(p, m0) * rect_mask(p, m1) * rect_mask(p, m2) * rect_mask(p, m3) * rect_mask(p, m4);
	m = 1.0;  // no masks: the whole card is affected; every inside term is low alpha so nothing becomes unreadable (masks drew visible rectangles)
	vec2 ed = min(UV, 1.0 - UV) * total;  // fade to 0 at the draw rect border: no visible box
	float rf = smoothstep(0.0, 30.0, ed.x) * smoothstep(0.0, 40.0, ed.y);
	COLOR = vec4(col, clamp(a, 0.0, 1.0) * m * opacity * rf);
}
