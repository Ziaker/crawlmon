shader_type spatial;
render_mode cull_back;
// D-1259 (teste): superficie dos Cascos com reflexo que varre a face + brilho de borda.

uniform vec4 albedo : source_color = vec4(1.0);
uniform float metallic = 0.35;
uniform float roughness = 0.5;
uniform float glow = 0.12;      // emissao base (cresce de bronze para ouro)
uniform float glint = 1.0;      // forca do reflexo que varre
uniform float rim = 0.15;        // brilho de borda
uniform float phase = 0.0;      // desencontra as moedas
uniform float flash = 0.0;      // clarao na coleta

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	float band = dot(wpos.xz + vec2(wpos.y * 0.4), normalize(vec2(1.0, 0.6)));
	float t = fract(TIME * 0.33 + phase + band * 2.2);
	float g = smoothstep(0.0, 0.05, t) * (1.0 - smoothstep(0.05, 0.14, t));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 hot = mix(albedo.rgb, vec3(1.0, 0.97, 0.85), 0.7);
	EMISSION = albedo.rgb * glow + hot * g * glint + albedo.rgb * fres * rim + hot * flash;
}
