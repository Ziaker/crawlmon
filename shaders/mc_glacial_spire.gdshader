shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled;
// Motion Composer V1.8 (D-337): Geleira Cônica 3D do Mabufula (spawnGlacialSpireCluster do Atelier HTML).

uniform vec4 c_deep : source_color = vec4(0.0, 0.4, 0.8, 1.0);      // #0066cc
uniform vec4 c_rim : source_color = vec4(0.722, 1.0, 1.0, 1.0);     // #b8ffff
uniform float opacity : hint_range(0.0, 1.0) = 0.92;

varying float v_height;

void vertex() {
	v_height = VERTEX.y;
}

void fragment() {
	float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	float heightGlow = clamp(v_height * 0.35, 0.0, 1.0);
	vec3 col = mix(c_deep.rgb, c_rim.rgb, clamp(fresnel * 0.75 + heightGlow * 0.45, 0.0, 1.0));
	ALBEDO = col * 1.35;
	ALPHA = opacity;
}
