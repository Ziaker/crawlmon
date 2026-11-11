shader_type canvas_item;
render_mode blend_mix, unshaded;
// D-1106: a short radial smoke-lens at the release of War Cry. It warps the view
// with a pressure wave and adds a radial Gaussian blur; the HUD stays sharp because
// this lives on a CanvasLayer below it.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float strength : hint_range(0.0, 0.02) = 0.0055;
uniform float blur : hint_range(0.0, 8.0) = 3.2;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - center;
	float r = length(d);
	vec2 dir = normalize(d + vec2(0.0001, 0.0001));
	float wave = sin(r * 55.0 - TIME * 18.0) * exp(-r * 5.0);
	uv += dir * wave * strength * amount;

	// 9-tap radial Gaussian: the view smears outward from the shout.
	vec2 step_px = SCREEN_PIXEL_SIZE * (blur * amount);
	vec3 col = texture(screen_tex, clamp(uv, vec2(0.0), vec2(1.0))).rgb * 0.227027;
	col += texture(screen_tex, clamp(uv + dir * step_px * 1.3846, vec2(0.0), vec2(1.0))).rgb * 0.316216;
	col += texture(screen_tex, clamp(uv - dir * step_px * 1.3846, vec2(0.0), vec2(1.0))).rgb * 0.316216;
	col += texture(screen_tex, clamp(uv + dir * step_px * 3.2308, vec2(0.0), vec2(1.0))).rgb * 0.070270;
	col += texture(screen_tex, clamp(uv - dir * step_px * 3.2308, vec2(0.0), vec2(1.0))).rgb * 0.070270;
	col += texture(screen_tex, clamp(uv + dir * step_px * 5.0769, vec2(0.0), vec2(1.0))).rgb * 0.008910;
	col += texture(screen_tex, clamp(uv - dir * step_px * 5.0769, vec2(0.0), vec2(1.0))).rgb * 0.008910;
	col += texture(screen_tex, clamp(uv + dir * step_px * 6.9231, vec2(0.0), vec2(1.0))).rgb * 0.002160;
	col += texture(screen_tex, clamp(uv - dir * step_px * 6.9231, vec2(0.0), vec2(1.0))).rgb * 0.002160;

	// Neutral white edge tint, very light (Neutral move; no red).
	col = mix(col, vec3(1.0, 0.98, 0.92), 0.04 * amount * clamp(1.0 - r, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
