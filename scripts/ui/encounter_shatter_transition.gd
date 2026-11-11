class_name EncounterShatterTransition
extends CanvasLayer
## D-1172: encounter transition "Shatter Gravitacional 3D (36 cacos) + Cut-In de 1 único
## bloco paralelogramo flat" (protótipo `crawlmon_encounter_transition_prototype`).
##
## The real overworld frame is captured and split into 36 extruded shards. They crack
## around the contact point (soft radial blur + chroma, one shockwave ring, no flash:
## D-418), the scene is swapped while the screen is still covered, then the shards fall
## and reveal the real battle. A flat parallelogram stamps the callout word and a slanted
## banner follows. Same public surface as the old `EncounterTransition` (kept in the repo,
## unused): `play_to`, `active`, `has_revealed`, `revealed`, `finished`.
##
## Timeline in seconds from the start (= prototype time - 0.45 s; the prototype's first
## 0.45 s is the real overworld dash, which the game already played, D-1115):
##   0.00-0.33 crack + cut-in entry, 0.12 scene swap, 0.33 rupture (battle run-in starts),
##   1.00 arena revealed, 0.79-1.13 cut-in exit, 0.80-1.57 banner, 1.65 end.

signal revealed  ## The shards start falling; the battle is behind them.
signal finished

const RUPTURE_START := 0.33
const ARENA_REVEALED := 1.00
const TOTAL_DURATION := 1.65
const SWAP_AT := 0.12
const SHATTER_LEN := 0.88
const SHARD_COLS := 6
const SHARD_ROWS := 6
const SHARD_THICKNESS := 0.068
const BLUR_MULTIPLIER := 0.85
const CHROMA_MULTIPLIER := 0.80

const FACE_SHADER := preload("res://shaders/encounter_shard_face.gdshader")
const ARENA_SHADER := preload("res://shaders/encounter_arena_blur.gdshader")

const PROFILES := {
	EncounterRules.Advantage.NORMAL: {
		"id": "neutral",
		"callout_word": "CONTATO",
		"banner_title": "CONTATO // INICIATIVA PADRÃO",
		"banner_sub": "COLISÃO MÚTUA • ATB NORMAL",
		"banner_bg": Color(15.0 / 255.0, 25.0 / 255.0, 35.0 / 255.0, 0.92),
		"banner_text": Color("#FBF8EA"),
		"banner_border": Color("#FBF8EA"),
		"css_main": Color("#FBF8EA"),
		"word_color": Color("#091017"),
		"primary_color": Color("#E2E8F0"),
		"accent_color": Color("#38BDF8"),
	},
	EncounterRules.Advantage.PLAYER_FIRST: {
		"id": "blue",
		"callout_word": "OPORTUNIDADE",
		"banner_title": "OPORTUNIDADE // VANTAGEM DO JOGADOR",
		"banner_sub": "ATAQUE PREVENTIVO • +1 ATB BONUS",
		"banner_bg": Color(8.0 / 255.0, 28.0 / 255.0, 46.0 / 255.0, 0.94),
		"banner_text": Color("#38BDF8"),
		"banner_border": Color("#D4FF32"),
		"css_main": Color("#38BDF8"),
		"word_color": Color("#091017"),
		"primary_color": Color("#38BDF8"),
		"accent_color": Color("#D4FF32"),
	},
	EncounterRules.Advantage.ENEMY_FIRST: {
		"id": "red",
		"callout_word": "EMBOSCADA",
		"banner_title": "EMBOSCADA // ATAQUE SURPRESA INIMIGO",
		"banner_sub": "FORMAÇÃO SOB PRESSÃO • ALERTA VERMELHO",
		"banner_bg": Color(38.0 / 255.0, 10.0 / 255.0, 14.0 / 255.0, 0.94),
		"banner_text": Color("#FF5555"),
		"banner_border": Color("#FBBF24"),
		"css_main": Color("#FF5555"),
		"word_color": Color("#FBF8EA"),
		"primary_color": Color("#FF5555"),
		"accent_color": Color("#FBBF24"),
	},
}

