class_name NatureSlotView
extends Control
## Slot-machine Nature roll (D-1215): 3 reels of status symbols, automatic spin, near miss on
## the last reel, impact on every stop, fanfare, stamp, payout chips and a wipe exit.
## Visual/sound 1:1 with prototypes/nature_slot/nature_slot.html (D-433). The result is locked
## before the animation (NatureSlotLogic.reel_plan); skipping or reduced motion only fast-forwards.
##
## Time is driven by advance(ms) (also used by _process), so tests and captures can step it
## deterministically. Stage = 1280x720, scaled to fit. No screen flash/strobe (D-418).

const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const Logic = preload("res://scripts/ui/pre_game/nature_slot_logic.gd")
const Sfx = preload("res://scripts/ui/pre_game/nature_slot_sfx.gd")

signal settled(summary: Dictionary)
signal enter_requested
signal state_changed(new_state: String)

const STAGE := Vector2(1280.0, 720.0)
const CELL_H := 96.0
const REEL_W := 196.0
const REEL_GAP := 12.0
const REELS_SIZE := Vector2(612.0, 288.0)
const VP_PAD := 40.0
const CAB_POS := Vector2(70.0, 226.0)
const CAB_PAD := Vector2(26.0, 44.0)
const CAB_SIZE := Vector2(664.0, 376.0)
const SKEW := -9.0
const BOOT_MS := 600.0
## Entrance from the confirm screen: slabs sweep over it, then reveal the machine rising in.
const INTRO_MS := 1100.0
const LEAD_MS := INTRO_MS + BOOT_MS
const TICK_RATE := 30.0

const C_BG := Color("051322")
const C_SLAB := Color("092133")
const C_SLAB2 := Color("143343")
const C_PANEL := Color("0a1929")
const C_REEL := Color("07131e")
const C_INK := Color("080e18")
const C_GOLD := Color("f0c57e")
const C_TEXT := Color("f4eee1")
const C_DIM := Color("8ea7b0")
const C_ACCENT := Color("d6fa66")
const C_NEG := Color("ff746c")
const C_PURE := Color("63d9ec")
const C_LAMP_OFF := Color("1d3a4d")

const HIT_STRENGTH: Array[float] = [12.0, 18.0, 28.0]

var state: String = "BOOT"
var speed: float = 1.0
var muted: bool = false
## Debug/capture: when true only advance() moves time (--roulette-at=).
var frozen: bool = false
var nature_id: String = ""
var nature_name: String = ""
var nature_desc: String = ""
var is_pure: bool = false

var _syms: Array[String] = []
var _all: Array[String] = []
var _plan: Array[Dictionary] = []
var _pos: Array[float] = [0.0, 0.0, 0.0]
var _stopped: Array[bool] = [true, true, true]
var _stop_t: Array[float] = [-1e9, -1e9, -1e9]
var _last_cell: Array[int] = [0, 0, 0]
var _run_t: float = 0.0
var _boot_left: float = -1.0
var _lead_t: float = 0.0
var _intro_on: bool = false
## false skips the entrance (reduced motion, tests that only need the result).
var intro_enabled: bool = true
var _intro_cab_dy: float = 0.0
var _intro_head_dx: float = 0.0
var _pending_spin: bool = false
var _spin_t0: float = 0.0
var _reveal_at: float = -1.0
var _reveal_t: float = -1e9
var _settle_at: float = -1.0
var _settle_t: float = -1e9
var _exit_t: float = -1e9
var _exit_done_at: float = -1.0
var _band_off: float = 0.0
var _hit_t: float = -1e9
var _hit_idx: int = 0
var _tick_count: int = 0
var _last_tick_t: float = -1e9
var _transitions: Array[Dictionary] = []
var _shards: Array[Dictionary] = []
var _chips: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _vp: SubViewport = null
var _reels: Control = null
var _reel_nodes: Array[Control] = []
var _base := Transform2D.IDENTITY
var _enter_rect := Rect2()
var _back_rect := Rect2()
var _skip_rect := Rect2()
var _btn_xf := Transform2D.IDENTITY


