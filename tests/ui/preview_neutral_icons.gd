extends SceneTree

const TITLE_FONT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1000, 620)

	var node := NeutralPreviewNode.new()
	node.size = Vector2(1000, 620)
	root.add_child(node)

	for i in 6:
		await process_frame

	var img := root.get_texture().get_image()
	img.save_png("test_captures/proposal_neutral_and_attacktag.png")
	img.save_png("C:/Users/zerke/.gemini/antigravity/brain/5135076f-0d88-4cc9-ae60-db4b51931cfb/proposal_neutral_and_attacktag.png")
	print("Preview saved successfully!")
	quit(0)


class NeutralPreviewNode extends Control:
	var font: Font
	var title_font: Font
	var opt_a: Texture2D
	var opt_b: Texture2D
	var opt_c: Texture2D
	var ic_type: Texture2D
	var ic_range: Texture2D

	func _init() -> void:
		font = SystemFont.new()
		font.font_names = PackedStringArray(["Arial", "Segoe UI"])
		font.font_weight = 800
		title_font = TITLE_FONT
		var ia := Image.load_from_file(ProjectSettings.globalize_path("res://scratch/svg_options/opt_a_fist.svg"))
		if ia != null:
			opt_a = ImageTexture.create_from_image(ia)
		var ib := Image.load_from_file(ProjectSettings.globalize_path("res://scratch/svg_options/opt_b_kinetic.svg"))
		if ib != null:
			opt_b = ImageTexture.create_from_image(ib)
		var ic := Image.load_from_file(ProjectSettings.globalize_path("res://scratch/svg_options/opt_c_diamond.svg"))
		if ic != null:
			opt_c = ImageTexture.create_from_image(ic)
		ic_type = load("res://assets/ui/icons/move_types/physical.svg")
		ic_range = load("res://assets/ui/icons/range/melee.svg")

	func _draw() -> void:
		# Background
		draw_rect(Rect2(0, 0, size.x, size.y), Color("080e18"))

		# Title bar
		draw_rect(Rect2(0, 0, size.x, 48), Color("0d1824"))
		draw_rect(Rect2(0, 0, size.x, 3), Color("d7fd6a"))
		draw_string(title_font, Vector2(24, 32), "PROPOSTAS DE GLIFO NEUTRAL / PHYSICAL & ATTACKTAG UNKNOWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d7fd6a"))

		# SECTION 1: 3 Options for Neutral Element Icon
		draw_string(title_font, Vector2(24, 75), "PARTE 1: NOVAS OPCOES DE GLIFO PARA O ELEMENTO NEUTRAL (SUBSTITUINDO O CIRCULO LISO)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

		var opts := [
			{"name": "OPCAO A: IMPACT FIST", "desc": "Punho de impacto cerrado neo-brutalista (combate corpo-a-corpo / forca fisica pura)", "tex": opt_a},
			{"name": "OPCAO B: KINETIC SHOCKWAVE", "desc": "Onda de choque cinetica com nucleo concentrico (impacto neutro / energia fisica)", "tex": opt_b},
			{"name": "OPCAO C: DIAMOND CORE", "desc": "Losango chanfrado angular com nucleo central (insignia geometrica pura)", "tex": opt_c}
		]

		var col_w := 300.0
		var start_x := 30.0
		var start_y := 95.0

		for idx in opts.size():
			var o: Dictionary = opts[idx]
			var x: float = start_x + float(idx) * (col_w + 20.0)
			var y: float = start_y
			var tex: Texture2D = o["tex"]

			# Card container
			draw_rect(Rect2(x, y, col_w, 240), Color("0d1824"))
			draw_rect(Rect2(x, y, col_w, 240), Color("1e293b"), false, 1.0)
			draw_rect(Rect2(x, y, col_w, 24), Color("1e293b"))
			draw_string(font, Vector2(x + 10, y + 17), o["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d7fd6a"))

			# Large showcase (48x48)
			draw_rect(Rect2(x + 16, y + 36, 56, 56), Color("cbd5e1"))
			if tex != null:
				draw_texture_rect(tex, Rect2(x + 20, y + 40, 48, 48), false, Color("080e18"))
			draw_string(font, Vector2(x + 82, y + 54), "Escala 48px", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("94a3b8"))
			draw_string(font, Vector2(x + 82, y + 72), "(Marca d'agua)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("64748b"))

			# Mini badges showcase (17px e 13px)
			draw_string(font, Vector2(x + 16, y + 112), "Mini Badge (17px):", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("94a3b8"))
			_draw_para(Rect2(x + 120, y + 100, 19, 19), 2.0, Color(0, 0, 0, 0.55))
			if tex != null:
				draw_texture_rect(tex, Rect2(x + 122, y + 102, 15, 15), false, Color("cbd5e1"))

			draw_string(font, Vector2(x + 160, y + 112), "Drawer (13px):", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("94a3b8"))
			draw_rect(Rect2(x + 245, y + 102, 14, 14), Color(0, 0, 0, 0.55))
			if tex != null:
				draw_texture_rect(tex, Rect2(x + 246, y + 103, 12, 12), false, Color("cbd5e1"))

			# Simulated SkillInfoPanel Header with this glyph
			var hdr_y := y + 132.0
			draw_string(font, Vector2(x + 16, hdr_y - 4), "Exemplo no cabecalho do Tackle:", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("64748b"))
			_draw_para(Rect2(x + 10, hdr_y + 2, col_w - 20, 36), 6.0, Color("cbd5e1"))
			# Watermark
			if tex != null:
				draw_texture_rect(tex, Rect2(x + col_w - 52, hdr_y - 2, 44, 44), false, Color(1, 1, 1, 0.25))
			# Title
			draw_string(title_font, Vector2(x + 20, hdr_y + 25), "TACKLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("080e18"))
			var bx := x + 88.0
			# Badge 1: Element
			_draw_para(Rect2(bx, hdr_y + 10, 17, 17), 2.0, Color(0, 0, 0, 0.55))
			if tex != null:
				draw_texture_rect(tex, Rect2(bx + 2, hdr_y + 12, 13, 13), false, Color("cbd5e1"))
			bx += 21.0
			# Badge 2: Type (Physical)
			_draw_para(Rect2(bx, hdr_y + 10, 17, 17), 2.0, Color("ef4444"))
			if ic_type != null:
				draw_texture_rect(ic_type, Rect2(bx + 2, hdr_y + 12, 13, 13), false, Color.WHITE)
			bx += 21.0
			# Badge 3: Range (Melee)
			_draw_para(Rect2(bx, hdr_y + 10, 17, 17), 2.0, Color.WHITE)
			if ic_range != null:
				draw_texture_rect(ic_range, Rect2(bx + 2, hdr_y + 12, 13, 13), false, Color("080e18"))

			# Description text below
			_draw_wrapped(font, Vector2(x + 12, y + 192), o["desc"], col_w - 24, 10, 3.0, Color("94a3b8"))

		# SECTION 2: ATTACKTAG (KNOWN vs UNKNOWN)
		var sec2_y := 370.0
		draw_line(Vector2(30, sec2_y - 15), Vector2(size.x - 30, sec2_y - 15), Color("1e293b"), 1.0)
		draw_string(title_font, Vector2(24, sec2_y), "PARTE 2: COMPORTAMENTO DO ATTACKTAG (AVISO DE ATAQUE INIMIGO)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		draw_string(font, Vector2(24, sec2_y + 18), "Como a regra de Descoberta (Unknown '?') se aplica quando um inimigo inicia um golpe:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("94a3b8"))

		# Tag 1: INIMIGO CONHECIDO (Elemento revelado - Ex: Pancham usando Tackle)
		var t1_x := 40.0
		var t1_y := sec2_y + 35.0
		draw_string(font, Vector2(t1_x, t1_y - 6), "CASO 1: Inimigo CONHECIDO (Mostra cor e marca d'agua oficial)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("4ade80"))
		_draw_sample_attack_tag(Vector2(t1_x, t1_y), "TACKLE", Color("cbd5e1"), Color("080e18"), opt_a, "PANCHAM", false)

		# Tag 2: INIMIGO DESCONHECIDO (Unknown - Fundo escuro/neutro + bloco '?')
		var t2_x := 380.0
		var t2_y := sec2_y + 35.0
		draw_string(font, Vector2(t2_x, t2_y - 6), "CASO 2: Inimigo DESCONHECIDO (Fundo neutro + bloco '?' - Nao da spoiler)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f59e0b"))
		_draw_sample_attack_tag(Vector2(t2_x, t2_y), "TACKLE", Color("1e293b"), Color("f8fafc"), null, "GIBLE", true)

		# Explanatory side note
		var note_x := 720.0
		var note_y := sec2_y + 30.0
		draw_rect(Rect2(note_x, note_y, 250, 110), Color("0d1824"))
		draw_rect(Rect2(note_x, note_y, 250, 110), Color("334155"), false, 1.0)
		draw_string(title_font, Vector2(note_x + 12, note_y + 20), "REGRAS DO ATTACKTAG", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d7fd6a"))
		var notes := [
			"- Mantem apenas 2 icones: Tipo e Alcance.",
			"- Se inimigo DESCONHECIDO (D-981):",
			"  fundo fica neutro/escuro e canto direito",
			"  mostra bloco com '?' (sem spoiler de cor).",
			"- Se CONHECIDO: fundo ganha a cor do move",
			"  e a marca d'agua do elemento revelado."
		]
		var ny := note_y + 36.0
		for l in notes:
			draw_string(font, Vector2(note_x + 12, ny), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("cbd5e1"))
			ny += 13.0

	func _draw_para(r: Rect2, skew: float, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			Vector2(r.position.x + skew, r.position.y),
			Vector2(r.end.x + skew, r.position.y),
			Vector2(r.end.x, r.end.y),
			Vector2(r.position.x, r.end.y)
		]), col)

	func _draw_sample_attack_tag(pos: Vector2, move_name: String, bg_col: Color, fg_col: Color, wm_tex: Texture2D, target_name: String, is_unknown: bool) -> void:
		var sz := Vector2(250, 48)
		_draw_para(Rect2(pos + Vector2(3, 3), sz), 6.0, Color(0, 0, 0, 0.4))
		_draw_para(Rect2(pos, sz), 6.0, bg_col)

		if is_unknown:
			# Unknown badge on the right: White slanted block with black '?'
			var qr := Rect2(pos.x + sz.x - 32, pos.y + 6, 20, 20)
			_draw_para(qr, 3.0, Color.WHITE)
			draw_string(font, Vector2(qr.position.x + 6, qr.position.y + 15), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)
		elif wm_tex != null:
			draw_texture_rect(wm_tex, Rect2(pos.x + sz.x - 38, pos.y + 4, 34, 34), false, Color(fg_col, 0.20))

		# Move name
		draw_string(title_font, Vector2(pos.x + 14, pos.y + 24), move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, fg_col)
		var nw := title_font.get_string_size(move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x

		# Type & Range icons (D-985)
		var ix := pos.x + 14.0 + nw + 8.0
		if ic_type != null:
			draw_texture_rect(ic_type, Rect2(ix, pos.y + 11, 14, 14), false, Color("ef4444") if is_unknown else fg_col)
		ix += 18.0
		if ic_range != null:
			draw_texture_rect(ic_range, Rect2(ix, pos.y + 11, 14, 14), false, fg_col)

		# Target name
		draw_string(font, Vector2(pos.x + 16, pos.y + 40), "> %s" % target_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(fg_col, 0.75))

		# Countdown bar below
		var bar := Rect2(pos.x + 6, pos.y + 50, sz.x - 40, 6)
		_draw_para(bar, 2.0, Color(0.04, 0.08, 0.12, 0.85))
		_draw_para(Rect2(bar.position, Vector2(bar.size.x * 0.65, bar.size.y)), 2.0, Color("ff624f"))
		draw_string(font, Vector2(pos.x + sz.x - 30, pos.y + 56), "1.2s", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("cbd5e1"))

	func _draw_wrapped(f: Font, pos: Vector2, text: String, max_w: float, fsz: int, spacing: float, col: Color) -> void:
		var words := text.split(" ")
		var cur := ""
		var y := pos.y
		for w in words:
			var test := cur + (" " if cur != "" else "") + w
			if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x > max_w and cur != "":
				draw_string(f, Vector2(pos.x, y), cur, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, col)
				y += float(fsz) + spacing
				cur = w
			else:
				cur = test
		if cur != "":
			draw_string(f, Vector2(pos.x, y), cur, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, col)