var active := false
var has_revealed := false
var time := 0.0

var _target := ""
var _advantage: int = EncounterRules.Advantage.NORMAL
var _swapped := false
var _impact_uv := Vector2(0.5, 0.5)  ## Bottom-origin, like the shard grid.

var _root: Control
var _arena_rect: ColorRect
var _arena_mat: ShaderMaterial
var _shards_view: SubViewport
var _shards_rect: TextureRect
var _shards_group: Node3D
var _crack_lines: MeshInstance3D
var _crack_mat: StandardMaterial3D
var _face_mat: ShaderMaterial
var _side_mat: StandardMaterial3D
var _shards: Array[Dictionary] = []
var _cutin: CutIn
var _banner: Banner


static func profile_for(advantage: int) -> Dictionary:
	return PROFILES.get(advantage, PROFILES[EncounterRules.Advantage.NORMAL])


static func callout_for(advantage: int) -> String:
	return String(profile_for(advantage)["callout_word"])


static func color_for(advantage: int) -> Color:
	return profile_for(advantage)["css_main"]


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "ShatterRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # Swallow clicks while the screen is covered.
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_arena_mat = ShaderMaterial.new()
	_arena_mat.shader = ARENA_SHADER
	_arena_rect = ColorRect.new()
	_arena_rect.name = "ArenaBlur"
	_arena_rect.material = _arena_mat
	_arena_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_arena_rect)
	_arena_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena_rect.visible = false

	_build_shard_stage()
	_shards_rect = TextureRect.new()
	_shards_rect.name = "Shards"
	_shards_rect.texture = _shards_view.get_texture()
	_shards_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shards_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_shards_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_shards_rect)
	_shards_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_cutin = CutIn.new()
	_cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_cutin)
	_cutin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner = Banner.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false


## `impact_screen_uv`: contact point on screen, 0..1 from the top-left corner.
func play_to(scene_path: String, advantage: int = EncounterRules.Advantage.NORMAL, impact_screen_uv := Vector2(0.5, 0.5)) -> void:
	if active:
		return
	active = true
	has_revealed = false
	_swapped = false
	time = 0.0
	_target = scene_path
	_advantage = advantage
	_impact_uv = Vector2(clampf(impact_screen_uv.x, 0.15, 0.85), clampf(1.0 - impact_screen_uv.y, 0.15, 0.85))
	_face_mat.set_shader_parameter("t_overworld", _capture_screen())
	var win := Vector2i(get_tree().root.size)
	_shards_view.size = Vector2i(maxi(win.x, 320), maxi(win.y, 180))
	_shards_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_root.visible = true
	_apply(0.0)
	get_tree().paused = true  # Freeze the map under the cracked screen.


func _process(delta: float) -> void:
	if not active:
		return
	time = minf(time + delta, TOTAL_DURATION)
	if not _swapped and time >= SWAP_AT:
		_swapped = true
		get_tree().paused = false
		if _target != "":
			get_tree().change_scene_to_file(_target)
	if not has_revealed and time >= RUPTURE_START:
		has_revealed = true
		revealed.emit()
	_apply(time)
	if time >= TOTAL_DURATION:
		active = false
		_root.visible = false
		_arena_rect.visible = false
		_shards_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_face_mat.set_shader_parameter("t_overworld", null)
		finished.emit()


## The frame the player was looking at. Headless (no renderer) falls back to a flat tone.
func _capture_screen() -> Texture2D:
	var img: Image = null
	var tex := get_tree().root.get_texture()
	if tex != null and DisplayServer.get_name() != "headless":
		img = tex.get_image()
	if img == null or img.is_empty():
		img = Image.create(16, 9, false, Image.FORMAT_RGB8)
		img.fill(Color("#0B1520"))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ shard stage

