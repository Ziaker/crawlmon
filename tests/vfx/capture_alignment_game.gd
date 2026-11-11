extends SceneTree
## Capturas no enquadramento real do jogo (CINEMA) para conferir centro/frente.

const OUT := "res://test_captures/alignment_game"
var bs: Node3D
var battle: Battle
var cam: Camera3D
var abra: Combatant
var pancham: Combatant
var gible: Combatant


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var packed := load("res://scenes/battle.tscn") as PackedScene
	bs = packed.instantiate()
	root.add_child(bs)
	battle = bs.get_node("Battle")
	await process_frame
	await process_frame
	for c in bs.models.keys():
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	battle.debug_roll = 1
	Engine.time_scale = 1.0
	while not battle.running:
		await process_frame
	await _wait(0.8)
	bs.director.set_process(false)
	cam = bs.get_node("Camera3D")
	cam.current = true
	cam.global_position = Vector3(3.8, 2.875, 7.0)
	cam.look_at(Vector3(-2.0, 0.0, -20.0))
	cam.rotate_object_local(Vector3.BACK, deg_to_rad(4.0))
	cam.fov = 80.0
	abra = battle.party[0]
	pancham = battle.party[1]
	gible = battle.enemies[0]

	await _status_case("01_tarukaja", pancham, "Tarukaja", abra)
	await _status_case("02_rakunda", gible, "Rakunda", abra)
	await _projectile_case("03_confusion", abra, "Confusion", gible, "confusao")
	await _projectile_case("04_psybeam", abra, "Psybeam", gible, "raio_psiquico")
	await _projectile_case("05_dragon_rage", gible, "Dragon Rage", abra, "furia_dragao")
	await _projectile_case("06_bite", gible, "Bite", abra, "mordida")
	await _projectile_case("07_karate", pancham, "Karate Chop", gible, "golpe_carate")
	await _projectile_case("08_dragon_claw", gible, "Dragon Claw", abra, "garra_dragao")

	print("ALIGNMENT_GAME_DONE")
	bs.queue_free()
	await process_frame
	quit(0)


func _status_case(tag: String, actor: Combatant, move: String, target: Combatant) -> void:
	await _wait_ready()
	actor.atb = 5.0
	battle.use_skill(actor, _find(actor, move), target)
	await _wait(1.15)
	await _snap(tag)
	await _wait(1.0)
	await _snap(tag + "_late")
	await _wait_ready()


func _projectile_case(tag: String, actor: Combatant, move: String, target: Combatant, _move_id: String) -> void:
	await _wait_ready()
	actor.atb = 5.0
	target.hp = target.max_hp
	var before := target.hp
	battle.use_skill(actor, _find(actor, move), target)
	await _wait(0.95)
	await _snap(tag + "_windup")
	var guard := 0
	while guard < 300 and target.hp >= before:
		await process_frame
		guard += 1
	await _wait(0.10)
	await _snap(tag + "_hit")
	await _wait(0.35)
	await _snap(tag + "_hit_late")
	await _wait_ready()


func _wait_ready() -> void:
	var guard := 0
	while guard < 600 and (battle._status_pause != null or not battle.incoming.is_empty() or not battle.attacks_in_flight().is_empty()):
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.hp = c.max_hp
		c.atb = 0.0
		c.clear_pending()
		c.clear_rest()
		c.engaged_with = null
		c.pos = c.home
	battle._update_positions()
	await process_frame


func _find(c: Combatant, name: String) -> Skill:
	for s in c.skills:
		if s.display_name == name:
			return s
	return null


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout


func _snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT + "/" + name + ".png")
		print("SNAP ", name)
