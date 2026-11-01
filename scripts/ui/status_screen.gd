class_name StatusScreen
extends Control
## Out-of-combat team status ("Vitrine" prototype): roster on the left, the
## selected character's art in the middle, combat panel on the right and the
## equipped moves along the bottom. Reads live data from GameState.party; any
## value the game does not track yet (level, EXP, MP, DEF, passive ability)
## is shown as N/D instead of an invented number.
##
## Up/Down: character. Left/Right: move. Z: details. X: close.

signal closed

const LIME := Color("d6fa66")
const CORAL := Color("ff746c")
const PAPER := Color("f4eee1")
const INK := Color("10263a")
const BLUE := Color("63d9ec")
const VIOLET := Color("bd9afd")
const GOLD := Color("f0c57e")
const ART_DIR := "res://sugimori/por_nome/"
const FACE_DIR := "res://personagens/portraits/"

var _party: Array[Combatant] = []
var _member := 0
var _move := 0
var _detail_open := false
var _bg: GradientTexture2D
var _art_cache: Dictionary = {}
var _faces: Array[TextureRect] = []


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("26535f"), Color("143343"), Color("092133"), Color("051322")])
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.66, 1.0])
	_bg = GradientTexture2D.new()
	_bg.gradient = g
	_bg.fill = GradientTexture2D.FILL_RADIAL
	_bg.fill_from = Vector2(0.48, 0.55)
	_bg.fill_to = Vector2(1.1, 1.0)
	_bg.width = 256
	_bg.height = 144


func open(party: Array[Combatant], index := 0) -> void:
	_party = party
	_member = clampi(index, 0, maxi(party.size() - 1, 0))
	_move = 0
	_detail_open = false
	visible = true
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		for f in _faces:
			f.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("menu"):
		if _detail_open:
			_detail_open = false
		else:
			visible = false
			closed.emit()
	elif _detail_open:
		if event.is_action_pressed("confirm"):
			_detail_open = false
		else:
			return
	elif event.is_action_pressed("ui_up"):
		_member = posmod(_member - 1, _party.size())
		_move = 0
	elif event.is_action_pressed("ui_down"):
		_member = posmod(_member + 1, _party.size())
		_move = 0
	elif event.is_action_pressed("ui_left"):
		_move = posmod(_move - 1, _moves(_party[_member]).size())
	elif event.is_action_pressed("ui_right"):
		_move = posmod(_move + 1, _moves(_party[_member]).size())
	elif event.is_action_pressed("confirm"):
		_detail_open = true
	else:
		return
	queue_redraw()
	get_viewport().set_input_as_handled()


func _moves(c: Combatant) -> Array[Skill]:
	var list: Array[Skill] = [Skill.basic()]
	list.append_array(c.skills)
	return list


func _art(c: Combatant) -> Texture2D:
	var key := c.name.to_lower()
	if not _art_cache.has(key):
		var path := ART_DIR + key + ".png"
		_art_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[key]


func _face(c: Combatant) -> Texture2D:
	var path := FACE_DIR + c.name.to_lower() + ".png"
	return load(path) if ResourceLoader.exists(path) else null


# --- Drawing helpers --------------------------------------------------------------

func _slant(r: Rect2, skew: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)


func _text(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_right(font: Font, right_x: float, y: float, text: String, size: int, color: Color) -> void:
	BattleHud.text_right(self, font, right_x, y, text, size, color)


func _draw() -> void:
	if _party.is_empty():
		return
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var c := _party[_member]
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false)
	_draw_spires()
	draw_rect(Rect2(0, 0, size.x * 0.25, 3), LIME)
	draw_rect(Rect2(size.x * 0.25, 0, size.x * 0.17, 3), CORAL)
	# Header.
	_text(title, Vector2(29, 56), "CRAWL", 40, PAPER)
	var w := title.get_string_size("CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	_text(title, Vector2(29 + w, 56), "/", 44, CORAL)
	_text(title, Vector2(29 + w + 16, 56), "MON", 40, LIME)
	_slant(Rect2(250, 28, 190, 36), 8.0, Color(0.035, 0.105, 0.17, 0.9))
	draw_rect(Rect2(250, 28, 4, 36), LIME)
	_text(title, Vector2(266, 46), "STATUS // EQUIPE", 16, PAPER)
	_text(body, Vector2(266, 59), "FORA DE COMBATE", 9, GOLD)
	_draw_roster()
	_draw_art(c)
	_draw_panel(c)
	_draw_moves(c)
	# Footer.
	draw_rect(Rect2(0, size.y - 28, size.x, 28), Color(0.012, 0.047, 0.086, 0.95))
	draw_rect(Rect2(0, size.y - 28, size.x, 1), Color("365365"))
	_text(body, Vector2(29, size.y - 10), "↑ ↓  PERSONAGEM   ·   ← →  GOLPES   ·   Z  DETALHES   ·   X  FECHAR", 10, Color("b2c5cb"))
	_text_right(body, size.x - 29, size.y - 10, "CRAWLMON // STATUS", 10, GOLD)
	if _detail_open:
		_draw_detail(c)


func _draw_spires() -> void:
	for i in 12:
		var h := 104.0 + float((i * 67) % 250) * 0.8
		var x := i * 114.0 + 20.0
		var base := size.y - 78.0 * 0.8 - 28.0
		var col := Color(0.11, 0.25, 0.3, 0.38)
		draw_rect(Rect2(x, base - h, 27, h), col)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, base - h), Vector2(x + 33, base - h), Vector2(x + 27, base - h - 10), Vector2(x, base - h - 10)]), Color(0.11, 0.27, 0.35, 0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 13.5, base - h - 40), Vector2(x + 27, base - h - 10), Vector2(x, base - h - 10)]), Color(0.06, 0.16, 0.22, 0.4))
		draw_circle(Vector2(x + 13.5, base - h - 46), 4.0, Color(0.96, 0.84, 0.56, 0.5))


