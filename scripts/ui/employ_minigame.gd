extends Control
## D-1257: rhythm minigame of the Employ attempt. PROVISIONAL LOOK (creator, 2026-11-16: "Sim, provisório"):
## the reticle that already exists in the game (open corners + diamond, as AttackTargetReticle), a dashed ring that
## closes on it, Kanit texts with an INK outline and gold stars. No cards, no backgrounds. The final look is pending.
## Rules live in EmployRhythm (one key, PERFECT +-60 ms, GOOD +-130 ms, MISS 0 pp, cannot be interrupted).
## Provisional timing (the creator has not decided the tempo): BPM, lead-in beats and approach time below.
## The battle is frozen while this is open (D-1229), so it keeps its own clock (_t, ms), like EmployMarker does
## by running with PROCESS_MODE_ALWAYS.

const EmployRhythm = preload("res://scripts/progression/employ_rhythm.gd")
const KANIT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")

signal finished(bonuses: Array)  ## every note judged and the closing pause is over; bonuses = pp per note, in order

const BPM := 110.0  # provisional
const LEAD_BEATS := 4  # provisional: beats before the first note
const APPROACH_MS := 1800.0  # provisional: how long the ring takes to close
const START_DELAY_MS := 700.0
const END_HOLD_MS := 1000.0

const CREAM := Color(0.918, 0.914, 0.851)
const INK := Color(0.067, 0.106, 0.161)
const GOLD := Color(0.969, 0.796, 0.471)
const AQUA := Color(0.384, 0.847, 0.906)
const CYAN := Color(0.251, 0.949, 0.851)
const STAR := Color(1.0, 0.847, 0.29)
const GREY := Color(0.604, 0.639, 0.678)

var _rhythm := EmployRhythm.new()
var _t := 0.0  # ms since open()
var _active := false
var _points: Array[Vector2] = []
var _times: Array = []
var _states: Array = []  # "pending" | "perfect" | "good" | "miss"
var _pops: Array = []  # {text, color, pos, age, size}
var _stars: Array = []  # {pos, vel, age, life, spin, size}
var _auto: Array = []  # debug: per note "perfect" | "good" | "" (no press); empty = a human plays
var _auto_done: Array = []
var _end_at := -1.0
var _spread := 100.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # The Employ attempt pauses the tree.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()


## anchor: screen position of the enemy centre; spread: its on-screen height (px). The notes are scattered around it.
func open(anchor: Vector2, note_count: int, spread: float) -> void:
	_spread = maxf(spread, 80.0)
	var offsets := [Vector2(-1.15, -0.35), Vector2(1.2, 0.1), Vector2(0.0, -1.1)]
	var rect := get_viewport_rect().grow(-90.0)
	_points.clear()
	var n := clampi(note_count, 1, EmployRhythm.NOTES_MAX)
	for i in n:
		var p: Vector2 = anchor + offsets[i] * _spread
		_points.append(Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y)))
	var beat := 60000.0 / BPM
	_times.clear()
	for i in n:
		_times.append(START_DELAY_MS + (LEAD_BEATS + i) * beat)
	_rhythm.setup(_times)
	_states = []
	for i in n:
		_states.append("pending")
	_auto_done = []
	for i in n:
		_auto_done.append(false)
	_pops.clear()
	_stars.clear()
	_t = 0.0
	_end_at = -1.0
	_active = true
	show()
	queue_redraw()


func close() -> void:
	_active = false
	hide()


func is_open() -> bool:
	return _active


## Debug/tests: grades to press by themselves, per note ("perfect", "good" or "" for no press).
func set_auto(plan: Array) -> void:
	_auto = plan


func note_times() -> Array:
	return _times


func summary() -> Dictionary:
	return _rhythm.summary()


func _process(delta: float) -> void:
	if _active:
		step(delta * 1000.0)


## Advances the minigame clock (ms). The only place time moves, so tests can drive it.
func step(ms: float) -> void:
	if not _active:
		return
	_t += ms
	_run_auto()
	for i in _rhythm.update(_t):
		_states[i] = "miss"
		_pop("MISS", GREY, _points[i] + Vector2(0, -56), 30)
	_age(ms / 1000.0)
	if _rhythm.is_finished():
		if _end_at < 0.0:
			_end_at = _t + END_HOLD_MS
			var total: float = _rhythm.total_bonus()
			if total > 0.0:
				_pop("+%d pp" % int(total), CREAM, _points[0] + Vector2(0, -92), 26)
		elif _t >= _end_at:
			_active = false
			hide()
			finished.emit(_rhythm.bonuses())
	queue_redraw()


func _run_auto() -> void:
	for i in _auto.size():
		if i >= _times.size() or _auto_done[i]:
			continue
		var plan: String = _auto[i]
		var at: float = _times[i] + (95.0 if plan == "good" else 0.0)
		if _t >= at:
			_auto_done[i] = true
			if plan != "":
				_press()


func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		_press()


