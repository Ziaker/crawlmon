extends SceneTree
## Captura o Bubble Shield na câmera real do jogo.
## Rodar SEM --headless:
##   Godot --path . --resolution 1280x720 --script res://tests/vfx/capture_bubble_shield.gd

const OUT := "res://test_captures/bubble_shield"

var _bs: Node3D
var _battle: Battle
var _fx: BattleFx
var _abra: Combatant
var _gible: Combatant
var _skill: Skill


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var packed := load("res://scenes/battle.tscn") as PackedScene
	_bs = packed.instantiate()
	root.add_child(_bs)
	_battle = _bs.get_node("Battle")
	_fx = _bs.fx
	var guard := 0
	while not _battle.running and guard < 900:
		await process_frame
		guard += 1
	for c in _battle.party + _battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	_abra = _battle.party[0]
	_gible = _battle.enemies[0]
	for s in _abra.skills:
		if s.display_name == "Bubble Shield":
			_skill = s
	# Câmera de cinema fixa (mesma do jogo).
	if _bs.director != null:
		_bs.director.set_process(false)
		_bs.director.cinema(0.0)
	for i in 8:
		await process_frame

	await _capture("01_idle")

	_abra.atb = 5.0
	_battle.use_skill(_abra, _skill, _abra)
	await _wait(0.30)
	await _capture("02_windup")
	await _wait(0.30)
	await _capture("03_windup_late")
	await _wait(0.42)
	await _capture("04_forming")
	await _wait(0.55)
	await _capture("05_forming_late")
	await _wait(0.65)
	await _capture("06_active")

	# Hit no lado da câmera.
	_battle._hit(_gible, _abra, 0.35, Element.Type.FISICO, "Tackle")
	await _wait(0.08)
	await _capture("07_hit")
	await _wait(0.20)
	await _capture("08_hit_late")

	# Ruptura: reserva a 1 e novo golpe.
	_abra.shield_hp = 1
	_battle._hit(_gible, _abra, 0.35, Element.Type.FISICO, "Tackle")
	await _wait(0.10)
	await _capture("09_break")
	await _wait(0.22)
	await _capture("10_break_burst")
	await _wait(0.45)
	await _capture("11_break_end")

	# Reaplica e força a expiração.
	while _battle._status_pause != null:
		await process_frame
	_abra.atb = 5.0
	_battle.use_skill(_abra, _skill, _abra)
	while not _abra.is_shielded():
		await process_frame
	await _wait(1.15)
	await _capture("12_active_again")
	_abra.tick_shield(8.0)
	await _wait(0.16)
	await _capture("13_expire")
	await _wait(0.42)
	await _capture("14_expire_burst")
	await _wait(0.60)
	await _capture("15_expire_end")

	# Prova de genericidade: bolha no inimigo (Gible, escala 2.16), centrada
	# pelo esqueleto e com splash no lado da câmera.
	_gible.apply_shield(60, 8.0)
	_fx.fx_bubble.on_shield_started(_abra, _gible)
	await _wait(1.10)
	await _capture("16_gible_active")
	var gv = _fx.fx_bubble._bubbles.get(_gible)
	if gv != null:
		var cam_g: Vector3 = _fx._cam_pos()
		var to_cam_g := Vector3(cam_g.x - gv.center.x, 0.0, cam_g.z - gv.center.z).normalized()
		var p_g: Vector3 = _fx.fx_bubble.camera_hit_point(gv.center, gv.radius)
		var to_p_g := Vector3(p_g.x - gv.center.x, 0.0, p_g.z - gv.center.z).normalized()
		print("GIBLE center=", gv.center, " radius=", gv.radius, " camera_dot=", to_p_g.dot(to_cam_g))
	_battle._hit(_abra, _gible, 0.3, Element.Type.FISICO, "Tackle")
	await _wait(0.08)
	await _capture("17_gible_hit")

	print("BUBBLE_SHIELD_CAPTURE_DONE")
	_bs.queue_free()
	await process_frame
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, false).timeout


func _capture(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		print("CAPTURE_FAIL ", name)
		return
	var path := OUT + "/" + name + ".png"
	var err := img.save_png(path)
	print("CAPTURE ", "OK " if err == OK else "ERROR %d " % err, path)