func _build_shard_stage() -> void:
	_shards_view = SubViewport.new()
	_shards_view.name = "ShardStage"
	_shards_view.own_world_3d = true
	_shards_view.world_3d = World3D.new()
	_shards_view.transparent_bg = true
	_shards_view.size = Vector2i(1280, 720)
	_shards_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_shards_view)

	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.near = 0.1
	cam.far = 30.0
	cam.position = Vector3(0.0, 0.0, 1.0 / tan(deg_to_rad(22.5)))
	cam.current = true
	_shards_view.add_child(cam)

	_face_mat = ShaderMaterial.new()
	_face_mat.shader = FACE_SHADER
	_side_mat = StandardMaterial3D.new()
	_side_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.72)
	_side_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_side_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_side_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Deterministic jittered 6x6 grid (same seeds as the prototype).
	var grid: Array = []
	for r in SHARD_ROWS + 1:
		var row: Array[Vector2] = []
		for c in SHARD_COLS + 1:
			var u := float(c) / float(SHARD_COLS)
			var v := float(r) / float(SHARD_ROWS)
			if c > 0 and c < SHARD_COLS and r > 0 and r < SHARD_ROWS:
				u += ((float((r * 13 + c * 29) % 19) / 19.0) - 0.5) * (0.58 / float(SHARD_COLS))
				v += ((float((r * 31 + c * 7) % 23) / 23.0) - 0.5) * (0.58 / float(SHARD_ROWS))
			row.append(Vector2(u, v))
		grid.append(row)

	_shards_group = Node3D.new()
	_shards_group.name = "ShardsGroup3D"
	_shards_view.add_child(_shards_group)
	var crack_st := SurfaceTool.new()
	crack_st.begin(Mesh.PRIMITIVE_LINES)

	for r in SHARD_ROWS:
		for c in SHARD_COLS:
			var corners: Array[Vector2] = [grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c]]
			var cu := (corners[0].x + corners[1].x + corners[2].x + corners[3].x) * 0.25
			var cv := (corners[0].y + corners[1].y + corners[2].y + corners[3].y) * 0.25
			var mesh := ArrayMesh.new()
			var st_face := SurfaceTool.new()
			st_face.begin(Mesh.PRIMITIVE_TRIANGLES)
			_face_tri(st_face, corners[0], corners[1], corners[2], cu, cv, 0.0)
			_face_tri(st_face, corners[0], corners[2], corners[3], cu, cv, 0.0)
			_face_tri(st_face, corners[0], corners[2], corners[1], cu, cv, -SHARD_THICKNESS)
			_face_tri(st_face, corners[0], corners[3], corners[2], cu, cv, -SHARD_THICKNESS)
			st_face.generate_normals()
			st_face.commit(mesh)
			var st_side := SurfaceTool.new()
			st_side.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in 4:
				var a := corners[i]
				var b := corners[(i + 1) % 4]
				var a3 := Vector3((a.x - cu) * 2.0, (a.y - cv) * 2.0, 0.0)
				var b3 := Vector3((b.x - cu) * 2.0, (b.y - cv) * 2.0, 0.0)
				var back := Vector3(0.0, 0.0, -SHARD_THICKNESS)
				st_side.add_vertex(a3); st_side.add_vertex(b3); st_side.add_vertex(b3 + back)
				st_side.add_vertex(a3); st_side.add_vertex(b3 + back); st_side.add_vertex(a3 + back)
				crack_st.add_vertex(Vector3((a.x - 0.5) * 2.0, (a.y - 0.5) * 2.0, 0.015))
				crack_st.add_vertex(Vector3((b.x - 0.5) * 2.0, (b.y - 0.5) * 2.0, 0.015))
			st_side.generate_normals()
			st_side.commit(mesh)
			mesh.surface_set_material(0, _face_mat)
			mesh.surface_set_material(1, _side_mat)

			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			var rest := Vector3((cu - 0.5) * 2.0, (cv - 0.5) * 2.0, 0.0)
			mi.position = rest
			_shards_group.add_child(mi)
			var idx := r * SHARD_COLS + c
			_shards.append({
				"mesh": mi, "rest": rest, "cu": cu, "cv": cv, "row": r,
				"rot_axis": Vector3(sin(float(idx) * 2.1), cos(float(idx) * 1.7), sin(float(idx) * 3.3) * 0.5).normalized(),
				"vel_jitter": 0.88 + float((idx * 17) % 9) * 0.035,
			})

	_crack_mat = StandardMaterial3D.new()
	_crack_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	_crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_crack_lines = MeshInstance3D.new()
	_crack_lines.name = "CrackLines"
	_crack_lines.mesh = crack_st.commit()
	_crack_lines.material_override = _crack_mat
	_crack_lines.visible = false
	_shards_view.add_child(_crack_lines)


