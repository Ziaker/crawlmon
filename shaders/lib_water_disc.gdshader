shader_type spatial;
// D-1077: a flat disc of textured water on the floor (Tidal Surge): the swirling vortex of the wind-up and the
// expanding foam rings of the release and of the impact. The mesh is a quad lying on the floor (UV 0..1); the
// water is drawn in POLAR coordinates over the baked `water_flow.png` (R caustic web, G soft noise, B foam).
// `swirl` twists the web into spiral arms; `ring_inner`/`ring_outer` cut a ring with a ragged foam rim.
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform sampler2D flow_tex : repeat_enable, filter_linear_mipmap;
uniform vec4 deep_color : source_color = vec4(0.01, 0.10, 0.30, 1.0);
uniform vec4 mid_color : source_color = vec4(0.08, 0.45, 0.95, 1.0);
uniform vec4 core_color : source_color = vec4(0.45, 0.90, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float fade = 0.0;
uniform float seed = 0.0;
uniform float arms = 3.0;        // whole number: tiles of the texture around the circle (keeps the seam closed)
uniform float swirl = 1.6;       // twist of the arms toward the centre
uniform float spin = 0.9;        // turns of the texture per second
uniform float inflow = 0.35;     // radial scroll (positive: the water is pulled in)
uniform float ring_inner = 0.0;  // 0..1 of the disc radius
uniform float ring_outer = 1.0;
uniform float rim_foam = 0.22;   // width of the foam band on the outer rim (in radius)

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / 6.2831853;
	vec2 uv = vec2(ang * arms + r * swirl - TIME * spin + seed * 0.37, r * 1.2 + TIME * inflow + seed * 0.61);
	float n = textureLod(flow_tex, uv * vec2(1.0, 0.8), 1.0).g;
	float c1 = textureLod(flow_tex, uv + vec2(n - 0.5, 0.0) * 0.12, 1.0).r;
	float c2 = textureLod(flow_tex, uv * vec2(2.0, 1.6) + vec2(TIME * spin * 0.5, 0.21), 1.0).r;
	float caustic = pow(c1 * c2, 1.25) * 2.4;
	float fb = textureLod(flow_tex, uv * vec2(3.0, 2.2), 1.0).b;

	float span = max(ring_outer - ring_inner, 0.001);
	float k = clamp((r - ring_inner) / span, 0.0, 1.0);  // 0 inner edge .. 1 outer rim
	vec3 col = mix(deep_color.rgb, mid_color.rgb, smoothstep(0.0, 0.6, k + (n - 0.5) * 0.3));
	col = mix(col, core_color.rgb, smoothstep(0.40, 0.48, caustic) * 0.75);
	float rim = smoothstep(ring_outer - rim_foam, ring_outer - rim_foam * 0.35, r + (fb - 0.5) * rim_foam);
	col = mix(col, foam_color.rgb, rim);

	float a = alpha;
	a *= smoothstep(ring_inner - 0.02, ring_inner + 0.10 * span + 0.02, r + (n - 0.5) * 0.10);
	a *= 1.0 - smoothstep(ring_outer - 0.06, ring_outer, r + (fb - 0.5) * 0.10);
	float er = clamp(fade, 0.0, 1.0) * 1.15;
	float mask = n * 0.6 + fb * 0.4;
	a *= smoothstep(er - 0.15, er, mask);
	col = mix(col, foam_color.rgb, (1.0 - smoothstep(er, er + 0.10, mask)) * step(0.02, er));
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
