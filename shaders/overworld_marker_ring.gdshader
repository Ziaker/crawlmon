shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 ring_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float inner_radius = 0.80;
uniform float outer_radius = 0.95;
uniform float softness = 0.04;
uniform float alpha = 0.9;

void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float d = length(p);
    float ring = smoothstep(inner_radius - softness, inner_radius, d)
        * (1.0 - smoothstep(outer_radius, outer_radius + softness, d));
    // very soft inner glow so the ring reads on the dark forest floor
    float glow = (1.0 - smoothstep(0.0, outer_radius, d)) * 0.035;
    ALBEDO = ring_color.rgb;
    ALPHA = clamp((ring + glow) * ring_color.a * alpha, 0.0, 1.0);
}