func _face_tri(st: SurfaceTool, a: Vector2, b: Vector2, d: Vector2, cu: float, cv: float, z: float) -> void:
	for p: Vector2 in [a, b, d]:
		st.set_uv(p)
		st.add_vertex(Vector3((p.x - cu) * 2.0, (p.y - cv) * 2.0, z))


# ------------------------------------------------------------------- animation

func _apply(t: float) -> void:
	var profile := profile_for(_advantage)
	var prim: Color = profile["primary_color"]
	var view := Vector2(_shards_view.size)
	var aspect := maxf(0.5, view.x / maxf(1.0, view.y))
	_shards_group.scale = Vector3(aspect, 1.0, 1.0)
	_crack_lines.scale = Vector3(aspect, 1.0, 1.0)
	_face_mat.set_shader_parameter("u_impact_center", Vector2(_impact_uv.x, 1.0 - _impact_uv.y))
	_face_mat.set_shader_parameter("u_primary_color", prim)
	_side_mat.albedo_color = Color(prim.r, prim.g, prim.b, 0.72)

	if t < RUPTURE_START:
		# Crack: soft blur/chroma, one shockwave, shards nudged away from the contact point.
		var p := clampf(t / RUPTURE_START, 0.0, 1.0)
		_set_face(sin(p * PI * 0.85) * 0.65 * BLUR_MULTIPLIER, sin(p * PI * 0.90) * 0.75 * CHROMA_MULTIPLIER, sin(p * PI) * 0.6, p, p * 0.25)
		_shards_group.visible = true
		_crack_lines.visible = true
		_crack_mat.albedo_color = Color(prim.r, prim.g, prim.b, _ease_out_cubic(p) * 0.78)
		_arena_rect.visible = false
		for sh in _shards:
			var mi := sh["mesh"] as Node3D
			var dx := float(sh["cu"]) - _impact_uv.x
			var dy := float(sh["cv"]) - _impact_uv.y
			var push := maxf(0.0, 1.0 - sqrt(dx * dx + dy * dy) * 1.4) * _ease_out_cubic(p) * 0.05
			var rest: Vector3 = sh["rest"]
			mi.position = Vector3(rest.x + dx * push, rest.y + dy * push, push * 1.1)
			mi.rotation = Vector3(dy * push * 1.4, -dx * push * 1.4, 0.0)
			mi.scale = Vector3.ONE
	else:
		# Rupture: gravity cascade, row by row; the live battle shows through, blurred at first.
		var dt := t - RUPTURE_START
		var p := clampf(dt / SHATTER_LEN, 0.0, 1.0)
		var blur := (1.0 - p) * 0.55 * BLUR_MULTIPLIER
		var chroma := (1.0 - p) * 0.65 * CHROMA_MULTIPLIER
		_crack_lines.visible = false
		_set_face(blur * 0.5, chroma * 0.6, maxf(0.0, (1.0 - p) * 0.35), 0.0, (1.0 - p) * 0.35)
		_arena_rect.visible = p < 1.0
		_arena_mat.set_shader_parameter("u_primary_color", prim)
		_arena_mat.set_shader_parameter("u_blur_strength", blur)
		_arena_mat.set_shader_parameter("u_chroma_shift", chroma)
		_arena_mat.set_shader_parameter("u_vignette_danger", 0.35 if profile["id"] == "red" else 0.14)
		_arena_mat.set_shader_parameter("u_amount", 1.0 - p)
		_shards_group.visible = p < 0.98
		if p < 0.98:
			for sh in _shards:
				var mi := sh["mesh"] as Node3D
				var dx := float(sh["cu"]) - 0.5
				var dy := float(sh["cv"]) - 0.5
				var nx := dx / maxf(0.06, sqrt(dx * dx + dy * dy))
				var local := maxf(0.0, dt - float(sh["row"]) * 0.042)
				var jit := float(sh["vel_jitter"])
				var rest: Vector3 = sh["rest"]
				var axis: Vector3 = sh["rot_axis"]
				mi.position = Vector3(rest.x + nx * local * 0.52 * jit, rest.y - (0.5 * 5.4 * local * local + 0.38 * local), -local * 0.26)
				mi.rotation = Vector3(local * 2.15 * jit, axis.y * local * 1.25, -nx * local * 1.15)
				mi.scale = Vector3.ONE * clampf(1.0 - p * p, 0.001, 1.0)
	_cutin.set_state(t, profile)
	_banner.set_state(t, profile)


