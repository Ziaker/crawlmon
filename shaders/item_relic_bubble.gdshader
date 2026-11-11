shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// D-1158: bolha de relíquia. O centro fica transparente para o ícone aparecer;
// só o rim Fresnel desenha, com um leve halo dourado.

uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.56, 1.0);
uniform float rim_power = 2.6;
uniform float rim_alpha = 0.72;
uniform float glow = 0.10;

void fragment() {
	float facing = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fres = pow(1.0 - facing, rim_power);
	ALBEDO = rim_color.rgb;
	ALPHA = clamp(fres * rim_alpha + glow * 0.08, 0.0, 1.0);
	EMISSION = rim_color.rgb * (fres * 0.45 + glow * 0.12);
}
