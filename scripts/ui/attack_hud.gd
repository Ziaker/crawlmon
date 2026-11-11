extends Control
## HUD de ataque do overworld — quatro conceitos SEM bloco/placa.
##
## Nada aqui é um retângulo: a HUD vive no alvo (mira, selo no chão), no
## jogador (glifo) ou entre os dois (fita). O Z é sempre o glifo central.
##
## Modos:
##   0 MIRA  — retículo vivo no inimigo, Z num medalhão hexagonal.
##   1 SELO  — sigilo projetado no chão, runas girando e pilar de luz.
##   2 GLIFO — Z grande flutuando ao lado do jogador, linha até o alvo.
##   3 FITA  — fita curva do jogador ao alvo, com Z no começo e seta no fim.
##
## Estados: READY, RECHARGING (arco de recarga) e NO_TARGET (fantasma no
## jogador, sem elementos de alvo). O ataque é Z; E não aparece.

signal hud_pressed

enum Mode { MIRA, SELO, GLIFO, FITA }
enum State { READY, RECHARGING, NO_TARGET }

const ATTACK_RANGE := 4.5
const KANIT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")

const CREAM := Color(0.918, 0.914, 0.851)
const INK := Color(0.067, 0.106, 0.161)
const AMBER := Color(1.000, 0.722, 0.278)
const GOLD := Color(0.969, 0.796, 0.471)
const CYAN := Color(0.220, 0.741, 0.973)
const AQUA := Color(0.384, 0.847, 0.906)
const CORAL := Color(1.000, 0.384, 0.310)
const LEAF := Color(0.560, 0.900, 0.470)

var mode := 0
var state := 0
var target_name := "SLIME"
var distance := 3.0
var cooldown := 0.0

var _cam: Camera3D
var _player: Node3D
var _target: Node3D
var _time := 0.0
var _press := 0.0
var _flash := 0.0
var _target_bounds := Vector2.ZERO
var _player_bounds := Vector2.ZERO
var _target_head_node: Node3D
var _target_body_node: Node3D
var _target_floor_node: Node3D
var _player_head_node: Node3D
var _player_floor_node: Node3D
var _font_body: SystemFont


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font_body = SystemFont.new()
	_font_body.font_names = PackedStringArray(["Arial", "Segoe UI"])
	_font_body.font_weight = 800


func _process(delta: float) -> void:
	_time += delta
	_press = maxf(0.0, _press - delta * 4.2)
	_flash = maxf(0.0, _flash - delta * 5.0)
	_target_bounds = _visual_bounds(_target)
	_player_bounds = _visual_bounds(_player)
	queue_redraw()


func set_mode(p_mode: int) -> void:
	mode = clampi(p_mode, 0, 3)
	queue_redraw()


func set_context(p_name: String, p_distance: float, p_state: int, p_cooldown := 0.0) -> void:
	target_name = p_name
	distance = clampf(p_distance, 0.05, ATTACK_RANGE)
	state = p_state
	cooldown = clampf(p_cooldown, 0.0, 1.0)
	queue_redraw()


func set_projection(cam: Camera3D, player: Node3D, target: Node3D) -> void:
	var target_changed := target != _target
	var player_changed := player != _player
	_cam = cam
	_player = player
	_target = target
	if target_changed:
		_target_head_node = _find_effect_anchor(target, "eff_head")
		_target_body_node = _find_effect_anchor(target, "eff_body")
		_target_floor_node = _find_effect_anchor(target, "eff_floor")
	if player_changed:
		_player_head_node = _find_effect_anchor(player, "eff_head")
		_player_floor_node = _find_effect_anchor(player, "eff_floor")
	queue_redraw()


func play_press() -> void:
	if state == State.NO_TARGET:
		return
	_press = 1.0
	_flash = 1.0
	hud_pressed.emit()


static func mode_name(p_mode: int) -> String:
	match p_mode:
		Mode.MIRA:
			return "MIRA"
		Mode.SELO:
			return "SELO"
		Mode.GLIFO:
			return "GLIFO"
		Mode.FITA:
			return "FITA"
		_:
			return "?"


