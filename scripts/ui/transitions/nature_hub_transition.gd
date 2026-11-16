class_name NatureHubTransition
extends CanvasLayer
## Nature lock to 3D Hub transition (D-1214, D-1218, D-235, D-1040, D-1060, D-418).
## This node is the only owner of the clock and of the state. The hub reads `state`
## and `progress()` and draws from them; it never keeps its own timers.
## Look: "Carimbo recortado" (D-1237). Played when the roulette Enter is pressed.
## Debug: --nht-auto --nht-load-min=<ms> --nht-quit --nht-shots=<dir> --nht-summary

signal state_changed(new_state: String)

const STATES: Array[String] = ["EXIT", "LOADING_LOOP", "REVEAL", "FALL", "LAND", "CONTROL"]

## Roulette wipe palette and skew, copied from scripts/ui/pre_game/nature_slot_view.gd.
const C_BG := Color("051322")
const C_ACCENT := Color("d6fa66")
const C_GOLD := Color("f0c57e")
const C_LAMP_OFF := Color("1d3a4d")
const SKEW := -9.0

const TUNING := {
	"exit_ms": 900.0,  # D-1237
	"loop_min_ms": 240.0,  # D-1237
	"loop_period_ms": 640.0,  # D-1237
	"reveal_ms": 1500.0,  # D-1237
	"fall_ms": 950.0,  # D-1237
	"land_ms": 950.0,  # D-1237
	"bars_in_ms": 260.0,  # D-1237
	"bars_out_ms": 320.0,  # D-1237
	"bar_h_frac": 0.115,  # D-1237
	"lamp_count": 5,  # D-1237
	"lamp_r_px": 5.0,  # D-1237
	"lamp_gap_px": 22.0,  # D-1237
	"lamp_fade_ms": 240.0,  # D-1237
	"lamp_y_frac": 0.56,  # D-1237
	"hub_ready_timeout_ms": 3000.0,  # D-1237
	"quit_after_control_ms": 1500.0,  # D-1237
}

var variant: String = "c"  ## Only "Carimbo recortado" exists (D-1237); kept for the log lines.
var state: String = "EXIT"
var state_ms: float = 0.0
var total_ms: float = 0.0
var hub: Node = null
var target_scene: String = ""

var _opts: Dictionary = {}
var _view: Control = null
var _visited: Array[Dictionary] = []
var _errors: Array[String] = []
var _load_ms: float = 0.0
var _scene_change_ms: float = -1.0
var _awaiting_hub: bool = false
var _loop_enter_ms: float = 0.0
var _loop_leave_ms: float = -1.0
var _quit_at_ms: float = -1.0
var _shot_dir: String = ""
var _shot_taken: Dictionary = {}
var _want_summary: bool = false
var _want_quit: bool = false
var _summary_printed: bool = false


static func begin(tree: SceneTree, target_scene_id: String, opts: Dictionary) -> NatureHubTransition:
	var node := NatureHubTransition.new()
	node.name = "NatureHubTransition"
	node.target_scene = target_scene_id
	node._opts = opts.duplicate(true)
	node.layer = 100
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	node.add_to_group("nature_hub_transition")
	tree.root.add_child(node)
	node._start()
	return node


func notify_hub_ready(hub_node: Node) -> void:
	hub = hub_node
	if not _awaiting_hub:
		return
	_awaiting_hub = false
	if state == "LOADING_LOOP":
		_enter_state("REVEAL")


func progress() -> float:
	if state == "LOADING_LOOP":
		var period: float = float(TUNING["loop_period_ms"])
		if period <= 0.0:
			return 0.0
		return clampf(fposmod(state_ms, period) / period, 0.0, 1.0)
	var dur := duration_ms(state)
	if dur <= 0.0:
		return 1.0
	return clampf(state_ms / dur, 0.0, 1.0)