func _press() -> void:
	var r: Dictionary = _rhythm.press(_t)
	if r.is_empty():
		return  # Outside every window: ignored (provisional, D-1257 open point).
	var i: int = int(r["note"])
	var perfect: bool = r["grade"] == "perfect"
	_states[i] = r["grade"]
	_burst(_points[i], 26 if perfect else 12)
	_pop("PERFECT" if perfect else "GOOD", GOLD if perfect else AQUA, _points[i] + Vector2(0, -56), 38 if perfect else 30)
	_pop("+%d pp" % int(_rhythm.bonuses()[i]), CREAM, _points[i] + Vector2(0, -22), 20)


func _pop(text: String, color: Color, pos: Vector2, size: int) -> void:
	_pops.append({"text": text, "color": color, "pos": pos, "age": 0.0, "size": size})


func _burst(pos: Vector2, count: int) -> void:
	for i in count:
		var a := randf() * TAU
		var sp := 120.0 + randf() * 260.0
		_stars.append({"pos": pos, "vel": Vector2(cos(a), sin(a) - 0.5) * sp, "age": 0.0, "life": 0.7 + randf() * 0.4,
			"spin": (randf() - 0.5) * 12.0, "size": 6.0 + randf() * 8.0, "ang": randf() * TAU})


func _age(dt: float) -> void:
	for s in _stars:
		s["age"] += dt
		s["vel"].y += 520.0 * dt
		s["pos"] += s["vel"] * dt
		s["ang"] += s["spin"] * dt
	_stars = _stars.filter(func(s: Dictionary) -> bool: return s["age"] < s["life"])
	for p in _pops:
		p["age"] += dt
	_pops = _pops.filter(func(p: Dictionary) -> bool: return p["age"] < 1.1)


func _draw() -> void:
	if not _active:
		return
	var beat := 60000.0 / BPM
	var phase := fposmod((_t - START_DELAY_MS) / beat, 1.0)
	var pulse := pow(1.0 - phase, 3.0)
	for i in _points.size():
		var state: String = _states[i]
		if state != "pending":
			continue
		var p: Vector2 = _points[i]
		var k: float = 1.0 - (float(_times[i]) - _t) / APPROACH_MS  # 0 = ring appears, 1 = the hit moment
		var live: bool = k > 0.0
		_reticle(p, 0.35 if not live else 0.55 + 0.45 * minf(k / 0.12, 1.0), pulse if live else 0.0)
		_text(str(i + 1), p + Vector2(0, 10), 30, CREAM)
		if live:
			var r := lerpf(_spread * 1.1, 34.0, clampf(k, 0.0, 1.15))
			_ring(p, r, minf(1.0, k * 2.2))
	for s in _stars:
		var a: float = clampf(1.0 - (s["age"] / s["life"] - 0.65) / 0.35, 0.0, 1.0)
		_draw_star(s["pos"], s["size"], s["ang"], Color(STAR.r, STAR.g, STAR.b, a))
	for p in _pops:
		var u: float = p["age"] / 1.1
		var grow: float = 0.6 + 0.4 * minf(u / 0.14, 1.0)
		var alpha: float = 1.0 if u < 0.65 else clampf(1.0 - (u - 0.65) / 0.35, 0.0, 1.0)
		var c: Color = p["color"]
		_text(p["text"], p["pos"] + Vector2(0, -u * 40.0), int(float(p["size"]) * grow), Color(c.r, c.g, c.b, alpha))


## The in-game reticle (AttackTargetReticle): four open corners and a diamond.
func _reticle(c: Vector2, alpha: float, pulse: float) -> void:
	var s := 30.0 + pulse * 3.0
	var col := Color(CYAN.r, CYAN.g, CYAN.b, alpha)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner: Vector2 = c + Vector2(sx * s, sy * s)
			draw_line(corner, corner + Vector2(-sx * 12.0, 0.0), Color(INK, 0.7 * alpha), 5.0)
			draw_line(corner, corner + Vector2(0.0, -sy * 12.0), Color(INK, 0.7 * alpha), 5.0)
			draw_line(corner, corner + Vector2(-sx * 12.0, 0.0), col, 2.4)
			draw_line(corner, corner + Vector2(0.0, -sy * 12.0), col, 2.4)


## Dashed ring (the one the attack HUD already uses) that closes on the reticle.
func _ring(c: Vector2, r: float, alpha: float) -> void:
	for i in 14:
		var a0 := TAU * float(i) / 14.0
		draw_arc(c, r, a0, a0 + 0.30, 6, Color(INK, 0.75 * alpha), 6.0)
		draw_arc(c, r, a0, a0 + 0.30, 6, Color(CREAM.r, CREAM.g, CREAM.b, alpha), 3.0)


func _text(text: String, center: Vector2, size: int, color: Color) -> void:
	var w := KANIT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := center + Vector2(-w * 0.5, size * 0.35)
	draw_string_outline(KANIT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(4, size / 5), Color(INK, color.a))
	draw_string(KANIT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_star(c: Vector2, r: float, ang: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := ang - PI * 0.5 + float(i) * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.42))
	draw_colored_polygon(pts, col)
