extends SceneTree
## 3D visual lab for the shield-value indicator. Three different proposals,
## each shown on the player's character (near) and the opponent (far).
## Run windowed with a movie:
##   Godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie out.avi \
##     --script res://tests/vfx/shield_value_lab.gd
## Visual lab only: it does not change the game HUD.

const FPS := 30
const SEGMENT := 4.0
const RING_SHADER = preload("res://shaders/proto/shield_ring.gdshader")
const PANEL_SHADER = preload("res://shaders/proto/shield_panel.gdshader")
const GUARD_ICON = preload("res://assets/ui/icons/move_types/guard.svg")
const NUMBER_FONT = preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")
const PORTRAIT_OVERLAY = preload("res://tests/vfx/shield_portrait_overlay.gd")

var bs: Node3D
var battle: Battle
var cam: Camera3D
var ally: Combatant
var enemy: Combatant
var ally_model: Node3D
var enemy_model: Node3D
var targets: Array[Combatant] = []
var title_font: Font
var body_font: Font
var indicator_sets: Array = [[], [], []]  ## [option][target] -> data
var values: Array[int] = [34, 28]
var max_values: Array[int] = [34, 28]
var labels: Dictionary = {}
var b_only := false
var combat := false
var no_shield := false
var portrait := false
var seconds := 12.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	b_only = OS.get_cmdline_user_args().has("--b-only")
	combat = OS.get_cmdline_user_args().has("--combat")
	no_shield = OS.get_cmdline_user_args().has("--no-shield")
	portrait = OS.get_cmdline_user_args().has("--portrait")
	var has_seconds := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.substr(10))
			has_seconds = true
	if combat and not has_seconds:
		seconds = 30.0
	title_font = FanMenu.title_font()
	body_font = FanMenu.body_font()
	bs = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	root.add_child(bs)
	battle = bs.get_node("Battle")
	if not combat and bs.models != null:
		for c in bs.models.keys():
			c.act_policy = Combatant.Act.HOLD
			c.react_policy = Combatant.React.NONE
	var guard := 0
	while not battle.running and guard < 1200:
		await process_frame
		guard += 1
	# D-1010/D-1033: the HUD, the cards and the menu stay on; the shield value is
	# judged in the real battle context, never on an empty screen.
	bs.hud.visible = true
	if not combat:
		bs.director.set_process(false)
	cam = bs.get_node("Camera3D")
	cam.current = true
	ally = battle.party[0]
	enemy = battle.enemies[0]
	ally_model = bs.models[ally]
	enemy_model = bs.models[enemy]
	targets.clear()
	max_values.clear()
	values.clear()
	if combat:
		# Real combat (debug scene): everyone gets a shield, the AI fights, and
		# the overlay reads the real shield_hp/shield_max every frame.
		if battle.enemies.size() == 1:
			bs._debug_add_test_enemies()
		for c in battle.party:
			targets.append(c)
		for c in battle.enemies:
			targets.append(c)
		# Known game VFX gap (MYSTIC color) would spam errors and drop the hit
		# effect; the capture is about the shield HUD, so MYSTIC moves are out.
		for c in targets:
			var keep: Array[Skill] = []
			for sk in c.skills:
				if sk.element != Element.Type.MYSTIC:
					keep.append(sk)
			c.skills = keep
		battle.debug_roll = 1  # guaranteed hit, no crit: the shields actually drain
		if no_shield:
			for c in targets:
				max_values.append(1)
				values.append(0)
		else:
			for c in targets:
				var mx := maxi(30, int(c.max_hp))
				c.apply_shield(mx, 45.0)
				max_values.append(mx)
				values.append(mx)
	else:
		targets.append(ally)
		for e in battle.enemies:
			targets.append(e)
		var enemy_max := [28, 22, 18]
		max_values = [34]
		values = [34]
		for i in battle.enemies.size():
			max_values.append(enemy_max[mini(i, enemy_max.size() - 1)])
			values.append(max_values[max_values.size() - 1])
		for i in targets.size():
			targets[i].apply_shield(max_values[i], 13.0)
	if portrait and combat:
		bs.hud.hide_shield_badges = true
		var ov := PORTRAIT_OVERLAY.new()
		ov.battle = battle
		ov.hud = bs.hud
		ov.number_font = NUMBER_FONT
		bs.hud.add_child(ov)
	else:
		_build_indicators()
	_build_labels()
	await process_frame
	await process_frame
	var frames := int(seconds * FPS)
	for f in frames:
		_animate(float(f) / float(FPS))
		await process_frame
	quit(0)