func duration_ms(state_name: String) -> float:
	match state_name:
		"EXIT":
			return float(TUNING["exit_ms"])
		"LOADING_LOOP":
			return float(TUNING["loop_period_ms"])
		"REVEAL":
			return float(TUNING["reveal_ms"])
		"FALL":
			return float(TUNING["fall_ms"])
		"LAND":
			return float(TUNING["land_ms"])
		"CONTROL":
			return float(TUNING["bars_out_ms"])
	return 0.0


func is_cutscene() -> bool:
	return state == "REVEAL" or state == "FALL" or state == "LAND"


func _start() -> void:
	_shot_dir = str(_opts.get("shots", ""))
	_want_summary = bool(_opts.get("summary", false))
	_want_quit = bool(_opts.get("quit", false))
	if not _shot_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	_build_view()
	_enter_state("EXIT")
	if target_scene.is_empty():
		_fail("target scene is empty")
		return
	var err: int = ResourceLoader.load_threaded_request(target_scene)
	if err != OK:
		_fail("threaded load request failed (%d)" % err)


func _build_view() -> void:
	_view = Control.new()
	_view.name = "View"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.draw.connect(_on_view_draw)


func _process(delta: float) -> void:
	var dt: float = minf(delta * 1000.0, 100.0)
	total_ms += dt
	state_ms += dt
	_tick_state()
	if _view != null:
		_view.queue_redraw()


func _enter_state(next: String) -> void:
	state = next
	state_ms = 0.0
	_visited.append({"state": next, "t": int(total_ms)})
	if next == "LOADING_LOOP":
		_loop_enter_ms = total_ms
		_loop_leave_ms = -1.0
	elif next == "CONTROL":
		_print_summary()
		if _want_quit:
			_quit_at_ms = total_ms + float(TUNING["quit_after_control_ms"])
	print("NHT " + JSON.stringify({"state": next, "t": int(total_ms), "variant": variant}))
	state_changed.emit(next)


func _tick_state() -> void:
	match state:
		"EXIT":
			_maybe_capture()
			if state_ms >= duration_ms("EXIT"):
				_enter_state("LOADING_LOOP")
		"LOADING_LOOP":
			_tick_loading()
			_maybe_capture()
		"REVEAL":
			_maybe_capture()
			if state_ms >= duration_ms("REVEAL"):
				_enter_state("FALL")
		"FALL":
			_maybe_capture()
			if state_ms >= duration_ms("FALL"):
				_enter_state("LAND")
		"LAND":
			_maybe_capture()
			if state_ms >= duration_ms("LAND"):
				_enter_state("CONTROL")
		"CONTROL":
			if _quit_at_ms >= 0.0 and total_ms >= _quit_at_ms:
				get_tree().quit(0)
				return
			_maybe_capture()
			if state_ms >= duration_ms("CONTROL") and not _want_quit:
				queue_free()


func _tick_loading() -> void:
	if _awaiting_hub:
		if total_ms - _scene_change_ms >= float(TUNING["hub_ready_timeout_ms"]):
			print("NHT_WARN hub did not notify")
			_awaiting_hub = false
			_enter_state("REVEAL")
		return
	if _scene_change_ms >= 0.0:
		return
	var status: int = ResourceLoader.load_threaded_get_status(target_scene)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fail("threaded load status %d" % status)
		return
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return
	var min_ms: float = maxf(float(TUNING["loop_min_ms"]), float(_opts.get("load_min_ms", 0.0)))
	if state_ms < min_ms:
		return
	if _loop_leave_ms < 0.0:
		var period: float = float(TUNING["loop_period_ms"])
		if period <= 0.0:
			_change_scene_now()
			return
		_loop_leave_ms = (floor(state_ms / period) + 1.0) * period
		return
	if state_ms >= _loop_leave_ms:
		_change_scene_now()


func _change_scene_now() -> void:
	var packed: PackedScene = ResourceLoader.load_threaded_get(target_scene)
	if packed == null:
		_fail("threaded get returned null")
		return
	_load_ms = total_ms
	_scene_change_ms = total_ms
	var err: int = get_tree().change_scene_to_packed(packed)
	if err != OK:
		_fail("change_scene_to_packed failed (%d)" % err)
		return
	_awaiting_hub = true


