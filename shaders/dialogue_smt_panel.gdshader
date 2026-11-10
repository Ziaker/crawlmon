shader_type canvas_item;

uniform float progress = 0.0;
uniform float time = 0.0;
uniform vec4 bg : source_color = vec4(0.015, 0.035, 0.045, 0.94);
uniform vec4 line : source_color = vec4(0.25, 0.95, 0.85, 0.92);
uniform vec4 accent : source_color = vec4(1.0, 0.36, 0.24, 0.95);

void fragment() {
    vec2 uv = UV;
    float band = floor(uv.y * 26.0);
    float g = fract(sin(band * 78.233 + floor(time * 12.0) * 0.37) * 43758.5453);
    float glitch = (g > 0.92 ? (g - 0.92) * 3.5 : 0.0) * (1.0 - progress);
    vec2 p = vec2(uv.x + glitch, uv.y);

    float wipe = step(p.x, progress);
    float scan = 0.90 + 0.10 * sin(p.y * 480.0 + time * 7.0);
    float border = step(p.x, 0.0025) + step(0.9975, p.x)
        + step(p.y, 0.010) + step(0.990, p.y);

    vec3 col = bg.rgb;
    float a = bg.a * wipe;

    if (border > 0.0) {
        col = line.rgb;
        a = line.a * wipe;
    }
    if (p.y < 0.020 && p.x < 0.34) {
        col = accent.rgb;
        a = accent.a * wipe;
    }
    if (p.y > 0.980 && p.x > 0.72) {
        col = accent.rgb;
        a = accent.a * wipe;
    }

    float edge = smoothstep(progress - 0.012, progress, p.x)
        * (1.0 - smoothstep(progress, progress + 0.012, p.x));
    col = mix(col, line.rgb, edge * 0.9);
    a = max(a, edge * 0.9 * wipe);

    // faint horizontal scanline gaps
    float gap = step(0.965, fract(p.y * 260.0 + time * 1.5));
    col *= 1.0 - gap * 0.10;

    COLOR = vec4(col * scan, a);
}
