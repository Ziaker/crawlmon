extends SceneTree
## D-1204: ataque no jogo REAL (nada congelado): IA dos inimigos, câmera, paredes e a tecla Z.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 960x540 --fixed-fps 60 \
##       --script res://tests/overworld/attack_real_scenario.gd -- --sp=abra --tg=dqt_cyclops \
##       --dist=3.6 --out=<pasta>
##
## Joga o jogador a `dist` m (centro a centro) do alvo, espera a câmera assentar, aperta Z e
## imprime por quadro: fase do ataque, distância de borda, fase do inimigo e se o texto HIT
## existe e está visível (na tela e não escondido por geometria). Salva quadros em --out.
const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

func _init() -> void:
	call_deferred("_run")

func _arg(n: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % n):
			return a.substr(n.length() + 3)
	return d

func _run() -> void:
	var sp := _arg("sp", "abra")
	var tg := _arg("tg", "dqt_cyclops")
	var dist := float(_arg("dist", "3.6"))
	var out := _arg("out", "")
	var wait := float(_arg("wait", "1.0"))
	var lab := (load(LAB) as PackedScene).instantiate()
	lab.set("player_species", sp)
	root.add_child(lab)
	await create_timer(0.8).timeout
	var player: CharacterBody3D = lab.get("player")
	var ctrl: Node = lab.get("_attack_controller")
	var body: Node3D
	for e in lab.get("_room_enemies"):
		if str(e["node"].name).ends_with(tg):
			body = e["node"]
	if body == null:
		print("REAL_JSON: {\"error\":\"no_target\"}")
		quit(1)
		return
	# Lado: o jogador chega vindo da direção de -z (a sala é aberta nesse eixo).
	var dir := Vector3(0, 0, 1)
	player.global_position = body.global_position + dir * dist
	player.velocity = Vector3.ZERO
	var to := body.global_position - player.global_position
	to.y = 0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await create_timer(wait).timeout
	var gap0: float = ctrl.call("_edge_gap", player, body)
	var acquired: bool = ctrl.get_attack_target() == body
	var tgt = ctrl.get_attack_target()
	print("REAL_TARGET: ", str(tgt.name) if tgt != null else "none", " blocked=", ctrl.get("_interaction_blocked"),
		" bonus=", ctrl.call("_weapon_reach_bonus", player), " meta=", player.get_meta("species_id", ""),
		" target_pos=", body.global_position, " player_pos=", player.global_position)
	print("REAL_START: ", JSON.stringify({"sp": sp, "tg": tg, "edge_gap": snappedf(gap0, 0.01),
		"acquired": acquired, "enemy_phase": _ephase(ctrl, body)}))
	ctrl.impact_requested.connect(func(_p, _d, adv, contacts: Array) -> void:
		var names: Array = []
		for c in contacts:
			names.append("%s<-%s" % [str(c["actor"].name), str(c["source"].name)])
		print("REAL_IMPACT: ", JSON.stringify({"advantage": str(EncounterRules.Advantage.keys()[int(adv)]), "contacts": names,
			"edge_at_impact": snappedf(float(ctrl.call("_edge_gap", player, body)), 0.01)})))
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_Z
	ev.keycode = KEY_Z
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var rel := InputEventKey.new()
	rel.physical_keycode = KEY_Z
	rel.keycode = KEY_Z
	rel.pressed = false
	Input.parse_input_event(rel)
	var impact_i := -1
	var cam: Camera3D = lab.get("_camera")
	for i in 200:
		await process_frame
		var hit_label: Label3D = null
		for l in lab.find_children("AttackHitText", "Label3D", true, false):
			hit_label = l
		var vis := false
		var on_screen := false
		if hit_label != null:
			vis = hit_label.is_visible_in_tree() and hit_label.modulate.a > 0.2
			var sp2 := cam.unproject_position(hit_label.global_position)
			on_screen = Rect2(Vector2.ZERO, get_root().size).has_point(sp2) and not cam.is_position_behind(hit_label.global_position)
		var imp := lab.get_node_or_null("TackleImpact") != null
		if imp and impact_i < 0:
			impact_i = i
		print("REAL_F ", JSON.stringify({"i": i, "ts": snappedf(Engine.time_scale, 0.01),
			"pphase": int(ctrl.get("_player_phase")), "ephase": _ephase(ctrl, body),
			"edge": snappedf(float(ctrl.call("_edge_gap", player, body)), 0.01),
			"impact": imp, "hit_text": hit_label != null, "hit_visible": vis, "hit_on_screen": on_screen,
			"battle": bool(ctrl.get("_battle_requested"))}))
		if out != "" and i < 70:
			DirAccess.make_dir_recursive_absolute(out)
			root.get_texture().get_image().save_png("%s/f%03d.png" % [out, i])
		if bool(ctrl.get("_battle_requested")) and impact_i >= 0 and i > impact_i + 5:
			break
	quit(0)

func _ephase(ctrl: Node, body: Node3D) -> int:
	for e in ctrl.get("_enemies"):
		if e["node"] == body:
			return int(e["phase"])
	return -1
