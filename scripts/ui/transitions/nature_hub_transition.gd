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
const WorldDefsRef = preload("res://scripts/world/world_defs.gd")
const PortraitIconRef = preload("res://scripts/ui/portrait_icon.gd")
const PreGameDrawRef = preload("res://scripts/ui/pre_game/pre_game_draw.gd")

const TUNING := {
	"exit_ms": 900.0,  # D-1237
	"loop_min_ms": 4000.0,  # D-1267: loading lasts at least 4 s (was 240 ms, D-1237)
	"loop_period_ms": 640.0,  # D-1237
	"reveal_ms": 1500.0,  # D-1237
	"fall_ms": 950.0,  # D-1237
	"land_ms": 950.0,  # D-1237
	"bars_in_ms": 260.0,  # D-1237
	"bars_out_ms": 320.0,  # D-1237
	"bar_h_frac": 0.115,  # D-1237
	"wave_period_ms": 1000.0,  # D-1260: one wave per second
	"wave_life_ms": 6000.0,  # D-1260: 6 waves in total (life = 6 periods)
	"wave_fade_ms": 240.0,  # D-1260
	"plaque_in_ms": 360.0,  # D-1260
	"badge_first_ms": 520.0,  # D-1260
	"badge_step_ms": 150.0,  # D-1260
	"badge_hit_ms": 140.0,  # D-1260
	"plaque_out_ms": 320.0,  # D-1260
	"hub_ready_timeout_ms": 40000.0,  # D-1237
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
var _frame_stats: Dictionary = {}  ## state -> {max_ms, slow} (frames over 40 ms), --nht-summary
var _errors: Array[String] = []
var _last_pipes: float = 0.0
var _hitches: Array[Dictionary] = []  ## frames over 25 ms (--nht-summary), with time since the scene change
var _load_ms: float = 0.0
var _scene_change_ms: float = -1.0
var _awaiting_hub: bool = false
var _hub_ready: bool = false
var warm_progress: float = 0.0  ## 0..1, set by the arrival cutscene while it compiles/warms up (D-1267)
var _loop_enter_ms: float = 0.0
var _loop_leave_ms: float = -1.0
var _quit_at_ms: float = -1.0
var _shot_dir: String = ""
var _shot_taken: Dictionary = {}
var _world_id: String = "hub"  ## D-1260: world being entered (WorldDefs)
var _wave_cols: Array[Color] = []
var _plaque_name: String = ""
var _party_icons: Array[Texture2D] = []
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
	_hub_ready = true


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
	_setup_world()
	_build_view()
	if str(_opts.get("sheet", "")) != "":
		# Debug sheet: straight into the loading loop, no scene load (see _tick_sheet).
		_shot_dir = str(_opts["sheet"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
		_enter_state("LOADING_LOOP")
		return
	_enter_state("EXIT")
	if target_scene.is_empty():
		_fail("target scene is empty")
		return
	var err: int = ResourceLoader.load_threaded_request(target_scene)
	if err != OK:
		_fail("threaded load request failed (%d)" % err)


## D-1260: wave colours and the plaque name come from WorldDefs data (no hardcoded world).
func _setup_world() -> void:
	_world_id = str(_opts.get("world", "hub"))
	_wave_cols.clear()
	for col in WorldDefsRef.world_colors(_world_id):
		_wave_cols.append(col as Color)
	if _wave_cols.is_empty():
		_wave_cols = [C_ACCENT, C_GOLD, C_LAMP_OFF]
	_plaque_name = ""
	_party_icons.clear()
	if not bool(_opts.get("plaque", _world_id != "hub")):
		return
	_plaque_name = str(WorldDefsRef.world_name(_world_id))
	var keys: Array = []
	if _opts.get("party") is Array:
		keys = _opts["party"]
	else:
		var gs := get_node_or_null("/root/GameState")
		if gs != null and gs.get("party") is Array:
			for member in gs.get("party"):
				keys.append(str(gs.call("species_key", member)))
	for key in keys:
		var tex: Texture2D = PortraitIconRef.get_icon(str(key))
		if tex != null:
			_party_icons.append(tex)


func _build_view() -> void:
	_view = Control.new()
	_view.name = "View"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.draw.connect(_on_view_draw)


func _process(delta: float) -> void:
	var raw_ms: float = delta * 1000.0
	var st: Dictionary = _frame_stats.get(state, {"max_ms": 0.0, "slow": 0})
	st["max_ms"] = snappedf(maxf(float(st["max_ms"]), raw_ms), 0.1)
	if raw_ms > 40.0:
		st["slow"] = int(st["slow"]) + 1
	var pipes: float = Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)
	var pipes_delta: int = int(pipes - _last_pipes)
	_last_pipes = pipes
	var vp_rid: RID = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	if raw_ms > 25.0:
		_hitches.append({"pipes_delta": pipes_delta, "render_cpu_ms": snappedf(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid), 0.1), "gpu_ms": snappedf(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid), 0.1), "state": state, "t": int(total_ms), "ms": snappedf(raw_ms, 0.1), "since_scene_change": int(total_ms - _scene_change_ms) if _scene_change_ms >= 0.0 else -1, "proc_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1), "phys_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.1), "draws": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "ram_mb": int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)})
	_frame_stats[state] = st
	var dt: float = minf(raw_ms, 100.0)
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
			if str(_opts.get("sheet", "")) != "":
				_tick_sheet()
				return
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


