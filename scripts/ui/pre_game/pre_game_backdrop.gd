class_name PreGameBackdrop
extends Control
## 1:1 Neo-Brutalist canvas backdrop for the Pre-Game UI (D-1207 / D-1208).
## Reproduces renderStage(), drawStatusSpires() and drawCoralMonolithBackdrop()
## from prototypes/pre_game_hud_s18_validacao.html with zero external PNGs:
## every glow is a GradientTexture2D built in code and every solid layer is a
## CanvasItem primitive. English only (D-413 / D-1085), static typing (D-1079).

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")

const DUST_COUNT: int = 35
const DUST_SEED: int = 20260818
const FRAME_RATE_BASE: float = 60.0
const TURNTABLE_STEP: float = 0.011
const FRAME_LERP: float = 0.12
const DRAG_RADIANS_PER_PX: float = 0.012
const ZOOM_OFFSET_MIN: float = -0.22
const ZOOM_OFFSET_MAX: float = 0.32
const PEDESTAL_POINTS: int = 48
const ORBIT_TICKS: int = 12
const SPIRE_COUNT: int = 12
const GRADIENT_SIZE: int = 256
const BG_A_RADIUS: float = 0.78
const BG_C_RADIUS: float = 0.75

const PROTO_BG := Color("04070c")
const PROTO_BG_GLOW := Color("0e1929")
const BG_B_TOP := Color("040910")
const BG_B_MID := Color("0e1f2d")
const BG_C_CENTER := Color("1c3e3b")
const BG_C_MID := Color("0a2024")
const BG_C_EDGE := Color("040b0e")

var current_view: String = "title"
## D-1226: charselect art view hides the monolith and pedestal (no 3D stage).
var art_mode: bool = false
var concept: String = "A"
var species_index: int = 0
var model_angle: float = 0.28
var turntable_active: bool = false
var reduce_motion: bool = false
var frozen: bool = false
var manual_zoom_offset: float = 0.0
var pedestal_safe_rect: Rect2 = Rect2()

var cam_x: float = -18.0
var cam_y: float = 0.0
var cam_zoom: float = 0.98
var tick: float = 0.0

var _dust: Array[Dictionary] = []
var _dust_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _proto_tex: GradientTexture2D = null
var _bg_tex: GradientTexture2D = null
var _bg_key: String = ""
var _aura_tex: GradientTexture2D = null
var _spec_cache: Dictionary = {}
var _spec_cache_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_dust()
	_aura_texture()
	snap_camera()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _process(p_delta: float) -> void:
	if frozen:
		return
	var delta: float = minf(p_delta, 0.1)
	tick += delta
	if turntable_active and not reduce_motion and (current_view == "charselect" or current_view == "menu"):
		model_angle += TURNTABLE_STEP * FRAME_RATE_BASE * delta
	var target: Dictionary = get_target_camera(_logical_size())
	var mix: float = 1.0
	if not reduce_motion:
		mix = 1.0 - pow(1.0 - FRAME_LERP, delta * FRAME_RATE_BASE)
	cam_x = lerpf(cam_x, float(target.get("target_x", cam_x)), mix)
	cam_y = lerpf(cam_y, float(target.get("target_y", cam_y)), mix)
	cam_zoom = lerpf(cam_zoom, float(target.get("target_zoom", cam_zoom)), mix)
	if not reduce_motion:
		_step_dust(delta)
	queue_redraw()


# --- Public API ---------------------------------------------------------------

func set_view_state(p_view: String, p_species_idx: int, p_concept: String = "A", p_safe_rect: Rect2 = Rect2()) -> void:
	current_view = p_view
	species_index = maxi(p_species_idx, 0)
	concept = p_concept
	pedestal_safe_rect = p_safe_rect
	if frozen or reduce_motion:
		snap_camera()
	queue_redraw()


func set_camera_controls(p_angle: float, p_turntable: bool, p_zoom_offset: float) -> void:
	model_angle = p_angle
	turntable_active = p_turntable
	manual_zoom_offset = clampf(p_zoom_offset, ZOOM_OFFSET_MIN, ZOOM_OFFSET_MAX)
	if frozen or reduce_motion:
		snap_camera()
	queue_redraw()


## Mirrors the HTML drag layer: 0.012 rad per horizontal pixel of drag.
func stage_drag(delta_x: float) -> void:
	model_angle += delta_x * DRAG_RADIANS_PER_PX
	queue_redraw()


