extends Node3D
## D-1151/D-1158: item coletável no overworld 3D. D-1158: bolha de relíquia
## com o ícone real dentro, etiqueta de papel com nome/tipo, anel, facho e sparkles.
## A coleta (grupo item_collector, raio 1,25 m, GameState.add_item) não muda.

signal collected(item_id: String, collector: Node3D)

const PICKUP_RADIUS := 1.25
const COLLECTOR_GROUP := "item_collector"
const BUBBLE_SHADER := preload("res://shaders/item_relic_bubble.gdshader")
const RING_SHADER := preload("res://shaders/overworld_marker_ring.gdshader")

const BUBBLE_RADIUS := 0.35
const TAG_Y := 0.24
const RING_Y := 0.02

var item_id := ""
var player: Node3D

var _base_y := 0.0
var _time := 0.0
var _taken := false
var _float_root: Node3D
var _icon: Sprite3D
var _ring_mat: ShaderMaterial
var _sparkles: Array[Sprite3D] = []


func setup(p_item_id: String, p_player: Node3D) -> void:
	item_id = p_item_id
	player = p_player
	_base_y = position.y
	if p_player != null and p_player.is_inside_tree():
		p_player.add_to_group(COLLECTOR_GROUP)


func _ready() -> void:
	add_to_group("overworld_item")
	_build_visual()


func _process(delta: float) -> void:
	_time += delta
	if _float_root != null:
		_float_root.position.y = sin(_time * 2.4) * 0.04
	if _icon != null:
		_icon.rotation.z = sin(_time * 1.7) * 0.045
	for i in _sparkles.size():
		var angle := _time * 0.9 + TAU * float(i) / float(maxi(_sparkles.size(), 1))
		var spark := _sparkles[i]
		spark.position = Vector3(
			cos(angle) * 0.33,
			sin(_time * 1.6 + float(i)) * 0.2,
			sin(angle) * 0.33)
		spark.modulate.a = 0.35 + 0.55 * (0.5 + 0.5 * sin(_time * 2.1 + float(i)))
	if _ring_mat != null:
		_ring_mat.set_shader_parameter("alpha", 0.55 + 0.25 * (0.5 + 0.5 * sin(_time * 2.2)))
	if _taken:
		return
	var collector := _nearest_collector()
	if collector == null:
		return
	if not GameState.add_item(item_id):
		return
	_taken = true
	collected.emit(item_id, collector)
	queue_free()


func _nearest_collector() -> Node3D:
	var best: Node3D = null
	var best_dist := PICKUP_RADIUS
	for node in get_tree().get_nodes_in_group(COLLECTOR_GROUP):
		if not node is Node3D:
			continue
		var body := node as Node3D
		if not body.visible:
			continue
		var flat := body.global_position - global_position
		flat.y = 0.0
		var dist := flat.length()
		if dist <= best_dist:
			best_dist = dist
			best = body
	return best