func _build_indicators() -> void:
	for opt in 3:
		for ti in targets.size():
			var target: Combatant = targets[ti]
			var data: Dictionary
			match opt:
				0:
					data = _make_badge(ti)
				1:
					data = _make_ring(ti)
				2:
					data = _make_panel(ti)
			data["target"] = target
			data["target_index"] = ti
			data["node"].visible = false
			bs.add_child(data["node"])
			indicator_sets[opt].append(data)


func _head_pos(target: Combatant) -> Vector3:
	var m: Node3D = bs.models.get(target)
	if m == null or not is_instance_valid(m):
		return Vector3.ZERO
	# The HUD anchors its own tags on the model origin + head height (head_y), which
	# stays on the body's centre; the bubble envelope includes the tail and would
	# push the indicator sideways (D-235: derive from the real model, not a fixed spot).
	var head_y := 2.0
	if m.has_meta("head_y"):
		head_y = float(m.get_meta("head_y"))
	return m.global_position + Vector3.UP * head_y


func _cam_right() -> Vector3:
	var b := cam.global_transform.basis
	return b.x.normalized()


## Screen anchor of the indicator: above the combatant's own HUD card/tag. The
## leader and the enemies stay on the right edge; the other allies use the left
## edge of their card (creator's request), so the ring stays away from the screen edge.
func _anchor_pos(target: Combatant, _ti: int, head: Vector3, s: float, side_k: float, up_k: float) -> Vector3:
	var screen: Variant = _anchor_screen(target)
	if screen != null:
		var sp: Vector2 = screen
		var depth := cam.global_position.distance_to(head)
		return cam.project_position(sp, depth)
	return head + _cam_right() * (side_k * s) + Vector3(0, up_k * s, 0)


func _anchor_screen(target: Combatant) -> Variant:
	var tag: Control = bs.hud._tags.get(target)
	if tag != null:
		# Enemy: beside the model, below the tag's portrait (not above the tag).
		var r := tag.get_global_rect()
		return Vector2(clampf(r.position.x + 22.0, 46.0, 1234.0), r.end.y + 39.0)
	for c in bs.hud._cards:
		if c.combatant == target:
			var r: Rect2 = c.get_global_rect()
			var x: float = (r.end.x + 2.0) if c.hero else (r.position.x - 2.0)
			return Vector2(clampf(x, 46.0, 1234.0), r.position.y - 56.0)
	return null


# --- Option A: floating badge ------------------------------------------------

func _make_badge(ti: int) -> Dictionary:
	var g := Node3D.new()
	g.name = "ShieldBadge_%d" % ti
	var vp := SubViewport.new()
	vp.size = Vector2i(260, 110)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var painter := BadgePainter.new()
	painter.value = values[ti]
	painter.max_value = max_values[ti]
	painter.title_font = title_font
	painter.body_font = body_font
	painter.icon = GUARD_ICON
	painter.size = Vector2(260, 110)
	vp.add_child(painter)
	g.add_child(vp)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.85, 0.36)
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = vp.get_texture()
	mat.albedo_color = Color.WHITE
	mat.no_depth_test = true
	mat.render_priority = 20
	mi.material_override = mat
	g.add_child(mi)
	return {"node": g, "painter": painter, "quad": mi, "kind": 0, "pop": 0.0}


# --- Option B: shield ring ---------------------------------------------------

