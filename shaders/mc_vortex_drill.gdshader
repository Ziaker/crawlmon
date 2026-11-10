shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// D-379: cone de vórtice do início da estocada. Um funil aditivo com linhas espirais que giram como um
// ventilador; a base larga fica na mão e a ponta fina vai para a frente. UV.x = volta, UV.y = altura.

uniform vec4 color : source_color = vec4(0.42, 0.90, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.90, 1.0, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.30;
uniform float energy = 2.2;
uniform float turns = 6.0;
uniform float spin_speed = 4.2;
uniform float tt = 0.0;
uniform float seed = 0.0;
uniform float rim_power = 1.5;

void fragment() {
	float ang = UV.x;
	float h = clamp(UV.y, 0.0, 1.0);
	// Várias linhas espirais correndo ao longo do cone; o giro é o do ventilador.
	float s = sin((ang * turns + h * 1.6 - tt * spin_speed) * 6.2831853 + seed);
	float arm = smoothstep(0.42, 0.98, s);
	// Bordas do cone: some no cabo e na ponta para não cortar duro.
	float body = smoothstep(0.0, 0.06, h) * smoothstep(1.0, 0.90, h);
	float fres = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), rim_power);
	float glow = 0.28 + 0.72 * arm;
	ALBEDO = mix(color.rgb, core_color.rgb, arm * 0.75) * energy;
	ALPHA = clamp(opacity * body * glow * (0.55 + 0.45 * fres), 0.0, 1.0);
}