# --- desenho ----------------------------------------------------------------

func _draw() -> void:
	if _cam == null or not is_instance_valid(_player):
		return
	if state == State.NO_TARGET or not is_instance_valid(_target):
		return
	match mode:
		Mode.MIRA:
			_draw_mira()
		Mode.SELO:
			_draw_selo()
		Mode.GLIFO:
			_draw_glifo()
		Mode.FITA:
			_draw_fita()


func _draw_mira() -> void:
	var anchor := _target_anchor()
	if anchor == Vector2.INF:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 4.2)
	var r := clampf(_screen_height(_target) * 0.55, 42.0, 82.0) + pulse * 2.5 - _press * 10.0
	var col := _tint(CREAM)
	var accent := _tint(AMBER)
	var ink := Color(INK.r, INK.g, INK.b, 0.72)
	# quatro cantos abertos (nada de caixa fechada)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := anchor + Vector2(sx * (r + 10.0), sy * (r + 10.0))
			draw_line(corner, corner + Vector2(-sx * 13.0, 0.0), ink, 4.0)
			draw_line(corner, corner + Vector2(0.0, -sy * 13.0), ink, 4.0)
			draw_line(corner, corner + Vector2(-sx * 13.0, 0.0), col, 1.8)
			draw_line(corner, corner + Vector2(0.0, -sy * 13.0), col, 1.8)
	# anel tracejado girando
	for i in 14:
		var a0 := _time * 0.95 + TAU * float(i) / 14.0
		draw_arc(anchor, r, a0, a0 + 0.155, 5, _tint(CREAM, 0.85), 1.6)
	# arco de alcance/recarga
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.06, 1.0)
	var arc_col := accent
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
		arc_col = _tint(CORAL)
	draw_arc(anchor, r + 15.0, -PI * 0.5, -PI * 0.5 + fill * TAU, 40,
		Color(INK.r, INK.g, INK.b, 0.45), 3.4)
	draw_arc(anchor, r + 15.0, -PI * 0.5, -PI * 0.5 + fill * TAU, 40, arc_col, 2.2)
	# centro
	var d := 4.5 + pulse * 1.5
	draw_colored_polygon(PackedVector2Array([
		anchor + Vector2(0.0, -d), anchor + Vector2(d, 0.0),
		anchor + Vector2(0.0, d), anchor + Vector2(-d, 0.0),
	]), accent)
	# medalhão do Z (hexágono, não é tecla quadrada)
	var medal := anchor + Vector2(r * 0.92, -r * 0.92)
	draw_line(anchor + Vector2(r * 0.55, -r * 0.55), medal - Vector2(9.0, -9.0), col, 1.2)
	_draw_medallion(medal, 14.0, accent)
	# textos soltos
	var head := _target_head()
	_draw_centered(_font_body, head + Vector2(0.0, -28.0), target_name, 11,
		_tint(CREAM), true)
	_draw_centered(_font_body, head + Vector2(0.0, -15.0), "%.1f m" % distance, 9,
		_tint(AMBER), true)
	var action := "RECARGA" if state == State.RECHARGING else "ATTACK"
	_draw_centered(KANIT, anchor + Vector2(0.0, r + 31.0), action, 13,
		_tint(CORAL if state == State.RECHARGING else CREAM), true, 2.0)
	# press: contrai e solta faíscas
	if _press > 0.0:
		for i in 8:
			var a := TAU * float(i) / 8.0 + 0.2
			var p0 := anchor + Vector2(cos(a), sin(a)) * (r + 6.0)
			var p1 := anchor + Vector2(cos(a), sin(a)) * (r + 6.0 + 34.0 * _press)
			draw_line(p0, p1, Color(AMBER.r, AMBER.g, AMBER.b, 0.8 * _press), 2.0)