func _make_ring(ti: int) -> Dictionary:
	var g := Node3D.new()
	g.name = "ShieldRing_%d" % ti
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.276
	tm.outer_radius = 0.3105
	tm.rings = 64
	tm.ring_segments = 12
	ring.mesh = tm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.rotation.x = PI * 0.5
	var rm := ShaderMaterial.new()
	rm.shader = RING_SHADER
	rm.set_shader_parameter("fill", 1.0)
	rm.set_shader_parameter("pulse", 0.0)
	ring.material_override = rm
	var pivot := Node3D.new()
	pivot.add_child(ring)
	g.add_child(pivot)

	# Expanding shock ring on every value change (more motion, still readable).
	var wave := MeshInstance3D.new()
	var wm := TorusMesh.new()
	wm.inner_radius = 0.281
	wm.outer_radius = 0.298
	wm.rings = 64
	wm.ring_segments = 8
	wave.mesh = wm
	wave.rotation.x = PI * 0.5
	wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wmat := StandardMaterial3D.new()
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wmat.albedo_color = Color(0.35, 0.85, 1.0, 0.0)
	wmat.no_depth_test = true
	wmat.render_priority = 32
	wave.material_override = wmat
	pivot.add_child(wave)

	# The number is a manual billboard so it can lean; `fixed_size` still keeps
	# the same pixel size near and far. Kanit Black Italic + the thick outline
	# follow the damage-number look (D-235: no character/side dependency).
	var num := _label3d(str(values[ti]), 23, Color.WHITE)
	num.font = NUMBER_FONT
	num.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	num.position = Vector3.ZERO
	g.add_child(num)

	var icon := _icon_quad(0.121)
	icon.position = Vector3(-0.3105, 0.3105, 0.0)
	g.add_child(icon)

	return {"node": g, "ring": ring, "ring_pivot": pivot, "ring_mat": rm, "wave": wave, "wave_mat": wmat, "num": num, "icon": icon, "kind": 1, "pop": 0.0}


# --- Option C: barrier panel -------------------------------------------------

func _make_panel(ti: int) -> Dictionary:
	var g := Node3D.new()
	g.name = "ShieldPanel_%d" % ti
	var visual := Node3D.new()
	g.add_child(visual)
	var panel := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 0.64)
	panel.mesh = q
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ShaderMaterial.new()
	pm.shader = PANEL_SHADER
	pm.set_shader_parameter("alpha", 0.30)
	pm.set_shader_parameter("pulse", 0.0)
	panel.material_override = pm
	visual.add_child(panel)

	var segs: Array = []
	for i in 3:
		var seg := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(0.85, 0.06)
		seg.mesh = sq
		seg.position = Vector3(0, -0.10 - float(i) * 0.07, 0.012)
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.albedo_color = Color(0.30, 0.78, 1.0, 0.75)
		seg.material_override = sm
		visual.add_child(seg)
		segs.append({"node": seg, "mat": sm})

	var num := _label3d(str(values[ti]), 28, Color.WHITE)
	num.position = Vector3(0, 0.13, 0.02)
	g.add_child(num)
	var icon := _icon_quad(0.19)
	icon.position = Vector3(-0.34, 0.13, 0.02)
	g.add_child(icon)

	return {"node": g, "visual": visual, "panel": panel, "panel_mat": pm, "segs": segs, "num": num, "icon": icon, "kind": 2, "pop": 0.0}


