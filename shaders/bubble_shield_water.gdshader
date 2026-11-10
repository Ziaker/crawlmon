shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Fitas de água helicoidais que sobem junto com a formação da bolha.
uniform float time = 0.0;
uniform float alpha = 0.0;
uniform float reveal = 1.0;
uniform float root_rot = 0.0;
uniform float cam_az = 0.0;
uniform vec3 color_a : source_color = vec3(0.027, 0.118, 0.247);
uniform vec3 color_b : source_color = vec3(0.561, 0.910, 1.0);
uniform float speed = 2.6;
uniform float amp = 0.035;

varying vec2 v_uv;
varying float v_angle;

void vertex() {
	v_uv = UV;
	v_angle = atan(VERTEX.z, VERTEX.x);
	vec3 p = VERTEX;
	float edge = sin(UV.y * 3.1415926);
	p.y += sin(UV.x * 18.0 + time * 3.1 + UV.y * 6.0) * amp * edge;
	p.x += sin(UV.x * 12.0 - time * 1.7 + UV.y * 4.0) * amp * 0.35 * edge;
	VERTEX = p;
}

void fragment() {
	float along = v_uv.x;
	float across = v_uv.y;
	float edge = smoothstep(0.0, 0.22, across) * (1.0 - smoothstep(0.78, 1.0, across));
	float head = smoothstep(0.0, 0.08, along) * (1.0 - smoothstep(0.72, 1.0, along));
	float flow = sin(along * 34.0 - time * speed + sin(across * 8.0 + time * 1.3) * 2.2);
	float caustic = smoothstep(0.42, 0.96, flow * 0.5 + 0.5);
	float filament = smoothstep(0.82, 1.0, sin(along * 60.0 + across * 9.0 - time * 2.6) * 0.5 + 0.5);
	float front = max(0.0, cos(v_angle + root_rot - cam_az));
	float fade = mix(1.0, 0.22, front);
	vec3 col = mix(color_a, color_b, clamp(along * 0.70 + caustic * 0.30, 0.0, 1.0));
	col += vec3(0.55, 0.95, 1.0) * (caustic * 0.45 + filament * 0.25);
	float a = (0.10 + caustic * 0.28 + filament * 0.16 + edge * 0.18)
		* edge * head * alpha * reveal * fade;
	if (a < 0.006) {
		discard;
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 0.92);
}