func _draw_selo() -> void:
	var floor := _floor_point(_target)
	var ground := _project(floor + Vector3.UP * 0.02)
	if ground == Vector2.INF:
		return
	var radius := clampf(_actor_radius(_target) * 1.65, 0.62, 1.15)
	var ring := _ground_ring(_target, radius, 40, 0.02)
	var inner := _ground_ring(_target, radius * 0.70, 32, 0.02)
	if ring.is_empty() or inner.is_empty():
		return
	var amber := _tint(AMBER)
	var cream := _tint(CREAM)
	var alpha := 0.5 if state == State.RECHARGING else 1.0
	draw_polyline(ring, Color(INK.r, INK.g, INK.b, 0.7 * alpha), 5.0, true)
	draw_polyline(ring, Color(amber.r, amber.g, amber.b, 0.95 * alpha), 2.2, true)
	draw_polyline(inner, Color(cream.r, cream.g, cream.b, 0.55 * alpha), 1.2, true)
	# runas girando
	for i in 12:
		var a := _time * 0.65 + TAU * float(i) / 12.0
		var p0 := _project(_target.global_position + Vector3(cos(a) * radius * 0.78, 0.03, sin(a) * radius * 0.78))
		var p1 := _project(_target.global_position + Vector3(cos(a) * radius * 0.94, 0.03, sin(a) * radius * 0.94))
		if p0 != Vector2.INF and p1 != Vector2.INF:
			draw_line(p0, p1, Color(cream.r, cream.g, cream.b, 0.85 * alpha), 2.0)
	# pilar de luz do chão até o alvo
	var top := _target_anchor()
	if top != Vector2.INF:
		for i in 7:
			var t0 := float(i) / 7.0
			var t1 := float(i + 1) / 7.0
			var a0 := ground.lerp(top, t0)
			var a1 := ground.lerp(top, t1)
			for k in 3:
				draw_line(a0 + Vector2(float(k - 1) * 2.0, 0.0), a1 + Vector2(float(k - 1) * 2.0, 0.0), Color(amber.r, amber.g, amber.b, 0.30 * (1.0 - t0) * alpha), 1.6)
	# Z na borda da frente do selo (no chão, sem cobrir o inimigo)
	var front := ring[0]
	for p in ring:
		if p.y > front.y:
			front = p
	_draw_text_centered(KANIT, front + Vector2(0.0, 14.0), "Z", 36,
		Color(cream.r, cream.g, cream.b, 0.92 * alpha), true, 3.0)
	# nome/distância acima e ação abaixo
	if top != Vector2.INF:
		var head := _target_head()
		_draw_centered(_font_body, head + Vector2(0.0, -28.0), target_name, 11, cream, true)
		_draw_centered(_font_body, head + Vector2(0.0, -15.0), "%.1f m" % distance, 9, amber, true)
	_draw_centered(KANIT, front + Vector2(0.0, 52.0),
		"RECARGA" if state == State.RECHARGING else "ATTACK", 14,
		_tint(CORAL if state == State.RECHARGING else CREAM), true, 2.0)
	# progresso no próprio anel (alcance/recarga)
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.05, 1.0)
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
	var partial := _ground_ring(_target, radius, 40, 0.025)
	var count := int(float(partial.size()) * fill)
	if count > 1:
		var pts := partial.slice(0, count)
		draw_polyline(pts, _tint(GOLD if state != State.RECHARGING else CORAL), 3.0, true)
	if _press > 0.0:
		var big := _ground_ring(_target, radius + 0.22 * _press, 40, 0.02)
		if not big.is_empty():
			draw_polyline(big, Color(AMBER.r, AMBER.g, AMBER.b, 0.6 * _press), 3.0, true)


