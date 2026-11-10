shader_type canvas_item;

// Neo-brutalist slanted parallelogram panel shader (-9 degree skew)
// Displaces vertices relative to vertical center (rect_size.y * 0.5) to match SlantedButton hit-testing.

uniform vec2 rect_size = vec2(100.0, 50.0);
uniform float skew_angle_deg : hint_range(-45.0, 45.0) = -9.0;
uniform vec4 bg_color : source_color = vec4(0.04, 0.08, 0.15, 0.95);
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float border_width : hint_range(0.0, 10.0) = 2.0;
uniform bool use_texture = false;

void vertex() {
	VERTEX.x -= (VERTEX.y - 0.5 * rect_size.y) * tan(radians(skew_angle_deg));
}

void fragment() {
	vec4 base = use_texture ? texture(TEXTURE, UV) * bg_color : bg_color;
	if (border_width > 0.0) {
		vec2 pixel_pos = UV * rect_size;
		bool is_border = pixel_pos.x < border_width || pixel_pos.x > (rect_size.x - border_width) ||
		                 pixel_pos.y < border_width || pixel_pos.y > (rect_size.y - border_width);
		if (is_border) {
			COLOR = border_color;
		} else {
			COLOR = base;
		}
	} else {
		COLOR = base;
	}
}
