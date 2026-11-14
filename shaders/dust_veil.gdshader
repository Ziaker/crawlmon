shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;
// Translucent atmospheric dust curtain veil (digDustVeil), ported literally from
// prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
// vertex 908-925, fragment 926-956.
// backFaceCulling = false and ALPHA_COMBINE in the HTML become cull_disabled and blend_mix;
// colors and progress arrive by uniform (D-235).
#include "res://shaders/dust_noise.gdshaderinc"

uniform float u_time = 0.0;
uniform float u_progress = 0.0;
uniform float u_base_opacity = 0.85;
uniform float u_edge_feather = 0.22;
uniform vec3 u_color_light : source_color = vec3(0.890196, 0.811765, 0.658824); // HTML #e3cfa8
uniform vec3 u_color_dark : source_color = vec3(0.490196, 0.380392, 0.243137); // HTML #7d613e

varying vec2 v_uv;
varying vec3 v_normal_w;
varying vec3 v_pos_w;

void vertex() {
	v_uv = UV;
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	v_pos_w = wp.xyz;
	v_normal_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_pos_w);
	float ndotv = abs(dot(normalize(v_normal_w), view_dir));
	float angle = v_uv.x * 6.2831853;
	float n1 = snoise(vec3(cos(angle) * 2.2, v_uv.y * 3.5 - u_time * 2.2, sin(angle) * 2.2)) * 0.5 + 0.5;
	float n2 = snoise(vec3(cos(angle) * 5.0, v_uv.y * 7.0 - u_time * 3.6, sin(angle) * 5.0)) * 0.5 + 0.5;
	float plume_mask = smoothstep(0.22, 0.78, n1 * 0.65 + n2 * 0.35);
	float bottom_soft = smoothstep(0.0, max(0.08, u_edge_feather), v_uv.y);
	float top_soft = pow(max(0.0, 1.0 - v_uv.y), 1.45);
	float vertical_profile = bottom_soft * top_soft;
	float silhouette_soft = smoothstep(0.0, 0.45, ndotv);
	float time_env = smoothstep(0.0, 0.12, u_progress) * (1.0 - smoothstep(0.32, 1.0, u_progress));
	vec3 col = mix(u_color_dark, u_color_light, clamp(v_uv.y * 0.65 + n1 * 0.35, 0.0, 1.0));
	float final_alpha = clamp(plume_mask * vertical_profile * silhouette_soft * time_env * u_base_opacity * 0.54, 0.0, 1.0);
	if (final_alpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = final_alpha;
}