## Places the camera exactly on its target so a deterministic screenshot matches
## the HTML frame without waiting for the smoothing to settle.
func snap_camera() -> void:
	var target: Dictionary = get_target_camera(_logical_size())
	cam_x = float(target.get("target_x", cam_x))
	cam_y = float(target.get("target_y", cam_y))
	cam_zoom = float(target.get("target_zoom", cam_zoom))
	queue_redraw()


## Snaps the camera and rewinds the clock and the dust field to frame zero.
func snap_state() -> void:
	tick = 0.0
	_seed_dust()
	snap_camera()


@warning_ignore("unused_parameter")
func get_target_camera(viewport_size: Vector2) -> Dictionary:
	var target_x: float = 0.0
	var target_y: float = 0.0
	var target_zoom: float = 1.0
	match current_view:
		"title":
			target_x = -18.0
			target_y = 0.0
			target_zoom = 0.98
		"menu":
			target_x = 76.0
			target_y = 6.0
			target_zoom = 1.02
		"charselect":
			var species_h: float = float(_species_spec().get("height", 2.0))
			target_x = 0.0
			target_y = (species_h - 2.0) * 6.0
			var base_z: float = clampf(2.0 / species_h, 0.78, 1.16)
			target_zoom = clampf(base_z + manual_zoom_offset, 0.70, 1.28)
		_:
			target_x = 0.0
			target_y = -16.0
			target_zoom = 0.90
	return {"target_x": target_x, "target_y": target_y, "target_zoom": target_zoom}


func get_character_stage_metrics(viewport_size: Vector2) -> Dictionary:
	var w: float = viewport_size.x
	var h: float = viewport_size.y
	var char_x: float = 0.0
	var ground_y: float = 0.0
	var max_stage_h: float = 0.0
	if current_view == "title":
		char_x = w * 0.71 + cam_x * 0.25
		ground_y = h * 0.78
		max_stage_h = h * 0.48
	elif current_view == "menu":
		char_x = w * 0.70 + cam_x * 0.25
		ground_y = h * 0.73
		max_stage_h = h * 0.45
	else:
		if pedestal_safe_rect.size.x > 10.0:
			char_x = pedestal_safe_rect.position.x + pedestal_safe_rect.size.x * 0.5
			ground_y = pedestal_safe_rect.position.y + pedestal_safe_rect.size.y - h * 0.015
			max_stage_h = pedestal_safe_rect.size.y * 0.88
		else:
			char_x = w * 0.44
			ground_y = h * 0.58
			max_stage_h = h * 0.36
	var spec: Dictionary = _species_spec()
	var species_h: float = float(spec.get("height", 2.0))
	var base_scale: float = clampf(species_h / 2.15, 0.68, 1.16) * cam_zoom
	var draw_h: float = minf(max_stage_h * 0.95, h * 0.35 * base_scale)
	var ring_rx: float = maxf(54.0, draw_h * 0.40)
	var ring_ry: float = ring_rx * 0.20
	var idle_bob: float = 0.0
	if not reduce_motion and not frozen:
		idle_bob = sin(tick * 2.2) * (h * 0.005)
	return {
		"char_x": char_x,
		"ground_y": ground_y,
		"draw_h": draw_h,
		"ring_rx": ring_rx,
		"ring_ry": ring_ry,
		"idle_bob": idle_bob,
		"accent": Color(spec.get("accent", PreGameDraw.CYAN)),
		"height": species_h,
		"target_zoom": float(get_target_camera(viewport_size).get("target_zoom", 1.0)),
	}


# --- Draw layers --------------------------------------------------------------

func _draw() -> void:
	var w: float = maxf(size.x, 1.0)
	var h: float = maxf(size.y, 1.0)
	var view_size := Vector2(w, h)
	# Layer 1: radial or linear background gradient.
	_draw_background(view_size)
	# Layer 2: horizon, status spires and the perspective floor grid.
	var cx: float = w * 0.5 + cam_x * (w / 1280.0)
	var horizon_y: float = h * 0.56 + cam_y * (h / 720.0)
	if concept == "A" or concept == "C":
		_draw_status_spires(w, h, horizon_y)
		_draw_perspective_floor(w, h, cx, horizon_y)
	else:
		_draw_typo_watermark(w, h)
	# Layer 3: diagonal brutalist cut-bar.
	_draw_cut_bar(w, h)
	# Layer 4: coral monolith and turntable pedestal.
	if (current_view == "charselect" and not art_mode) or current_view == "menu" or current_view == "title":
		_draw_stage(view_size)
	# Layer 5: floating ambient dust.
	_draw_dust(view_size)


