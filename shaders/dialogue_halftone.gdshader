shader_type canvas_item;

uniform vec4 dot_color : source_color = vec4(0.08, 0.08, 0.10, 0.16);
uniform float scale = 16.0;

void fragment() {
    vec2 grid = vec2(scale, scale * 0.72);
    vec2 cell = fract(UV * grid) - 0.5;
    float d = length(cell);
    float a = smoothstep(0.30, 0.14, d);
    COLOR = vec4(dot_color.rgb, dot_color.a * a);
}
