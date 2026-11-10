shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Papel mágico do wind-up: fita que ondula no vertex e corre no sentido oposto ao giro.
uniform float time = 0.0;
uniform float alpha = 0.82;
uniform float root_rot = 0.0;
uniform float cam_az = 0.0;
uniform float speed = 2.4;
uniform float wave = 0.10;
uniform vec3 color_a : source_color = vec3(0.078, 0.314, 0.659);
uniform vec3 color_b : source_color = vec3(0.180, 0.608, 1.0);
uniform vec3 foam : source_color = vec3(0.949, 1.0, 1.0);

varying vec2 v_uv;
varying float v_angle;

void vertex() {
	v_uv = UV;
	v_angle = atan(VERTEX.z, VERTEX.x);
	vec3 p = VERTEX;
	float edge = sin(UV.y * 3.1415926);
	p.z += sin(UV.x * 12.0 + time * 2.4 + UV.y * 4.0) * wave * edge;
	p.y += cos(UV.x * 8.0 - time * 1.8 + UV.y * 3.0) * wave * 0.55 * edge;
	p.x += sin(UV.x * 10.0 + time * 1.4) * wave * 0.20 * edge;
	VERTEX = p;
}

void fragment() {
	float along = v_uv.x;
	float across = v_uv.y;
	float front = max(0.0, cos(v_angle + root_rot - cam_az));
	float fade = mix(1.0, 0.18, front);
	float edge_noise = 0.5 + 0.5 * sin(along * 90.0 + sin(along * 17.0) * 2.0);
	float edge_cut = 0.05 + 0.035 * edge_noise;
	float edge = smoothstep(0.0, edge_cut, across) * (1.0 - smoothstep(1.0 - edge_cut, 1.0, across));
	float crest = smoothstep(0.55, 0.95,
		sin(along * 32.0 - time * speed + sin(across * 7.0 + time) * 2.0) * 0.5 + 0.5);
	float foam_field = smoothstep(0.70, 0.98, across + 0.06 * sin(along * 26.0 - time * 1.4))
		* (0.55 + 0.45 * crest);
	float paper_edge = smoothstep(0.0, 0.08, min(across, 1.0 - across));
	float fold = smoothstep(0.985, 1.0, sin(along * 40.0 + across * 3.0) * 0.5 + 0.5) * 0.14;
	float fiber = 0.94 + 0.06 * sin(along * 140.0 + across * 20.0);

	vec3 col = mix(color_a, color_b, clamp(across * 0.80 + crest * 0.20, 0.0, 1.0));
	col = mix(vec3(0.02, 0.10, 0.13), col, paper_edge);
	col = mix(col, foam, clamp(foam_field * 0.35 + crest * 0.08, 0.0, 1.0));
	col *= fiber * (1.0 - fold);

	float a = (0.55 + crest * 0.14 + foam_field * 0.06) * edge * alpha * fade;
	if (a < 0.008) {
		discard;
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
