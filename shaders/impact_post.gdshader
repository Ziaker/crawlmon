shader_type canvas_item;
// Screen-space impact post-processing: subtle radial blur, chromatic aberration
// and elemental color grading strictly during the strike frame.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float monochrome : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.46);
uniform vec4 tint_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);

void fragment() {
	if (strength <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = SCREEN_UV;
		vec2 to_center = center - uv;
		float dist = length(to_center);
		vec2 dir = dist > 0.0001 ? to_center / dist : vec2(0.0);

		// 1. Radial blur (5-tap) weighted toward screen edges
		float blur_amt = strength * 0.018 * smoothstep(0.05, 0.65, dist);
		vec3 accum = vec3(0.0);
		for (int i = 0; i < 5; i++) {
			float f = float(i) / 4.0;
			accum += texture(screen_tex, clamp(uv + dir * blur_amt * f, vec2(0.001), vec2(0.999))).rgb;
		}
		accum *= 0.2;

		// 2. Subtle radial chromatic aberration
		float ca = strength * 0.0085 * smoothstep(0.08, 0.7, dist);
		float r_ch = texture(screen_tex, clamp(uv - dir * ca, vec2(0.001), vec2(0.999))).r;
		float b_ch = texture(screen_tex, clamp(uv + dir * ca, vec2(0.001), vec2(0.999))).b;
		vec3 col = vec3(mix(accum.r, r_ch, 0.65), accum.g, mix(accum.b, b_ch, 0.65));

		// 3. Elemental color grade & contrast punch at impact
		vec3 graded = mix(col, col * mix(vec3(1.0), tint_color.rgb * 1.35, 0.42), strength * 0.65);
		graded = pow(max(graded, vec3(0.0)), vec3(1.0 - strength * 0.12)) * (1.0 + strength * 0.14);

		// Edge vignette flash in elemental color
		float edge_glow = smoothstep(0.28, 0.85, dist) * strength * 0.22;
		graded += tint_color.rgb * edge_glow;

		// Optional two-frame high-contrast monochrome impact pulse.
		float luma = dot(graded, vec3(0.299, 0.587, 0.114));
		float ink = smoothstep(0.30, 0.70, luma);
		graded = mix(graded, vec3(ink), monochrome);

		COLOR = vec4(graded, clamp(strength * 0.92, 0.0, 1.0));
	}
}