func _draw_background(view_size: Vector2) -> void:
	var w: float = view_size.x
	var h: float = view_size.y
	if current_view == "charselect":
		# D-1226: dark prototype background (prototypes/pre_game_hud.html #04070c / #0e1929).
		draw_rect(Rect2(Vector2.ZERO, view_size), PROTO_BG)
		draw_texture_rect(_proto_radial_texture(), Rect2(Vector2(w * 0.5 - w * 0.75, -h * 0.1), Vector2(w * 1.5, h * 1.5)), false)
		return
	if concept == "B":
		draw_texture_rect(_linear_texture(), Rect2(Vector2.ZERO, view_size), false)
		return
	var center := Vector2(w * 0.48, h * 0.52)
	var radius: float = w * BG_A_RADIUS
	if concept == "C":
		center = Vector2(w * 0.5, h * 0.55)
		radius = w * BG_C_RADIUS
	draw_rect(Rect2(Vector2.ZERO, view_size), _radial_outer())
	draw_texture_rect(
		_radial_texture(),
		Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)),
		false
	)


func _proto_radial_texture() -> GradientTexture2D:
	if _proto_tex != null:
		return _proto_tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	g.colors = PackedColorArray([PROTO_BG_GLOW, PROTO_BG, PROTO_BG])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = GRADIENT_SIZE
	tex.height = GRADIENT_SIZE
	_proto_tex = tex
	return _proto_tex


func _radial_outer() -> Color:
	return BG_C_EDGE if concept == "C" else PreGameDraw.BG_DARK


func _radial_texture() -> GradientTexture2D:
	if _bg_tex != null and _bg_key == concept:
		return _bg_tex
	var g := Gradient.new()
	if concept == "C":
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([BG_C_CENTER, BG_C_MID, BG_C_EDGE])
	else:
		g.offsets = PackedFloat32Array([0.0, 0.35, 0.66, 1.0])
		g.colors = PackedColorArray([
			PreGameDraw.BG_TOP, PreGameDraw.BG_MID1, PreGameDraw.BG_MID2, PreGameDraw.BG_DARK
		])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = GRADIENT_SIZE
	tex.height = GRADIENT_SIZE
	_bg_tex = tex
	_bg_key = concept
	return _bg_tex


func _linear_texture() -> GradientTexture2D:
	if _bg_tex != null and _bg_key == "B":
		return _bg_tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	g.colors = PackedColorArray([BG_B_TOP, BG_B_MID, BG_B_TOP])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.width = 8
	tex.height = GRADIENT_SIZE
	_bg_tex = tex
	_bg_key = "B"
	return _bg_tex


func _aura_texture() -> GradientTexture2D:
	if _aura_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([
			Color(0.388, 0.851, 0.925, 0.28),
			Color(0.839, 0.980, 0.400, 0.10),
			Color(0.0, 0.0, 0.0, 0.0),
		])
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_aura_tex = tex
	return _aura_tex


func _draw_status_spires(w: float, h: float, horizon_y: float) -> void:
	var hy: float = h / 720.0
	var base_y: float = horizon_y + h * 0.14
	var bw: float = 25.0 * (w / 1280.0)
	var shaft_col := Color(0.086, 0.243, 0.298, 0.36)
	var capital_col := Color(0.110, 0.282, 0.361, 0.40)
	var spire_col := Color(0.051, 0.165, 0.227, 0.44)
	var pinnacle_col := Color(0.961, 0.839, 0.561, 0.54)
	for i in SPIRE_COUNT:
		var sh: float = (92.0 + float((i * 67) % 230)) * hy
		var sx: float = ((float(i) + 0.4) / float(SPIRE_COUNT)) * w + cam_x * 0.25
		draw_rect(Rect2(sx, base_y - sh, bw, sh), shaft_col)
		var capital := PackedVector2Array([
			Vector2(sx - bw * 0.22, base_y - sh),
			Vector2(sx + bw * 1.22, base_y - sh),
			Vector2(sx + bw, base_y - sh - 9.0 * hy),
			Vector2(sx, base_y - sh - 9.0 * hy),
		])
		draw_colored_polygon(capital, capital_col)
		var spire := PackedVector2Array([
			Vector2(sx + bw * 0.5, base_y - sh - 38.0 * hy),
			Vector2(sx + bw, base_y - sh - 9.0 * hy),
			Vector2(sx, base_y - sh - 9.0 * hy),
		])
		draw_colored_polygon(spire, spire_col)
		draw_circle(
			Vector2(sx + bw * 0.5, base_y - sh - 44.0 * hy),
			maxf(2.2, 3.6 * hy),
			pinnacle_col
		)