class _ReelCanvas extends Control:
	var view: Control
	var idx: int = 0

	func _draw() -> void:
		if view != null:
			view.call("_draw_reel", self, idx)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp = SubViewport.new()
	_vp.size = Vector2i(int(REELS_SIZE.x * 2.0), int((REELS_SIZE.y + VP_PAD * 2.0) * 2.0))
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_transform = Transform2D(Vector2(2.0, 0.0), Vector2(0.0, 2.0), Vector2.ZERO)
	add_child(_vp)
	_reels = Control.new()
	_reels.size = Vector2(REELS_SIZE.x, REELS_SIZE.y + VP_PAD * 2.0)
	_vp.add_child(_reels)
	for i in 3:
		var rc := _ReelCanvas.new()
		rc.view = self
		rc.idx = i
		rc.clip_contents = true  # each reel window clips its own strip (axis-aligned inside the SubViewport)
		rc.size = Vector2(REEL_W, REELS_SIZE.y)
		_reel_nodes.append(rc)
		_reels.add_child(rc)
	set_process(true)


# --- Public API ---------------------------------------------------------------

func start(id: String, info: Dictionary = {}, instant: bool = false) -> void:
	nature_id = id.to_lower()
	nature_name = str(info.get("name", nature_id.capitalize()))
	nature_desc = str(info.get("desc", ""))
	is_pure = bool(info.get("pure", PreGameCatalog.PURE_NATURES.has(nature_id)))
	_syms = Logic.symbols_for(nature_id)
	_all = Logic.all_symbols()
	_rng.seed = 1215
	_shards.clear()
	_chips.clear()
	_transitions.clear()
	_run_t = 0.0
	_band_off = 0.0
	_tick_count = 0
	_last_tick_t = -1e9
	_reveal_at = -1.0
	_settle_at = -1.0
	_exit_done_at = -1.0
	_reveal_t = -1e9
	_settle_t = -1e9
	_exit_t = -1e9
	_hit_t = -1e9
	for i in 3:
		_stopped[i] = true
		_stop_t[i] = -1e9
	_set_state("BOOT")
	if instant:
		_begin_spin()
		_finish_all(false)
		_reveal_now()
		_settle_now()
		_redraw_all()
		return
	_pending_spin = true
	_intro_on = intro_enabled
	_lead_t = 0.0
	_boot_left = _ms(LEAD_MS if _intro_on else BOOT_MS)
	if _intro_on:
		_play("whoosh", 0)
	_redraw_all()


func skip() -> void:
	if not is_spinning():
		return
	if _pending_spin:
		_pending_spin = false
		_intro_on = false
		_begin_spin()
	_finish_all(false)
	_play("stop", 2)
	_reveal_now()
	_settle_now()
	_redraw_all()


func request_exit() -> bool:
	if state != "SETTLED":
		return false
	_set_state("EXIT")
	_exit_t = _run_t
	_exit_done_at = _run_t + _ms(Logic.TIMING_EXIT_MS)
	return true


func is_spinning() -> bool:
	return state == "SPINNING" or state == "STOP_1" or state == "STOP_2" or state == "STOP_3" or _pending_spin


func is_settled() -> bool:
	return state == "SETTLED"


func summary() -> Dictionary:
	var shown := Logic.shown_symbols_at(_pos)
	var match_ok := shown == _syms
	return {
		"locked": nature_id,
		"state": state,
		"shown": shown,
		"expected": _syms.duplicate(),
		"match": match_ok,
		"ticks": _tick_count,
		"transitions": _transitions.duplicate(true),
	}


## Returns "skip", "enter", "back" or "" for a click at `point` (control coordinates).
func hit_test(point: Vector2) -> String:
	var local := _base.affine_inverse() * point
	if is_spinning():
		return "skip" if _skip_rect.has_point(_skip_xf().affine_inverse() * local) else ""
	if state == "SETTLED":
		var p := _btn_xf.affine_inverse() * local
		if _enter_rect.has_point(p):
			return "enter"
		if _back_rect.has_point(p):
			return "back"
	return ""


func _process(delta: float) -> void:
	if frozen or not is_visible_in_tree():
		return
	advance(delta * 1000.0)


## Deterministic stepping: splits `ms` into <=16 ms slices.
func advance(ms: float) -> void:
	var left := ms
	while left > 0.0:
		var step := minf(left, 16.0)
		left -= step
		_step(step)
	_redraw_all()


# --- State machine ------------------------------------------------------------

func _ms(value: float) -> float:
	return value / maxf(speed, 0.05)


func _set_state(next: String) -> void:
	state = next
	_transitions.append({"t": int(_run_t), "state": next})
	state_changed.emit(next)


