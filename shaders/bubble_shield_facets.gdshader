shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Concha facetada da opção C dentro da bolha A: facetas quantizadas, sem wireframe.
uniform float time = 0.0;
uniform float opacity = 1.0;
uniform float hit_flash = 0.0;
uniform float freeze = 0.35;
uniform vec3 hit_dir = vec3(0.0, 0.0, 1.0);
uniform float hit_age = 0.0;
uniform float hit_strength = 0.0;
uniform float form = 1.0;
uniform float form_active = 0.0;
uniform float radius = 1.0;
uniform vec3 tint : source_color = vec3(0.180, 0.608, 1.0);
uniform vec3 color_a : source_color = vec3(0.027, 0.118, 0.247);
uniform vec3 color_b : source_color = vec3(0.078, 0.314, 0.659);
uniform vec3 color_c : source_color = vec3(0.180, 0.608, 1.0);
uniform vec3 color_d : source_color = vec3(0.561, 0.910, 1.0);
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float refract_amount = 0.55;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 view_dir;
varying float hit_dot;
varying vec3 local_pos;

void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	world_pos = wp.xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	view_dir = normalize(INV_VIEW_MATRIX[3].xyz - wp.xyz);
	hit_dot = dot(normalize(NORMAL), normalize(hit_dir));
	local_pos = VERTEX;
}

void fragment() {
	vec3 N = normalize(world_normal);
	vec3 V = normalize(view_dir);
	float ndv = abs(dot(N, V));
	float fres = pow(1.0 - ndv, 1.45);

	float h = clamp((local_pos.y + radius) / (2.0 * radius), 0.0, 1.0);
	float swirl = sin(atan(local_pos.z, local_pos.x) * 5.0 + time * 2.0 + h * 8.0) * 0.035;
	float form_h = form + swirl;
	float fill = mix(1.0, 1.0 - smoothstep(form_h - 0.045, form_h + 0.045, h), form_active);
	float form_line = exp(-pow((h - form_h) / 0.045, 2.0)) * form_active;

	float facet = smoothstep(0.0, 1.0, abs(N.x * 0.6 + N.y * 0.8));
	float facet_tone = 0.5 + 0.5 * facet;
	float film = 0.5 + 0.5 * sin(facet * 8.0 + time * 0.55 + world_pos.y * 2.2);
	vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film * 1.1 + fres * 0.7));

	float ang = atan(local_pos.z, local_pos.x);
	float flow = 0.5 + 0.5 * sin(local_pos.y * 5.0 + ang * 3.0 - time * 0.9);
	vec3 palette = mix(color_a, color_b, smoothstep(0.05, 0.70, flow));
	palette = mix(palette, color_c, smoothstep(0.48, 0.94, flow));
	palette = mix(palette, color_d, smoothstep(0.82, 1.0,
		0.5 + 0.5 * sin(ang * 4.0 + local_pos.y * 6.0 + time * 0.5)));

	float caustic = smoothstep(0.55, 0.95, sin(local_pos.y * 8.0 + ang * 5.0 - time * 1.4) * 0.5 + 0.5);
	float streak = 0.5 + 0.5 * sin(ang * 7.0 + local_pos.y * 9.0 - time * 1.7);
	palette = mix(palette, color_d, smoothstep(0.78, 0.98, streak) * 0.40);
	palette = mix(palette, color_a, smoothstep(0.82, 0.99, 1.0 - streak) * 0.30);

	vec3 facet_palette = mix(color_a, color_b, smoothstep(0.0, 0.55, facet_tone));
	facet_palette = mix(facet_palette, color_c, smoothstep(0.45, 0.82, facet_tone));
	facet_palette = mix(facet_palette, color_d, smoothstep(0.82, 1.0, facet_tone));

	vec3 col = mix(tint, facet_palette, 0.75);
	col = mix(col, irid, (0.25 + freeze * 0.10) * 0.35);
	col = mix(col, palette, 0.18);
	col += color_c * caustic * 0.08;
	col += fres * mix(color_c, color_d, 0.5) * 0.22;
	col += form_line * mix(color_c, color_d, 0.5) * 0.35;

	vec2 refr_uv = SCREEN_UV + N.xy * (0.004 + fres * 0.014) * refract_amount;
	vec3 refracted = texture(screen_tex, clamp(refr_uv, vec2(0.0), vec2(1.0))).rgb;
	col = mix(col, refracted, refract_amount * (0.10 + fres * 0.20));

	float edge = pow(1.0 - ndv, 5.0) * 0.8;
	float hit_dent = exp(-pow(hit_dot - (1.0 - hit_age * 1.6), 2.0) / 0.02) * hit_strength;
	col = mix(col, color_a * 0.55, hit_dent * 0.35);

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, 1.22);

	float alpha = 0.055 + fres * 0.65 + edge + hit_flash * 0.10;
	alpha += hit_dent * 0.06 + hit_strength * 0.015 + form_line * 0.14;
	alpha *= opacity * fill;
	if (alpha < 0.008) {
		discard;
	}
	ALBEDO = col * 1.10;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
