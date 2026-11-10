shader_type spatial;
render_mode diffuse_toon, specular_toon;

// D-1118: paliçada triplanar com crossfade nos cantos e 60% de textura.
uniform sampler2D tex_own : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 base_color : source_color = vec4(0.075, 0.145, 0.135, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.60;
uniform float tile = 0.20;
uniform float corner_width = 1.2;
uniform vec4 corner_a = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 corner_b = vec4(0.0, 0.0, 0.0, 0.0);

varying vec3 w_pos;
varying vec3 w_norm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w = pow(abs(w_norm), vec3(6.0));
	w /= max(w.x + w.y + w.z, 0.0001);

	vec4 own = texture(tex_own, w_pos.zy * tile) * w.x
		+ texture(tex_own, w_pos.xz * tile) * w.y
		+ texture(tex_own, w_pos.xy * tile) * w.z;
	vec4 na = texture(tex_a, w_pos.zy * tile) * w.x
		+ texture(tex_a, w_pos.xz * tile) * w.y
		+ texture(tex_a, w_pos.xy * tile) * w.z;
	vec4 nb = texture(tex_b, w_pos.zy * tile) * w.x
		+ texture(tex_b, w_pos.xz * tile) * w.y
		+ texture(tex_b, w_pos.xy * tile) * w.z;

	float da = length(w_pos.xz - corner_a.xy);
	float wa = 0.5 * (1.0 - smoothstep(0.0, corner_width, da)) * corner_a.w;
	own = mix(own, na, wa);

	float db = length(w_pos.xz - corner_b.xy);
	float wb = 0.5 * (1.0 - smoothstep(0.0, corner_width, db)) * corner_b.w;
	own = mix(own, nb, wb);

	ALBEDO = mix(base_color.rgb, own.rgb, strength);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	RIM = 0.22;
	RIM_TINT = 0.35;
}
