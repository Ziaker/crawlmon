class_name ElementBadge
extends Control
## D-404/D-413/D-423: flat parallelogram badge with the element ICON, same colours and glyph
## colours as the Status screen (StatusScreen.ELEMENT_COLORS / ELEMENT_GLYPH_COLORS).
## One element = one wider badge; two elements = two narrower ones (the caller decides the width).

const ICON_NAMES := {
	Element.Type.FISICO: "neutral", Element.Type.FOGO: "fire", Element.Type.AGUA_GELO: "water_ice",
	Element.Type.RAIO: "electric", Element.Type.PSIQUICO: "psychic", Element.Type.VENENO: "nature",
	Element.Type.SOM: "sound", Element.Type.TERRA: "earth", Element.Type.VENTO: "wind",
	Element.Type.LUZ: "light", Element.Type.TREVAS: "dark", Element.Type.MYSTIC: "mystic",
}
const SKEW := 2.5

var element: Element.Type = Element.Type.FISICO


func setup(e: Element.Type, badge_size: Vector2) -> ElementBadge:
	element = e
	custom_minimum_size = badge_size
	size = badge_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tooltip_text = Element.name_of(e)
	return self


func _draw() -> void:
	var bg: Color = StatusScreen.ELEMENT_COLORS.get(element, Color("cbd5e1"))
	var fg: Color = StatusScreen.ELEMENT_GLYPH_COLORS.get(element, Color("080e18"))
	var w := size.x - SKEW
	draw_colored_polygon(PackedVector2Array([
		Vector2(SKEW, 0.0), Vector2(SKEW + w, 0.0), Vector2(w, size.y), Vector2(0.0, size.y),
	]), bg)
	# Dark outline (inset by half the line width so it stays inside the badge rect).
	var o := 1.0
	draw_polyline(PackedVector2Array([
		Vector2(SKEW + o, o), Vector2(SKEW + w - o, o), Vector2(w - o, size.y - o), Vector2(o + 0.5, size.y - o), Vector2(SKEW + o, o),
	]), Color("080e18"), 2.0, true)
	var icon := _icon_texture(str(ICON_NAMES.get(element, "neutral")), int(ceilf(minf(size.y - 6.0, 18.0) * 2.0)))
	if icon != null:
		var s := minf(size.y - 6.0, 18.0)
		draw_texture_rect(icon, Rect2(Vector2((size.x - s) * 0.5, (size.y - s) * 0.5), Vector2(s, s)), false, fg)


static var _cache: Dictionary = {}


## The SVG rasterised at ~2x the drawn size (a 4x import scaled down to 16 px aliases into a blob).
static func _icon_texture(icon_name: String, px: int) -> Texture2D:
	var key := "%s@%d" % [icon_name, px]
	if not _cache.has(key):
		var path := "res://assets/ui/icons/elements/%s.svg" % icon_name
		var tex: Texture2D = null
		if FileAccess.file_exists(path):
			var img := Image.new()
			if img.load_svg_from_buffer(FileAccess.get_file_as_bytes(path), float(px) / 24.0) == OK:
				tex = ImageTexture.create_from_image(img)
		_cache[key] = tex
	return _cache[key]