func _step(dt: float) -> void:
	if _pending_spin:
		_boot_left -= dt
		_lead_t += dt * maxf(speed, 0.05)
		if _boot_left <= 0.0:
			_pending_spin = false
			_intro_on = false
			_begin_spin()
		return
	if state == "BOOT":
		return
	_run_t += dt
	if state == "SPINNING" or state == "STOP_1" or state == "STOP_2":
		_band_off = fposmod(_band_off + dt / 900.0 * 88.0, 88.0)
	if state == "SPINNING" or state == "STOP_1" or state == "STOP_2" or state == "STOP_3":
		var t := _run_t - _spin_t0
		for i in 3:
			if _stopped[i]:
				continue
			var p: Dictionary = _plan[i]
			_pos[i] = Logic.position_at(float(p["start_pos"]), float(p["end_pos"]), _ms(float(p["dur_ms"])),
				_ms(float(p["flat_ms"])), bool(p["tease"]), t)
			var cell := roundi(_pos[i])
			if cell != _last_cell[i]:
				_last_cell[i] = cell
				if _run_t - _last_tick_t >= 1000.0 / TICK_RATE:
					_last_tick_t = _run_t
					_tick_count += 1
					_play("tick", i)
		for i in 3:
			if not _stopped[i] and t >= _ms(float(_plan[i]["dur_ms"])):
				_stop_reel(i)
	if _reveal_at >= 0.0 and _run_t >= _reveal_at and state == "STOP_3":
		_reveal_now()
	if _settle_at >= 0.0 and _run_t >= _settle_at and state == "REVEAL":
		_settle_now()
	if state == "EXIT" and _exit_done_at >= 0.0 and _run_t >= _exit_done_at:
		_exit_done_at = -1.0
		enter_requested.emit()


func _begin_spin() -> void:
	var starts: Array[float] = [_pos[0], _pos[1], _pos[2]]
	_plan = Logic.reel_plan(nature_id, starts)
	for i in 3:
		_stopped[i] = false
		_last_cell[i] = roundi(_pos[i])
	_spin_t0 = _run_t
	_set_state("SPINNING")
	_play("start", 0)


func _stop_reel(i: int) -> void:
	_pos[i] = float(_plan[i]["end_pos"])
	_stopped[i] = true
	_stop_t[i] = _run_t
	_play("stop", i)
	_set_state("STOP_%d" % (i + 1))
	_hit_t = _run_t
	_hit_idx = i
	_spawn_shards(i)
	if i == 2:
		_reveal_at = _run_t + _ms(Logic.TIMING_REVEAL_MS)


func _finish_all(with_effects: bool) -> void:
	for i in 3:
		_pos[i] = float(_plan[i]["end_pos"])
		if not _stopped[i]:
			_stop_t[i] = _run_t
		_stopped[i] = true
	_reveal_at = -1.0
	if with_effects:
		_hit_t = _run_t


func _reveal_now() -> void:
	if state == "REVEAL" or state == "SETTLED" or state == "EXIT":
		return
	_set_state("REVEAL")
	_reveal_t = _run_t
	_settle_at = _run_t + _ms(Logic.TIMING_SETTLE_MS)
	_spawn_chips()
	_play("stamp", 0)
	_play("pure" if is_pure else "win", 0)


func _settle_now() -> void:
	if state != "REVEAL":
		return
	_settle_at = -1.0
	_set_state("SETTLED")
	_settle_t = _run_t
	settled.emit(summary())


func _play(kind: String, idx: int) -> void:
	if muted or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = Sfx.stream(kind, idx)
	if AudioServer.get_bus_index("SFX") >= 0:
		player.bus = "SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _spawn_shards(i: int) -> void:
	var count := 10 + i * 4
	var kind := Logic.symbol_kind(_syms[i])
	var col := C_TEXT
	if kind == "pos":
		col = C_ACCENT
	elif kind == "neg":
		col = C_NEG
	for k in count:
		var angle := (float(k) / float(count)) * TAU + _rng.randf() * 0.5
		var dist := 120.0 + _rng.randf() * 110.0 + float(i) * 30.0
		_shards.append({
			"t0": _run_t,
			"x": CAB_PAD.x + float(i) * (REEL_W + REEL_GAP) + REEL_W * 0.5,
			"y": CAB_PAD.y + REELS_SIZE.y * 0.5,
			"dx": cos(angle) * dist,
			"dy": sin(angle) * dist * 0.7,
			"rot": deg_to_rad(_rng.randf() * 540.0 - 270.0),
			"col": C_GOLD if k % 3 == 2 else col,
		})