## Debug sheet (--nht-sheet): captures at 0.5, 1.5 ... 7.5 s of the loading, prints the number
## of waves alive at each one, then quits. About 9 s end to end.
func _tick_sheet() -> void:
	var idx: int = int(floor((state_ms - 500.0) / 1000.0)) + 1
	if state_ms >= 500.0 and idx >= 1 and not _shot_taken.has("s%d" % idx) and idx <= 8:
		_shot_taken["s%d" % idx] = true
		var life: float = float(TUNING["wave_life_ms"])
		var period: float = float(TUNING["wave_period_ms"])
		var alive := 0
		for k in range(0, int(floor(state_ms / period)) + 1):
			var age: float = state_ms - float(k) * period
			if age > 0.0 and age < life:
				alive += 1
		print("NHT_SHEET t=%d waves=%d" % [int(state_ms), alive])
		_sheet_shot(idx)
	if state_ms >= 8200.0:
		get_tree().quit(0)


func _sheet_shot(idx: int) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(ProjectSettings.globalize_path(_shot_dir.path_join("nht_sheet_%d.png" % idx)))


func _tick_loading() -> void:
	var min_ms: float = maxf(float(TUNING["loop_min_ms"]), float(_opts.get("load_min_ms", 0.0)))
	var period: float = maxf(1.0, float(TUNING["loop_period_ms"]))
	if _awaiting_hub:
		# D-1267: the scene is already swapped and builds/warms up UNDER the loading screen;
		# the reveal starts only when it is ready AND the minimum loading time has passed.
		if total_ms - _scene_change_ms >= float(TUNING["hub_ready_timeout_ms"]):
			print("NHT_WARN hub did not notify")
			_awaiting_hub = false
			_enter_state("REVEAL")
			return
		if _hub_ready:
			if _loop_leave_ms < 0.0 and state_ms >= min_ms:
				_loop_leave_ms = (floor(state_ms / period) + 1.0) * period
			if _loop_leave_ms >= 0.0 and state_ms >= _loop_leave_ms:
				_awaiting_hub = false
				_enter_state("REVEAL")
		return
	if _scene_change_ms >= 0.0:
		return
	var status: int = ResourceLoader.load_threaded_get_status(target_scene)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fail("threaded load status %d" % status)
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_change_scene_now()  # swap early: the rest of the loading time is spent warming up


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
		"frames": _frame_stats,
		"hitches": _hitches,
	}
	print("NHT_SUMMARY " + JSON.stringify(data))


