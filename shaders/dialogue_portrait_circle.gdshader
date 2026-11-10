shader_type canvas_item;

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    vec2 p = UV - 0.5;
    float d = length(p);
    float mask = smoothstep(0.5, 0.485, d);
    COLOR = vec4(c.rgb, c.a * mask);
}