func _draw_roster() -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	_text(body, Vector2(29, 100), "EQUIPE // %d POKÉMON" % _party.size(), 11, LIME)
	draw_rect(Rect2(29, 105, 276, 2), Color(LIME, 0.35))
	for i in _party.size():
		var u := _party[i]
		var on := i == _member
		var r := Rect2(29 + (6.0 if on else 0.0), 116 + i * 74.0, 276, 66)
		_slant(Rect2(r.position + Vector2(4, 5), r.size), 8.0, Color(0.016, 0.05, 0.086, 0.65))
		_slant(r, 8.0, Color("fdfde8") if on else PAPER)
		if on:
			draw_rect(Rect2(r.position.x, r.position.y, 7, r.size.y), LIME)
		var face := Rect2(r.position.x + 14, r.position.y + 10, 46, 46)
		draw_rect(face, Color(0.07, 0.145, 0.21))
		var tex := _face(u)
		_place_face(i, tex, face.grow(-2))
		draw_rect(face, Color(0.137, 0.25, 0.34), false, 2.0)
		var tx := r.position.x + 70
		_text(title, Vector2(tx, r.position.y + 28), u.name.to_upper(), 20, Color("0a1a27"))
		_text_right(body, r.end.x - 14, r.position.y + 26, "NV. —", 10, Color("536f80"))
		_stat_bar(Vector2(tx, r.position.y + 38), 128.0, "HP", float(u.hp) / u.max_hp, CORAL, "%d/%d" % [u.hp, u.max_hp], r.end.x - 14)
		_stat_bar(Vector2(tx, r.position.y + 52), 128.0, "MP", 0.0, Color("5f88f5"), "N/D", r.end.x - 14)


## Portraits are TextureRect children (drawn above this control's own drawing).
func _place_face(i: int, tex: Texture2D, rect: Rect2) -> void:
	while _faces.size() <= i:
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(tr)
		_faces.append(tr)
	var face_rect := _faces[i]
	face_rect.texture = tex
	face_rect.position = rect.position
	face_rect.size = rect.size
	face_rect.visible = tex != null


func _stat_bar(pos: Vector2, w: float, label: String, k: float, color: Color, value: String, right_x: float) -> void:
	var body := FanMenu.body_font()
	_text(body, Vector2(pos.x, pos.y + 6), label, 9, Color("6b8290"))
	var track := Rect2(pos.x + 18, pos.y, w, 6)
	draw_rect(track, Color("abbdc6"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(k, 0.0, 1.0), track.size.y)), color)
	_text_right(body, right_x, pos.y + 7, value, 9, Color("183040"))