func _spawn_chips() -> void:
	var palette: Array[Color] = [C_ACCENT, C_GOLD, C_NEG, C_TEXT]
	if is_pure:
		palette = [C_PURE, C_TEXT]
	for k in 30:
		_chips.append({
			"t0": _run_t,
			"x": _rng.randf() * 1240.0 + 20.0,
			"delay": _rng.randf() * 500.0,
			"dur": (1.1 + _rng.randf() * 0.7) * 1000.0,
			"r0": deg_to_rad(_rng.randf() * 60.0 - 30.0),
			"r1": deg_to_rad(_rng.randf() * 360.0 - 180.0),
			"col": palette[k % palette.size()],
		})


func _redraw_all() -> void:
	queue_redraw()
	for i in _reel_nodes.size():
		var clunk := 0.0
		var ct := (_run_t - _stop_t[i]) / 300.0
		if _stopped[i] and _stop_t[i] > -1e8 and ct >= 0.0 and ct < 1.0:
			clunk = 30.0 * (1.0 - _bez(0.2, 1.8, 0.4, 1.0, ct))
		_reel_nodes[i].position = Vector2(float(i) * (REEL_W + REEL_GAP), VP_PAD + clunk)
		_reel_nodes[i].queue_redraw()


# --- Math helpers -------------------------------------------------------------

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


static func _rot(deg: float) -> Transform2D:
	return Transform2D(deg_to_rad(deg), Vector2.ZERO)


static func _scale_t(sx: float, sy: float) -> Transform2D:
	return Transform2D(Vector2(sx, 0.0), Vector2(0.0, sy), Vector2.ZERO)


func _use(ci: CanvasItem, t: Transform2D) -> void:
	ci.draw_set_transform_matrix(_base * t)


func _tw(font: Font, text: String, size: int, spacing: float) -> float:
	if spacing == 0.0:
		return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var w := 0.0
	for ch in text:
		w += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x + spacing
	return w - spacing


