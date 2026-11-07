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
const BiomeVisuals := preload("res://scripts/dungeon/biome_visuals.gd")
## Room embedded in a wall mass (the same case the game generates), so the
## sides use the core side pieces instead of the free-standing border strips.
const ROOM := Vector2i(14, 10)
const FLOOR_RECT := Rect2i(4, 3, 6, 4)
## A 1-tile corridor through the left wall: the doorway case (D-356).
const DOOR_CELLS := [Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 4)]
const MASK_ORIGIN := Vector2i(0, 20)
const MASK_COLUMNS := 6
const MASK_STEP := 4
const VARIATION_SEED := 12345

@export var profile_override := ""
@export var alt1_percent := 5
@export var alt2_percent := 5

var _roles: Dictionary = {}
var _role_sides: Dictionary = {}
var _role_face: Dictionary = {}
var _decals: Dictionary = {}
var _columns := 28
var _mask_mode := false
var _name := "tileset"
var _atlas: Texture2D
var _modulate: CanvasModulate
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
	if args.has("--golden"):
		await get_tree().process_frame
		if _title != null:
			_title.visible = false
		if _hover != null:
			_hover.visible = false
		_camera.zoom = Vector2(2.3, 2.3)
		_camera.position = Vector2(7 * TILE, 13 * TILE)
		await capture("res://scratch/tileset_lab_golden_room.png")
		get_tree().quit()
		return
	if args.has("--alt-capture"):
		for pair in [[0, 0], [2, 3], [5, 5], [7, 8]]:
			alt1_percent = pair[0]
			alt2_percent = pair[1]
			setup(ACTIVE_PROFILE)
			await get_tree().process_frame
			_camera.zoom = Vector2(2.3, 2.3)
			_camera.position = Vector2(7 * TILE, 13 * TILE)
			_title.text = "Wall Alt. %d%% + %d%%" % [alt1_percent, alt2_percent]
			_title.position = Vector2(200, 520)
			if _hover != null:
				_hover.visible = false
			await capture("res://scratch/tileset_lab_alt_%d_%d.png" % [alt1_percent, alt2_percent])
		get_tree().quit()
		return
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
	elif event.keycode == KEY_M:
		_mask_mode = not _mask_mode
		_camera.zoom = Vector2(1.0, 1.0) if _mask_mode else Vector2(2.3, 2.3)
		_camera.position = Vector2(552, 1320) if _mask_mode else Vector2(7 * TILE, 13 * TILE)


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
	_role_sides = {}
	_role_face = data.get("role_sides", {})
	if bool(data.get("side_contract_ok", false)):
		_role_sides = data.get("role_sides", {})
	_columns = int(data.get("columns", 28))
	_name = str(data.get("name", "tileset"))
	var atlas_path := str(data.get("atlas", ""))
	if not ResourceLoader.exists(atlas_path):
		push_error("tileset lab: missing atlas " + atlas_path)
		return
	_atlas = _load_texture(atlas_path)
	_modulate = CanvasModulate.new()
	_modulate.color = BiomeVisuals.ambient(_name)
	add_child(_modulate)
	_build_tileset()
	_build_catalog()
	_build_decals()
	_build_room()
	_build_masks()
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
	var origin := Vector2i(0, 8)
	for y in ROOM.y:
		for x in ROOM.x:
			var index := _wall_index(x, y) if _is_wall(x, y) else _ground_index(x, y)
			_room_layer.set_cell(origin + Vector2i(x, y), _source_id, Vector2i(index, 0))


## One 3x3 mini-grid per wall role: the centre is the role, the neighbours
## show its 8-neighbour mask. This is how the rare pieces (island, tips, cross)
## are seen instead of only inferred from the atlas.
func _build_masks() -> void:
	var cases: Array[String] = []
	for role in _roles.keys():
		if str(role).begins_with("wall_"):
			cases.append(str(role))
	cases.sort()
	for index in cases.size():
		var role := cases[index]
		var base := MASK_ORIGIN + Vector2i(
			(index % MASK_COLUMNS) * MASK_STEP,
			(index / MASK_COLUMNS) * MASK_STEP)
		_paint_mask_case(base, role)
		var label := Label.new()
		label.text = "%s %s" % [role, _mask_signature(role)]
		label.position = Vector2(base.x * TILE + 2, base.y * TILE + 2)
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		label.z_index = 5
		add_child(label)