func _set_face(blur: float, chroma: float, flash: float, shock: float, glint: float) -> void:
	_face_mat.set_shader_parameter("u_blur_strength", blur)
	_face_mat.set_shader_parameter("u_chroma_shift", chroma)
	_face_mat.set_shader_parameter("u_flash_amount", flash)
	_face_mat.set_shader_parameter("u_shockwave_progress", shock)
	_face_mat.set_shader_parameter("u_specular_glint", glint)


static func _ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var p := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + (c1 + 1.0) * p * p * p + c1 * p * p


## CSS-like transform: rotate, then skewX, then scale, around `pos`.
static func _css_xform(pos: Vector2, rot: float, skew_x: float, sc: Vector2) -> Transform2D:
	return Transform2D(rot, pos) * Transform2D(Vector2(1.0, 0.0), Vector2(tan(skew_x), 1.0), Vector2.ZERO) \
		* Transform2D(Vector2(sc.x, 0.0), Vector2(0.0, sc.y), Vector2.ZERO)


## One flat parallelogram (no border, shadow or texture) with the word slamming in
## letter by letter.
class CutIn extends Control:
	const END := 1.17
	var t := 0.0
	var profile: Dictionary = {}

	func set_state(p_t: float, p_profile: Dictionary) -> void:
		t = p_t
		profile = p_profile
		queue_redraw()

	func _draw() -> void:
		if profile.is_empty() or t > END:
			return
		var ease_entry := EncounterShatterTransition._ease_out_back(clampf(t / 0.16, 0.0, 1.0))
		var p_entry := clampf(t / 0.16, 0.0, 1.0)
		var p_exit := clampf((t - 0.79) / 0.34, 0.0, 1.0)
		var ease_exit := p_exit * p_exit * p_exit
		var alpha := clampf(1.0 - ease_exit, 0.0, 1.0)
		if alpha <= 0.005:
			return
		var slide_x := (1.0 - ease_entry) * -260.0 + ease_exit * 280.0
		var scale_y := lerpf(1.0, 0.05, ease_exit) if p_exit > 0.0 else 1.0
		var skew_deg := lerpf(-34.0, -20.0, p_entry) - ease_exit * 18.0
		var word := String(profile["callout_word"]) + "!"
		var font := FanMenu.body_font()
		var font_size := 52
		var advances: Array[float] = []
		var total_w := 0.0
		for i in word.length():
			var adv := font.get_string_size(word.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 3.0
			advances.append(adv)
			total_w += adv
		var hw := maxf(290.0, total_w + 108.0) * 0.5
		var hh := 44.0
		var block := EncounterShatterTransition._css_xform(size * 0.5 + Vector2(slide_x, 0.0), deg_to_rad(-5.0),
			deg_to_rad(skew_deg), Vector2(1.0, maxf(0.01, scale_y)))
		draw_set_transform_matrix(block)
		var bg: Color = profile["css_main"]
		bg.a = alpha
		draw_colored_polygon(PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]), bg)

		var word_col: Color = profile["word_color"]
		var cursor := -total_w * 0.5
		var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		for i in word.length():
			var adv := advances[i]
			var cx := cursor + adv * 0.5
			cursor += adv
			var p_char := clampf((t - (0.02 + float(i) * 0.022)) / 0.13, 0.0, 1.0)
			var ease_char := EncounterShatterTransition._ease_out_back(p_char)
			var char_alpha := clampf(p_char * 2.0, 0.0, 1.0) * alpha
			if p_char < 0.01 or char_alpha <= 0.01:
				continue
			var wave_y := sin(t * 16.0 - float(i) * 0.7) * 2.5 if p_char >= 1.0 else (1.0 - ease_char) * -32.0
			var sc := lerpf(1.75, 1.0, clampf(p_char * 1.1, 0.0, 1.0))
			var rot := (1.0 - ease_char) * (-16.0 if i % 2 == 0 else 16.0)
			draw_set_transform_matrix(block * EncounterShatterTransition._css_xform(Vector2(cx, wave_y), deg_to_rad(rot), deg_to_rad(12.0), Vector2(sc, sc)))
			draw_string(font, Vector2(-adv * 0.5, baseline), word.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				Color(word_col.r, word_col.g, word_col.b, char_alpha))
		draw_set_transform_matrix(Transform2D.IDENTITY)