func _maybe_capture() -> void:
	if _shot_dir.is_empty() or _shot_taken.has(state):
		return
	var dur := duration_ms(state)
	if dur <= 0.0:
		return
	var mid: float = dur * 0.5
	if state == "LOADING_LOOP" and float(_opts.get("load_min_ms", 0.0)) > 0.0:
		mid = float(_opts["load_min_ms"]) * 0.85  # D-1260: debug shot late in the loop (waves + badges settled)
	elif state == "LOADING_LOOP" and _loop_leave_ms > 0.0:
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
	_draw_plaque(ci, _view_size(ci))
	_draw_shader_bar(ci, _view_size(ci))


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
		outline_s = s0 * (1.0 + 0.035 * sin(TAU * _loop_phase()))  # centre stamp pulses (creator, D-1260)
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
	var tilt: float = deg_to_rad(SKEW) + _loop_spin()
	for i in n:
		var ang: float = TAU * float(i) / float(n)
		# Rounded square with a perforated (scalloped) edge, like a postage stamp.
		var sq: float = pow(pow(absf(cos(ang)), 4.0) + pow(absf(sin(ang)), 4.0), -0.25)
		var u: float = sq * (1.0 + 0.028 * cos(ang * 28.0))
		dirs.append(Vector2.from_angle(ang + tilt))
		unit.append(u)
		radii.append(u * hole_s)
	_cover_hole(ci, c, dirs, radii, reach * 1.2, C_BG)
	_draw_waves(ci, c, vp, s0)
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
		ci.draw_polyline(outer, Color(_wave_cols[1], motif), 3.0, true)
		ci.draw_polyline(inner, Color(_wave_cols[0], motif * 0.9), 2.0, true)
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


## Loading spin: a quarter turn per wave period (the stamp's square has 4-fold symmetry, so every
## whole period the shape is identical to the resting one and the exit into REVEAL has no jump).
func _loop_spin() -> float:
	return 0.0  # spin removed by the creator
	if state != "LOADING_LOOP":
		return 0.0
	return (state_ms / maxf(1.0, float(TUNING["wave_period_ms"]))) * PI * 0.5


## D-1260: loading waves = the stamp's own wavy outline pair, in the colours of the world being
## entered. Every second the centre pair emits a copy of itself that flies outwards; seen from
## above in perspective (like looking down a funnel/tunnel): the radius grows as 1/z, so the
## gap between consecutive waves widens the further out they are. No other shape is drawn.
func _draw_waves(ci: Control, c: Vector2, _vp: Vector2, s0: float) -> void:
	if state != "LOADING_LOOP" or _wave_cols.size() < 2:
		return
	var period: float = maxf(1.0, float(TUNING["wave_period_ms"]))
	var life: float = maxf(1.0, float(TUNING["wave_life_ms"]))
	var k_last: int = int(floor(state_ms / period))
	var k_first: int = maxi(0, k_last - int(ceil(life / period)))  # k < 0 would draw waves born before the loading
	var n := 140
	var tilt: float = deg_to_rad(SKEW) + _loop_spin()
	for k in range(k_first, k_last + 1):
		var age: float = state_ms - float(k) * period
		if age <= 0.0 or age > life:
			continue
		var u: float = age / life
		# At most 6 waves at once (life = 6 periods): 1 at the start, +1 each second; they stay
		# and glide outwards with widening spacing (funnel); the oldest fades off the edge.
		var slot: float = age / period
		var alpha: float = clampf(age / 250.0, 0.0, 1.0) * clampf(life / period - slot, 0.0, 1.0)
		if alpha <= 0.01:
			continue
		var r: float = s0 * (1.0 + 0.35 * slot + 0.1 * slot * slot)
		var width: float = lerpf(3.0, 9.0, u)
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in n + 1:
			var ang: float = TAU * float(i % n) / float(n)
			var sq: float = pow(pow(absf(cos(ang)), 4.0) + pow(absf(sin(ang)), 4.0), -0.25)
			var unit: float = sq * (1.0 + 0.028 * cos(ang * 28.0))
			var dir := Vector2.from_angle(ang + tilt)
			outer.append(c + dir * unit * r)
			inner.append(c + dir * unit * r * 0.86)
		ci.draw_polyline(outer, Color(_wave_cols[1], alpha), width, true)
		ci.draw_polyline(inner, Color(_wave_cols[0], alpha * 0.9), width * 0.67, true)


