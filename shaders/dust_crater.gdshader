shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;
// Torn-earth physical crater decal (digCrater), ported literally from
// prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
// vertex 791-801, fragment 802-833.
// The HTML material sets backFaceCulling = false and ALPHA_COMBINE, mirrored here by
// cull_disabled and blend_mix; it never sets disableDepthWrite, so Godot's transparent default
// (no depth write) is left untouched. Colors arrive by uniform (D-235).
// UV is expected in 0..1 across the decal quad (the HTML's ground plane); the plane itself is
// built by the caller, not here.
#include "res://shaders/dust_noise.gdshaderinc"

uniform float u_time = 0.0;
uniform float u_progress = 0.0;
uniform float u_base_opacity = 0.85;
uniform float u_edge_feather = 0.22;
uniform vec3 u_color_soil_light : source_color = vec3(0.639216, 0.486275, 0.298039); // HTML #a37c4c
uniform vec3 u_color_soil_mid : source_color = vec3(0.360784, 0.243137, 0.137255); // HTML #5c3e23
uniform vec3 u_color_abyss : source_color = vec3(0.070588, 0.043137, 0.023529); // HTML #120b06

varying vec2 v_uv;

void vertex() {
	v_uv = UV * 2.0 - 1.0;
}

void fragment() {
	float r = length(v_uv);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(v_uv.y, v_uv.x);
	float n1 = snoise(vec3(v_uv * 5.0, 1.2));
	float n2 = snoise(vec3(v_uv * 12.0, 3.4));
	float holeEdge = 0.44 + n1 * 0.09;
	float abyssHole = 1.0 - smoothstep(holeEdge - 0.08, holeEdge + 0.05, r);
	float rimBand = smoothstep(holeEdge - 0.06, holeEdge + 0.08, r) * (1.0 - smoothstep(0.65, 0.98, r + n1 * 0.1));
	float crackWave = abs(sin(angle * 7.0 + r * 6.0 + n1 * 2.4));
	float darkCrack = (1.0 - smoothstep(0.0, 0.14, crackWave)) * (1.0 - smoothstep(0.35, 0.92, r));
	vec3 soilCol = mix(u_color_soil_mid, u_color_soil_light, clamp(n2 * 0.5 + 0.5, 0.0, 1.0));
	soilCol = mix(soilCol, u_color_abyss, darkCrack * 0.85);
	vec3 col = mix(soilCol, u_color_abyss, abyssHole);
	float outerFeather = 1.0 - smoothstep(0.95 - u_edge_feather, 1.0, r);
	float fadeOut = 1.0 - smoothstep(0.68, 1.0, u_progress);
	float finalAlpha = clamp((abyssHole * 0.96 + rimBand * 0.88 + darkCrack * 0.65) * outerFeather * fadeOut * u_base_opacity, 0.0, 1.0);
	if (finalAlpha < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = finalAlpha;
}
