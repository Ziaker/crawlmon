extends SceneTree
## Visual check of QoL 1-8 on the current branch. Runs windowed and saves to
## test_captures/qol/.

const OUT := "res://test_captures/qol"
var bs: Node3D
var battle: Battle
var hud: BattleHud
var cam: Camera3D
var abra: Combatant
var gible: Combatant
var menu_node: Node


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
	await _wait(0.7)
	bs.director.set_process(false)
	cam = bs.get_node("Camera3D")
	cam.current = true
	cam.global_position = Vector3(5.8, 3.2, 8.8)
	cam.look_at(Vector3(1.6, 1.25, -0.2))
	cam.rotate_object_local(Vector3.BACK, deg_to_rad(3.0))
	cam.fov = 52.0
	abra = battle.party[0]
	gible = battle.enemies[0]
	hud = bs.hud
	menu_node = root.get_node_or_null("Menus")

	# QoL 2 + 4: real timers and a queued move on the leader card.
	abra.apply_shield(37, 6.4)
	abra.guard_timer = 1.7
	abra.queued_skill = Skill.new("Bubble Shield", 0.0, 3, Element.Type.AGUA_GELO, Skill.Kind.STATUS, false, true, true, 0.7)
	abra.queued_target = abra
	# QoL 1: every event family in the history.
	for line in [
		"Abra usa Bubble Shield! 37 de reserva sem tipo para cada aliado (8 s).",
		"Gible prepara Dragon Rage em Abra...",
		"Abra desvia perfeitamente e surge diante de Gible! BURST!",
		"Gible usa Rakunda! A defesa de Abra foi reduzida!",
		"Braço de ferro! A Guard de Abra foi quebrada.",
		"Gible sofre Burn! O fogo queima por 4 s.",
		"Media cura a equipe! Abra recupera 22 HP.",
	]:
		battle.log_message.emit(line)

	# QoL 3/8: a real sheet for a support move and for a damage move.
	var bubble := Skill.new("Bubble Shield", 0.0, 3, Element.Type.AGUA_GELO, Skill.Kind.STATUS, false, true, true, 0.7)
	abra.skills.append(bubble)
	# QoL 5: enough moves for a second page.
	for i in 4:
		abra.skills.append(Skill.new("Extra %d" % (i + 1), 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.0))

	bs._show_fight()
	await _wait(0.35)
	await _snap("01_fight_page1")

	bs._menu.select(8)  # Tackle + 8 skills: Bubble Shield
	await _wait(0.25)
	await _snap("02_move_sheet_bubble")

	bs._menu.select(1)  # Confusion
	await _wait(0.25)
	await _snap("03_move_sheet_damage")

	bs._change_fight_page(1)
	await _wait(0.25)
	await _snap("04_fight_page2")

	# QoL 2: paused Status card with timers and move effects.
	bs._show_status()
	await _wait(0.45)
	await _snap("05_status_timers")
	hud._status.visible = false
	hud._status.closed.emit()
	await _wait(0.2)

	# QoL 1 (log toggle) removed with the panel (D-959).

	# QoL 6: pickup and full-inventory toasts.
	if menu_node != null:
		menu_node.call("toast", "Poção +1   ·   4/20", Color("d7fd6a"), 4.0)
		await _wait(0.3)
		await _snap("08_toast_pickup")
		menu_node.call("toast", "Inventário cheio — libere um slot", Color("ff8a72"), 4.0)
		await _wait(0.3)
		await _snap("09_toast_full")
		# QoL 7: settings row.
		menu_node.call("_open", 3)  # Mode.SETTINGS
		menu_node.call("_build_settings", false)
		await _wait(0.25)
		await _snap("10_settings_text_speed")
		menu_node.call("_close")

	# QoL 3: out-of-combat Status detail with effect/description.
	var gs := root.get_node_or_null("GameState")
	if gs != null:
		var ss := StatusScreen.new()
		root.add_child(ss)
		ss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var party: Array[Combatant] = gs.party
		ss.open(party, 0)
		ss._detail_open = true
		ss._move = 8
		await _snap("11_status_screen_effect")
		ss.queue_free()

	print("QOL_CAPTURE_DONE")
	bs.queue_free()
	await process_frame
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout


func _snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT + "/" + name + ".png")
		print("SNAP ", name)