func _draw_perspective_floor(w: float, h: float, cx: float, horizon_y: float) -> void:
	var stroke := Color(0.388, 0.851, 0.925, 0.16)
	if concept == "C":
		stroke = Color(0.839, 0.980, 0.400, 0.15)
	var line_w: float = maxf(1.0, w / 1100.0)
	for i in range(-12, 13):
		var near_x: float = cx + float(i) * (w * 0.025) * cam_zoom
		var far_x: float = cx + float(i) * (w * 0.105) * cam_zoom
		draw_line(Vector2(near_x, horizon_y), Vector2(far_x, h), stroke, line_w, true)
	for r in range(1, 7):
		var py: float = horizon_y + pow(float(r) / 6.0, 1.55) * (h - horizon_y)
		draw_line(Vector2(0.0, py), Vector2(w, py), stroke, line_w, true)


func _draw_typo_watermark(w: float, h: float) -> void:
	var title: String = "CRAWL/MON"
	if current_view == "charselect":
		title = str(_species_spec().get("name", "")).to_upper()
	if title.is_empty():
		title = "CRAWL/MON"
	var font: Font = PreGameDraw.title_font()
	var font_size: int = maxi(1, int(round(w * 0.12)))
	var text_w: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_set_transform(Vector2(w * 0.5, h * 0.44), deg_to_rad(-6.0), Vector2.ONE)
	draw_string(
		font,
		Vector2(-text_w * 0.5, 0.0),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.839, 0.980, 0.400, 0.06)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_cut_bar(w: float, h: float) -> void:
	var poly := PackedVector2Array([
		Vector2(0.0, h * 0.72),
		Vector2(w, h * 0.44),
		Vector2(w, h * 0.455),
		Vector2(0.0, h * 0.735),
	])
	draw_colored_polygon(poly, Color(1.0, 0.455, 0.424, 0.12))


func _draw_stage(viewport_size: Vector2) -> void:
	var metrics: Dictionary = get_character_stage_metrics(viewport_size)
	var char_x: float = float(metrics.get("char_x", 0.0))
	var ground_y: float = float(metrics.get("ground_y", 0.0))
	var draw_h: float = float(metrics.get("draw_h", 0.0))
	var ring_rx: float = float(metrics.get("ring_rx", 54.0))
	var ring_ry: float = float(metrics.get("ring_ry", 10.8))
	var accent: Color = Color(metrics.get("accent", PreGameDraw.CYAN))
	_draw_coral_monolith(char_x, ground_y - draw_h * 0.98, draw_h)
	_draw_pedestal(char_x, ground_y, ring_rx, ring_ry, accent, viewport_size.x)


