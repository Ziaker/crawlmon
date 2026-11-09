shader_type spatial;
render_mode specular_disabled;

// D-1076: toon do overworld no gl_compatibility (DIFFUSE_TOON nativo é ignorado).
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float bands = 3.0;
uniform float rim_amount = 0.22;

void fragment() {
	vec4 tex = use_texture ? texture(albedo_texture, UV) : vec4(1.0);
	ALBEDO = albedo_color.rgb * tex.rgb;
	ALPHA = albedo_color.a * tex.a;
	EMISSION = emission_color.rgb * emission_energy;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	RIM = rim_amount;
	RIM_TINT = 0.35;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float q = min(floor(ndl * bands) / max(bands - 1.0, 1.0), 1.0);
	DIFFUSE_LIGHT += q * ATTENUATION * LIGHT_COLOR / PI;
}