func _paint_mask_case(base: Vector2i, role: String) -> void:
	var signature := _mask_signature(role)
	var floor_cells := {}
	if role == "wall_cross":
		for dx in [-1, 1]:
			for dy in [-1, 1]:
				floor_cells[Vector2i(dx, dy)] = true
	elif role != "wall_c":
		for side in signature:
			var direction := _side_direction(side)
			floor_cells[direction] = true
			if side == "N" or side == "S":
				floor_cells[Vector2i(-1, direction.y)] = true
				floor_cells[Vector2i(1, direction.y)] = true
			else:
				floor_cells[Vector2i(direction.x, -1)] = true
				floor_cells[Vector2i(direction.x, 1)] = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := base + Vector2i(dx, dy)
			if dx == 0 and dy == 0:
				_room_layer.set_cell(cell, _source_id, Vector2i(_role(role), 0))
			elif floor_cells.get(Vector2i(dx, dy), false):
				_room_layer.set_cell(cell, _source_id, Vector2i(_role("ground_c"), 0))
			else:
				_room_layer.set_cell(cell, _source_id, Vector2i(_role("wall_c"), 0))


func _mask_signature(role: String) -> String:
	if _role_face.has(role):
		return str(_role_face[role])
	var fallback := {
		"wall_tl": "NW", "wall_t": "N", "wall_tr": "NE",
		"wall_l": "W", "wall_c": "", "wall_r": "E",
		"wall_bl": "SW", "wall_b": "S", "wall_br": "SE",
		"wall_strip_v": "WE", "wall_strip_h": "NS",
		"wall_island": "NSWE",
		"wall_tip_n": "NWE", "wall_tip_s": "SWE",
		"wall_tip_w": "NSW", "wall_tip_e": "NSE",
		"wall_cross": "",
		"wall_alt_1": "", "wall_alt_2": "",
	}
	return str(fallback.get(role, ""))


func _side_direction(side: String) -> Vector2i:
	match side:
		"N": return Vector2i(0, -1)
		"S": return Vector2i(0, 1)
		"W": return Vector2i(-1, 0)
		"E": return Vector2i(1, 0)
	return Vector2i.ZERO


## A 3-tile thin wall exercises the horizontal strip and the two tips; the
## room ring exercises the four corners.
func _is_pillar(x: int, y: int) -> bool:
	return y == 4 and (x == 6 or x == 7 or x == 8)