func _txt(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, col: Color, spacing: float = 0.0) -> void:
	if spacing == 0.0:
		ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)
		return
	var x := pos.x
	for ch in text:
		ci.draw_string(font, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x + spacing


func _accent() -> Color:
	return C_PURE if is_pure else C_ACCENT


func _skip_xf() -> Transform2D:
	return Transform2D.IDENTITY


# --- Main drawing -------------------------------------------------------------

func _draw() -> void:
	var s := minf(size.x / STAGE.x, size.y / STAGE.y)
	if s <= 0.0:
		return
	var origin := (size - STAGE * s) * 0.5
	_base = Transform2D(Vector2(s, 0.0), Vector2(0.0, s), origin)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var title := PreGameDraw.title_font()
	var mono := PreGameDraw.mono_font()
	var lt := _lead_t if _intro_on else 1e9
	if lt < 400.0:
		_draw_intro_wipe(lt)  # the previous screen is still visible under the sweeping slabs
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	draw_rect(Rect2(Vector2.ZERO, size), C_BG)
	_intro_cab_dy = 0.0
	_intro_head_dx = 0.0
	if lt < INTRO_MS:
		_intro_cab_dy = 460.0 * (1.0 - _bez(0.2, 1.35, 0.4, 1.0, clampf((lt - 520.0) / 600.0, 0.0, 1.0)))
		_intro_head_dx = -520.0 * (1.0 - _bez(0.2, 1.2, 0.4, 1.0, clampf((lt - 580.0) / 450.0, 0.0, 1.0)))
	_draw_backdrop()
	_draw_header(title, mono)
	_draw_cabinet(mono)
	_draw_result(title, mono)
	_draw_chips()
	_draw_chrome(mono)
	_draw_wipe()
	if lt < INTRO_MS:
		_draw_intro_wipe(lt)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_backdrop() -> void:
	_use(self, _about(Vector2(640.0, 330.0), _rot(-8.0)))
	draw_rect(Rect2(-260.0, 150.0, 1800.0, 360.0), C_SLAB)
	_use(self, _about(Vector2(640.0, 563.0), _rot(-8.0)))
	draw_rect(Rect2(-260.0, 548.0, 1800.0, 30.0), C_SLAB)
	var k := -2
	while true:
		var x := -260.0 + float(k) * 88.0 + _band_off
		if x > 1540.0:
			break
		if x + 44.0 > -260.0:
			draw_rect(Rect2(x, 548.0, 44.0, 30.0), C_SLAB2)
		k += 1


func _draw_header(title: Font, mono: Font) -> void:
	_use(self, Transform2D(0.0, Vector2(78.0 + _intro_head_dx, 34.0)) * _rot(-3.0) * _skew_x(SKEW))
	var label := "NATURE ROLL"
	var lw := _tw(mono, label, 15, 3.0)
	draw_rect(Rect2(0.0, 0.0, lw + 28.0, 28.0), C_GOLD)
	_txt(self, mono, Vector2(14.0, 20.0), label, 15, C_INK, 3.0)
	var head := "ROLLING..."
	var col := C_TEXT
	if state == "REVEAL" or state == "SETTLED" or state == "EXIT":
		head = "%s LOCKED" % nature_name.to_upper()
		col = _accent()
	_txt(self, title, Vector2(0.0, 28.0 + 10.0 + 56.0), head, 66, col, 1.3)


func _cabinet_xf() -> Transform2D:
	var jolt := Vector2.ZERO
	var e_t := (_run_t - _hit_t) / 360.0
	if e_t >= 0.0 and e_t < 1.0:
		var h := HIT_STRENGTH[_hit_idx]
		if e_t < 0.4:
			var e := _bez(0.2, 1.7, 0.4, 1.0, e_t / 0.4)
			jolt = Vector2(h * 0.4, h).lerp(Vector2(0.0, -h * 0.4), e)
		else:
			var e2 := _bez(0.2, 1.7, 0.4, 1.0, (e_t - 0.4) / 0.6)
			jolt = Vector2(0.0, -h * 0.4).lerp(Vector2.ZERO, e2)
	var center := CAB_POS + CAB_SIZE * 0.5
	return Transform2D(0.0, center + Vector2(0.0, _intro_cab_dy)) * _rot(-3.0) * _skew_x(SKEW) * Transform2D(0.0, jolt) * Transform2D(0.0, -CAB_SIZE * 0.5)


func _draw_cabinet(_mono: Font) -> void:
	var cab := _cabinet_xf()
	_use(self, cab)
	draw_rect(Rect2(Vector2(16.0, 16.0), CAB_SIZE), Color.BLACK)
	draw_rect(Rect2(Vector2.ZERO, CAB_SIZE), C_PANEL)
	# Chase lights: each lamp changes at most once per 1.3 s (well under 3 Hz).
	var spinning_lamps := state == "SPINNING" or state == "STOP_1" or state == "STOP_2"
	var all_lit := state == "STOP_3" or state == "REVEAL" or state == "SETTLED" or state == "EXIT"
	var bulb_gap := (REELS_SIZE.x - 13.0 * 30.0) / 12.0
	for row in 2:
		for b in 13:
			var lit := all_lit
			if spinning_lamps:
				var delay := float(b) * 100.0
				if _run_t >= delay:
					var ph := fposmod(_run_t - delay, 1300.0) / 1300.0
					lit = ph < 0.3 if row == 0 else ph > 0.7
			var col := _accent() if all_lit else (C_GOLD if lit else C_LAMP_OFF)
			if all_lit:
				col = _accent()
			var y := 14.0 if row == 0 else CAB_SIZE.y - 14.0 - 16.0
			draw_rect(Rect2(CAB_PAD.x + float(b) * (30.0 + bulb_gap), y, 30.0, 16.0), col)
	# Reels (rendered by the SubViewport so the window clips cleanly under skew).
	if _vp != null:
		draw_texture_rect(_vp.get_texture(), Rect2(CAB_PAD.x, CAB_PAD.y - VP_PAD, REELS_SIZE.x, REELS_SIZE.y + VP_PAD * 2.0), false)
	_draw_payline()
	_draw_shards()


func _draw_payline() -> void:
	var y_mid := CAB_PAD.y + CELL_H + CELL_H * 0.5
	var e := 1.0
	var t := (_run_t - _hit_t) / 300.0
	if t >= 0.0 and t < 1.0:
		e = _bez(0.2, 1.7, 0.4, 1.0, t)
	var sc := lerpf(1.5, 1.0, e)
	var shift := 20.0 * (1.0 - e)
	var lc := Vector2(CAB_PAD.x - 13.0 + shift, y_mid)
	var left := PackedVector2Array([
		lc + Vector2(-10.0, -20.0) * sc, lc + Vector2(10.0, 0.0) * sc, lc + Vector2(-10.0, 20.0) * sc])
	draw_colored_polygon(left, C_GOLD)
	var rc := Vector2(CAB_PAD.x + REELS_SIZE.x + 13.0 - shift, y_mid)
	var right := PackedVector2Array([
		rc + Vector2(10.0, -20.0) * sc, rc + Vector2(-10.0, 0.0) * sc, rc + Vector2(10.0, 20.0) * sc])
	draw_colored_polygon(right, C_GOLD)


func _draw_shards() -> void:
	var keep: Array[Dictionary] = []
	for sh in _shards:
		var u := (_run_t - float(sh["t0"])) / 550.0
		if u < 0.0 or u >= 1.0:
			continue
		keep.append(sh)
		var e := _bez(0.1, 0.7, 0.3, 1.0, u)
		var alpha := 1.0 if u < 0.7 else 1.0 - (u - 0.7) / 0.3
		var p := Vector2(float(sh["x"]) + float(sh["dx"]) * e, float(sh["y"]) + float(sh["dy"]) * e)
		var col: Color = sh["col"]
		col.a = alpha
		var m := _cabinet_xf() * Transform2D(float(sh["rot"]) * e, p)
		_use(self, m)
		draw_rect(Rect2(-12.0, -6.5, 24.0, 13.0), col)
	_shards = keep


func _draw_result(title: Font, mono: Font) -> void:
	if state != "REVEAL" and state != "SETTLED" and state != "EXIT":
		_enter_rect = Rect2()
		_back_rect = Rect2()
		return
	var since := _run_t - _reveal_t
	# Name slam
	var slam := _bez(0.2, 1.5, 0.4, 1.0, clampf(since / 240.0, 0.0, 1.0))
	var sc := lerpf(2.5, 1.0, slam)
	var nm := nature_name.to_upper()
	_use(self, Transform2D(0.0, Vector2(796.0, 293.0)) * _rot(-5.0) * _skew_x(SKEW) * _scale_t(sc, sc))
	var name_col := C_TEXT
	name_col.a = clampf(slam, 0.0, 1.0)
	_txt(self, title, Vector2(0.0, -7.0), nm, 108, name_col, 1.1)
	# Stamp (starts 140 ms late)
	var st := (since - 140.0) / 200.0
	if st >= 0.0:
		var se := _bez(0.3, 1.6, 0.5, 1.0, clampf(st, 0.0, 1.0))
		var ssc := lerpf(3.2, 1.0, se)
		var label := "PURE DISCIPLINE" if is_pure else "STAMPED: %s" % nm
		var lw := _tw(mono, label, 19, 3.0)
		var box := Vector2(lw + 36.0, 41.0)
		var sc_center := Vector2(796.0 + 150.0 + box.x * 0.5, 311.0 + box.y * 0.5)
		_use(self, Transform2D(0.0, sc_center) * _rot(6.0) * _scale_t(ssc, ssc))
		var bg := C_PURE if is_pure else C_GOLD
		bg.a = clampf(se, 0.0, 1.0)
		draw_rect(Rect2(-box * 0.5, box), bg)
		var tc := C_INK
		tc.a = bg.a
		_txt(self, mono, Vector2(-box.x * 0.5 + 18.0, 7.0), label, 19, tc, 3.0)
	# Description + buttons (SETTLED)
	if state == "SETTLED" or state == "EXIT":
		var rs := clampf((_run_t - _settle_t) / 220.0, 0.0, 1.0)
		var rise := 1.0 - rs
		var body := _mono_regular()
		var lines := _wrap(body, nature_desc, 20, 440.0)
		var block_h := float(lines.size()) * 28.0
		var center := Vector2(796.0 + 220.0, 392.0 + block_h * 0.5)
		_use(self, Transform2D(0.0, Vector2(0.0, 18.0 * rise)) * _about(center, _skew_x(SKEW)))
		var dc := C_TEXT
		dc.a = rs
		for li in lines.size():
			_txt(self, body, Vector2(796.0, 392.0 + 20.0 + float(li) * 28.0), lines[li], 20, dc)
		_draw_buttons(mono, rs)


var _mono_reg: Font = null


func _mono_regular() -> Font:
	if _mono_reg == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
		f.font_weight = 400
		_mono_reg = f
	return _mono_reg


func _wrap(font: Font, text: String, size: int, width: float) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" "):
		var cand := word if cur.is_empty() else "%s %s" % [cur, word]
		if font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= width:
			cur = cand
		else:
			if not cur.is_empty():
				out.append(cur)
			cur = word
	if not cur.is_empty():
		out.append(cur)
	return out