func _draw_glifo() -> void:
	var p := _player_anchor() + Vector2(150.0, -40.0)
	p.x = clampf(p.x, 120.0, size.x - 120.0)
	p.y = clampf(p.y, 140.0, size.y - 120.0)
	if p.x > size.x - 120.0:
		p.x = _player_anchor().x - 110.0
	var anchor := _target_anchor()
	var col := _tint(CREAM)
	var accent := _tint(AMBER)
	var ink := Color(INK.r, INK.g, INK.b, 0.78)
	# linha fina do glifo até o alvo
	if anchor != Vector2.INF:
		draw_line(p + Vector2(34.0, 8.0), anchor, Color(cream_a(col, 0.35)), 1.2)
		var d := 5.0
		draw_polyline(PackedVector2Array([
			anchor + Vector2(0.0, -d), anchor + Vector2(d, 0.0),
			anchor + Vector2(0.0, d), anchor + Vector2(-d, 0.0),
			anchor + Vector2(0.0, -d),
		]), accent, 1.8)
		_draw_centered(_font_body, _target_head() + Vector2(0.0, -30.0), target_name, 10, col, true)
		_draw_centered(_font_body, _target_head() + Vector2(0.0, -17.0), "%.1f m" % distance, 9, accent, true)
	# arco de recarga/alcance em volta do Z
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.06, 1.0)
	var arc_col := accent
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
		arc_col = _tint(CORAL)
	draw_arc(p, 43.0, -PI * 0.5, -PI * 0.5 + fill * TAU, 34,
		Color(INK.r, INK.g, INK.b, 0.5), 4.0)
	draw_arc(p, 43.0, -PI * 0.5, -PI * 0.5 + fill * TAU, 34, arc_col, 2.4)
	# Z grande com contorno grosso (sem fundo)
	var bob := sin(_time * 2.2) * 2.0
	var zp := p + Vector2(-24.0, 20.0 + bob)
	if _press > 0.0 and anchor != Vector2.INF:
		zp = zp.lerp(anchor, 0.10 * _press)
	_draw_text_centered(KANIT, zp + Vector2(3.0, 4.0), "Z", 58,
		Color(AMBER.r, AMBER.g, AMBER.b, 0.55), true, 3.0)
	_draw_text_centered(KANIT, zp, "Z", 58, col, true, 4.0)
	_draw_centered(KANIT, p + Vector2(0.0, 34.0),
		"RECARGA" if state == State.RECHARGING else "ATTACK", 13,
		_tint(CORAL if state == State.RECHARGING else CREAM), true, 2.0)
	if _press > 0.0:
		for i in 4:
			var y := p.y - 22.0 + float(i) * 13.0
			draw_line(Vector2(p.x - 64.0 - 26.0 * _press, y), Vector2(p.x - 46.0, y),
				Color(AMBER.r, AMBER.g, AMBER.b, 0.65 * _press), 2.0)


