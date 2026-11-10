shader_type canvas_item;

uniform vec4 paper : source_color = vec4(0.90, 0.82, 0.64, 1.0);

void fragment() {
    float n = fract(sin(dot(floor(UV * 180.0), vec2(12.9898, 78.233))) * 43758.5453);
    float fiber = sin(UV.y * 260.0 + sin(UV.x * 32.0) * 2.0) * 0.018;
    float edge = smoothstep(0.0, 0.035, UV.x) * smoothstep(0.0, 0.035, 1.0 - UV.x)
        * smoothstep(0.0, 0.05, UV.y) * smoothstep(0.0, 0.05, 1.0 - UV.y);
    vec3 col = paper.rgb * (0.95 + n * 0.08) + fiber;
    col = mix(col * 0.86, col, edge);
    COLOR = vec4(col, 1.0);
}