func _fail(reason: String) -> void:
	print("NHT_ERROR %s" % reason)
	if not _errors.has(reason):
		_errors.append(reason)
	_print_summary()
	var tree := get_tree()
	if tree != null and not target_scene.is_empty():
		tree.change_scene_to_file(target_scene)
	queue_free()


func _print_summary() -> void:
	if not _want_summary or _summary_printed:
		return
	_summary_printed = true
	var ok: bool = _visited.size() == STATES.size()
	if ok:
		for i in STATES.size():
			if str(_visited[i].get("state", "")) != STATES[i]:
				ok = false
	var data: Dictionary = {
		"variant": variant,
		"ok": ok,
		"states": _visited,
		"load_ms": int(_load_ms),
		"errors": _errors,
	}
	print("NHT_SUMMARY " + JSON.stringify(data))


func _maybe_capture() -> void:
	if _shot_dir.is_empty() or _shot_taken.has(state):
		return
	var dur := duration_ms(state)
	if dur <= 0.0:
		return
	var mid: float = dur * 0.5
	if state == "LOADING_LOOP" and _loop_leave_ms > 0.0:
		mid = maxf(1.0, (_loop_leave_ms - _loop_enter_ms) * 0.5)
	if state_ms >= mid:
		_capture_state(state)


func _capture_state(state_name: String) -> void:
	if _shot_dir.is_empty() or _shot_taken.has(state_name):
		return
	_shot_taken[state_name] = true
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	img.save_png(ProjectSettings.globalize_path(_shot_dir.path_join("nht_%s_%s.png" % [variant, state_name])))


# --- Drawing -------------------------------------------------------------------

func _on_view_draw() -> void:
	var ci: Control = _view
	_draw_variant(ci)
	_draw_letterbox(ci)
	_draw_load_indicator(ci)


func _draw_variant(ci: Control) -> void:
	_draw_stamp(ci)


## The roulette's own exit wipe ends on a solid C_BG screen, so the
## transition starts from that same flat colour (no cut) and only then shows its
## motif. It opens a growing hole onto the hub during REVEAL and never fills the
## screen with a bright colour (D-418).

