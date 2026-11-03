shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Expanding shockwave ring on a QuadMesh (lay it flat on the floor, or face it
// at the camera). `progress` 0..1 grows and fades it.

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 2.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float ring_r = 0.12 + progress * 0.85;
	float w = mix(0.16, 0.035, progress);
	float ring = smoothstep(w, 0.0, abs(r - ring_r));
	float inner = smoothstep(ring_r, 0.0, r) * (1.0 - progress) * 0.18;
	float fade = (1.0 - progress) * (1.0 - progress);
	float a = clamp((ring + inner) * fade * color.a, 0.0, 1.0);
	if (a < 0.02) {
		discard;
	}
	ALBEDO = mix(color.rgb, vec3(1.0), ring * 0.6) * energy;
	ALPHA = a;
}