func _draw_buttons(mono: Font, rs: float) -> void:
	var enter_label := "ENTER 3D EXPEDITION [ENTER]"
	var back_label := "BACK TO HUB [X]"
	var ew := _tw(mono, enter_label, 16, 1.0) + 32.0
	var bw := _tw(mono, back_label, 14, 1.0) + 32.0
	var origin := Vector2(796.0, 568.0)
	var total_w := ew + 10.0 + bw
	_enter_rect = Rect2(origin, Vector2(ew, 45.0))
	_back_rect = Rect2(origin + Vector2(ew + 10.0, 0.0), Vector2(bw, 45.0))
	var center := origin + Vector2(total_w * 0.5, 22.5)
	_btn_xf = Transform2D(0.0, Vector2(0.0, 18.0 * (1.0 - rs))) * _about(center, _skew_x(SKEW))
	_use(self, _btn_xf)
	var a := rs
	draw_rect(_enter_rect, Color(C_ACCENT, a))
	_txt(self, mono, origin + Vector2(16.0, 28.0), enter_label, 16, Color(C_INK, a), 1.0)
	draw_rect(_back_rect, Color(C_SLAB2, a))
	_txt(self, mono, _back_rect.position + Vector2(16.0, 27.0), back_label, 14, Color(C_TEXT, a), 1.0)


