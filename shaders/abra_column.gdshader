shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Column of energy on a CylinderMesh (local Y up): scrolling noise bands rise along it,
// hot white core, soft silhouette. `progress` 0..1 plays the whole life: the column swells
// in, holds, then thins out (mode 0), or starts full and collapses upward (mode 1).
// Compatibility renderer: no HDR, so the colours are saturated and `energy` stays modest.

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.1, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 0.45, 0.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 1.6;
uniform float scroll = 3.0;
uniform float bands = 9.0;
uniform int mode = 0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float y = UV.y;
	float n = vnoise(vec2(UV.x * 6.0, y * bands - TIME * scroll)) * 0.65 + vnoise(vec2(UV.x * 13.0, y * bands * 2.0 - TIME * scroll * 1.7)) * 0.35;
	float facing = abs(dot(NORMAL, VIEW));
	float soft = smoothstep(0.0, 0.55, facing);
	float life = mode == 0 ? sin(clamp(progress, 0.0, 1.0) * 3.14159265) : 1.0 - progress;
	float cut = mode == 0 ? 1.0 : smoothstep(progress - 0.05, progress + 0.25, y);
	float edge = smoothstep(0.0, 0.08, y) * smoothstep(1.0, 0.82, y);
	float a = clamp((0.35 + n * 0.9) * soft * life * cut * (0.55 + edge * 0.45), 0.0, 1.0);
	float core = pow(soft, 3.0) * life;
	vec3 col = mix(color2.rgb, color.rgb, n);
	col = mix(col, vec3(1.0), core * 0.55);
	ALBEDO = col * energy;
	ALPHA = a;
}
