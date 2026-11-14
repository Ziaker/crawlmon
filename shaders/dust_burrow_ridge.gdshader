shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque;
// Dig burrow ridge (D-1196, trajeto): a ground strip along the path whose vertices rise into a traveling mound of
// earth that follows the hidden digger (head at u_head), splits into a trench behind it and leaves churned soil.
// Palette and noise come from the HTML's digCrater / dust shaders (#a37c4c, #5c3e23, #120b06; simplex noise).
// Not a port: the HTML has no continuous trail (creator: "o trajeto só tem efeito de dust"); built by the IA on delegation.
#include "res://shaders/dust_noise.gdshaderinc"

uniform float u_head = 0.0;  // 0..1 along the path (meters = u_head * u_length)
uniform float u_length = 30.0;
uniform float u_width = 3.2;
uniform float u_height = 0.9;
uniform float u_time = 0.0;
uniform float u_fade = 1.0;
uniform vec3 u_soil_light : source_color = vec3(0.639216, 0.486275, 0.298039);
uniform vec3 u_soil_mid : source_color = vec3(0.360784, 0.243137, 0.137255);
uniform vec3 u_soil_dark : source_color = vec3(0.070588, 0.043137, 0.023529);

varying vec3 v_normal_w;
varying vec2 v_local;
varying float v_h;
varying float v_behind;

float ridge_height(vec2 p) {
	float d = u_head * u_length - p.y;  // meters behind the head
	if (d < 0.0) {
		return 0.0;
	}
	float rise = smoothstep(0.0, 1.8, d);
	float decay = exp(-d / 4.5);
	float across = exp(-pow(p.x / (u_width * 0.24), 2.0));
	float clump = 0.65 + 0.35 * snoise(vec3(p.x * 1.6, p.y * 1.6, 0.0));
	float mound = rise * decay * across * clump;
	float trench = exp(-pow(p.x / 0.22, 2.0)) * smoothstep(0.6, 2.0, d) * exp(-d / 2.4) * clump;
	return max(u_height * (mound - 0.4 * trench), 0.0);
}

void vertex() {
	vec2 p = vec2(VERTEX.x, VERTEX.z);
	float h = ridge_height(p);
	float eps = 0.18;
	float hx = ridge_height(p + vec2(eps, 0.0)) - ridge_height(p - vec2(eps, 0.0));
	float hz = ridge_height(p + vec2(0.0, eps)) - ridge_height(p - vec2(0.0, eps));
	vec3 n_local = normalize(vec3(-hx, 2.0 * eps, -hz));
	v_normal_w = normalize((MODEL_MATRIX * vec4(n_local, 0.0)).xyz);
	v_local = p;
	v_h = h;
	v_behind = u_head * u_length - p.y;
	VERTEX.y += h;
}

void fragment() {
	vec3 light_dir = normalize(vec3(-0.35, 0.85, 0.4));
	float ndl = dot(normalize(v_normal_w), light_dir) * 0.5 + 0.5;
	float h_norm = clamp(v_h / max(u_height, 0.001), 0.0, 1.0);
	float grain = snoise(vec3(v_local * 3.2, 1.7)) * 0.5 + 0.5;
	float lit = clamp(pow(ndl, 2.2) * 0.8 + grain * 0.2, 0.0, 1.0);
	vec3 col = mix(u_soil_dark * 1.6, u_soil_light, lit);
	float crack = abs(snoise(vec3(v_local * 1.5, 3.1)));
	float fissure = (1.0 - smoothstep(0.0, 0.09, crack)) * smoothstep(0.05, 0.4, h_norm);
	col = mix(col, u_soil_dark, fissure * 0.85);
	// churned soil left on the ground behind the head
	float behind = smoothstep(0.0, 0.6, v_behind);
	float footprint = exp(-pow(v_local.x / (u_width * 0.28), 2.0)) * behind * 0.6;
	col = mix(col, u_soil_mid * 0.7, footprint * (1.0 - h_norm));
	float edge = 1.0 - smoothstep(u_width * 0.42, u_width * 0.5, abs(v_local.x));
	float alpha = clamp(max(smoothstep(0.015, 0.14, v_h), footprint), 0.0, 1.0) * edge * u_fade;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = alpha;
}