func _label3d(text: String, size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = title_font
	l.font_size = size
	l.pixel_size = 0.0026
	l.fixed_size = true
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = col
	l.outline_size = 7
	l.outline_modulate = Color(0.015, 0.08, 0.16)
	l.render_priority = 30
	l.outline_render_priority = 29
	return l


func _icon_quad(size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = GUARD_ICON
	m.albedo_color = Color(0.45, 0.90, 1.0)
	m.no_depth_test = true
	m.render_priority = 31
	mi.material_override = m
	return mi


# --- Animation ---------------------------------------------------------------

func _sync_combat() -> void:
	for i in targets.size():
		var t := targets[i]
		var hp := t.shield_hp if t.is_shielded() else 0
		var mx := maxi(t.shield_max, 1)
		if hp != values[i]:
			values[i] = hp
			for opt in 3:
				for data in indicator_sets[opt]:
					if data["target"] == t:
						data["pop"] = 1.0
		max_values[i] = mx


func _animate(t: float) -> void:
	var active := 1 if (b_only or combat) else clampi(int(t / SEGMENT), 0, 2)
	if combat:
		_sync_combat()
	elif b_only:
		# One 12 s take, one drop beat per combatant so the three opponents can
		# be compared side by side without all rings moving at once.
		if t < 0.05:
			for i in values.size():
				values[i] = max_values[i]
			_refresh_all()
		for i in values.size():
			var m := max_values[i]
			var first := int(round(float(m) * 0.60))
			var second := int(round(float(m) * 0.30))
			if t >= 4.0 + float(i) * 0.6 and values[i] > first:
				values[i] = first
				_refresh_all()
			if t >= 8.0 + float(i) * 0.6 and values[i] > second:
				values[i] = second
				_refresh_all()
	else:
		var local_t := fmod(t, SEGMENT)
		if local_t < 0.05:
			for i in values.size():
				values[i] = max_values[i]
			_refresh_all()
		for i in values.size():
			var m := max_values[i]
			var first := int(round(float(m) * 0.60))
			var second := int(round(float(m) * 0.30))
			if local_t >= 1.3 + float(i) * 0.12 and values[i] > first:
				values[i] = first
				_refresh_all()
			if local_t >= 2.6 + float(i) * 0.12 and values[i] > second:
				values[i] = second
				_refresh_all()

	for opt in 3:
		for data in indicator_sets[opt]:
			var show := opt == active
			if combat and opt == active:
				show = data["target"].is_shielded()
			data["node"].visible = show
	for data in indicator_sets[active]:
		if not data["node"].visible:
			continue
		var ti: int = data["target_index"]
		var target: Combatant = data["target"]
		var head := _head_pos(target)
		var dist := cam.global_position.distance_to(head)
		# Constant on-screen size (D-1010): the indicator keeps the same footprint on
		# the player (near) and on the opponent (far), beside the head, clear of the
		# enemy tag and of the ally cards.
		var s := clampf(dist / 5.0, 0.45, 9.0)
		var right := _cam_right()
		var d: Dictionary = data
		d["pop"] = maxf(0.0, float(d["pop"]) - 0.10)
		var bob := sin(t * 2.2 + float(ti) * 1.7) * 0.05
		match int(d["kind"]):
			0:
				var node: Node3D = d["node"]
				node.global_position = _anchor_pos(target, ti, head, s, 0.52, 0.18) + Vector3(0, bob * s, 0)
				var quad: MeshInstance3D = d["quad"]
				var sc := s * (1.0 + 0.12 * float(d["pop"]))
				quad.global_transform = Transform3D(cam.global_transform.basis.scaled(Vector3.ONE * sc), node.global_position)
			1:
				# B: diagonal composition. The ring stays upright; the number and
				# the shield lean together, punch on every value change and keep a
				# slow sway, like the damage number's pop.
				var node: Node3D = d["node"]
				node.global_position = _anchor_pos(target, ti, head, s, 0.95, 0.34) + Vector3(0, bob * s, 0)
				var e := float(d["pop"])
				var punch := 1.0 + 0.42 * sin(e * PI) - 0.22 * e * e
				var lean := deg_to_rad(-14.0 - 9.0 * sin(e * PI) + 1.6 * sin(t * 1.9 + float(ti) * 1.3))
				var flash := e * e
				var cam_basis := cam.global_transform.basis
				var cam_up := cam_basis.y.normalized()
				var pivot: Node3D = d["ring_pivot"]
				var ring_k := s * (1.0 + 0.12 * sin(e * PI))
				pivot.global_transform = Transform3D(cam_basis.scaled(Vector3.ONE * ring_k), pivot.global_position)
				var rm: ShaderMaterial = d["ring_mat"]
				rm.set_shader_parameter("fill", clampf(float(values[ti]) / float(max_values[ti]), 0.0, 1.0))
				rm.set_shader_parameter("pulse", e)
				var wave: MeshInstance3D = d["wave"]
				var wmat: StandardMaterial3D = d["wave_mat"]
				wave.scale = Vector3.ONE * (1.0 + 0.55 * (1.0 - e))
				wmat.albedo_color.a = 0.55 * e
				var num: Label3D = d["num"]
				num.text = str(values[ti])
				num.modulate = Color.WHITE.lerp(Color(0.62, 0.95, 1.0), flash)
				num.outline_modulate = Color(0.01, 0.05, 0.10, 0.95).lerp(Color(0.05, 0.55, 0.85, 0.95), flash * 0.7)
				var base := node.global_position
				var num_pos := base + right * (0.0431 * s) + cam_up * ((0.0 + 0.0431 * e) * s)
				var num_basis := cam_basis * Basis(Vector3.BACK, lean) * Basis.from_scale(Vector3.ONE * punch)
				num.global_transform = Transform3D(num_basis, num_pos)
				var icon: MeshInstance3D = d["icon"]
				var icon_k := 1.0 + 0.28 * sin(e * PI)
				var icon_pos := base + right * (-0.3105 * s) + cam_up * (0.3105 * s)
				var icon_basis := cam_basis * Basis(Vector3.BACK, lean - deg_to_rad(12.0)) * Basis.from_scale(Vector3.ONE * (s * icon_k))
				icon.global_transform = Transform3D(icon_basis, icon_pos)
			2:
				var node: Node3D = d["node"]
				node.global_position = _anchor_pos(target, ti, head, s, 0.62, 0.11) + Vector3(0, bob * s, 0)
				node.global_transform.basis = cam.global_transform.basis
				var visual: Node3D = d["visual"]
				visual.scale = Vector3.ONE * s
				var pm: ShaderMaterial = d["panel_mat"]
				pm.set_shader_parameter("pulse", float(d["pop"]))
				var frac := clampf(float(values[ti]) / float(max_values[ti]), 0.0, 1.0)
				var segs: Array = d["segs"]
				for i in 3:
					var seg: Dictionary = segs[i]
					var node_seg: MeshInstance3D = seg["node"]
					var mat: StandardMaterial3D = seg["mat"]
					var on := frac > float(i) / 3.0
					var c := mat.albedo_color
					c.a = 0.75 if on else 0.12
					mat.albedo_color = c
					node_seg.visible = on
				var num: Label3D = d["num"]
				num.text = str(values[ti])
				num.position = Vector3(0, 0.13 * s, 0.02)
				var icon: MeshInstance3D = d["icon"]
				icon.position = Vector3(-0.34 * s, 0.13 * s, 0.02)
				icon.scale = Vector3.ONE * s

	if labels.has("title"):
		if combat:
			labels["title"].text = "B · EM COMBATE"
			labels["sub"].text = "%d aliados · %d oponentes · valor real de shield_hp" % [battle.party.size(), battle.enemies.size()]
			labels["title"].add_theme_color_override("font_color", Color("63d9ec"))
		else:
			var titles := ["A · SELO FLUTUANTE", "B · ANEL DE ESCUDO", "C · BARREIRA EM CAMADAS"]
			var subs := [
				"número grande + ícone de escudo · fundo azul · leitura de dano",
				"anel 3D acima da etiqueta do oponente · arco = reserva atual · número no centro",
				"painel de vidro ao lado · 3 camadas de escudo · valor grande",
			]
			labels["title"].text = titles[active]
			labels["sub"].text = subs[active]
			labels["title"].add_theme_color_override("font_color", [Color("63d9ec"), Color("7fb8ff"), Color("b5a5fe")][active])


# --- Labels ------------------------------------------------------------------

func _build_labels() -> void:
	if no_shield:
		return
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var head := Label.new()
	head.text = ("SHIELD VALUE // B · EM COMBATE" if combat
		else ("SHIELD VALUE // B · 3 OPONENTES" if b_only else "SHIELD VALUE // 3 PROPOSTAS"))
	head.position = Vector2(40, 22)
	head.size = Vector2(760, 30)
	head.add_theme_font_override("font", title_font)
	head.add_theme_font_size_override("font_size", 28)
	head.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	head.add_theme_constant_override("outline_size", 5)
	head.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06))
	layer.add_child(head)
	var note := Label.new()
	note.text = ("jogador e aliados · oponentes · valor real de shield_hp · HUD ligada" if combat
		else ("jogador (perto) · 3 oponentes (longe) · cartões e HUD ligados · escudo em azul" if b_only
		else "jogador (aliado, perto) · oponente (longe) · cartões e HUD ligados · escudo em azul"))
	note.position = Vector2(42, 52)
	note.size = Vector2(760, 20)
	note.add_theme_font_override("font", body_font)
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.62, 0.78, 0.82))
	layer.add_child(note)
	var title := Label.new()
	title.position = Vector2(40, 106)
	title.size = Vector2(900, 30)
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("63d9ec"))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04))
	layer.add_child(title)
	var sub := Label.new()
	sub.position = Vector2(40, 136)
	sub.size = Vector2(900, 20)
	sub.add_theme_font_override("font", body_font)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.65, 0.78, 0.82))
	layer.add_child(sub)
	var foot := Label.new()
	foot.text = ("PROTÓTIPO 3D · COMBATE REAL (DEBUG) · NÃO IMPLEMENTADO NO JOGO" if combat
		else ("PROTÓTIPO 3D · B ESCOLHIDA · AJUSTE DE ESTILO, ÂNGULO E ANIMAÇÃO" if b_only
		else "PROTÓTIPO 3D · NÃO IMPLEMENTADO NO JOGO · ESCOLHA A, B OU C"))
	foot.position = Vector2(0, 690)
	foot.size = Vector2(1280, 20)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_override("font", body_font)
	foot.add_theme_font_size_override("font_size", 11)
	foot.add_theme_color_override("font_color", Color(0.45, 0.60, 0.66))
	layer.add_child(foot)
	labels = {"title": title, "sub": sub}