func _draw_fita() -> void:
	var a := _player_anchor(0.38, 18.0) + Vector2(12.0, 0.0)
	var b := _target_anchor()
	if b == Vector2.INF:
		return
	var mid := (a + b) * 0.5 + Vector2(0.0, -86.0)
	var pts := _bezier(a, mid, b, 30)
	if pts.is_empty():
		return
	var col := _tint(CREAM)
	var accent := _tint(CYAN)
	var ink := Color(INK.r, INK.g, INK.b, 0.7)
	draw_polyline(pts, ink, 9.0, true)
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.92), 5.5, true)
	draw_polyline(pts, Color(accent.r, accent.g, accent.b, 0.95), 2.0, true)
	# tracejados correndo para o alvo
	for k in 7:
		var t := fmod(_time * 0.55 + float(k) / 7.0, 1.0)
		var p0 := _bezier_point(a, mid, b, t)
		var p1 := _bezier_point(a, mid, b, minf(t + 0.05, 1.0))
		draw_line(p0, p1, Color(AMBER.r, AMBER.g, AMBER.b, 0.9), 4.0)
	# seta no alvo
	var dir := (b - _bezier_point(a, mid, b, 0.94)).normalized()
	var perp := Vector2(-dir.y, dir.x)
	draw_polyline(PackedVector2Array([
		b - dir * 18.0 + perp * 11.0, b, b - dir * 18.0 - perp * 11.0,
	]), Color(AMBER.r, AMBER.g, AMBER.b, 0.95), 3.0)
	# medalhão do Z no começo
	_draw_medallion(a, 16.0, accent)
	# alvo
	_draw_brackets(b, clampf(_screen_height(_target) * 0.30, 18.0, 42.0), accented(accent, 0.9), 2.0)
	_draw_centered(_font_body, _target_head() + Vector2(0.0, -30.0), target_name, 10, col, true)
	_draw_centered(_font_body, _target_head() + Vector2(0.0, -17.0), "%.1f m" % distance, 9, accent, true)
	# ação no meio da fita
	var mid_screen := _bezier_point(a, mid, b, 0.5)
	_draw_centered(KANIT, mid_screen + Vector2(0.0, -18.0),
		"RECARGA" if state == State.RECHARGING else "ATTACK", 13,
		_tint(CORAL if state == State.RECHARGING else CREAM), true, 2.0)
	# progresso (alcance/recarga): segunda fita fina por cima
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.05, 1.0)
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
	var count := maxi(2, int(30.0 * fill))
	var prog := pts.slice(0, count)
	if prog.size() > 1:
		draw_polyline(prog, _tint(CORAL if state == State.RECHARGING else GOLD), 3.0, true)
	# pulso viajando no press
	if _press > 0.0:
		var t := 1.0 - _press
		var pulse := _bezier_point(a, mid, b, t)
		draw_circle(pulse, 5.0 + 3.0 * _press, Color(255, 255, 255, 0.9 * _press))
		draw_circle(pulse, 12.0 + 8.0 * _press, Color(AMBER.r, AMBER.g, AMBER.b, 0.28 * _press))
		draw_arc(b, 20.0 + 24.0 * (1.0 - _press), 0.0, TAU, 24,
			Color(AMBER.r, AMBER.g, AMBER.b, 0.6 * _press), 2.0)


# --- helpers ----------------------------------------------------------------

func _tint(c: Color, alpha := 1.0) -> Color:
	var out := c
	if state == State.RECHARGING:
		out = out.lerp(Color(0.42, 0.44, 0.47), 0.55)
	out.a *= alpha
	return out


func _project(world: Vector3) -> Vector2:
	if _cam == null or _cam.is_position_behind(world):
		return Vector2.INF
	return _cam.unproject_position(world)


func _target_anchor() -> Vector2:
	if not is_instance_valid(_target):
		return Vector2.INF
	if _target_body_node != null and is_instance_valid(_target_body_node):
		return _project(_target_body_node.global_position)
	if _target_head_node != null and is_instance_valid(_target_head_node):
		return _project(_target_head_node.global_position)
	var y := lerpf(_target_bounds.x, _target_bounds.y, 0.52)
	var p := _target.global_position
	return _project(Vector3(p.x, y, p.z))


func _target_head() -> Vector2:
	if not is_instance_valid(_target):
		return Vector2.INF
	if _target_head_node != null and is_instance_valid(_target_head_node):
		return _project(_target_head_node.global_position)
	var p := _target.global_position
	return _project(Vector3(p.x, _target_bounds.y + 0.02, p.z))


func _player_anchor(factor := 0.62, y_offset := 0.0) -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.INF
	var p := _player.global_position
	var y := lerpf(_player_bounds.x, _player_bounds.y, factor)
	if _player_head_node != null and _player_floor_node != null:
		y = lerpf(_player_floor_node.global_position.y, _player_head_node.global_position.y, factor)
	return _project(Vector3(p.x, y, p.z)) + Vector2(0.0, y_offset)


func _screen_height(node: Node3D) -> float:
	if node == null or not is_instance_valid(node):
		return 90.0
	var bottom := Vector2.INF
	var top := Vector2.INF
	if node == _target and _target_head_node != null:
		if _target_floor_node != null:
			bottom = _project(_target_floor_node.global_position)
		top = _project(_target_head_node.global_position)
	if bottom == Vector2.INF or top == Vector2.INF:
		var bounds := _target_bounds if node == _target else _visual_bounds(node)
		var p := node.global_position
		bottom = _project(Vector3(p.x, bounds.x, p.z))
		top = _project(Vector3(p.x, bounds.y, p.z))
	if bottom == Vector2.INF or top == Vector2.INF:
		return 90.0
	return absf(bottom.y - top.y)