## "Carimbo recortado": the Nature stamp outline is drawn, breathes
## while loading, then is punched out and the cut-out grows past the screen.
func _draw_stamp(ci: Control) -> void:
	if not _cover_active():
		return
	var vp: Vector2 = _view_size(ci)
	var c: Vector2 = vp * 0.5
	var reach: float = vp.length() * 0.5 + 24.0
	var s0: float = vp.y * 0.24
	var outline_s: float = s0
	var hole_s := 0.0
	if state == "LOADING_LOOP":
		outline_s = s0 * (1.0 + 0.035 * sin(TAU * _loop_phase()))
	elif state == "REVEAL":
		var p: float = progress()
		var punch: float = clampf(p / 0.2, 0.0, 1.0)
		var open: float = _bez(0.7, 0.0, 0.2, 1.0, clampf((p - 0.2) / 0.8, 0.0, 1.0))
		outline_s = lerpf(s0 * lerpf(1.0, 0.92, sin(punch * PI * 0.5)), reach * 1.5, open)
		hole_s = maxf(0.0, lerpf(s0 * 0.86 * _bez(0.2, 0.0, 0.2, 1.0, punch), reach * 1.5 - 8.0, open))
	var n := 280
	var dirs := PackedVector2Array()
	var unit := PackedFloat32Array()
	var radii := PackedFloat32Array()
	var tilt: float = deg_to_rad(SKEW)
	for i in n:
		var ang: float = TAU * float(i) / float(n)
		# Rounded square with a perforated (scalloped) edge, like a postage stamp.
		var sq: float = pow(pow(absf(cos(ang)), 4.0) + pow(absf(sin(ang)), 4.0), -0.25)
		var u: float = sq * (1.0 + 0.028 * cos(ang * 28.0))
		dirs.append(Vector2.from_angle(ang + tilt))
		unit.append(u)
		radii.append(u * hole_s)
	_cover_hole(ci, c, dirs, radii, reach * 1.2, C_BG)
	var motif: float = _motif_alpha()
	var shown := n
	if state == "EXIT":
		shown = int(round(float(n) * _bez(0.3, 0.0, 0.2, 1.0, progress())))
	if shown >= 2 and outline_s < reach * 1.45:
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in shown + 1:
			var k: int = i % n
			outer.append(c + dirs[k] * unit[k] * outline_s)
			inner.append(c + dirs[k] * unit[k] * outline_s * 0.86)
		ci.draw_polyline(outer, Color(C_GOLD, motif), 3.0, true)
		ci.draw_polyline(inner, Color(C_ACCENT, motif * 0.9), 2.0, true)
	# Seal details inside the stamp; they fade as soon as the punch opens the hole.
	var detail: float = motif * (1.0 - clampf(hole_s / maxf(1.0, outline_s * 0.5), 0.0, 1.0))
	if shown >= n and detail > 0.01:
		var rr: float = outline_s * 0.6
		# Dashed ring turning one dash per loop (seamless), with a thin ring inside.
		var turn: float = TAU / 24.0 * _loop_phase()
		for i in 24:
			var a0: float = turn + TAU * float(i) / 24.0
			ci.draw_arc(c, rr, a0, a0 + TAU / 24.0 * 0.55, 5, Color(C_GOLD, detail * 0.9), 2.0, true)
		ci.draw_arc(c, rr * 0.8, 0.0, TAU, 64, Color(C_ACCENT, detail * 0.55), 1.5, true)
		ci.draw_arc(c, rr * 1.12, 0.0, TAU, 64, Color(C_LAMP_OFF, detail), 1.5, true)
		# Radial ticks counter-turning, and four studs on the stamp corners.
		for i in 12:
			var a1: float = -turn * 2.0 + TAU * float(i) / 12.0
			var d1 := Vector2.from_angle(a1)
			ci.draw_line(c + d1 * rr * 0.86, c + d1 * rr * 0.94, Color(C_ACCENT, detail * 0.8), 2.0, true)
		for i in 4:
			var d2 := Vector2.from_angle(tilt + PI * 0.25 + PI * 0.5 * float(i))
			var stud: Vector2 = c + d2 * outline_s * 0.93
			ci.draw_circle(stud, outline_s * 0.035, Color(C_GOLD, detail))
			ci.draw_arc(stud, outline_s * 0.06, 0.0, TAU, 20, Color(C_ACCENT, detail * 0.7), 1.5, true)


## True while the cover (and its motif) still hides or frames the hub.
func _cover_active() -> bool:
	return state == "EXIT" or state == "LOADING_LOOP" or state == "REVEAL"


## Motif opacity: fades in over EXIT, stays on afterwards.
func _motif_alpha() -> float:
	if state == "EXIT":
		return clampf(progress() * 1.6, 0.0, 1.0)
	return 1.0


## Seamless loop phase 0..1 shared by every motif (driven by the transition clock).
func _loop_phase() -> float:
	var period: float = maxf(1.0, float(TUNING["loop_period_ms"]))
	if state == "EXIT":
		return 0.0
	if state == "REVEAL":
		return fposmod(progress() * duration_ms("REVEAL") / period, 1.0)
	return fposmod(state_ms / period, 1.0)


## Fills the screen with `col` except a star-shaped hole around `c`
## (hole edge = c + dirs[i] * radii[i]). Radius 0 means fully covered.
func _cover_hole(ci: Control, c: Vector2, dirs: PackedVector2Array, radii: PackedFloat32Array, far: float, col: Color) -> void:
	var n: int = dirs.size()
	var cols := PackedColorArray([col, col, col])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	for i in n:
		var j: int = (i + 1) % n
		if radii[i] >= far and radii[j] >= far:
			continue
		var a: Vector2 = c + dirs[i] * minf(radii[i], far)
		var b: Vector2 = c + dirs[j] * minf(radii[j], far)
		var a2: Vector2 = c + dirs[i] * far
		var b2: Vector2 = c + dirs[j] * far
		if a.distance_squared_to(b) > 0.0001:
			ci.draw_primitive(PackedVector2Array([a, b, b2]), cols, uvs)
		ci.draw_primitive(PackedVector2Array([a, b2, a2]), cols, uvs)


