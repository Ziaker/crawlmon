shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
// White physical hologram for the toon hand (D-1209): almost invisible body, readable
// stepped rim. No textures, no emission above white, works in gl_compatibility (D-1076).

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // brown (D-1209)
uniform float base_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float rim_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float rim_power : hint_range(0.5, 8.0) = 2.4;
uniform int bands : hint_range(1, 8) = 3;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float form : hint_range(0.0, 1.0) = 1.0;
uniform float tt = 0.0;
uniform float scan : hint_range(0.0, 1.0) = 0.08;

varying vec3 v_local;


void vertex() {
	v_local = VERTEX;
}


// Stable 3D cell hash: whole chunks of the hand vanish instead of a soft noise mask.
float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.37, 0.71));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}


void fragment() {
	vec3 n = FRONT_FACING ? NORMAL : -NORMAL;
	float ndotv = clamp(dot(normalize(n), normalize(VIEW)), 0.0, 1.0);
	float fres = 1.0 - ndotv;
	// stepped rim: anime/toon, never a smooth gradient
	float steps = float(bands);
	float rim = floor(pow(fres, rim_power) * steps) / steps;
	float a = base_alpha + rim_alpha * rim;

	// thin horizontal lines crawling slowly from wrist to fingers
	float lines = smoothstep(0.72, 1.0, 0.5 + 0.5 * sin(v_local.y * 130.0 - tt * 2.2));
	a *= 1.0 - scan * lines;

	// materialisation: vertical sweep, wrist (y=0) towards the fingers (y=1)
	float sweep = clamp(v_local.y, 0.0, 1.0);
	float m_form = clamp((form * 1.08 - sweep) / 0.08, 0.0, 1.0);

	// dissolve: hash cells are discarded; the crumb that is leaving gets a clear edge
	float h = hash3(floor(v_local * 9.0));
	float m_keep = step(dissolve, h);
	float edge = m_keep * (1.0 - smoothstep(0.0, 0.10, h - dissolve));

	a = (a * m_form * m_keep) * fade + edge * rim_alpha * m_keep * m_form * fade;

	// HTML look (D-1209), as colour only (no new opacity): dark-brown ink contour, lighter brown little-finger edge,
	// and the cuff fades below the wrist; alpha only shrinks there.
	float ink = 1.0 - smoothstep(0.18, 0.33, ndotv);
	float shuto = smoothstep(0.22, 0.36, v_local.x) * smoothstep(0.0, 0.85, v_local.y) * 0.72;
	float wrist = smoothstep(0.0, 0.08, v_local.y);
	vec3 col = mix(tint.rgb, tint.rgb * 0.34, ink);
	col = mix(col, tint.rgb * 1.32, shuto);
	ALBEDO = col;
	ALPHA = clamp(a * wrist, 0.0, 1.0);
}
