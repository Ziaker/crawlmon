shader_type spatial;
// D-1021: stylized water of the projectile library (Tidal Surge). Cel bands picked by Fresnel: pale core where the
// surface faces the camera, cyan mid, deep-blue rim. A slow caustic ripple runs on the surface. No Glow (D-337):
// the brightness comes from the bands and the light-blue core. `fade` dissolves the mesh smoothly (Start/Post).
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 core_color : source_color = vec4(0.55, 0.92, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(0.12, 0.55, 0.95, 1.0);
uniform vec4 deep_color : source_color = vec4(0.015, 0.12, 0.35, 1.0);
uniform float alpha = 1.0;
uniform float fade = 0.0;
uniform float flow = 1.0;
uniform float seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 col = f > 0.70 ? core_color.rgb : (f > 0.35 ? mid_color.rgb : deep_color.rgb);
	// Slow, wide caustic bands: the surface reads as moving water without becoming noisy at ~37 m.
	float ripple = sin(UV.x * 18.0 + UV.y * 12.0 + TIME * (1.4 + flow) + seed * 6.283);
	float caustic = smoothstep(0.72, 1.0, ripple);
	col += mid_color.rgb * caustic * 0.28;
	// Tiny bright specks, like foam, kept sparse so they do not read as sparks.
	float specks = step(0.93, hash21(floor(UV * vec2(26.0, 10.0)) + seed));
	col = mix(col, core_color.rgb, specks * 0.45);
	ALBEDO = col;
	ALPHA = clamp(alpha * (1.0 - fade), 0.0, 1.0);
}
