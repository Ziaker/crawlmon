shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 ice_color : source_color = vec4(0.30, 0.76, 0.87, 1.0);
uniform float progress = 0.0;
uniform float fade = 1.0;
uniform float phase_time = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float spread = mix(0.02, 1.12, smoothstep(0.0, 1.0, progress));
	float mask = (1.0 - smoothstep(spread - 0.12, spread, radius)) * (1.0 - smoothstep(0.55, 1.0, radius));
	float a = atan(p.y, p.x);
	float rays = abs(sin(a * 6.0 + sin(radius * 13.0) * 0.12));
	float branches = abs(sin(a * 24.0 + radius * 32.0));
	float veins = (1.0 - smoothstep(0.02, 0.10, rays)) * 0.65;
	veins += (1.0 - smoothstep(0.03, 0.09, branches)) * (1.0 - smoothstep(0.1, 0.6, rays)) * 0.45;
	float glitter = pow(max(0.0, sin(p.x * 97.0 + p.y * 71.0 + phase_time * 1.4)), 26.0) * 0.10;
	ALBEDO = mix(ice_color.rgb * 0.55, vec3(0.78, 0.98, 1.0), veins + glitter);
	ALPHA = mask * (0.08 + veins * 0.55 + glitter) * fade;
}
