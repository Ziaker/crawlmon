extends Node2D
## Tileset lab (D-345/D-347): manual 9-piece renderer + organic floor,
## catalog and mask room at the real 48 px and 2.3x camera.
##
## Open `scenes/tileset_lab.tscn` to inspect the active atlas. Left/Right
## cycles the 16 profiles. Run `scratch/capture_tileset_lab.tscn` to capture
## all 16.

const TILE := 48
const ACTIVE_PROFILE := "res://assets/pmd/dungeons/sky/atlas/temporal_tower_profile.json"
const POOL_PATH := "res://assets/pmd/dungeons/sky/atlas/biome_pool.json"
const ROOM := Vector2i(10, 6)
const VARIATION_SEED := 12345

@export var profile_override := ""

var _roles: Dictionary = {}
var _columns := 18
var _name := "tileset"
var _atlas: Texture2D
var _camera: Camera2D
var _catalog_layer: TileMapLayer
var _room_layer: TileMapLayer
var _source_id := -1
var _title: Label
var _hover: Label
var _profile_path := ""
var _pool: Array = []
var _pool_index := -1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_pool()
	var args := OS.get_cmdline_user_args()
	var profile_path := profile_override
	if profile_path.is_empty():
		profile_path = ACTIVE_PROFILE
		for arg in args:
			if arg.begins_with("--profile="):
				profile_path = arg.trim_prefix("--profile=")
	setup(profile_path)
	if args.has("--capture"):
		await get_tree().process_frame
		await capture_views("res://scratch/tileset_lab_active")
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_RIGHT:
		_cycle(1)
	elif event.keycode == KEY_LEFT:
		_cycle(-1)


func _load_pool() -> void:
	if not FileAccess.file_exists(POOL_PATH):
		return
	var file := FileAccess.open(POOL_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	_pool = data.get("profiles", [])


func _cycle(delta: int) -> void:
	if _pool.is_empty():
		return
	_pool_index = wrapi(_pool_index + delta, 0, _pool.size())
	setup(str(_pool[_pool_index].get("profile", ACTIVE_PROFILE)))


func setup(profile_path: String) -> void:
	for child in get_children():
		child.free()
	_camera = null
	_catalog_layer = null
	_room_layer = null
	_title = null
	_hover = null
	_profile_path = profile_path

	if not FileAccess.file_exists(profile_path):
		push_error("tileset lab: missing profile " + profile_path)
		return
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		push_error("tileset lab: cannot open " + profile_path)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("tileset lab: invalid profile " + profile_path)
		return
	_roles = data.get("roles", {})
	_columns = int(data.get("columns", 18))
	_name = str(data.get("name", "tileset"))
	var atlas_path := str(data.get("atlas", ""))
	if not ResourceLoader.exists(atlas_path):
		push_error("tileset lab: missing atlas " + atlas_path)
		return
	_atlas = _load_texture(atlas_path)
	_build_tileset()
	_build_catalog()
	_build_room()
	_build_camera()
	_build_title()
	_sync_pool_index()


func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null:
			return ImageTexture.create_from_image(image)
	return load(path)


func _sync_pool_index() -> void:
	_pool_index = -1
	for index in _pool.size():
		if str(_pool[index].get("profile", "")) == _profile_path:
			_pool_index = index
			return


func _build_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = _atlas
	source.texture_region_size = Vector2i(TILE, TILE)
	for column in _columns:
		source.create_tile(Vector2i(column, 0))
	_source_id = tileset.add_source(source)
	_catalog_layer = TileMapLayer.new()
	_catalog_layer.tile_set = tileset
	add_child(_catalog_layer)
	_room_layer = TileMapLayer.new()
	_room_layer.tile_set = tileset
	add_child(_room_layer)


func _build_catalog() -> void:
	for index in _columns:
		var column := index % 6
		var row := index / 6
		_catalog_layer.set_cell(Vector2i(column, row), _source_id, Vector2i(index, 0))
		var label := Label.new()
		label.text = "%02d" % index
		label.position = Vector2(column * TILE + 2, row * TILE + 2)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		label.z_index = 5
		add_child(label)


func _build_room() -> void:
	var origin := Vector2i(0, 6)
	for y in ROOM.y:
		for x in ROOM.x:
			var index := _wall_index(x, y) if _is_wall(x, y) else _ground_index(x, y)
			_room_layer.set_cell(origin + Vector2i(x, y), _source_id, Vector2i(index, 0))


## A 2x2 free pillar exercises the four wall corners.
func _is_pillar(x: int, y: int) -> bool:
	return (x == 3 or x == 4) and (y == 2 or y == 3)


func _is_wall(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= ROOM.x or y >= ROOM.y:
		return true
	if x == 0 or y == 0 or x == ROOM.x - 1 or y == ROOM.y - 1:
		return true
	return _is_pillar(x, y)


func _role(role_name: String) -> int:
	return int(_roles.get(role_name, -1))


func _is_solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= ROOM.x or y >= ROOM.y:
		return false
	return _is_wall(x, y)


func _is_floor(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= ROOM.x or y >= ROOM.y:
		return false
	return not _is_wall(x, y)


func _wall_index(x: int, y: int) -> int:
	var n := not _is_solid(x, y - 1)
	var s := not _is_solid(x, y + 1)
	var w := not _is_solid(x - 1, y)
	var e := not _is_solid(x + 1, y)
	if n and s and not w and not e:
		var strip_h := _role("wall_strip_h")
		if strip_h >= 0:
			return strip_h
	if w and e and not n and not s:
		var strip_v := _role("wall_strip_v")
		if strip_v >= 0:
			return strip_v
	var nf := _is_floor(x, y - 1)
	var sf := _is_floor(x, y + 1)
	var wf := _is_floor(x - 1, y)
	var ef := _is_floor(x + 1, y)
	var floors := int(nf) + int(sf) + int(wf) + int(ef)
	if floors == 1:
		if sf:
			return _role("wall_b")
		if nf:
			return _role("wall_t")
		if ef:
			return _role("wall_r")
		if wf:
			return _role("wall_l")
	if floors == 0:
		if _is_floor(x + 1, y + 1):
			return _role("wall_inner_br")
		if _is_floor(x - 1, y + 1):
			return _role("wall_inner_bl")
		if _is_floor(x + 1, y - 1):
			return _role("wall_inner_tr")
		if _is_floor(x - 1, y - 1):
			return _role("wall_inner_tl")
	if n and w:
		return _role("wall_tl")
	if n and e:
		return _role("wall_tr")
	if s and w:
		return _role("wall_bl")
	if s and e:
		return _role("wall_br")
	if n:
		return _role("wall_t")
	if w:
		return _role("wall_l")
	if e:
		return _role("wall_r")
	if s:
		return _role("wall_b")
	return _role("wall_c")


func _ground_index(x: int, y: int) -> int:
	var n := _is_solid(x, y - 1)
	var s := _is_solid(x, y + 1)
	var w := _is_solid(x - 1, y)
	var e := _is_solid(x + 1, y)
	if n and w:
		return _role("ground_tl")
	if n and e:
		return _role("ground_tr")
	if s and w:
		return _role("ground_bl")
	if s and e:
		return _role("ground_br")
	if n:
		return _role("ground_t")
	if w:
		return _role("ground_l")
	if e:
		return _role("ground_r")
	if s:
		return _role("ground_b")
	var inner := -1
	if _is_solid(x - 1, y - 1):
		inner = _role("ground_inner_tl")
	elif _is_solid(x + 1, y - 1):
		inner = _role("ground_inner_tr")
	elif _is_solid(x - 1, y + 1):
		inner = _role("ground_inner_bl")
	elif _is_solid(x + 1, y + 1):
		inner = _role("ground_inner_br")
	if inner >= 0:
		return inner
	return _ground_center(x, y)


func _ground_center(x: int, y: int) -> int:
	var alt1 := _role("ground_alt_1")
	var alt2 := _role("ground_alt_2")
	var roll := absi(_hash(x, y) ^ VARIATION_SEED) % 100
	if alt2 >= 0 and roll < 4:
		return alt2
	if alt1 >= 0 and roll < 8:
		return alt1
	return _role("ground_c")


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663))


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2.3, 2.3)
	_camera.position = Vector2(5 * TILE, 9 * TILE)
	_camera.enabled = true
	add_child(_camera)
	_camera.make_current()