## D-1260: crooked (skewed) plaque with the destination name, dialogue-box style (hard shadow,
## gold border). Party badges are stamped at its extreme bottom-right, one per member, each
## with an impact. Slides in, then leaves to the right when the reveal starts.
func _draw_plaque(ci: Control, vp: Vector2) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if _plaque_name.is_empty():
		return
	var t: float = -1.0
	var out := 0.0
	if state == "LOADING_LOOP":
		t = state_ms
	elif state == "REVEAL":
		t = 1.0e6
		out = _bez(0.7, 0.0, 0.2, 1.0, clampf(state_ms / maxf(1.0, float(TUNING["plaque_out_ms"])), 0.0, 1.0))
	if t < 0.0 or out >= 1.0:
		return
	var in_ms: float = maxf(1.0, float(TUNING["plaque_in_ms"]))
	var enter: float = _bez(0.2, 0.0, 0.2, 1.0, clampf(t / in_ms, 0.0, 1.0))
	var w: float = vp.x * 0.5
	var h: float = vp.y * 0.13
	var centre := Vector2(vp.x * 0.5, vp.y * 0.83)
	var impact: float = clampf((t - in_ms) / 180.0, 0.0, 1.0)
	var shake := Vector2.ZERO
	if impact > 0.0 and impact < 1.0:
		shake = Vector2(sin(impact * 40.0), cos(impact * 33.0)) * 7.0 * (1.0 - impact)
	# Each badge stamp (D-1260, option A) also shakes the card.
	for bi in _party_icons.size():
		var since: float = t - float(TUNING["badge_first_ms"]) - float(TUNING["badge_step_ms"]) * float(bi) - float(TUNING["badge_hit_ms"])
		if since > 0.0 and since < 220.0:
			var kk: float = since / 220.0
			shake += Vector2(sin(kk * 40.0), cos(kk * 33.0)) * 5.0 * (1.0 - kk)
	var punch := 1.0
	if impact > 0.0:
		punch = 1.0 + 0.06 * sin(impact * PI)
	var off := Vector2(lerpf(-vp.x * 0.7, 0.0, enter) + out * vp.x * 0.8, 0.0) + shake
	var xf: Transform2D = Transform2D(0.0, centre + off) * Transform2D(Vector2(punch, 0.0), Vector2(0.0, punch), Vector2.ZERO)
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	ci.draw_set_transform_matrix(xf)
	# D-1260: same card as the in-game DialogueBox (scripts/ui/dialogue_box.gd): hard block shadow,
	# navy slanted body with faint hatching, steel outline, aqua left edge, lime + coral top accent.
	var sl: float = h * 0.3
	var l := rect.position.x
	var t0 := rect.position.y
	var r_ := rect.end.x
	var b_ := rect.end.y
	var ink_shadow := Color(0.01, 0.02, 0.05, 0.88)
	var navy := Color("101c2c")
	var steel := Color(0.27, 0.39, 0.48, 0.9)
	var aqua := Color("62d8e7")
	var lime := Color("d7fd6a")
	var coral := Color("ff624f")
	ci.draw_colored_polygon(PackedVector2Array([Vector2(l + sl + 8.0, t0 + 8.0), Vector2(r_ + 8.0, t0 + 8.0), Vector2(r_ - sl + 8.0, b_ + 8.0), Vector2(l + 8.0, b_ + 8.0)]), ink_shadow)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(l + sl, t0), Vector2(r_, t0), Vector2(r_ - sl, b_), Vector2(l, b_)]), navy)
	var hx: float = l + sl
	while hx < r_:
		ci.draw_line(Vector2(hx, t0), Vector2(hx - sl * 0.7, b_), Color(1.0, 1.0, 1.0, 0.02), 1.0)
		hx += 24.0
	ci.draw_polyline(PackedVector2Array([Vector2(l + sl, t0), Vector2(r_, t0), Vector2(r_ - sl, b_), Vector2(l, b_), Vector2(l + sl, t0)]), steel, 1.5)
	ci.draw_line(Vector2(l + sl, t0), Vector2(l, b_), aqua, 4.0)
	var lime_end: float = minf(l + sl + w * 0.5, r_ - 70.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(l + sl, t0), Vector2(lime_end, t0), Vector2(lime_end - 4.0, t0 + 4.0), Vector2(l + sl - 1.0, t0 + 4.0)]), lime)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(lime_end + 3.0, t0), Vector2(lime_end + 68.0, t0), Vector2(lime_end + 64.0, t0 + 4.0), Vector2(lime_end - 1.0, t0 + 4.0)]), coral)
	var font: Font = PreGameDrawRef.title_font()
	var fsize: int = int(h * 0.5)
	var tsz: Vector2 = font.get_string_size(_plaque_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize)
	var base := Vector2(-tsz.x * 0.5, tsz.y * 0.5 - font.get_descent(fsize))
	ci.draw_string(font, base, _plaque_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize, Color("f0eedf"))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Badges: stamped one by one at the extreme bottom-right corner, leftwards.
	var r: float = h * 0.3
	# Badges sit inside the card at its right end; with many members they overlap instead of reaching the name.
	var avail: float = w * 0.5 - tsz.x * 0.5 - r * 0.6
	var step_x: float = r * 2.2
	if _party_icons.size() > 1:
		step_x = clampf((avail - r * 1.1) / float(_party_icons.size() - 1), r * 0.9, r * 2.2)
	var first: float = float(TUNING["badge_first_ms"])
	var step: float = float(TUNING["badge_step_ms"])
	var hit: float = maxf(1.0, float(TUNING["badge_hit_ms"]))
	for i in _party_icons.size():
		var bt: float = (t - first - step * float(i)) / hit
		if bt < 0.0:
			continue
		var landed: float = clampf(bt, 0.0, 1.0)
		var sc: float = lerpf(2.4, 1.0, _bez(0.5, 0.0, 0.9, 0.6, landed))
		# Straddling the card edge (half in, half out): first one on the bottom-right tip, the rest leftwards along the bottom edge.
		var corner: Vector2 = xf * Vector2(rect.end.x - sl - float(i) * step_x, rect.end.y)
		var pos := corner
		if bt < 1.0:
			pos += Vector2(sin(bt * 50.0), cos(bt * 41.0)) * 5.0 * (1.0 - landed)
		_draw_badge(ci, pos, r * sc, _party_icons[i], clampf(bt * 3.0, 0.0, 1.0), lerpf(-0.31, 0.0, landed))


