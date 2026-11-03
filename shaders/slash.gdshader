shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Crescent slash sweep. Put on a QuadMesh; `progress` 0..1 sweeps the arc from
// one tip to the other and fades it out; the bright core is white.

uniform vec4 color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 1.6;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 + vec2(0.3, 0.0);
	// Signed distance to a crescent: outer disk minus an offset inner disk.
	float outer_d = length(p) - 0.96;
	float inner_d = 0.92 - length(p - vec2(0.22, 0.0));
	float sd = max(outer_d, inner_d);
	float body = smoothstep(0.02, -0.10, sd);
	float core = smoothstep(-0.06, -0.20, sd) * body;
	// Position along the arc (0 at one tip, 1 at the other).
	float ang = atan(p.y, p.x - 0.0);
	float u = clamp((ang + 2.5) / 5.0, 0.0, 1.0);
	float head = progress * 1.5;
	float sweep = clamp(1.0 - (head - u) / 0.55, 0.0, 1.0) * step(u, head);
	float fade = 1.0 - smoothstep(0.65, 1.0, progress);
	float a = clamp(body * sweep * fade * color.a, 0.0, 1.0);
	if (a < 0.02) {
		discard;
	}
	ALBEDO = mix(color.rgb, vec3(1.0), core) * energy;
	ALPHA = a;
}