func _refresh_all() -> void:
	if combat:
		return
	for opt in 3:
		for data in indicator_sets[opt]:
			var ti: int = data["target_index"]
			# Keep the real HUD badge in sync with the value being judged, so the
			# cards/tags show the same reserve as the floating indicator.
			var target: Combatant = data["target"]
			target.shield_hp = maxi(values[ti], 1)
			match int(data["kind"]):
				0:
					var p: BadgePainter = data["painter"]
					p.value = values[ti]
					p.max_value = max_values[ti]
					p.queue_redraw()
					data["pop"] = 1.0
				1:
					(data["num"] as Label3D).text = str(values[ti])
					data["pop"] = 1.0
				2:
					(data["num"] as Label3D).text = str(values[ti])
					data["pop"] = 1.0


# --- 2D badge ----------------------------------------------------------------

class BadgePainter extends Control:
	var value := 0
	var max_value := 0
	var title_font: Font
	var body_font: Font
	var icon: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := 260.0
		var h := 110.0
		var pts := PackedVector2Array([
			Vector2(10, 0), Vector2(w, 0), Vector2(w - 10, h), Vector2(0, h),
		])
		draw_colored_polygon(pts, Color("0a3766"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("63d9ec"), 3.0, true)
		draw_line(Vector2(15, 5), Vector2(w - 6, 5), Color(1, 1, 1, 0.32), 1.5)
		# Shield icon + big white number + max, the compact form of the idea:
		# blue plate, cyan shield, white value, light-blue maximum.
		if icon != null:
			draw_texture_rect(icon, Rect2(14, 33, 42, 42), false, Color(0.55, 0.88, 1.0))
		draw_string(title_font, Vector2(62, 100), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 104, Color.WHITE)
		var max_txt := "/%d" % max_value
		var mw := body_font.get_string_size(max_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(body_font, Vector2(w - 12.0 - mw, 96), max_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.55, 0.86, 1.0))