func _find_effect_anchor(node: Node3D, anchor_name: String) -> Node3D:
	if node == null or not is_instance_valid(node):
		return null
	for child in node.find_children("*", "Node3D", true, false):
		if child.name == anchor_name:
			return child as Node3D
	return null


func _floor_point(node: Node3D) -> Vector3:
	if node == _target and _target_floor_node != null and is_instance_valid(_target_floor_node):
		return _target_floor_node.global_position
	return node.global_position


func _visual_bounds(node: Node3D) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.ZERO
	var lo := INF
	var hi := -INF
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		lo = minf(lo, box.position.y)
		hi = maxf(hi, box.position.y + box.size.y)
	if lo == INF:
		var y := node.global_position.y
		return Vector2(y, y + 1.0)
	return Vector2(lo, hi)


func _actor_radius(node: Node3D) -> float:
	if node == null:
		return 0.45
	var radius := 0.45
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		radius = maxf(radius, maxf(box.size.x, box.size.z) * 0.5)
	return radius


func _ground_ring(node: Node3D, radius: float, segments: int, lift: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if _cam == null or node == null:
		return pts
	for i in segments + 1:
		var a := TAU * float(i) / float(segments)
		var world := _floor_point(node) + Vector3(cos(a) * radius, lift, sin(a) * radius)
		if _cam.is_position_behind(world):
			return PackedVector2Array()
		pts.append(_cam.unproject_position(world))
	return pts


func _bezier(a: Vector2, b: Vector2, c: Vector2, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		pts.append(_bezier_point(a, b, c, float(i) / float(steps)))
	return pts


func _bezier_point(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c


func _draw_medallion(center: Vector2, radius: float, accent: Color) -> void:
	var hex := PackedVector2Array()
	for i in 6:
		var a := -PI * 0.5 + TAU * float(i) / 6.0
		hex.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(hex, Color(INK.r, INK.g, INK.b, 0.94))
	var outline := PackedVector2Array(hex)
	outline.append(hex[0])
	draw_polyline(outline, accent, 2.0, true)
	_draw_text_centered(KANIT, center + Vector2(0.0, radius * 0.54), "Z", int(radius * 1.55),
		CREAM, false)


func _draw_brackets(center: Vector2, radius: float, color: Color, width: float) -> void:
	var arm := radius * 0.45
	draw_line(center + Vector2(-radius, -radius), center + Vector2(-radius + arm, -radius), color, width)
	draw_line(center + Vector2(-radius, -radius), center + Vector2(-radius, -radius + arm), color, width)
	draw_line(center + Vector2(radius, -radius), center + Vector2(radius - arm, -radius), color, width)
	draw_line(center + Vector2(radius, -radius), center + Vector2(radius, -radius + arm), color, width)
	draw_line(center + Vector2(-radius, radius), center + Vector2(-radius + arm, radius), color, width)
	draw_line(center + Vector2(-radius, radius), center + Vector2(-radius, radius - arm), color, width)
	draw_line(center + Vector2(radius, radius), center + Vector2(radius - arm, radius), color, width)
	draw_line(center + Vector2(radius, radius), center + Vector2(radius, radius - arm), color, width)


func _draw_centered(font: Font, pos: Vector2, text: String, font_size: int, color: Color,
		outline: bool, outline_width := 2.0) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text_centered(font, pos + Vector2(-w * 0.5, 0.0), text, font_size, color, outline, outline_width)


func _draw_text_centered(font: Font, pos: Vector2, text: String, font_size: int, color: Color,
		outline: bool, outline_width := 2.0) -> void:
	if font == null:
		font = ThemeDB.fallback_font
	if outline:
		var o := Color(INK.r, INK.g, INK.b, 0.82)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				draw_string(font, pos + Vector2(dx, dy) * outline_width, text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, o)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func cream_a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


func accented(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)
