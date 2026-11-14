class_name DrainSpearHud
extends Control
## D-377: HUD do laboratório. Desenha a fase, a distância, as tags flutuantes com badge rack, o voo das badges
## (0,3 s) e o BattleLog com retratos (opção C). Tudo é tela/laboratório: não é o HUD do jogo e não altera nenhuma
## regra de combate.

const PAPER := Color(0.96, 0.95, 0.92)
const INK := Color(0.07, 0.12, 0.18)
const CYAN := Color(0.38, 0.85, 0.92)
const LIME := Color(0.84, 0.99, 0.41)
const CORAL := Color(1.0, 0.38, 0.31)
const VIOLET := Color(0.78, 0.70, 1.0)
const GOLD := Color(0.97, 0.79, 0.47)

const BADGE_COLORS := {
	"atk_up": Color(0.84, 0.99, 0.41),
	"shield": Color(0.33, 0.87, 0.99),
	"mag_immune": Color(0.78, 0.70, 1.0),
	"def_down": Color(1.0, 0.63, 0.28),
}
const BADGE_TEXT := {
	"atk_up": "ATK+1",
	"shield": "SHD",
	"mag_immune": "IMM",
	"def_down": "DEF-1",
}

var _state := {}
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font


func set_state(s: Dictionary) -> void:
	_state = s
	queue_redraw()


func _draw() -> void:
	if _state.is_empty():
		return
	if _font == null:
		_font = ThemeDB.fallback_font
	var t := float(_state.get("time", 0.0))
	var attacker: Dictionary = _state.get("attacker", {})
	var target: Dictionary = _state.get("target", {})
	var cam: Camera3D = _state.get("camera")
	if attacker.is_empty() or target.is_empty() or cam == null:
		return
	_draw_phase()
	_draw_distance()
	_draw_log()
	_draw_tags(attacker, target, cam, t)
	_draw_flying_badges(attacker, target, cam, t)


