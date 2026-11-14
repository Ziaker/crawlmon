shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;
// Sculpted polar split-crown dust shell (crownShell), ported literally from
// prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
// vertex 724-749, fragment 750-788.
// backFaceCulling = false becomes cull_disabled. The HTML sets no disableDepthWrite (Babylon then
// writes depth for the blended mesh); Godot's blend_mix default does not. Pending: decide by
// comparing real frames against the HTML (same for the other three dust shaders).
// Every color, lobe count, gap, open/dissolve progress and alpha arrives by uniform: nothing
// depends on character, team or side (D-235).

uniform vec3 u_core : source_color = vec3(0.960784, 0.901961, 0.827451); // HTML #f5e6d3
uniform vec3 u_primary : source_color = vec3(0.760784, 0.607843, 0.407843); // HTML #c29b68
uniform vec3 u_secondary : source_color = vec3(0.360784, 0.250980, 0.141176); // HTML #5c4024
uniform float u_lobes = 7.0;
uniform float u_gap_openness = 0.44;
uniform float u_open_progress = 0.0;
uniform float u_dissolve = 0.0;
uniform float u_master_alpha = 1.0;
uniform float u_base_opacity = 0.85;
uniform float u_edge_feather = 0.22;

varying vec2 v_uv;
varying vec3 v_normal_w;
varying vec3 v_position_w;

void vertex() {
	v_uv = UV;
	float u = UV.x;
	float angle = UV.y * 6.2831853;
	float wave = cos(angle * u_lobes) * 0.5 + 0.5;
	vec3 pos = VERTEX;
	float flare = smoothstep(0.10, 0.95, u) * u_open_progress;
	pos += NORMAL * (wave * 0.22 * flare);
	vec4 world_pos = MODEL_MATRIX * vec4(pos, 1.0);
	v_position_w = world_pos.xyz;
	v_normal_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = pos;
}

void fragment() {
	vec3 uCameraPos = CAMERA_POSITION_WORLD;
	float u = v_uv.x;
	float angle = v_uv.y * 6.2831853;
	float lobeWave = cos(angle * u_lobes) * 0.5 + 0.5;
	float tipReach = mix(0.28, 0.98, pow(lobeWave, 0.72)) * (1.0 - u_dissolve * 0.82);
	float valleyFloor = 0.14 + (1.0 - u_gap_openness) * 0.34;
	float cutoffU = mix(valleyFloor, tipReach, lobeWave);
	float edgeMargin = cutoffU - u;
	if (edgeMargin < 0.0 || u < u_dissolve * 0.32) {
		discard;
	}
	vec3 viewDir = normalize(uCameraPos - v_position_w);
	float ndotv = abs(dot(normalize(v_normal_w), viewDir));
	float fresnel = 1.0 - ndotv;
	float isCutoutLip = 1.0 - smoothstep(0.0, 0.095, edgeMargin);
	vec3 col = mix(u_secondary, u_primary, smoothstep(0.15, 0.65, lobeWave));
	col = mix(col, u_core, isCutoutLip * 0.92 + smoothstep(0.68, 0.95, fresnel) * 0.65);
	float edgeAlpha = smoothstep(0.0, max(0.02, u_edge_feather), edgeMargin);
	float bodyAlpha = mix(u_base_opacity * 0.44, u_base_opacity, clamp(pow(fresnel, 1.1) + isCutoutLip * 0.85, 0.0, 1.0));
	float groundContactFade = smoothstep(0.0, 0.22, v_position_w.y + 0.04);
	float finalAlpha = clamp(bodyAlpha * edgeAlpha * groundContactFade * u_master_alpha, 0.0, 1.0);
	if (finalAlpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = finalAlpha;
}
