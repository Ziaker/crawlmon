shader_type canvas_item;
// D-991: post-process for the 3D overworld models.
// Runs on the Sprite2D that shows the SubViewport texture. The goal is to make
// the smooth 3D render read closer to the 16/32 px sprite art: flat colour
// bands, a darker silhouette and a limited palette.

uniform int color_levels : hint_range(2, 32) = 12;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;
uniform int toon_bands : hint_range(0, 8) = 0;
uniform float toon_strength : hint_range(0.0, 1.0) = 0.0;
uniform float outline_darkness : hint_range(0.0, 1.0) = 0.5;
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < alpha_cutoff) {
		discard;
	}

	// Saturation and contrast first, so the banding/posterize work on the
	// colour that will actually be seen.
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(lum), c.rgb, saturation);
	c.rgb = clamp((c.rgb - 0.5) * contrast + 0.5, 0.0, 1.0);

	// Flat light bands (toon). 0 = off.
	if (toon_bands > 0) {
		lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		float bands = float(toon_bands);
		float q = floor(lum * bands) / bands + 0.5 / bands;
		c.rgb *= mix(1.0, q / max(lum, 0.001), toon_strength);
	}

	// Limited palette.
	if (color_levels > 1) {
		float levels = float(color_levels - 1);
		c.rgb = floor(c.rgb * levels + 0.5) / levels;
	}

	// Darker inner silhouette, sampled from alpha.
	if (outline_width > 0.0) {
		float edge = 0.0;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398;
			vec2 o = vec2(cos(a), sin(a)) * TEXTURE_PIXEL_SIZE * outline_width;
			float na = texture(TEXTURE, UV + o).a;
			edge = max(edge, step(na, alpha_cutoff));
		}
		c.rgb = mix(c.rgb, c.rgb * (1.0 - outline_darkness), edge);
	}

	c.a = smoothstep(alpha_cutoff, alpha_cutoff + 0.15, c.a);
	COLOR = c;
}