func _build_title() -> void:
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	_title.z_index = 10
	add_child(_title)
	_hover = Label.new()
	_hover.add_theme_font_size_override("font_size", 10)
	_hover.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
	_hover.position = Vector2(8, 6 * TILE + 28)
	_hover.z_index = 10
	add_child(_hover)


func _process(_delta: float) -> void:
	if _room_layer == null or _hover == null:
		return
	var mouse := get_global_mouse_position()
	var cell := Vector2i(int(floor(mouse.x / TILE)), int(floor(mouse.y / TILE)))
	var source_id := _room_layer.get_cell_source_id(cell)
	if source_id < 0:
		_hover.text = "célula %s vazia" % cell
		return
	var atlas := _room_layer.get_cell_atlas_coords(cell)
	_hover.text = "célula %s  índice %d  papel %s" % [cell, atlas.x, _role_name(atlas.x)]


func _role_name(index: int) -> String:
	for key in _roles.keys():
		if int(_roles[key]) == index:
			return str(key)
	return "?"


func _label() -> String:
	if _pool_index >= 0:
		return "%s (%d/%d)" % [_name, _pool_index + 1, _pool.size()]
	return _name


func capture_views(prefix: String) -> void:
	if _hover != null:
		_hover.visible = false
	_camera.position = Vector2(3 * TILE, 1.5 * TILE)
	_title.text = "%s — catálogo (índices)" % _label()
	_title.position = Vector2(8, -18)
	await capture(prefix + "_catalog.png")
	_camera.position = Vector2(5 * TILE, 9 * TILE)
	_title.text = "%s — piso orgânico, 48 px, câmera 2,3x" % _label()
	_title.position = Vector2(8, 6 * TILE + 8)
	await capture(prefix + "_room.png")


func capture(path: String) -> void:
	for i in 3:
		await get_tree().process_frame
	var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
	if not DirAccess.dir_exists_absolute(absolute_dir):
		DirAccess.make_dir_recursive_absolute(absolute_dir)
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	print("TILESET LAB: ", path)
