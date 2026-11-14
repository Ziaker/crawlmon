class_name VfxRoomAnalysis
extends Node
## Ferramentas de análise visual da sala de VFX (D-1044). Extraído de vfx_room.gd
## na Etapa 4; a sala mantém o estado e os wrappers, então CLI, painel e testes
## continuam chamando os mesmos métodos.

var room


func _init(p_room) -> void:
	room = p_room


## 1. Auditor Automático de "Restos e Órfãos" (VFX Leak & Ghost Detector)
func _audit_vfx_leaks() -> void:
	room._last_leaks.clear()
	if room._bs == null or room._bs.fx == null:
		return
	for ch in room._bs.fx.get_children():
		if room._baseline_fx_ids.has(ch.get_instance_id()):
			continue
		var cname := String(ch.name)
		if cname in ["DebugFreeCam3D", "DebugGizmos3D"] or cname.begins_with("FxLane"):
			continue
		var is_leaking := false
		if ch is OmniLight3D and (ch as OmniLight3D).visible and (ch as OmniLight3D).light_energy > 0.01:
			is_leaking = true
		elif ch is CPUParticles3D:
			if (ch as CPUParticles3D).visible and (ch as CPUParticles3D).emitting and not (ch as CPUParticles3D).one_shot:
				is_leaking = true
		elif ch is GPUParticles3D:
			if (ch as GPUParticles3D).visible and (ch as GPUParticles3D).emitting and not (ch as GPUParticles3D).one_shot:
				is_leaking = true
			is_leaking = true
		elif ch is VisualInstance3D and (ch as VisualInstance3D).visible:
			var a := _node_alpha(ch)
			if a > 0.02:
				is_leaking = true
		elif ch is Node3D and (ch as Node3D).visible:
			for sub in ch.find_children("*", "VisualInstance3D", true, false):
				if not (sub is CPUParticles3D or sub is GPUParticles3D) and (sub as VisualInstance3D).visible and _node_alpha(sub) > 0.02:
					is_leaking = true
					break
		if is_leaking:
			var kids: PackedStringArray = []
			for k in ch.get_children():
				kids.append("%s:%s" % [k.get_class(), String(k.name)])
			room._last_leaks.append("%s[%s]{%s}" % [cname, ch.get_class(), ",".join(kids.slice(0, 4))])  # which node leaks (D-1196 debugging)
	if room._audit_leaks_on or not room._last_leaks.is_empty():
		print("[vfx_audit] leaks=%d nodes=%s" % [room._last_leaks.size(), JSON.stringify(room._last_leaks)])
		room._note("AUDITORIA VFX: %d sobras (%s)" % [room._last_leaks.size(), ", ".join(room._last_leaks) if not room._last_leaks.is_empty() else "limpo"])


func _node_alpha(n: Node) -> float:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.get_active_material(0)
		if mat is StandardMaterial3D:
			return (mat as StandardMaterial3D).albedo_color.a
		elif mat is ShaderMaterial:
			for param in ["alpha", "opacity", "albedo", "color", "tint"]:
				var v = (mat as ShaderMaterial).get_shader_parameter(param)
				if v is float:
					return float(v)
				elif v is Color:
					return (v as Color).a
	return 1.0


## 2, 4, 9. Overlay 2D de Análise Visual (Reticulado em pixels + Régua métrica 3D + Sonda de Osso + Curva de Envelope)
func _build_analysis_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 95
	room.add_child(cl)
	room._analysis_overlay = Control.new()
	room._analysis_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	room._analysis_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room._analysis_overlay.draw.connect(_draw_analysis_overlay)
	cl.add_child(room._analysis_overlay)


func _tick_vfx_analysis(delta: float) -> void:
	if room._bs == null or room._bs.fx == null:
		return
	if room._bone_probe_on and room._fired and not room._paused and delta > 0.0001:
		_sample_bone_probe(delta)
	if room._envelope_graph_on and room._fired and not room._paused:
		_sample_envelope()
	if room._overdraw_on:
		_apply_overdraw_pass()
	if room._analysis_overlay != null:
		room._analysis_overlay.queue_redraw()


