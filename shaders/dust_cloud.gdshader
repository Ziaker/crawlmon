shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;
// Volumetric 3D billowing dust cloud (digDustCloud), ported literally from
// prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
// vertex 836-863, fragment 864-905.
// Beer-Lambert translucency + FBM concave erosion + ground contact fade. The vertex
// displacement uses the mesh's LOCAL position (VERTEX, like Babylon's `position` attribute);
// the fragment works from the world position varying. backFaceCulling = false and
// ALPHA_COMBINE in the HTML become cull_disabled and blend_mix. Colors, seed and progress
// arrive by uniform: nothing depends on character, team or side (D-235).
#include "res://shaders/dust_noise.gdshaderinc"

uniform float u_time = 0.0;
uniform float u_progress = 0.0;
uniform float u_seed = 0.0;
uniform float u_base_opacity = 0.85;
uniform float u_edge_feather = 0.22;
uniform vec3 u_color_lit : source_color = vec3(0.901961, 0.823529, 0.709804); // HTML #e6d2b5
uniform vec3 u_color_mid : source_color = vec3(0.701961, 0.572549, 0.407843); // HTML #b39268
uniform vec3 u_color_shadow : source_color = vec3(0.388235, 0.294118, 0.188235); // HTML #634b30

varying vec2 v_uv;
varying vec3 v_normal_w;
varying vec3 v_pos_w;
varying float v_billow;

void vertex() {
	v_uv = UV;
	float n = snoise(vec3(VERTEX * 1.9 + vec3(0.0, -u_time * 1.8, u_seed * 4.3)));
	float n2 = snoise(vec3(VERTEX * 3.8 + vec3(u_seed * 2.1, u_time * 2.4, 0.0))) * 0.45;
	float displacement = (n + n2) * (0.26 + u_progress * 0.22);
	v_billow = n * 0.5 + 0.5;
	vec3 displaced_pos = VERTEX + NORMAL * displacement;
	vec4 wp = MODEL_MATRIX * vec4(displaced_pos, 1.0);
	v_pos_w = wp.xyz;
	v_normal_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = displaced_pos;
}

void fragment() {
	vec3 n_w = normalize(v_normal_w);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_pos_w);
	float ndotv = abs(dot(n_w, view_dir));
	vec3 light_dir = normalize(vec3(-0.35, 0.85, 0.4));
	float ndotl = dot(n_w, light_dir) * 0.5 + 0.5;
	float shade_val = clamp(ndotl * 0.72 + v_billow * 0.36, 0.0, 1.0);
	vec3 col = u_color_shadow;
	col = mix(col, u_color_mid, smoothstep(0.28, 0.48, shade_val));
	col = mix(col, u_color_lit, smoothstep(0.62, 0.82, shade_val));
	float fbm1 = snoise(vec3(v_pos_w * 2.2 + vec3(u_seed, -u_time * 1.4, u_seed))) * 0.5 + 0.5;
	float fbm2 = snoise(vec3(v_pos_w * 4.6 - vec3(u_time * 2.1, u_seed, 0.0))) * 0.5 + 0.5;
	float density_map = clamp(fbm1 * 0.65 + fbm2 * 0.35, 0.0, 1.0);
	float rim_softness = pow(ndotv, mix(0.65, 1.55, clamp(u_edge_feather * 2.5, 0.0, 1.0)));
	float concave_erosion = u_progress * 1.15 - (density_map * 0.68 + ndotv * 0.48);
	if (concave_erosion > 0.0) {
		discard;
	}
	float erosion_feather = smoothstep(0.0, max(0.06, u_edge_feather * 1.35), -concave_erosion);
	float beer_lambert_alpha = mix(0.22, 0.76, density_map * rim_softness);
	float ground_contact_fade = smoothstep(0.0, 0.26, v_pos_w.y + 0.05);
	float fade_in = smoothstep(0.0, 0.10, u_progress);
	float fade_out = 1.0 - smoothstep(0.45, 1.0, u_progress);
	float final_alpha = clamp(beer_lambert_alpha * erosion_feather * ground_contact_fade * fade_in * fade_out * u_base_opacity, 0.0, 1.0);
	if (final_alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = final_alpha;
}
