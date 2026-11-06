extends SceneTree
## D-238 na cena: o Fire Bullet que interrompe a canalização do alvo o queima; o tick tira 2 HP; quem morre
## queimando toca a animação de morte ("down") e NÃO é lançado (sem K.O. balístico), inimigo ou aliado.
## Rodar: godot --headless --path . --script res://tests/vfx/test_burn_scene.gd

var fails := 0
var room: Node


func _init() -> void:
	call_deferred("_run")


func ok(c: bool, m: String) -> void:
	if c:
		print("  [PASS] ", m)
	else:
		fails += 1
		print("  [FAIL] ", m)


func _run() -> void:
	room = (load("res://scenes/debug/vfx_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var waited := 0
	while room._units.is_empty() and waited < 900:
		await process_frame
		waited += 1
	for mirror in [false, true]:
		await _case(mirror)
	room.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	print("  Resultado: %d falhas" % fails)
	if fails == 0:
		print("BURN_SCENE_TEST_PASS")
	quit(1 if fails > 0 else 0)


func _case(mirror: bool) -> void:
	await room._load_battle(mirror)
	room._speed.value = 1.5
	room._immortal.button_pressed = false
	var att: int = 1 if mirror else 0
	var tgt: int = 0 if mirror else 2
	room._attacker.select(att)
	room._fill_moves()
	for i in room._move.item_count:
		if room._move.get_item_text(i) == "Fire Bullet":
			room._move.select(i)
	room._target.select(tgt)
	room._force.select(1)
	room._channel.button_pressed = true
	var target: Combatant = room._units[tgt]
	var side := "espelhado" if mirror else "normal"
	room._fire()
	var guard := 0
	while guard < 900 and not target.is_burning():
		await process_frame
		guard += 1
	ok(target.is_burning(), "[%s] o alvo canalizando queima depois do Fire Bullet" % side)
	var hp0 := target.hp
	var waited_s := 0.0
	while waited_s < 4.0 and target.hp > hp0 - 2 and target.is_alive():
		await create_timer(0.1).timeout
		waited_s += 0.1
	ok(target.hp <= hp0 - 2 or not target.is_alive(), "[%s] o tick tira 2 HP (hp %d -> %d)" % [side, hp0, target.hp])
	# morte por Burn: sem lançamento, animação de morte
	target.inventory = {}  # sem poções: a IA não se cura quando a vida fica baixa
	target.set_hp_instant(1)
	waited_s = 0.0
	while waited_s < 6.0 and target.is_alive():
		await create_timer(0.1).timeout
		waited_s += 0.1
	ok(not target.is_alive(), "[%s] o Burn derrota o alvo (hp %d, queimando %s, ticks %d, rodando %s)" % [side, target.hp, target.is_burning(), target.burn_ticks_left, room._battle.running])
	await create_timer(0.3).timeout
	var model: Node3D = room._bs.models.get(target)
	var ap: AnimationPlayer = model.get_meta("anim_player") if model != null and model.has_meta("anim_player") else null
	ok(ap != null and ap.current_animation == "down", "[%s] toca a animação de morte (down): %s" % [side, str(ap.current_animation) if ap != null else "sem player"])
	ok(model != null and model.position.y < 1.0, "[%s] sem lançamento balístico (y = %.2f)" % [side, model.position.y if model != null else -1.0])