func _log_scale_metrics() -> void:
	if room._bs == null or room._units.is_empty():
		return
	var cam := room._bs.get_node_or_null("Camera3D") as Camera3D
	var t_unit: Combatant = room._units[clampi(room._target.selected, 0, room._units.size() - 1)]
	var t_model: Node3D = room._bs.models.get(t_unit)
	if cam == null or t_model == null:
		return
	var p0 := cam.unproject_position(t_model.global_position)
	var p1 := cam.unproject_position(t_model.global_position + Vector3(0, 1.0, 0))
	var px_per_m := p0.distance_to(p1)
	print("[vfx_scale] target=%s screen_pos=(%.1f,%.1f) px_per_meter=%.1f height_1_2m_px=%.1f" % [
		t_unit.name, p0.x, p0.y, px_per_m, px_per_m * 1.2
	])


func _sample_bone_probe(delta: float) -> void:
	if room._units.is_empty():
		return
	var a_unit: Combatant = room._units[clampi(room._attacker.selected, 0, room._units.size() - 1)]
	var a_model: Node3D = room._bs.models.get(a_unit)
	if a_model == null or not is_instance_valid(a_model):
		return
	var skel: Skeleton3D = null
	for s in a_model.find_children("*", "Skeleton3D", true, false):
		skel = s as Skeleton3D
		break
	var pos := a_model.global_position + Vector3(0, 1.0, 0)
	if skel != null and skel.get_bone_count() > 0:
		var best_idx := 0
		for i in skel.get_bone_count():
			var bname := skel.get_bone_name(i).to_lower()
			if "buki" in bname or "weapon" in bname or "hand" in bname or "_te_" in bname or "hte" in bname or "wrist" in bname:
				best_idx = i
				room._bone_name_tracked = skel.get_bone_name(i)
				break
		if room._bone_name_tracked == "":
			room._bone_name_tracked = skel.get_bone_name(0)
		pos = skel.global_transform * skel.get_bone_global_pose(best_idx).origin
	else:
		room._bone_name_tracked = "model_origin"
	if room._bone_has_prev:
		room._bone_cur_speed = pos.distance_to(room._bone_prev_pos) / delta
		if room._bone_cur_speed > room._bone_peak_speed:
			room._bone_peak_speed = room._bone_cur_speed
			print("[vfx_bone_probe] bone=%s peak_speed=%.2f m/s t=%.3f" % [room._bone_name_tracked, room._bone_peak_speed, room._clock - room._fire_clock])
	room._bone_prev_pos = pos
	room._bone_has_prev = true
	room._bone_trail.append(pos)
	if room._bone_trail.size() > 40:
		room._bone_trail.pop_front()


func _sample_envelope() -> void:
	var max_a := 0.0
	var count := 0
	var cur_alphas: Dictionary = {}
	for ch in room._bs.fx.get_children():
		if room._baseline_fx_ids.has(ch.get_instance_id()):
			continue
		for v in ch.find_children("*", "VisualInstance3D", true, false) + ([ch] if ch is VisualInstance3D else []):
			var vi := v as VisualInstance3D
			if vi == null or not vi.visible:
				continue
			var a := _node_alpha(vi)
			var id := vi.get_instance_id()
			cur_alphas[id] = {"name": String(vi.name), "a": a}
			if room._prev_node_alphas.has(id):
				var prev_a: float = float(room._prev_node_alphas[id]["a"])
				if prev_a - a > 0.55:
					var msg := "%s: %.2f -> %.2f" % [String(vi.name), prev_a, a]
					if not room._envelope_pops.has(msg):
						room._envelope_pops.append(msg)
						print("[POP_DETECTED] node=%s prev_alpha=%.2f new_alpha=%.2f t=%.3f" % [String(vi.name), prev_a, a, room._clock - room._fire_clock])
			max_a = maxf(max_a, a)
			count += 1
	room._prev_node_alphas = cur_alphas
	room._envelope_samples.append({"t": room._clock - room._fire_clock, "a": max_a, "n": count})
	if room._envelope_samples.size() > 180:
		room._envelope_samples.pop_front()


