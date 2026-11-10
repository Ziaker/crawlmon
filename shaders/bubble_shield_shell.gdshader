shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Bubble Shield A: membrana lisa de sabão (Safira Gelo), refração da cena,
// ondas de superfície, espuma na base e depressão de impacto.
uniform float time = 0.0;
uniform float opacity = 1.0;
uniform float hit_flash = 0.0;
uniform vec3 hit_dir = vec3(0.0, 0.0, 1.0);
uniform float hit_age = 0.0;
uniform float hit_strength = 0.0;
uniform float wave_amp = 0.012;
uniform float depletion = 0.0;
uniform float base_alpha = 0.018;
uniform float form = 1.0;
uniform float form_active = 0.0;
uniform float radius = 1.0;
uniform vec3 color_a : source_color = vec3(0.027, 0.118, 0.247);
uniform vec3 color_b : source_color = vec3(0.078, 0.314, 0.659);
uniform vec3 color_c : source_color = vec3(0.180, 0.608, 1.0);
uniform vec3 color_d : source_color = vec3(0.561, 0.910, 1.0);
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float refract_amount = 0.8;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 view_dir;
varying vec2 v_uv;
varying float hit_ang;
varying vec3 local_pos;

void vertex() {
	v_uv = UV;
	local_pos = VERTEX;
	vec3 n = normalize(NORMAL);
	float ang = acos(clamp(dot(normalize(VERTEX), normalize(hit_dir)), -1.0, 1.0));
	hit_ang = ang;
	float dent = exp(-pow(ang / 0.34, 2.0)) * hit_strength;
	vec3 p = VERTEX - n * dent * 0.13;
	p += n * sin(ang * 18.0 - hit_age * 16.0) * exp(-ang * 3.5) * hit_strength * 0.026;
	p += n * (sin(UV.x * 16.0 + time * 1.1) + sin(UV.y * 12.0 - time * 0.8)) * 0.0035;
	float surf = sin(VERTEX.y * 7.0 + time * 2.0 + VERTEX.x * 3.0) * 0.6
		+ sin(VERTEX.x * 8.0 - time * 1.6 + VERTEX.z * 4.0) * 0.4;
	p += n * surf * wave_amp;
	VERTEX = p;
	vec4 wp = MODEL_MATRIX * vec4(p, 1.0);
	world_pos = wp.xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	view_dir = normalize(INV_VIEW_MATRIX[3].xyz - wp.xyz);
}

void fragment() {
	vec3 N = normalize(world_normal);
	vec3 V = normalize(view_dir);
	float ndv = abs(dot(N, V));
	float fres = pow(1.0 - ndv, 2.15);
	float rim = pow(1.0 - ndv, 3.6);

	float h = clamp((local_pos.y + radius) / (2.0 * radius), 0.0, 1.0);
	float swirl = sin(atan(local_pos.z, local_pos.x) * 5.0 + time * 2.0 + h * 8.0) * 0.035;
	float form_h = form + swirl;
	float fill = mix(1.0, 1.0 - smoothstep(form_h - 0.045, form_h + 0.045, h), form_active);
	float form_line = exp(-pow((h - form_h) / 0.045, 2.0)) * form_active;

	float film = 0.5 + 0.5 * sin(fres * 13.0 + time * 0.9 + world_pos.y * 4.0
		+ sin(world_pos.x * 2.0 + time * 0.5) * 0.8);
	vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film * 1.15 + fres * 0.55));

	float ang = atan(local_pos.z, local_pos.x);
	float flow = 0.5 + 0.5 * sin(local_pos.y * 5.0 + ang * 3.0 - time * 0.9);
	vec3 palette = mix(color_a, color_b, smoothstep(0.05, 0.70, flow));
	palette = mix(palette, color_c, smoothstep(0.48, 0.94, flow));
	palette = mix(palette, color_d, smoothstep(0.82, 1.0,
		0.5 + 0.5 * sin(ang * 4.0 + local_pos.y * 6.0 + time * 0.5)));

	float streak = 0.5 + 0.5 * sin(ang * 7.0 + local_pos.y * 9.0 - time * 1.7);
	palette = mix(palette, color_d, smoothstep(0.78, 0.98, streak) * 0.45);
	palette = mix(palette, color_a, smoothstep(0.82, 0.99, 1.0 - streak) * 0.35);

	float caustic = smoothstep(0.55, 0.95,
		sin(local_pos.y * 8.0 + ang * 5.0 - time * 1.4 + sin(local_pos.x * 3.0 + time) * 1.2) * 0.5 + 0.5);
	vec3 col = mix(palette, irid, clamp(fres * 0.85, 0.0, 1.0) * 0.22);
	col = mix(col, palette, 0.48);
	col += color_c * caustic * 0.08;
	col += rim * mix(color_c, color_d, 0.35) * 0.30;
	col += form_line * mix(color_c, color_d, 0.55) * 0.35;

	float surf_crest = smoothstep(0.66, 1.0,
		sin(ang * 6.0 + local_pos.y * 7.0 - time * 2.2) * 0.5 + 0.5);
	float ripple = smoothstep(0.72, 0.98,
		sin(local_pos.y * 10.0 + ang * 4.0 - time * 1.5) * 0.5 + 0.5);
	float base_foam = smoothstep(0.38, 0.30, h) * (1.0 - smoothstep(0.26, 0.18, h));
	float foam_bubbles = smoothstep(0.50, 0.90,
		sin(ang * 14.0 + h * 30.0 - time * 3.0) * 0.5 + 0.5);
	float foam = base_foam * (0.40 + 0.60 * foam_bubbles);
	col += vec3(0.92, 0.99, 1.0) * (foam * 0.34 + surf_crest * 0.08);
	col += mix(color_d, vec3(0.92, 0.99, 1.0), 0.35) * (surf_crest * 0.28 + ripple * 0.20);

	float band = smoothstep(0.88, 1.0, sin(world_pos.y * 8.5 - time * 1.4 + fres * 5.0)) * 0.10;
	col += band * mix(color_c, color_d, 0.5);

	// Refração real da cena atrás da membrana. A leitura escura do palco do jogo
	// pede menos mistura do fundo e mais paleta Safira Gelo do que o laboratório.
	vec2 refr_uv = SCREEN_UV + N.xy * (0.005 + fres * 0.019) * refract_amount;
	vec3 refracted = texture(screen_tex, clamp(refr_uv, vec2(0.0), vec2(1.0))).rgb;
	col = mix(col, refracted, refract_amount * (0.09 + fres * 0.20));

	float hit_dent = exp(-pow(hit_ang / 0.32, 2.0)) * hit_strength;
	col = mix(col, color_a * 0.55, hit_dent * 0.45);

	// O palco do jogo é mais claro que o laboratório: recupera a saturação
	// Safira Gelo sem trocar a paleta aprovada.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, 1.28);

	float alpha = base_alpha + rim * 0.72 + fres * 0.10 + band * 0.30 + hit_flash * 0.28;
	alpha += hit_dent * 0.10;
	alpha += form_line * 0.24 + foam * 0.20 + surf_crest * 0.16 + ripple * 0.10;
	alpha *= (1.0 - depletion * 0.26) * opacity * fill;
	if (alpha < 0.008) {
		discard;
	}
	ALBEDO = col * 1.16;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
