shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Spark ring (D-236): a thin, clean ring made of bright dashes, red and orange only. It reads as a ring of sparks,
// not of fire. Lies on a quad turned to any plane; the ring sits at 0.78 of the quad's half size.

uniform vec4 orange : source_color = vec4(1.0, 0.42, 0.05, 1.0);
uniform vec4 red : source_color = vec4(0.9, 0.12, 0.03, 1.0);
uniform float tt = 0.0;
uniform float intensity = 1.0;
uniform float thick = 0.05;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float dashes = 18.0;

float hash11(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
	float seg = floor(ang * dashes + tt * 1.5 + seed);
	float on = step(0.35, hash11(seg + seed));                 // some dashes are missing
	float within = fract(ang * dashes + tt * 1.5 + seed);
	float dash = smoothstep(0.0, 0.12, within) * smoothstep(1.0, 0.55, within);
	float line = 1.0 - smoothstep(thick * 0.6, thick, abs(r - 0.78 - (hash11(seg) - 0.5) * 0.04));
	float a = line * dash * on * (1.0 - fade);
	if (a < 0.03) {
		discard;
	}
	vec3 c = mix(red.rgb, orange.rgb, hash11(seg * 3.1 + seed) * 0.8 + 0.2);
	ALBEDO = c * intensity;
	ALPHA = a;
}