func _draw_phase() -> void:
	var phase := String(_state.get("phase", ""))
	var hint := String(_state.get("hint", ""))
	_slant(Rect2(16, 14, 250, 34), 10.0, PAPER)
	draw_string(_font, Vector2(28, 37), "FASE — %s" % phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_string(_font, Vector2(18, 66), hint, HORIZONTAL_ALIGNMENT_LEFT, 430, 11, Color(0.85, 0.92, 0.96))


func _draw_distance() -> void:
	var dist := float(_state.get("distance", 0.0))
	var in_band := dist >= 15.3 and dist <= 17.3
	var col := LIME if in_band else CORAL
	draw_string(_font, Vector2(18, 86), "DIST %.2f u  [15,3–17,3]" % dist, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	var reach := String(_state.get("reach", "impala")).capitalize()
	draw_string(_font, Vector2(18, 104), "ALCANCE: %s (cabo cresce, lâmina fixa)" % reach, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.82, 0.88))
	var pov := String(_state.get("pov", "normal"))
	draw_string(_font, Vector2(18, 120), "POV: %s" % ("OUTRO LADO" if pov == "other" else "NORMAL (CINEMA)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.62, 0.90, 0.96))
	var mag := int(_state.get("mag", 10))
	var spi := int(_state.get("spi", 3))
	var base := 5 + mag
	draw_string(_font, Vector2(18, 138), "DANO: 5 + %d MAG = %d  ·  SPI %d (simulação local)" % [mag, base, spi], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.62, 0.78, 0.88))


func _draw_log() -> void:
	var entries := _log_entries()
	var x := size.x - 330.0
	var y := 14.0
	draw_string(_font, Vector2(x + 208, y + 2), "BattleLog", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CYAN)
	y += 10.0
	for i in entries.size():
		var e: Dictionary = entries[i]
		var rect := Rect2(x, y + float(i) * 27.0, 314, 24)
		var pts := _slant_points(rect, 6.0)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
		draw_colored_polygon(_slant_points(Rect2(x + 2, y + float(i) * 27.0 - 2, 310, 22), 6.0), PAPER)
		var tex := _portrait(String(e.get("who", "dqt_orc")))
		if tex != null:
			draw_texture_rect(tex, Rect2(rect.position + Vector2(6, 2), Vector2(20, 20)), false)
		draw_string(_font, rect.position + Vector2(32, 17), String(e.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, 270, 11, INK)


func _log_entries() -> Array:
	var out: Array = [{"who": "dqt_orc", "text": "Drain Spear — preparação"}]
	var t := float(_state.get("time", 0.0))
	var outcome := String(_state.get("outcome", "hit"))
	var stolen: Array = _state.get("stolen", [])
	var target: Dictionary = _state.get("target", {})
	var who := String(target.get("id", "dqt_cyclops"))
	if outcome == "interrupt" and t >= 1.65:
		out.append({"who": "dqt_orc", "text": "Execução interrompida"})
	elif outcome == "evade" and t >= 2.10:
		out.append({"who": who, "text": "Evade — golpe esquivado"})
	elif outcome == "hit" and t >= 2.10:
		out.append({"who": who, "text": "Contato confirmado"})
		if not stolen.is_empty():
			out.append({"who": "dqt_orc", "text": "Badge Steal — %d badge(s)" % stolen.size()})
		out.append({"who": who, "text": "Dano mágico — base %d" % (5 + int(_state.get("mag", 10)))})
	if out.size() > 4:
		out = out.slice(out.size() - 4)
	return out


func _draw_tags(attacker: Dictionary, target: Dictionary, cam: Camera3D, t: float) -> void:
	var apos := _tag_screen(attacker, cam)
	var bpos := _tag_screen(target, cam)
	if apos != Vector2(-9999, -9999) and bpos != Vector2(-9999, -9999):
		# Evita que as duas tags se empilhem em cima do contato: afasta cada uma para o seu lado.
		if absf(apos.x - bpos.x) < 230.0 and absf(apos.y - bpos.y) < 90.0:
			var sign := 1.0 if apos.x >= bpos.x else -1.0
			apos.x = clampf(apos.x + 82.0 * sign, 80.0, size.x - 360.0)
			bpos.x = clampf(bpos.x - 82.0 * sign, 80.0, size.x - 360.0)
	if apos != Vector2(-9999, -9999):
		var ah := _head_screen(attacker, cam)
		if ah != Vector2(-9999, -9999):
			draw_line(Vector2(apos.x, apos.y + 2), ah, Color(0.85, 0.95, 1.0, 0.35), 1.0)
		_draw_rack(apos, attacker, true, t)
	if bpos != Vector2(-9999, -9999):
		var bh := _head_screen(target, cam)
		if bh != Vector2(-9999, -9999):
			draw_line(Vector2(bpos.x, bpos.y + 2), bh, Color(0.85, 0.95, 1.0, 0.35), 1.0)
		_draw_rack(bpos, target, false, t)


func _head_screen(f: Dictionary, cam: Camera3D) -> Vector2:
	var root: Node3D = f.get("root")
	if root == null:
		return Vector2(-9999, -9999)
	var world := root.global_position + Vector3(0, float(f.get("height", 2.0)), 0)
	if cam.is_position_behind(world):
		return Vector2(-9999, -9999)
	return cam.unproject_position(world)


func _tag_screen(f: Dictionary, cam: Camera3D) -> Vector2:
	var root: Node3D = f.get("root")
	if root == null:
		return Vector2(-9999, -9999)
	var h := float(f.get("height", 2.0))
	var world := root.global_position + Vector3(0, h + 0.35, 0)
	if cam.is_position_behind(world):
		return Vector2(-9999, -9999)
	var p := cam.unproject_position(world)
	return Vector2(clampf(p.x, 90.0, size.x - 120.0), clampf(p.y, 70.0, size.y - 70.0))


func _draw_rack(pos: Vector2, f: Dictionary, is_attacker: bool, t: float) -> void:
	var id := String(f.get("id", "dqt_orc"))
	var name := id.replace("dqt_", "").to_upper()
	var w := 118.0
	var rect := Rect2(pos.x - w * 0.5, pos.y - 17, w, 17)
	draw_colored_polygon(_slant_points(Rect2(rect.position + Vector2(2, 2), rect.size), 7.0), Color(0, 0, 0, 0.4))
	draw_colored_polygon(_slant_points(rect, 7.0), PAPER)
	var tex := _portrait(id)
	if tex != null:
		draw_texture_rect(tex, Rect2(rect.position + Vector2(4, 1.5), Vector2(14, 14)), false)
	draw_string(_font, rect.position + Vector2(22, 13), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
	# Badge rack abaixo da tag.
	var badges: Dictionary = _state.get("badges", {})
	var stolen: Array = _state.get("stolen", [])
	var keys: Array = []
	if is_attacker:
		if t >= 2.13:
			for k in stolen:
				if t >= 2.43:
					keys.append(k)
	else:
		for k in ["atk_up", "shield", "mag_immune", "def_down"]:
			if bool(badges.get(k, false)):
				if k in stolen and t >= 2.13:
					continue
				keys.append(k)
	var bx := rect.position.x + 2
	for k in keys:
		_draw_badge(Vector2(bx, rect.end.y + 3), String(k), 1.0)
		bx += 50.0


func _draw_flying_badges(attacker: Dictionary, target: Dictionary, cam: Camera3D, t: float) -> void:
	var stolen: Array = _state.get("stolen", [])
	if stolen.is_empty() or t < 2.13 or t >= 2.43:
		return
	var k := clampf((t - 2.13) / 0.30, 0.0, 1.0)
	var from := _head_screen(target, cam) + Vector2(-86, -26)
	var to := _head_screen(attacker, cam) + Vector2(86, -26)
	if from == Vector2(-9999, -9999) or to == Vector2(-9999, -9999):
		return
	for i in stolen.size():
		var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 38.0)
		_draw_badge(p + Vector2(float(i) * 50.0, 0), String(stolen[i]), 1.0)


func _rack_anchor(f: Dictionary, cam: Camera3D) -> Vector2:
	var p := _tag_screen(f, cam)
	if p == Vector2(-9999, -9999):
		return p
	return p + Vector2(-55, 7)


func _draw_badge(pos: Vector2, key: String, alpha: float) -> void:
	var c: Color = BADGE_COLORS.get(key, CYAN)
	var rect := Rect2(pos, Vector2(46, 14))
	var pts := _slant_points(rect, 4.0)
	draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.95 * alpha))
	draw_string(_font, pos + Vector2(4, 11), String(BADGE_TEXT.get(key, key)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, INK)


func _portrait(id: String) -> Texture2D:
	var name := id.replace("dqt_", "")
	return preload("res://scripts/ui/portrait_icon.gd").get_icon(name)


func _slant_points(r: Rect2, skew: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y),
		Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y),
		Vector2(r.position.x, r.end.y),
	])


func _slant(r: Rect2, skew: float, color: Color) -> void:
	draw_colored_polygon(_slant_points(Rect2(r.position + Vector2(2, 2), r.size), skew), Color(0, 0, 0, 0.35))
	draw_colored_polygon(_slant_points(r, skew), color)
