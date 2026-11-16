shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
// D-1259 (teste): brilho suave no chao sob cada Casco.

uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float strength = 0.6;
uniform float phase = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float fall = pow(clamp(1.0 - d, 0.0, 1.0), 2.2);
	float pulse = 0.75 + 0.25 * sin(TIME * 2.4 + phase);
	ALBEDO = tint.rgb;
	ALPHA = fall * strength * pulse;
}