func _draw_coral_monolith(char_x: float, char_top_y: float, char_h: float) -> void:
	var mon_w: float = maxf(150.0, char_h * 0.86)
	var mon_h: float = maxf(190.0, char_h * 1.18)
	var mcx: float = char_x
	var mcy: float = char_top_y + mon_h * 0.44

	var shard := PackedVector2Array([
		Vector2(-mon_w * 0.32, -mon_h * 0.52),
		Vector2(-mon_w * 0.18, -mon_h * 0.52),
		Vector2(-mon_w * 0.26, mon_h * 0.52),
		Vector2(-mon_w * 0.40, mon_h * 0.52),
	])
	draw_set_transform(Vector2(mcx - mon_w * 0.08, mcy + 6.0), deg_to_rad(8.0), Vector2.ONE)
	draw_colored_polygon(shard, Color(0.388, 0.851, 0.925, 0.18))

	var body := PackedVector2Array([
		Vector2(-mon_w * 0.28, -mon_h * 0.5),
		Vector2(mon_w * 0.42, -mon_h * 0.5),
		Vector2(mon_w * 0.16, mon_h * 0.5),
		Vector2(-mon_w * 0.50, mon_h * 0.5),
	])
	var top_col := Color(0.980, 0.400, 0.369, 0.72)
	var bottom_col := Color(0.600, 0.200, 0.239, 0.78)
	draw_set_transform(Vector2(mcx, mcy), deg_to_rad(-11.0), Vector2.ONE)
	draw_polygon(body, PackedColorArray([top_col, top_col, bottom_col, bottom_col]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pedestal(char_x: float, ground_y: float, ring_rx: float, ring_ry: float, accent: Color, w: float) -> void:
	var ax: float = ring_rx * 1.35
	var ay: float = ring_ry * 1.9
	var aura: GradientTexture2D = _aura_texture()
	draw_texture_rect(aura, Rect2(char_x - ax, ground_y - ay, ax * 2.0, ay * 2.0), false)

	var points := PackedVector2Array()
	for i in PEDESTAL_POINTS:
		var a: float = TAU * float(i) / float(PEDESTAL_POINTS)
		points.append(Vector2(char_x + cos(a) * ring_rx, ground_y + sin(a) * ring_ry))
	draw_colored_polygon(points, Color(0.031, 0.075, 0.122, 0.88))
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, accent, maxf(1.8, w / 640.0), true)

	var tick_col := Color(0.839, 0.980, 0.400, 0.72)
	for t in ORBIT_TICKS:
		var a: float = model_angle + float(t) / float(ORBIT_TICKS) * TAU
		draw_line(
			Vector2(char_x + cos(a) * ring_rx * 0.80, ground_y + sin(a) * ring_ry * 0.80),
			Vector2(char_x + cos(a) * ring_rx, ground_y + sin(a) * ring_ry),
			tick_col,
			1.3,
			true
		)


func _draw_dust(viewport_size: Vector2) -> void:
	if reduce_motion:
		return
	var base: Color = PreGameDraw.LIME if concept == "C" else PreGameDraw.CYAN
	for point in _dust:
		var pos := Vector2(
			float(point.get("x", 0.0)) * viewport_size.x,
			float(point.get("y", 0.0)) * viewport_size.y
		)
		var radius: float = float(point.get("r", 1.0))
		var alpha: float = float(point.get("a", 0.0))
		draw_circle(pos, radius, Color(base, alpha))


# --- Helpers ------------------------------------------------------------------

func _logical_size() -> Vector2:
	var rect: Vector2 = size
	if rect.x <= 1.0 or rect.y <= 1.0:
		var vp: Viewport = get_viewport()
		if vp != null:
			rect = vp.get_visible_rect().size
	return Vector2(maxf(rect.x, 1.0), maxf(rect.y, 1.0))


func _species_spec() -> Dictionary:
	var index: int = maxi(species_index, 0)
	if _spec_cache_index != index or _spec_cache.is_empty():
		_spec_cache_index = index
		_spec_cache = PreGameCatalog.get_protagonist_by_index(index)
	return _spec_cache


func _seed_dust() -> void:
	_dust.clear()
	_dust_rng.seed = DUST_SEED
	for i in DUST_COUNT:
		var px: float = _dust_rng.randf()
		var py: float = _dust_rng.randf()
		var radius: float = 1.0 + _dust_rng.randf() * 2.0
		var vx: float = (-0.3 + _dust_rng.randf() * 0.6) * 0.0004 * FRAME_RATE_BASE
		var vy: float = (-0.00035 - _dust_rng.randf() * 0.0005) * FRAME_RATE_BASE
		var alpha: float = 0.18 + _dust_rng.randf() * 0.36
		_dust.append({"x": px, "y": py, "r": radius, "vx": vx, "vy": vy, "a": alpha})


func _step_dust(delta: float) -> void:
	for i in _dust.size():
		var point: Dictionary = _dust[i]
		var px: float = float(point.get("x", 0.0)) + float(point.get("vx", 0.0)) * delta
		var py: float = float(point.get("y", 0.0)) + float(point.get("vy", 0.0)) * delta
		if py < 0.0:
			py = 1.0
			px = _dust_rng.randf()
		point["x"] = px
		point["y"] = py
		_dust[i] = point
