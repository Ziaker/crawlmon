shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled;
// Motion Composer V1.1 (D-322): the body of a flame on a real 3D tube (MotionMesh) or a sphere. Cel-shaded like the
// game (hard colour bands: pale core, yellow, orange, red edge) but volumetric: the silhouette is pushed out by noise
// that streams along the body and rises, the centre facing the camera is hot and the rim is red, and the tail is eaten
// away by noise instead of fading flat. Opaque (alpha-tested), so it never needs sorting and works in GL Compatibility.
// Explicit time `tt` (never TIME): the effect clock decides (D-019).
//
// Vertex colour (MotionMesh): r = 0 tail .. 1 head, g = intensity, b = dissolve progress (0 whole .. 1 gone), a = radius (m).
// UV.x = angle 0..1, UV.y = metres along the strand (stable while the tube stretches).

uniform vec4 core : source_color = vec4(1.0, 0.97, 0.72, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.5, 0.06, 1.0);
uniform vec4 edge : source_color = vec4(0.93, 0.2, 0.04, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float seed = 0.0;
uniform float flow = 3.2;           // how fast the noise streams from the head toward the tail (m/s of pattern)
uniform float lick = 0.35;          // how far the silhouette is pushed out by the noise (fraction of the radius scale)
uniform float rise = 0.5;           // how much the loose tail drifts upward
uniform float noise_scale = 2.2;    // pattern density along the body (cycles per metre)
uniform float swirl = 0.6;          // pattern twist around the body
uniform float bias = 0.0;           // shifts the colour bands (negative = more orange)
uniform float tail_erode = 0.55;    // how strongly noise eats the tail (0 = clean taper)
uniform float use_uv_len = 1.0;     // 1 = UV.y is metres along a tube; 0 = a sphere (UV is 0..1, no vertex colour)
uniform float dissolve = 0.0;       // sphere only: dissolve progress
uniform float head_pos = 0.85;      // sphere only: how 'head' the sphere is (colour and licking)
uniform float sphere_radius = 0.4;  // sphere only: radius in metres (the licks are a fraction of the radius)
uniform float core_sharp = 2.2;     // how narrow the hot centre is (higher = the red/orange body dominates)

varying vec3 pcoord;
varying vec4 vc;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), f.x), mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), f.x), mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

float fbm3(vec3 p) {
	return vnoise3(p) * 0.6 + vnoise3(p * 2.07 + 5.3) * 0.4;
}

// Seamless cylindrical pattern coordinate: angle wraps without a seam, the along axis flows toward the tail.
vec3 pattern_coord(vec2 uv, float u_head) {
	float a = uv.x * 6.2831853;
	float along = (use_uv_len > 0.5 ? uv.y : uv.y * 3.0) * noise_scale;
	float tw = a + along * swirl;
	return vec3(cos(tw) * 0.9, sin(tw) * 0.9, along - tt * flow + seed);
}

void vertex() {
	vc = use_uv_len > 0.5 ? COLOR : vec4(head_pos, 1.0, dissolve, sphere_radius);
	vec3 pc = pattern_coord(UV, vc.r);
	pcoord = pc;
	float n = fbm3(pc * 1.3) - 0.45;
	float k = lick * vc.a * (0.45 + 0.55 * (1.0 - vc.r));   // licks are a fraction of the radius; the tail licks more than the head
	VERTEX += NORMAL * n * k;
	VERTEX.y += max(n, 0.0) * k * rise * (1.0 - vc.r);
}

void fragment() {
	float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float n = fbm3(pcoord * 1.6);
	float head = vc.r;
	float heat = pow(ndv, core_sharp) * 0.95 + (n - 0.5) * 0.7 + head * 0.1 - 0.02 + bias;
	// Erosion: the dissolve progress plus a ragged tail (the old end of the flame breaks into licks and ends).
	float e = fbm3(pcoord * 2.3 + vec3(3.7, 1.9, 0.0));
	float cut = vc.b * 1.06 + pow(1.0 - head, 2.2) * tail_erode * (0.35 + 0.65 * e);
	if (e < cut) {
		discard;
	}
	float rim_ember = step(e, cut + 0.07);   // a thin dark-red edge where the flame is being eaten
	vec3 c = edge.rgb;
	c = mix(c, mid.rgb, step(0.2, heat));
	c = mix(c, hot.rgb, step(0.44, heat));
	c = mix(c, core.rgb, step(0.76, heat));
	c = mix(c, edge.rgb * 0.7, rim_ember);
	ALBEDO = c * intensity * vc.g;
	ALPHA = 1.0;
}