## Slanted lower banner with the initiative read-out.
class Banner extends Control:
	const START := 0.80
	const END := 1.57
	var t := 0.0
	var profile: Dictionary = {}

	func set_state(p_t: float, p_profile: Dictionary) -> void:
		t = p_t
		profile = p_profile
		queue_redraw()

	func _draw() -> void:
		if profile.is_empty() or t < START or t > END:
			return
		var alpha := clampf((t - START) / 0.12, 0.0, 1.0) * (1.0 - clampf((t - 1.45) / 0.12, 0.0, 1.0))
		if alpha <= 0.01:
			return
		var banner_w := clampf(size.x - 48.0, 320.0, 960.0)
		var hw := banner_w * 0.5
		var outer := EncounterShatterTransition._css_xform(Vector2(size.x * 0.5, size.y - 32.0), 0.0, deg_to_rad(-14.0), Vector2.ONE)
		draw_set_transform_matrix(outer)
		var bg: Color = profile["banner_bg"]
		bg.a *= alpha
		draw_rect(Rect2(-hw, -18.0, banner_w, 36.0), bg, true)
		var border: Color = profile["banner_border"]
		border.a = alpha
		draw_rect(Rect2(-hw, -18.0, 5.0, 36.0), border, true)
		draw_set_transform_matrix(outer * EncounterShatterTransition._css_xform(Vector2.ZERO, 0.0, deg_to_rad(14.0), Vector2.ONE))
		var font := FanMenu.body_font()
		var col: Color = profile["banner_text"]
		col.a = alpha
		var sub := String(profile["banner_sub"])
		draw_string(font, Vector2(-hw + 18.0, 6.0), String(profile["banner_title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
		draw_string(font, Vector2(hw - font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x - 18.0, 5.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		draw_set_transform_matrix(Transform2D.IDENTITY)
