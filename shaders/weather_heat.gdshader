shader_type canvas_item;
render_mode blend_mix, unshaded;

// Calor ondulado (D-387), camada 2D de ambiente, fora do Motion Composer (D-383).
// Distorce a tela com duas senoides, mais forte perto do chão, e aplica um tom
// âmbar com um RGB shift bem leve. `amount` 0..1 faz o fade do evento.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.02) = 0.0048;
uniform float speed : hint_range(0.0, 4.0) = 1.0;
uniform float tint_amount : hint_range(0.0, 0.5) = 0.10;
uniform vec4 tint : source_color = vec4(1.0, 0.68, 0.42, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * speed;
	float w1 = sin(uv.y * 34.0 + t * 2.1);
	float w2 = sin(uv.y * 13.0 - t * 1.4 + uv.x * 3.0);
	float wave = w1 * 0.62 + w2 * 0.38;
	float ground = mix(0.55, 1.0, uv.y);
	vec2 offset = vec2(wave * strength * amount * ground, 0.0);
	offset.y += sin(uv.x * 21.0 + t * 1.7) * strength * 0.35 * amount * ground;
	vec2 sample_uv = clamp(uv + offset, vec2(0.0), vec2(1.0));
	float shift = 0.0012 * amount;
	vec3 col;
	col.r = texture(screen_tex, clamp(sample_uv + vec2(shift, 0.0), vec2(0.0), vec2(1.0))).r;
	col.g = texture(screen_tex, sample_uv).g;
	col.b = texture(screen_tex, clamp(sample_uv - vec2(shift, 0.0), vec2(0.0), vec2(1.0))).b;
	col = mix(col, tint.rgb, tint_amount * amount);
	COLOR = vec4(col, 1.0);
}