## D-1267: flat slanted progress bar flush with the top-right corner: shader compilation / warm-up.
func _draw_shader_bar(ci: Control, vp: Vector2) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if state != "LOADING_LOOP":
		return
	var w: float = vp.x * 0.30
	var h: float = vp.y * 0.075
	var sl: float = h * 0.5
	var x0: float = vp.x - w
	var navy := Color("101c2c")
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 + sl, 0.0), Vector2(vp.x, 0.0), Vector2(vp.x, h), Vector2(x0, h)]), navy)
	ci.draw_line(Vector2(x0 + sl, 0.0), Vector2(x0, h), Color("62d8e7"), 4.0)
	var pct: float = clampf(warm_progress, 0.0, 1.0)
	var track_h: float = maxf(5.0, h * 0.2)
	var tx0: float = x0 + sl * 0.5 + 12.0
	var tx1: float = vp.x - 14.0
	var ty: float = h - track_h - 6.0
	ci.draw_rect(Rect2(tx0, ty, tx1 - tx0, track_h), Color(0.27, 0.39, 0.48, 0.6))
	ci.draw_rect(Rect2(tx0, ty, (tx1 - tx0) * pct, track_h), Color("d7fd6a"))
	var font: Font = PreGameDrawRef.mono_font()
	var fsize: int = int(h * 0.36)
	ci.draw_string(font, Vector2(tx0, ty - 8.0), "COMPILING SHADERS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize, Color("f0eedf"))
	ci.draw_string(font, Vector2(tx0, ty - 8.0), "%d%%" % int(round(pct * 100.0)), HORIZONTAL_ALIGNMENT_RIGHT, tx1 - tx0, fsize, Color("f7cb78"))


func _draw_badge(ci: Control, pos: Vector2, radius: float, tex: Texture2D, alpha: float, rot: float = 0.0) -> void:
	var n := 40
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(pos + Vector2.from_angle(a) * radius)
		uvs.append(Vector2(0.5, 0.5) + Vector2.from_angle(a - rot) * 0.5)  # texture turns by `rot`
	ci.draw_circle(pos + Vector2(4.0, 4.0), radius, Color("080e18", alpha))
	ci.draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, alpha), uvs, tex)
	ci.draw_arc(pos, radius, 0.0, TAU, 40, Color(Color("62d8e7"), alpha), 3.0, true)


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
