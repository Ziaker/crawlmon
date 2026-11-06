shader_type canvas_item;
render_mode blend_mix;

// Vinheta suave de tela: escurece só as bordas, com dither para não criar
// degraus de cor. Fica numa CanvasLayer abaixo do diálogo e dos menus.
uniform vec4 tint : source_color = vec4(0.015, 0.022, 0.035, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.32;
uniform float softness : hint_range(0.05, 1.0) = 0.55;
uniform float dither_strength : hint_range(0.0, 0.05) = 0.008;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = distance(uv, vec2(0.5));
	float v = smoothstep(0.5 - softness * 0.5, 0.5 + softness * 0.5, d) * strength;
	v += (hash(FRAGCOORD.xy) - 0.5) * dither_strength;
	COLOR = vec4(tint.rgb, clamp(v, 0.0, 1.0));
}