func _draw_chips() -> void:
	for chip in _chips:
		var u := (_run_t - float(chip["t0"]) - float(chip["delay"])) / float(chip["dur"])
		if u < 0.0 or u >= 1.0:
			continue
		var e := _bez(0.5, 0.0, 0.9, 0.6, u)
		var p := Vector2(float(chip["x"]), -40.0 + 800.0 * e)
		var r := lerpf(float(chip["r0"]), float(chip["r1"]), e)
		_use(self, Transform2D(0.0, p) * _skew_x(SKEW) * _rot(rad_to_deg(r)))
		draw_rect(Rect2(-14.0, -8.0, 28.0, 16.0), chip["col"])


func _draw_chrome(mono: Font) -> void:
	if not is_spinning():
		_skip_rect = Rect2()
		return
	var label := "SKIP [SPACE]"
	var w := _tw(mono, label, 14, 2.0) + 32.0
	var rect := Rect2(1226.0 - w, 686.0 - 34.0, w, 34.0)
	_skip_rect = rect
	_use(self, _about(rect.get_center(), _skew_x(SKEW)))
	draw_rect(rect, C_SLAB2)
	_txt(self, mono, rect.position + Vector2(16.0, 22.0), label, 14, C_TEXT, 2.0)


## Entrance: accent + dark slabs sweep in from the left over the previous screen (0-500 ms),
## hold, then leave to the right (500-1100 ms) revealing the machine. Flat, skewed, no flashing.
func _draw_intro_wipe(lt: float) -> void:
	var rect := Rect2(-384.0, -72.0, 2048.0, 864.0)
	var width := rect.size.x
	for k in 2:
		var enter := clampf((lt - 120.0 * float(k)) / 380.0, 0.0, 1.0)
		var leave := clampf((lt - 500.0 - 120.0 * float(1 - k)) / 420.0, 0.0, 1.0)
		var tx := lerpf(-1.35 * width, 0.0, _bez(0.7, 0.0, 0.2, 1.0, enter)) + lerpf(0.0, 1.35 * width, _bez(0.7, 0.0, 0.2, 1.0, leave))
		if tx >= 1.3 * width or tx <= -1.3 * width:
			continue
		_use(self, Transform2D(0.0, Vector2(tx, 0.0)) * _about(Vector2(640.0, 360.0), _skew_x(SKEW)))
		draw_rect(rect, C_ACCENT if k == 0 else C_BG)


