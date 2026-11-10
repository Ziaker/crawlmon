shader_type spatial;
// D-1077: textured stylized water of the projectile library (Tidal Surge body, tongues and sheets).
// The baked seamless texture `water_flow.png` gives the look: R = caustic web, G = soft noise, B = foam breakup.
// Two panned copies of the web are multiplied (water that flows instead of sliding), a broken foam crest sits on
// the top of the form (UV.y) and the mesh dissolves by EROSION (holes and a foam edge), not by flat opacity.
// UV  = form coordinates (x: along 0..1 or around, y: height / top side)   UV2 = texture coordinates (tile space).
// No Glow, no screen flash (D-337/D-418): the brightness comes from the cel bands and the foam.
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform sampler2D flow_tex : repeat_enable, filter_linear_mipmap;
uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.35, 1.0);
uniform vec4 mid_color : source_color = vec4(0.10, 0.50, 0.95, 1.0);
uniform vec4 core_color : source_color = vec4(0.62, 0.95, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float fade = 0.0;        // 0 = solid, 1 = fully eroded
uniform float seed = 0.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 flow = vec2(0.0, -0.6);   // texture scroll, tiles per second
uniform float crest = 0.30;      // share of the top (UV.y) that is broken foam
uniform float soft_tail = 0.0;   // share of the start (UV.x) that breaks up raggedly (the tail of the stream)
uniform float soft_base = 0.0;   // share of the base (UV.y) that fades in (no hard edge on the floor)
uniform bool use_instance = false;  // MultiMesh: INSTANCE_CUSTOM = (seed, fade, -, alpha)

varying vec4 inst;

void vertex() {
	inst = use_instance ? INSTANCE_CUSTOM : vec4(0.0, 0.0, 0.0, 1.0);
}

void fragment() {
	float sd = seed + inst.x;
	vec2 uv = UV2 * uv_scale + vec2(sd * 0.37, sd * 0.61);
	vec2 scroll = TIME * flow;
	float n = texture(flow_tex, uv * 0.8 + scroll * 0.5).g;
	vec2 warp = vec2(n - 0.5, texture(flow_tex, uv * 0.6 - scroll * 0.3 + 0.5).g - 0.5) * 0.14;
	float c1 = texture(flow_tex, uv + scroll + warp).r;
	float c2 = texture(flow_tex, uv * 1.7 + scroll * 0.55 - warp + 0.31).r;
	float caustic = pow(c1 * c2, 1.25) * 2.4;
	float fb = texture(flow_tex, uv * 2.3 + scroll * 1.3).b;

	float h = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(deep_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, h + (n - 0.5) * 0.30));
	col = mix(col, core_color.rgb, smoothstep(0.62, 0.90, h + (n - 0.5) * 0.25));
	// Cel caustic net: a hard-edged light web that travels with the flow.
	col = mix(col, core_color.rgb, smoothstep(0.52, 0.60, caustic) * 0.50);
	// Volume: the silhouette edge goes deep, so the form reads as a body of water and not as a flat sheet.
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	col = mix(mix(deep_color.rgb, mid_color.rgb, 0.35), col, smoothstep(0.05, 0.50, f));
	// Broken foam crest on the top of the form.
	float lip = smoothstep(1.0 - crest, 1.0 - crest * 0.40, h + (fb - 0.5) * 0.40);
	col = mix(col, foam_color.rgb, lip);

	float a = alpha * inst.w;
	// Erosion: the water opens in holes, with a foam edge around each hole, and falls apart.
	float er = clamp(max(fade, inst.y), 0.0, 1.0) * 1.15;
	float mask = n * 0.6 + fb * 0.4;
	a *= smoothstep(er - 0.15, er, mask);
	col = mix(col, foam_color.rgb, (1.0 - smoothstep(er, er + 0.05, mask)) * step(0.02, er) * 0.75);
	if (soft_tail > 0.0) {
		float k = UV.x / soft_tail;
		float tail = smoothstep(0.0, 0.25, k * 1.3 - (1.0 - mask) * 0.9);
		col = mix(foam_color.rgb, col, 0.25 + 0.75 * smoothstep(0.0, 0.22, k * 1.3 - (1.0 - mask) * 0.9 - 0.10));
		a *= tail;
	}
	if (soft_base > 0.0) {
		a *= smoothstep(0.0, soft_base, UV.y);
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