## Cutscene bars (D-1214): in during the first bars_in_ms of REVEAL, full in FALL
## and LAND, out during CONTROL.
func _draw_letterbox(ci: Control) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	var frac := 0.0
	match state:
		"REVEAL":
			frac = clampf(state_ms / maxf(1.0, float(TUNING["bars_in_ms"])), 0.0, 1.0)
		"FALL", "LAND":
			frac = 1.0
		"CONTROL":
			frac = 1.0 - clampf(state_ms / maxf(1.0, float(TUNING["bars_out_ms"])), 0.0, 1.0)
	if frac <= 0.001:
		return
	var vp: Vector2 = _view_size(ci)
	var h: float = vp.y * float(TUNING["bar_h_frac"]) * frac
	ci.draw_rect(Rect2(0.0, 0.0, vp.x, h), Color.BLACK)
	ci.draw_rect(Rect2(0.0, vp.y - h, vp.x, h), Color.BLACK)


## Discreet loading indicator: five lamps of the roulette payline that light in
## sequence with the loop phase. No text, no bar.
func _draw_load_indicator(ci: Control) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if state != "LOADING_LOOP":
		return
	var fade: float = maxf(1.0, float(TUNING["lamp_fade_ms"]))
	var alpha: float = clampf(state_ms / fade, 0.0, 1.0)
	if _loop_leave_ms > 0.0:
		alpha = minf(alpha, clampf((_loop_leave_ms - state_ms) / fade, 0.0, 1.0))
	if alpha <= 0.01:
		return
	var count: int = int(TUNING["lamp_count"])
	if count <= 0:
		return
	var vp: Vector2 = _view_size(ci)
	var gap: float = float(TUNING["lamp_gap_px"])
	var radius: float = float(TUNING["lamp_r_px"])
	var active: int = int(floor(progress() * float(count))) % count
	var x0: float = vp.x * 0.5 - gap * float(count - 1) * 0.5
	var y: float = vp.y * float(TUNING["lamp_y_frac"])
	for i in count:
		var col: Color = C_GOLD if i == active else C_LAMP_OFF
		col.a *= alpha
		ci.draw_circle(Vector2(x0 + gap * float(i), y), radius, col)


func _view_size(ci: Control) -> Vector2:
	var vp: Vector2 = ci.size
	if vp.x < 1.0 or vp.y < 1.0:
		vp = ci.get_viewport_rect().size
	return vp


# --- Math helpers (same as nature_slot_view.gd) --------------------------------

static func _bez(x1: float, y1: float, x2: float, y2: float, t: float) -> float:
	if t <= 0.0:
		return 0.0
	if t >= 1.0:
		return 1.0
	var lo := 0.0
	var hi := 1.0
	var u := t
	for _i in 22:
		var bx := 3.0 * (1.0 - u) * (1.0 - u) * u * x1 + 3.0 * (1.0 - u) * u * u * x2 + u * u * u
		if bx < t:
			lo = u
		else:
			hi = u
		u = (lo + hi) * 0.5
	return 3.0 * (1.0 - u) * (1.0 - u) * u * y1 + 3.0 * (1.0 - u) * u * u * y2 + u * u * u


static func _skew_x(deg: float) -> Transform2D:
	return Transform2D(Vector2(1.0, 0.0), Vector2(tan(deg_to_rad(deg)), 1.0), Vector2.ZERO)


static func _about(center: Vector2, t: Transform2D) -> Transform2D:
	return Transform2D(0.0, center) * t * Transform2D(0.0, -center)