func _draw_wipe() -> void:
	if state != "EXIT":
		return
	var since := _run_t - _exit_t
	var rect := Rect2(-384.0, -72.0, 2048.0, 864.0)
	var width := rect.size.x
	for k in 2:
		var u := clampf((since - (160.0 * k)) / 460.0, 0.0, 1.0) if k == 1 else clampf(since / 460.0, 0.0, 1.0)
		var e := _bez(0.7, 0.0, 0.2, 1.0, u)
		var tx := lerpf(-1.35 * width, 0.0, e)
		_use(self, Transform2D(0.0, Vector2(tx, 0.0)) * _about(Vector2(640.0, 360.0), _skew_x(SKEW)))
		draw_rect(rect, C_ACCENT if k == 0 else C_BG)


# --- Reels (drawn inside the SubViewport) ---------------------------------------

func _draw_reel(ci: Control, i: int) -> void:
	if _all.is_empty():
		_all = Logic.all_symbols()
	var title := PreGameDraw.title_font()
	var mono := PreGameDraw.mono_font()
	var size_n := _all.size()
	var x0 := 0.0
	var y0 := 0.0
	ci.draw_rect(Rect2(x0, y0, REEL_W, REELS_SIZE.y), C_REEL)
	var wrapped := fposmod(_pos[i], float(size_n))
	var base_j := int(floor(wrapped))
	var spinning := not _stopped[i]
	var win_j := roundi(wrapped) + 1
	for k in 4:
		var j := base_j + k
		var top := y0 + (float(j) - wrapped) * CELL_H
		if top <= y0 - CELL_H or top >= y0 + REELS_SIZE.y:
			continue
		var sym: String = _all[posmod(j, size_n)]
		var kind := Logic.symbol_kind(sym)
		var is_win := _stopped[i] and _stop_t[i] > -1e8 and j == win_j and state != "BOOT"
		var center := Vector2(x0 + REEL_W * 0.5, top + CELL_H * 0.5)
		var sx := 1.0
		var sy := 1.22 if spinning else 1.0
		var win_t := clampf((_run_t - _stop_t[i]) / 300.0, 0.0, 1.0)
		if is_win:
			var pe := lerpf(1.55, 1.0, _bez(0.2, 1.9, 0.4, 1.0, win_t))
			sx = pe
			sy = pe
		ci.draw_set_transform_matrix(Transform2D(0.0, center) * _scale_t(sx, sy) * Transform2D(0.0, -center))
		var fg := C_DIM
		if kind == "pos":
			fg = C_ACCENT
		elif kind == "neg":
			fg = C_NEG
		if is_win:
			var bg := C_TEXT
			if kind == "pos":
				bg = C_ACCENT
			elif kind == "neg":
				bg = C_NEG
			ci.draw_rect(Rect2(x0, top, REEL_W, CELL_H), bg)
			fg = C_INK
		_draw_symbol(ci, title, mono, sym, Vector2(x0, top), fg)
		if is_win:
			var fa := 0.85 * (1.0 - _bez(0.0, 0.0, 0.58, 1.0, clampf((_run_t - _stop_t[i]) / 260.0, 0.0, 1.0)))
			if fa > 0.0:
				ci.draw_rect(Rect2(x0, top, REEL_W, CELL_H), Color(C_TEXT, fa))
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	ci.draw_rect(Rect2(x0, y0, REEL_W, CELL_H), Color(0.0196, 0.0745, 0.1333, 0.66))
	ci.draw_rect(Rect2(x0, y0 + 2.0 * CELL_H, REEL_W, CELL_H), Color(0.0196, 0.0745, 0.1333, 0.66))


func _draw_symbol(ci: Control, title: Font, mono: Font, sym: String, top_left: Vector2, col: Color) -> void:
	var base_y := top_left.y + 69.0
	var parts := sym.split(" ")
	if parts.size() == 2:
		var ws := _tw(mono, parts[0], 23, 1.8)
		var wv := _tw(title, parts[1], 50, 0.5)
		var x := top_left.x + (REEL_W - (ws + 10.0 + wv)) * 0.5
		_txt(ci, mono, Vector2(x, base_y), parts[0], 23, col, 1.8)
		_txt(ci, title, Vector2(x + ws + 10.0, base_y), parts[1], 50, col, 0.5)
	else:
		var wn := _tw(title, sym, 40, 3.2)
		_txt(ci, title, Vector2(top_left.x + (REEL_W - wn) * 0.5, base_y), sym, 40, col, 3.2)
