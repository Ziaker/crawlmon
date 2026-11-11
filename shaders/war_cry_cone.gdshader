shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// D-1106: faint megaphone shell for War Cry. UV.y runs from the mouth (0) to the
// far end (1); opacity falls toward the opponents and the ribs suggest the rings.

uniform vec4 color : source_color = vec4(1.0, 0.12, 0.08, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.38, 0.24, 1.0);
uniform float alpha = 0.16;
uniform float energy = 1.2;
uniform float time = 0.0;
uniform sampler2D wave_tex : filter_linear, repeat_enable;

float hash11(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	float along = clamp(UV.y, 0.0, 1.0);
	float fade = mix(1.0, 0.08, along);
	float ribs = 0.72 + 0.28 * sin(along * 62.0 - time * 22.0);
	float n = hash11(floor(UV.x * 36.0) + floor(along * 18.0));
	vec4 detail = texture(wave_tex, vec2(UV.x, along * 1.25 + time * 0.05));
	float a = alpha * fade * ribs * (0.35 + 0.65 * detail.a) * (0.72 + 0.28 * n);
	if (a < 0.01) {
		discard;
	}
	vec3 c = mix(color.rgb, core.rgb, (1.0 - along) * 0.7);
	ALBEDO = c * energy;
	ALPHA = a;
}
