class_name EyeShine
extends RefCounted

## Pokémon GLBs (Pikachu, Eevee...) ship eye textures that are a FLAT near-black color:
## the catchlight (white highlight) of the original game lives in a mask/specular layer
## that was not exported. Without it the eyes read as black voids (criador: "olhos pretos").
## Generic fix, by data and not by species: any surface whose material is named `*_eye`
## and whose albedo texture is uniform gets the same dark base plus a painted catchlight.
## Eyes that already have painted art (Charmander, Bulbasaur, Gible) are untouched by the highlight;
## `apply` then attaches EyeBlink (scripts/common/eye_blink.gd) to every model with `*_eye` surfaces.

const SIZE := 128
const META := "eye_shine_done"
static var _cache := {}


static func apply(root: Node) -> int:
	var fixed := 0
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat == null or not str(mat.resource_name).ends_with("_eye") or mat.has_meta(META):
				continue
			mat.set_meta(META, true)
			var tex := mat.albedo_texture
			if tex == null:
				continue
			var base := _flat_color(tex)
			if base.a < 0.0:
				continue  # already painted art
			mat.albedo_texture = _shine_texture(base)
			fixed += 1
	preload("res://scripts/common/eye_blink.gd").attach(root)  # blink on every `*_eye` surface
	return fixed


## Returns the uniform color of the texture, or alpha -1 when it has painted detail.
static func _flat_color(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color(0, 0, 0, -1)
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var first := img.get_pixel(0, 0)
	var step := maxi(1, img.get_width() / 16)
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var c := img.get_pixel(x, y)
			if absf(c.r - first.r) > 0.02 or absf(c.g - first.g) > 0.02 or absf(c.b - first.b) > 0.02:
				return Color(0, 0, 0, -1)
	return first


static func _shine_texture(base: Color) -> Texture2D:
	var key := base.to_html()
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	# Big catchlight (upper-right) + small secondary (lower-left), soft 1-texel edge.
	_blob(img, Vector2(0.60, 0.30), Vector2(0.13, 0.16), Color.WHITE)
	_blob(img, Vector2(0.38, 0.70), Vector2(0.06, 0.07), Color(1, 1, 1, 0.9))
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


static func _blob(img: Image, c: Vector2, r: Vector2, col: Color) -> void:
	for y in SIZE:
		for x in SIZE:
			var p := Vector2((x + 0.5) / SIZE, (y + 0.5) / SIZE)
			var d := Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y).length()
			var a := clampf((1.0 - d) * r.x * SIZE * 0.5 + 0.5, 0.0, 1.0) * col.a
			if a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(col.r, col.g, col.b, 1.0), a))
