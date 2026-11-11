extends SceneTree
## Demonstração in-game do Bubble Shield com o Slime como usuário principal.
## Grava uma vista por execução:
##   Godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie <saida.avi>
##         --script res://tests/vfx/record_bubble_slime.gd -- --view=normal
##         ... -- --view=mirrored --dqt-mirror
## D-235: o Slime pode estar no time aliado (perto) ou inimigo (longe); a câmera
## é derivada do modelo e do eixo da câmera real da batalha, sem lado fixo.

var battle: Battle
var bs: Node3D
var cam: Camera3D
var slime: Combatant
var enemy: Combatant
var view := "normal"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--view="):
			view = a.substr(7)
	call_deferred("_run")


func _run() -> void:
	DqtTestParty.enabled = true
	bs = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	root.add_child(bs)
	battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 1200:
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	battle.debug_roll = 1
	Engine.time_scale = 1.0

	for c in battle.party + battle.enemies:
		if c.name.to_lower().contains("slime"):
			slime = c
			break
	if slime == null:
		push_error("Slime não encontrado no cenário (%s)" % view)
		bs.queue_free()
		quit(1)
		return
	print("[BUBBLE-VIDEO] party=", _roster_line(battle.party), " enemies=", _roster_line(battle.enemies))
	enemy = null
	for c in battle.party + battle.enemies:
		if c != slime and c.is_alive():
			enemy = c
			break
	var bubble := Skill.from_id(&"bubble_shield")
	if bubble != null and not slime.skills.has(bubble):
		slime.skills.append(bubble)
	slime.max_mp = maxi(slime.max_mp, 99)
	slime.mp = 99

	var game_cam := bs.get_node("Camera3D") as Camera3D
	var back := game_cam.global_transform.basis.z.normalized()
	var right := game_cam.global_transform.basis.x.normalized()
	bs.director.set_process(false)
	# Câmera própria da gravação: o BattleCamera do jogo continua livre e não
	# rouba o enquadramento no status_shot (o Slime continua o mesmo do jogo).
	cam = Camera3D.new()
	cam.name = "RecordCamera"
	bs.add_child(cam)
	var sm: Node3D = bs.models[slime]
	var env := FxBubbleShield.body_envelope(sm)
	var body_center: Vector3 = env["center"]
	var body_radius := float(env["radius"])
	print("[BUBBLE-VIDEO] env_center=", body_center, " radius=", body_radius, " height=", env["height"])
	# Distância derivada do raio medido do corpo (D-235), com margem para a bolha
	# 15% mais larga caber inteira no quadro.
	var dist := body_radius * 4.8
	cam.global_position = body_center + back * dist + right * (body_radius * 0.45) + Vector3.UP * (body_radius * 0.55)
	cam.look_at(body_center)
	cam.fov = 52.0
	cam.current = true

	_add_title("BUBBLE SHIELD  ·  SLIME  ·  %s" % ("VISTA NORMAL" if view == "normal" else "VISTA ESPELHADA"))
	await _wait(0.9)
	slime.atb = 5.0
	var cast_ok := bubble != null and battle.use_skill(slime, bubble, slime)
	print("[BUBBLE-VIDEO] view=", view, " cast=", cast_ok, " slime=", slime.name, " enemy=", enemy.name)
	await _wait_until(func() -> bool: return slime.is_shielded(), 6.0)
	# D-1108: a coroa do wind-up agora leva 2,45 s para sumir; espera a saída completa.
	await _wait(2.6)

	var attack := _attack_skill(enemy)
	var shield_before := slime.shield_hp
	enemy.atb = 5.0
	enemy.mp = maxi(enemy.mp, 20)
	var hit_ok := attack != null and battle.use_skill(enemy, attack, slime)
	print("[BUBBLE-VIDEO] first_hit=", hit_ok, " attack=", attack.display_name if attack != null else "none")
	await _wait_until(func() -> bool: return slime.shield_hp < shield_before, 12.0)
	await _wait(1.3)

	# Segunda pancada com a reserva baixa: mostra a ruptura da bolha.
	slime.shield_hp = 5
	enemy.atb = 5.0
	var break_ok := battle.use_skill(enemy, attack, slime)
	print("[BUBBLE-VIDEO] break_hit=", break_ok, " shielded=", slime.is_shielded())
	await _wait_until(func() -> bool: return not slime.is_shielded(), 12.0)
	await _wait(1.6)

	bs.queue_free()
	await process_frame
	quit(0)


func _attack_skill(c: Combatant) -> Skill:
	for s in c.skills:
		if s.kind != Skill.Kind.STATUS and not s.is_friendly:
			return s
	return Skill.basic()


func _roster_line(list: Array) -> String:
	var parts: Array[String] = []
	for c in list:
		var m = bs.models.get(c)
		var p: Vector3 = m.global_position if m != null and is_instance_valid(m) else c.pos
		parts.append("%s@(%.1f,%.1f,%.1f)" % [c.name, p.x, p.y, p.z])
	return ", ".join(parts)


func _add_title(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var label := Label.new()
	label.text = text
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.98, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.06))
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout


func _wait_until(predicate: Callable, timeout: float) -> bool:
	var frames := int(timeout * 30.0)
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	return predicate.call()