func _build_visual() -> void:
	var item := Item.get_item(item_id)
	var display := item.display_name if item != null else item_id.to_upper()
	var kind := "CONSUMABLE" if item != null and item.kind == Item.Kind.CONSUMABLE else "HELD"

	_float_root = Node3D.new()
	add_child(_float_root)

	# Halo quente atrás da bolha.
	var glow := _additive_sprite(_radial_texture(64, Color(1.0, 0.86, 0.55, 0.85)),
		0.014, Color(1.0, 0.88, 0.6, 0.55), 0)
	_float_root.add_child(glow)

	# Ícone real do item dentro da bolha.
	var texture := Item.icon_of(item_id)
	if texture != null:
		_icon = Sprite3D.new()
		_icon.texture = texture
		_icon.pixel_size = 0.013
		_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_icon.shaded = false
		_icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_icon.render_priority = 1
		_float_root.add_child(_icon)
	else:
		var fallback := Label3D.new()
		fallback.text = display
		fallback.font_size = 42
		fallback.pixel_size = 0.0035
		fallback.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		fallback.modulate = Color(1.0, 0.86, 0.42)
		fallback.no_depth_test = false
		fallback.render_priority = 1
		_float_root.add_child(fallback)

	# Bolha de vidro (só o rim Fresnel aparece; o centro é transparente).
	var sphere := SphereMesh.new()
	sphere.radius = BUBBLE_RADIUS
	sphere.height = BUBBLE_RADIUS * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	var bubble := MeshInstance3D.new()
	bubble.mesh = sphere
	bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bubble_mat := ShaderMaterial.new()
	bubble_mat.shader = BUBBLE_SHADER
	bubble_mat.set_shader_parameter("rim_color", Color(1.0, 0.86, 0.56, 1.0))
	bubble_mat.set_shader_parameter("rim_power", 2.6)
	bubble_mat.set_shader_parameter("rim_alpha", 0.85)
	bubble_mat.render_priority = 2
	bubble.material_override = bubble_mat
	_float_root.add_child(bubble)

	for i in 4:
		var spark := _additive_sprite(_radial_texture(16, Color(1.0, 0.95, 0.72, 1.0)),
			0.006, Color(1.0, 0.9, 0.62, 0.9), 3)
		_float_root.add_child(spark)
		_sparkles.append(spark)

	# Facho de luz 3D do chão até a bolha (cone aditivo suave).
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.06
	cone_mesh.bottom_radius = 0.44
	cone_mesh.height = 0.78
	cone_mesh.radial_segments = 24
	var cone := MeshInstance3D.new()
	cone.mesh = cone_mesh
	cone.position = Vector3(0.0, 0.4 - _base_y, 0.0)
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cone_mat := StandardMaterial3D.new()
	cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	cone_mat.albedo_color = Color(1.0, 0.9, 0.65, 0.11)
	cone.material_override = cone_mat
	add_child(cone)

	# Anel dourado no chão.
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.92, 0.92)
	var ring := MeshInstance3D.new()
	ring.mesh = plane
	ring.position = Vector3(0.0, RING_Y - _base_y, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = RING_SHADER
	_ring_mat.set_shader_parameter("ring_color", Color(1.0, 0.82, 0.45, 0.9))
	_ring_mat.set_shader_parameter("inner_radius", 0.90)
	_ring_mat.set_shader_parameter("outer_radius", 0.965)
	_ring_mat.set_shader_parameter("softness", 0.02)
	_ring_mat.set_shader_parameter("alpha", 0.7)
	ring.material_override = _ring_mat
	add_child(ring)

	# Etiqueta de papel com o nome e o tipo, abaixo da bolha.
	var tag_texture := _paper_texture()
	var tag := Sprite3D.new()
	tag.texture = tag_texture
	tag.pixel_size = 0.72 / 128.0
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.shaded = false
	tag.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tag.modulate = Color.WHITE
	tag.position = Vector3(0.0, TAG_Y - _base_y, 0.0)
	tag.render_priority = 4
	add_child(tag)

	var name_label := _make_label(display, 32, Color("#211b15"), false)
	var name_size := 32
	var name_font: Font = name_label.font
	while name_size > 18 and name_font.get_string_size(
			display, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x * 0.0035 > 0.60:
		name_size -= 2
	name_label.font_size = name_size
	name_label.position = Vector3(0.0, TAG_Y + 0.05 - _base_y, 0.002)
	add_child(name_label)
	var type_label := _make_label(kind, 16, Color("#6d5d45"), true)
	type_label.position = Vector3(0.0, TAG_Y - 0.05 - _base_y, 0.002)
	add_child(type_label)


func _make_label(text: String, size: int, color: Color, mono: bool) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = true
	label.render_priority = 5
	var font := SystemFont.new()
	font.font_names = PackedStringArray(
		["Consolas", "Courier New"] if mono else ["Georgia", "Times New Roman", "Cambria"])
	font.font_weight = 800 if mono else 700
	label.font = font
	return label


func _additive_sprite(texture: Texture2D, pixel: float, color: Color, priority: int) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = pixel
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.modulate = color
	sprite.render_priority = priority
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = texture
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.material_override = mat
	return sprite


func _radial_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := float(size) * 0.5
	for y in size:
		for x in size:
			var dist := Vector2(x, y).distance_to(center) / radius
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _shaft_texture() -> ImageTexture:
	var w := 64
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	for y in h:
		var t := float(y) / float(h - 1)
		var half := int(round(lerpf(30.0, 5.0, t)))
		var alpha := (1.0 - t) * 0.38
		for x in range(maxi(0, int(cx) - half), mini(w, int(cx) + half + 1)):
			var edge: float = 1.0 - abs(float(x) - cx) / float(maxi(half, 1))
			if edge > 0.0:
				img.set_pixel(x, y, Color(1.0, 0.9, 0.62, alpha * edge))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _paper_texture() -> ImageTexture:
	var w := 128
	var h := 52
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cream := Color("#e8dfc8")
	var ink := Color("#211b15")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1158
	for y in range(2, h - 2):
		var left := 2 + int(round(1.0 + sin(float(y) * 0.55) * 1.5))
		var right := w - 3 - int(round(1.0 + cos(float(y) * 0.43) * 1.5))
		for x in range(left, right + 1):
			var color := cream
			if x <= left + 1 or x >= right - 1 or y <= 3 or y >= h - 4:
				color = ink
			elif rng.randf() < 0.035:
				color = cream.darkened(0.06)
			img.set_pixel(x, y, color)
	for i in 7:
		var nx := rng.randi_range(12, w - 12)
		var ny := 2 if i % 2 == 0 else h - 3
		for k in 3:
			img.set_pixel(clampi(nx + k, 0, w - 1), ny, Color(0, 0, 0, 0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