func _draw_analysis_overlay() -> void:
	if room._bs == null or room._units.is_empty():
		return
	var cam := room._bs.get_node_or_null("Camera3D") as Camera3D
	if cam == null:
		return
	var font := ThemeDB.fallback_font
	if room._scale_overlay_on:
		var t_unit: Combatant = room._units[clampi(room._target.selected, 0, room._units.size() - 1)]
		var a_unit: Combatant = room._units[clampi(room._attacker.selected, 0, room._units.size() - 1)]
		var t_model: Node3D = room._bs.models.get(t_unit)
		var a_model: Node3D = room._bs.models.get(a_unit)
		if t_model != null and not cam.is_position_behind(t_model.global_position + Vector3(0, 1.2, 0)):
			var center_2d := cam.unproject_position(t_model.global_position + Vector3(0, 1.2, 0))
			for r in [50.0, 100.0, 200.0]:
				room._analysis_overlay.draw_arc(center_2d, r, 0.0, TAU, 48, Color(0.84, 0.99, 0.42, 0.55), 1.5)
				room._analysis_overlay.draw_string(font, center_2d + Vector2(r + 4.0, 4.0), "%dpx" % int(r), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.99, 0.42, 0.9))
		for m in [a_model, t_model]:
			if m == null or cam.is_position_behind(m.global_position):
				continue
			var base_2d := cam.unproject_position(m.global_position)
			var top_2d := cam.unproject_position(m.global_position + Vector3(0, 2.5, 0))
			room._analysis_overlay.draw_line(base_2d, top_2d, Color(0.38, 0.85, 0.91, 0.8), 2.0)
			for h in [0.5, 1.0, 1.2, 2.0, 2.5]:
				var p_h := cam.unproject_position(m.global_position + Vector3(0, h, 0))
				var col := Color(1.0, 0.85, 0.2, 0.95) if is_equal_approx(h, 1.2) or is_equal_approx(h, 2.5) else Color(0.38, 0.85, 0.91, 0.75)
				room._analysis_overlay.draw_line(p_h - Vector2(8, 0), p_h + Vector2(8, 0), col, 1.5)
				room._analysis_overlay.draw_string(font, p_h + Vector2(10, 4), "%.1fm" % h, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	if room._bone_probe_on and room._bone_trail.size() >= 2:
		for i in range(1, room._bone_trail.size()):
			if not cam.is_position_behind(room._bone_trail[i - 1]) and not cam.is_position_behind(room._bone_trail[i]):
				var p0 := cam.unproject_position(room._bone_trail[i - 1])
				var p1 := cam.unproject_position(room._bone_trail[i])
				var k := float(i) / float(room._bone_trail.size())
				room._analysis_overlay.draw_line(p0, p1, Color(0.2, 1.0, 0.4, k).lerp(Color(1.0, 0.2, 0.3, k), k), 2.5)
		room._analysis_overlay.draw_string(font, Vector2(20, 40), "SONDA DE OSSO [%s]: vel=%.1f m/s | pico=%.1f m/s" % [room._bone_name_tracked, room._bone_cur_speed, room._bone_peak_speed], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d7fd6a"))
	if room._envelope_graph_on and room._envelope_samples.size() >= 2:
		var rect := Rect2(20, 560, 320, 110)
		room._analysis_overlay.draw_rect(rect, Color(0.02, 0.04, 0.08, 0.82), true)
		room._analysis_overlay.draw_rect(rect, Color("62d8e7"), false, 1.5)
		room._analysis_overlay.draw_string(font, rect.position + Vector2(8, 16), "ENVELOPE DE OPACIDADE (pops=%d)" % room._envelope_pops.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("62d8e7"))
		for i in range(1, room._envelope_samples.size()):
			var x0 := rect.position.x + 8.0 + float(i - 1) / 180.0 * (rect.size.x - 16.0)
			var x1 := rect.position.x + 8.0 + float(i) / 180.0 * (rect.size.x - 16.0)
			var y0 := rect.position.y + rect.size.y - 10.0 - float(room._envelope_samples[i - 1]["a"]) * (rect.size.y - 30.0)
			var y1 := rect.position.y + rect.size.y - 10.0 - float(room._envelope_samples[i]["a"]) * (rect.size.y - 30.0)
			room._analysis_overlay.draw_line(Vector2(x0, y0), Vector2(x1, y1), Color("d7fd6a"), 2.0)


## 6. Impact Macro Cam (FOV 15° focada no ponto de contato + 0.05x no impacto)
func _update_macro_cam() -> void:
	var cam: Camera3D = room._bs.get_node_or_null("Camera3D")
	var a: Node3D = room._bs.models.get(room._units[room._attacker.selected])
	var t: Node3D = room._bs.models.get(room._units[room._target.selected])
	if cam == null or a == null or t == null:
		return
	var axis := t.global_position - a.global_position
	axis.y = 0.0
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var side := Vector3(-axis.z, 0.0, axis.x)
	cam.current = true
	cam.fov = 15.0
	var contact := t.global_position + Vector3(0, 1.2, 0)
	cam.global_position = contact - axis * 6.5 + side * 2.2 + Vector3(0, 0.4, 0)
	cam.look_at(contact)


## 7. Visualizador de Overdraw e Densidade de Transparência
func _apply_overdraw_pass() -> void:
	if room._bs == null or room._bs.fx == null:
		return
	if room._overdraw_mat == null:
		room._overdraw_mat = StandardMaterial3D.new()
		room._overdraw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		room._overdraw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		room._overdraw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		room._overdraw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		room._overdraw_mat.no_depth_test = true
		room._overdraw_mat.albedo_color = Color(0.22, 0.07, 0.02, 0.65)
	var count := 0
	for ch in room._bs.fx.get_children():
		if room._baseline_fx_ids.has(ch.get_instance_id()):
			continue
		for m in ch.find_children("*", "MeshInstance3D", true, false) + ([ch] if ch is MeshInstance3D else []):
			var mi := m as MeshInstance3D
			if mi != null and mi.visible:
				if not room._orig_materials.has(mi.get_instance_id()):
					room._orig_materials[mi.get_instance_id()] = mi.material_override
				mi.material_override = room._overdraw_mat
				count += 1
	if count > 0 and room._tick_from_fire % 15 == 1:
		print("[vfx_overdraw] active_transparent_meshes=%d" % count)


## 8. Teste de Silhueta e Contraste com Fundos Alternativos (arena, gray, black, white)
func _apply_bg_mode(mode: String) -> void:
	room._bg_mode = mode
	if room._bs == null:
		return
	var is_solid := mode in ["gray", "black", "white"]
	var col := Color(0.03, 0.06, 0.1)
	if mode == "gray":
		col = Color(0.5, 0.5, 0.5)
	elif mode == "black":
		col = Color(0.0, 0.0, 0.0)
	elif mode == "white":
		col = Color(1.0, 1.0, 1.0)
	RenderingServer.set_default_clear_color(col)
	for n in room._bs.get_children():
		if n.get_script() == preload("res://scripts/combat/battle_arena.gd"):
			(n as Node3D).visible = not is_solid
		elif n is WorldEnvironment:
			var we := n as WorldEnvironment
			if we.environment != null and is_solid:
				we.environment.background_mode = Environment.BG_COLOR
				we.environment.background_color = col
	print("[vfx_bg] mode=%s" % mode)


## 10. Comparador Visual A/B (Diff de Versões em Magenta + RMSE)
func _compare_images(shot_file: String, ref_arg: String) -> void:
	var ref_path := ProjectSettings.globalize_path(ref_arg) if ref_arg.begins_with("res://") else ref_arg
	var img_a := Image.load_from_file(shot_file)
	var img_b := Image.load_from_file(ref_path)
	if img_a == null or img_b == null:
		print("[vfx_diff] erro ao abrir imagens: shot=%s ref=%s" % [shot_file, ref_path])
		return
	if img_b.get_size() != img_a.get_size():
		img_b.resize(img_a.get_width(), img_a.get_height(), Image.INTERPOLATE_BILINEAR)
	var w := img_a.get_width()
	var h := img_a.get_height()
	var diff_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sum_sq := 0.0
	var changed := 0
	var total := w * h
	for y in h:
		for x in w:
			var ca := img_a.get_pixel(x, y)
			var cb := img_b.get_pixel(x, y)
			var d := ( absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) ) / 3.0
			sum_sq += d * d
			if d > 0.04:
				changed += 1
				diff_img.set_pixel(x, y, Color(1.0, 0.0, 1.0, 1.0).lerp(ca, 0.25))
			else:
				var g := ca.r * 0.299 + ca.g * 0.587 + ca.b * 0.114
				diff_img.set_pixel(x, y, Color(g * 0.4, g * 0.4, g * 0.4, 1.0))
	var rmse := sqrt(sum_sq / maxf(float(total), 1.0))
	var pct := float(changed) * 100.0 / maxf(float(total), 1.0)
	var out_diff := shot_file.get_basename() + "_diff.png"
	diff_img.save_png(out_diff)
	room._telemetry["diff_result"] = {"rmse": snappedf(rmse, 0.0001), "changed_pct": snappedf(pct, 0.01), "diff_path": out_diff}
	print("[vfx_diff] rmse=%.4f changed_pct=%.2f%% diff_path=%s" % [rmse, pct, out_diff])


## 3. Gerador Automático de Folha de Prova das 4 Fases D-308 (Normal + Espelhado, 2x4)
func _run_proof_sheet(out_arg: String) -> void:
	var out_path := ProjectSettings.globalize_path(out_arg) if out_arg.begins_with("res://") else out_arg
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var move_name := String(room._args.get("move", "Fire Bullet"))
	var phases := ["windup", "release", "travel", "impact"]
	var cell_w := 320
	var cell_h := 180
	var sheet := Image.create(cell_w * 4, cell_h * 2, false, Image.FORMAT_RGB8)
	room._panel.visible = false
	for row in 2:
		await room._load_battle(row == 1)
		for col in phases.size():
			var ph: String = phases[col]
			var pi: int = room.PAUSE_KEYS.find(ph)
			room._pause_event.select(pi if pi >= 0 else 0)
			room._pause_delay.value = 0.04
			room._pick(room._move, move_name)
			await room._fire()
			var wait_steps := 0
			while not room._paused and wait_steps < 180:
				await get_tree().process_frame
				wait_steps += 1
			await RenderingServer.frame_post_draw
			var snap := get_viewport().get_texture().get_image()
			snap.convert(Image.FORMAT_RGB8)
			snap.resize(cell_w, cell_h, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(snap, Rect2i(0, 0, cell_w, cell_h), Vector2i(col * cell_w, row * cell_h))
			if room._paused:
				room._toggle_pause()
			room._pause_event.select(0)
	sheet.save_png(out_path)
	print("[vfx_proof_sheet] saved=%s move=%s phases=windup,release,travel,impact rows=normal,mirrored" % [out_path, move_name])
	if room._quit_flag:
		get_tree().quit()


## Runner Automatizado de Simetria D-235 (outro atacante + lado espelhado + alvos de tamanhos diferentes)
func _run_test_d235() -> void:
	var test_moves := [String(room._args["move"])] if room._args.has("move") else ["Tackle", "Fire Bullet", "Electric Beam", "Drain Spear"]
	var results: Array[Dictionary] = []
	var all_ok := true
	for mv in test_moves:
		# Caso A: Vista normal, Atacante 0 (Abra) -> Inimigo
		await room._load_battle(false)
		room._attacker.select(0)
		room._fill_moves()
		room._pick(room._move, mv)
		room._target.select(mini(2, room._units.size() - 1))
		await room._fire()
		for _i in 25:
			await get_tree().process_frame
		var ok_a: bool = room._fired
		# Caso B: Vista normal, Outro Atacante (Pancham, índice 1) -> Inimigo
		await room._load_battle(false)
		room._attacker.select(mini(1, room._units.size() - 1))
		room._fill_moves()
		room._pick(room._move, mv)
		room._target.select(mini(2, room._units.size() - 1))
		await room._fire()
		for _i in 25:
			await get_tree().process_frame
		var ok_b: bool = room._fired
		# Caso C: Vista Espelhada (Inimigo distante ataca aliado próximo) + escala diferente (2,5m vs 0,8m)
		await room._load_battle(true)
		room._apply_scale_test(2.2)
		room._attacker.select(1 if room._units.size() > 1 else 0)
		room._fill_moves()
		room._pick(room._move, mv)
		room._target.select(0)
		await room._fire()
		for _i in 25:
			await get_tree().process_frame
		var ok_c: bool = room._fired
		var mv_ok: bool = ok_a and ok_b and ok_c
		if not mv_ok:
			all_ok = false
		results.append({"move": mv, "attacker_a": ok_a, "attacker_b": ok_b, "mirrored_scaled": ok_c, "pass": mv_ok})
	print("[vfx_room] D235_RESULT: %s details=%s" % ["PASS" if all_ok else "FAIL", JSON.stringify(results)])
	get_tree().quit(0 if all_ok else 1)


## Matriz de Cobertura de Moves (--test-all-moves-matrix)
func _run_test_all_moves_matrix() -> void:
	var tested := 0
	var failed: Array[String] = []
	for mv_name in room._catalog:
		room._attacker.select(0)
		room._fill_moves()
		room._pick(room._move, String(mv_name))
		room._target.select(mini(2, room._units.size() - 1))
		await room._fire()
		for _i in 6:
			await get_tree().process_frame
		if not room._fired:
			failed.append(String(mv_name))
		tested += 1
		room._battle.incoming.clear()
		room._battle._landing.clear()
		room._battle._returning.clear()
		room._battle._status_pause = null
	var ok := failed.is_empty()
	print("[vfx_room] MATRIX_RESULT: %s count=%d failed=%s" % ["PASS" if ok else "FAIL", tested, JSON.stringify(failed)])
	get_tree().quit(0 if ok else 1)


func _build_vfx_analysis_tab(tabs: TabContainer) -> void:
	var box: VBoxContainer = room._page(tabs, "Análise VFX")
	room._section(box, "DIAGNÓSTICO E MEDIÇÃO (D-1044)")
	var cb_leaks := CheckButton.new()
	cb_leaks.text = "1. Auditor de Restos e Órfãos (--audit-leaks)"
	cb_leaks.toggled.connect(func(on: bool) -> void: room._audit_leaks_on = on)
	box.add_child(cb_leaks)
	var cb_scale := CheckButton.new()
	cb_scale.text = "2. Reticulado 50/100/200px e Régua 3D (--scale-overlay)"
	cb_scale.toggled.connect(func(on: bool) -> void: room._scale_overlay_on = on)
	box.add_child(cb_scale)
	var cb_bone := CheckButton.new()
	cb_bone.text = "4. Sonda de Osso e Velocidade de Swing (--bone-probe)"
	cb_bone.toggled.connect(func(on: bool) -> void: room._bone_probe_on = on)
	box.add_child(cb_bone)
	var cb_over := CheckButton.new()
	cb_over.text = "7. Mapa de Calor de Overdraw (--overdraw)"
	cb_over.toggled.connect(func(on: bool) -> void: room._overdraw_on = on)
	box.add_child(cb_over)
	var cb_env := CheckButton.new()
	cb_env.text = "9. Curva de Envelope de Opacidade (--envelope-graph)"
	cb_env.toggled.connect(func(on: bool) -> void: room._envelope_graph_on = on)
	box.add_child(cb_env)
	room._section(box, "8. FUNDO DE SILHUETA E CONTRASTE (--bg)")
	var bg_row := HBoxContainer.new()
	box.add_child(bg_row)
	for bm in [["Arena", "arena"], ["Cinza 50%", "gray"], ["Preto", "black"], ["Branco", "white"]]:
		var b := Button.new()
		b.text = bm[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_apply_bg_mode.bind(bm[1]))
		bg_row.add_child(b)
	room._section(box, "5. FILTRO SOLO / MUTE DE NÓ VFX")
	var solo_in := LineEdit.new()
	solo_in.placeholder_text = "Solo nó (ex.: spark, ring, beam...)"
	solo_in.text_changed.connect(func(t: String) -> void: room._solo_node_pattern = t.strip_edges().to_lower())
	box.add_child(solo_in)
	var mute_in := LineEdit.new()
	mute_in.placeholder_text = "Mute nó (ex.: smoke, trail...)"
	mute_in.text_changed.connect(func(t: String) -> void: room._mute_node_pattern = t.strip_edges().to_lower())
	box.add_child(mute_in)