func _is_wall(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= ROOM.x or y >= ROOM.y:
		return true
	if DOOR_CELLS.has(Vector2i(x, y)):
		return false
	if not FLOOR_RECT.has_point(Vector2i(x, y)):
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
	var key := ""
	if n:
		key += "N"
	if s:
		key += "S"
	if w:
		key += "W"
	if e:
		key += "E"
	if key.is_empty():
		if _role("wall_cross") >= 0 and _diagonal_floor(x, y):
			return _role("wall_cross")
		var alt1 := _role("wall_alt_1")
		var alt2 := _role("wall_alt_2")
		if (alt1 >= 0 or alt2 >= 0) and _deep_wall(x, y):
			var roll := absi(_hash(x, y) ^ VARIATION_SEED) % 100
			if alt1 >= 0 and roll < alt1_percent:
				return alt1
			if alt2 >= 0 and roll < alt1_percent + alt2_percent:
				return alt2
		return _role("wall_c")
	var matched := int(_role_sides.get(key, -1))
	if matched >= 0:
		return matched
	if n and s and w and e:
		return _role("wall_island")
	if n and w and e:
		return _role("wall_tip_n")
	if s and w and e:
		return _role("wall_tip_s")
	if n and s and w:
		return _role("wall_tip_w")
	if n and s and e:
		return _role("wall_tip_e")
	if n and s:
		return _role("wall_strip_h")
	if w and e:
		return _role("wall_strip_v")
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


func _diagonal_floor(x: int, y: int) -> bool:
	return _is_floor(x - 1, y - 1) and _is_floor(x + 1, y - 1) \
		and _is_floor(x - 1, y + 1) and _is_floor(x + 1, y + 1)


func _deep_wall(x: int, y: int) -> bool:
	if not _is_solid(x, y):
		return false
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if not _is_solid(nx, ny):
				return false
	return true


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
	return _ground_center(x, y)


func _build_decals() -> void:
	_decals.clear()
	var alt1 := _role("ground_alt_1")
	var alt2 := _role("ground_alt_2")
	if alt1 < 0 and alt2 < 0:
		return
	var candidates: Array[Vector2i] = []
	for y in ROOM.y:
		for x in ROOM.x:
			if _is_interior_floor(x, y):
				candidates.append(Vector2i(x, y))
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = VARIATION_SEED
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	var target1 := int(round(candidates.size() * 0.04))
	var target2 := int(round(candidates.size() * 0.04))
	var placed1 := 0
	var placed2 := 0
	for cell in candidates:
		if placed1 >= target1 and placed2 >= target2:
			break
		if _has_decal_near(cell):
			continue
		var role := -1
		if alt1 >= 0 and placed1 < target1 and (alt2 < 0 or placed1 <= placed2):
			role = alt1
			placed1 += 1
		elif alt2 >= 0 and placed2 < target2:
			role = alt2
			placed2 += 1
		if role >= 0:
			_decals[cell] = role


func _ground_center(x: int, y: int) -> int:
	var decal := int(_decals.get(Vector2i(x, y), -1))
	return decal if decal >= 0 else _role("ground_c")


func _has_decal_near(cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			if _decals.has(cell + Vector2i(dx, dy)):
				return true
	return false


func _is_interior_floor(x: int, y: int) -> bool:
	if _is_wall(x, y):
		return false
	return not _is_wall(x - 1, y) and not _is_wall(x + 1, y) \
		and not _is_wall(x, y - 1) and not _is_wall(x, y + 1)


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663))


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2.3, 2.3)
	_camera.position = Vector2(7 * TILE, 13 * TILE)
	_camera.enabled = true
	add_child(_camera)
	_camera.make_current()


func _build_title() -> void:
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	_title.z_index = 10
	_title.position = Vector2(200, 520)
	add_child(_title)
	_hover = Label.new()
	_hover.add_theme_font_size_override("font_size", 10)
	_hover.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
	_hover.position = Vector2(200, 540)
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
	# The 42-tile catalog needs a slightly wider view than the 2.3x room.
	_camera.zoom = Vector2(1.8, 1.8)
	_camera.position = Vector2(3 * TILE, 3 * TILE)
	_title.text = "%s — catálogo (índices)" % _label()
	_title.position = Vector2(8, -18)
	await capture(prefix + "_catalog.png")
	_camera.zoom = Vector2(2.3, 2.3)
	_camera.position = Vector2(7 * TILE, 13 * TILE)
	_title.text = "%s — piso orgânico, 48 px, câmera 2,3x" % _label()
	_title.position = Vector2(200, 520)
	await capture(prefix + "_room.png")
	_title.visible = false
	_camera.zoom = Vector2(1.0, 1.0)
	_camera.position = Vector2(552, 1320)
	await capture(prefix + "_masks.png")
	_title.visible = true
	_camera.zoom = Vector2(2.3, 2.3)
	_camera.position = Vector2(7 * TILE, 13 * TILE)
	_title.position = Vector2(200, 520)


func capture(path: String) -> void:
	for i in 3:
		await get_tree().process_frame
	var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
	if not DirAccess.dir_exists_absolute(absolute_dir):
		DirAccess.make_dir_recursive_absolute(absolute_dir)
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	print("TILESET LAB: ", path)