func _draw_art(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	# Red diagonal strike behind the art.
	var box := Rect2(384, 84, 352, 464)
	var center := box.get_center()
	draw_set_transform(center, deg_to_rad(-11.0), Vector2.ONE)
	var pts := PackedVector2Array([
		Vector2(-box.size.x * 0.5 + box.size.x * 0.32, -box.size.y * 0.5), Vector2(-box.size.x * 0.5 + box.size.x * 0.94, -box.size.y * 0.5),
		Vector2(-box.size.x * 0.5 + box.size.x * 0.68, box.size.y * 0.5), Vector2(-box.size.x * 0.5, box.size.y * 0.5)])
	var cols := PackedColorArray([Color(0.98, 0.4, 0.37, 0.66), Color(0.98, 0.4, 0.37, 0.66), Color(0.6, 0.2, 0.24, 0.72), Color(0.6, 0.2, 0.24, 0.72)])
	draw_polygon(pts, cols)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var art := _art(c)
	var area := Rect2(336, 68, 488, 504)
	if art != null:
		var s := minf(area.size.x / art.get_width(), area.size.y / art.get_height())
		var sz := Vector2(art.get_width(), art.get_height()) * s
		var pos := area.position + (area.size - sz) * 0.5
		draw_texture_rect(art, Rect2(pos + Vector2(10, 14), sz), false, Color(0, 0, 0, 0.35))
		draw_texture_rect(art, Rect2(pos, sz), false)
	else:
		_text(title, Vector2(area.position.x + 130, area.get_center().y), c.name.to_upper(), 44, Color(1, 1, 1, 0.25))
	var role := "JOGADOR // LÍDER" if c == _party[0] else "ALIADO // CONTROLADO POR IA"
	var tag_w := body.get_string_size("◆ " + role, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 34.0
	draw_rect(Rect2(352, 548, tag_w, 28), Color(0.027, 0.11, 0.17, 0.92))
	draw_rect(Rect2(352, 548, 4, 28), CORAL)
	_text(title, Vector2(366, 568), "◆ " + role, 15, PAPER)


func _draw_panel(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var x := 848.0
	var w := 403.0
	var y := 82.0
	var is_leader := c == _party[0]
	_slant(Rect2(x, y, 168, 16), 5.0, Color(0.027, 0.11, 0.17))
	draw_rect(Rect2(x, y, 3, 16), CORAL)
	_text(body, Vector2(x + 10, y + 12), "PROTAGONISTA" if is_leader else "ALIADO", 9, LIME)
	_text(title, Vector2(x, y + 62), c.name.to_upper(), 50, PAPER)
	# Level / EXP (not tracked yet).
	var lv := Rect2(x, y + 82, w, 56)
	draw_rect(lv, Color(0.035, 0.12, 0.17, 0.86))
	draw_rect(lv, Color("4f7387"), false, 1.0)
	_text(body, Vector2(x + 14, y + 107), "NÍVEL", 11, PAPER)
	_text(title, Vector2(x + 66, y + 112), "—", 28, Color(LIME, 0.6))
	_text_right(body, lv.end.x - 14, y + 105, "EXP  N/D", 10, Color("9ec0cc"))
	draw_rect(Rect2(x + 14, y + 120, w - 28, 8), Color("355060"))
	# Combat bars + stats.
	var sy := y + 152
	var pw := w * 0.6
	_slant(Rect2(x, sy, pw, 122), 6.0, PAPER)
	_text(body, Vector2(x + 14, sy + 20), "BARRAS DE COMBATE", 10, Color("0e2435"))
	_panel_bar(x + 14, sy + 38, pw - 28, "HP", float(c.hp) / c.max_hp, CORAL, "%d / %d" % [c.hp, c.max_hp])
	_panel_bar(x + 14, sy + 62, pw - 28, "MP", 0.0, Color("5f86f5"), "N/D")
	_text(body, Vector2(x + 14, sy + 100), "ATB", 11, Color("0a1a27"))
	for i in int(Combatant.BLOCKS):
		_slant(Rect2(x + 52 + i * 24, sy + 90, 21, 11), 3.0, Color("138cb5"))
	_text_right(body, x + pw - 14, sy + 100, "5 BLOCOS", 9, Color("0a1a27"))
	var sx := x + pw + 8
	var sw := w - pw - 8
	draw_rect(Rect2(sx, sy, sw, 122), Color(0.03, 0.1, 0.17, 0.92))
	draw_rect(Rect2(sx, sy, sw, 122), Color(0.4, 0.54, 0.58, 0.45), false, 1.0)
	var weak := c.weakness_text()
	var rows := [["ATK", str(c.attack), Color.WHITE], ["DEF", "N/D", Color(1, 1, 1, 0.45)], ["VEL", "%.2f" % c.speed, Color.WHITE], ["FRAQ.", weak if weak != "" else "—", CORAL]]
	for i in rows.size():
		var ry := sy + 22 + i * 26.0
		_text(body, Vector2(sx + 10, ry), rows[i][0], 10, Color("8ea9b5"))
		_text_right(body, sx + sw - 10, ry, rows[i][1], 10 if i == 3 else 12, rows[i][2])
		if i < rows.size() - 1:
			draw_rect(Rect2(sx + 8, ry + 8, sw - 16, 1), Color(0.53, 0.65, 0.69, 0.22))
	# Passive ability (not in the game yet).
	var ay := sy + 136
	draw_rect(Rect2(x, ay, w, 62), Color(0.03, 0.105, 0.17, 0.88))
	draw_rect(Rect2(x, ay, 6, 62), VIOLET)
	_text(body, Vector2(x + 16, ay + 22), "PASSIVA", 9, VIOLET)
	_text(title, Vector2(x + 76, ay + 24), "SEM HABILIDADE", 18, Color(PAPER, 0.7))
	_text(body, Vector2(x + 16, ay + 46), "O jogo ainda não tem habilidades passivas (N/D).", 10, Color("c1d3d8"))


func _panel_bar(x: float, y: float, w: float, label: String, k: float, color: Color, value: String) -> void:
	var body := FanMenu.body_font()
	_text(body, Vector2(x, y + 8), label, 11, Color("0a1a27"))
	var track := Rect2(x + 36, y, w - 36 - 70, 9)
	draw_rect(track, Color("8d9caa"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(k, 0.0, 1.0), track.size.y)), color)
	_text_right(body, x + w, y + 9, value, 10, Color("0a1a27"))


func _draw_moves(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var list := _moves(c)
	var top := 586.0
	_text(body, Vector2(29, top - 6), "GOLPES // TACKLE + %d EQUIPADOS" % c.skills.size(), 10, LIME)
	_text_right(body, size.x - 29, top - 6, "Z  PARA DETALHES", 10, Color("8ea7b0"))
	draw_rect(Rect2(29, top - 2, size.x - 58, 2), Color(LIME, 0.35))
	var gap := 7.0
	var cw := (size.x - 58 - gap * (list.size() - 1)) / list.size()
	for i in list.size():
		var m := list[i]
		var on := i == _move
		var r := Rect2(29 + i * (cw + gap), top + 6, cw, 82)
		_slant(r, 6.0, Color("1d465c") if on else Color(0.055, 0.19, 0.255, 0.95))
		draw_rect(r, LIME if on else Color("4e7386"), false, 2.0 if on else 1.0)
		var col: Color = BattleFx.COLORS[m.element]
		_slant(Rect2(r.position.x + 14, r.position.y + 10, 32, 30), 5.0, col)
		_text(title, Vector2(r.position.x + 24, r.position.y + 32), Element.name_of(m.element).substr(0, 1), 18, Color("0a1926"))
		_text(title, Vector2(r.position.x + 54, r.position.y + 24), m.display_name.to_upper(), 15, Color.WHITE)
		_slant(Rect2(r.position.x + 54, r.position.y + 30, 44, 15), 3.0, Color(LIME, 0.18))
		_text(body, Vector2(r.position.x + 59, r.position.y + 41), "%d ATB" % m.cost, 9, LIME)
		_slant(Rect2(r.position.x + 102, r.position.y + 30, r.size.x - 116, 15), 3.0, Color("142738"))
		_text(body, Vector2(r.position.x + 107, r.position.y + 41), Element.name_of(m.element).to_upper(), 9, Color("a6c5d1"))
		draw_rect(Rect2(r.position.x + 14, r.position.y + 52, r.size.x - 34, 1), Color(0.33, 0.45, 0.5, 0.5))
		_text(body, Vector2(r.position.x + 14, r.position.y + 70), "Poder ×%s" % String.num(m.power, 1).replace(".", ","), 11, Color("cbdbe0"))


func _draw_detail(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var m := _moves(c)[_move]
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.016, 0.063, 0.106, 0.88))
	var r := Rect2((size.x - 450) * 0.5, 150, 450, 300)
	_slant(Rect2(r.position + Vector2(10, 10), r.size), 10.0, Color(0.008, 0.03, 0.06, 0.9))
	_slant(r, 10.0, Color("0e2a3b"))
	draw_polyline(PackedVector2Array([
		Vector2(r.position.x + 10, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - 10, r.end.y),
		Vector2(r.position.x, r.end.y), Vector2(r.position.x + 10, r.position.y)]), LIME, 2.0)
	_text(body, Vector2(r.position.x + 28, r.position.y + 36), "GOLPE // DETALHES", 11, LIME)
	_text(title, Vector2(r.position.x + 28, r.position.y + 84), m.display_name.to_upper(), 38, PAPER)
	var lines := [
		"Custo de ATB:   %d bloco(s)" % m.cost,
		"Elemento:   %s" % Element.name_of(m.element),
		"Poder:   ×%s do ataque de %s" % [String.num(m.power, 1).replace(".", ","), c.name],
		"Descrição:   N/D",
	]
	for i in lines.size():
		_text(body, Vector2(r.position.x + 28, r.position.y + 128 + i * 28.0), lines[i], 14, Color("e1edf0"))
	_slant(Rect2(r.position.x + 28, r.end.y - 52, 130, 32), 6.0, LIME)
	_text(title, Vector2(r.position.x + 42, r.end.y - 29), "FECHAR (Z / X)", 16, Color("0a1a24"))
