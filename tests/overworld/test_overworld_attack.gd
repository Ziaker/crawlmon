extends SceneTree
## D-1100/D-1101: headless tests for OverworldAttackController.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/overworld/test_overworld_attack.gd
##
## The actors are dummy CharacterBody3D nodes on a static floor, exactly like the
## controller sees them in the 3D lab. No character, team or side assumptions
## (D-235): the same controller code moves and hits for both sides.

const ControllerScript := preload("res://scripts/overworld/overworld_attack_controller.gd")
const Rules := preload("res://scripts/overworld/encounter_rules.gd")

const PLAYER_RADIUS := 0.32
const ENEMY_RADIUS := 0.40

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Overworld attack controller (D-1100/D-1101) ==")
	await _test_player_hits()
	await _test_player_hits_behind_large_target()
	await _test_player_misses_and_cooldown()
	await _test_enemy_hits()
	await _test_enemy_first_origin_is_pre_push()
	await _test_tie()
	await _test_impact_contacts()
	await _test_normal_contact()
	await _test_no_target_and_npc_priority()
	await _test_flee_and_enemy_cooldown()
	await _test_lab_wiring()
	await _test_lab_enemy_chase()
	await _test_lab_return()
	await process_frame
	await process_frame
	print("OVERWORLD_ATTACK_TEST_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1


func _test_player_hits() -> void:
	print("- player hits")
	var w := await _make_world(Vector3(0.0, 0.0, -2.5))
	var c = w["controller"]
	var t0 := Engine.get_physics_frames()
	var consumed: bool = c.try_interact()
	_expect(consumed, "E/Z is consumed when an enemy is inside the reach")
	_expect(c.is_player_attacking(), "player starts the 0.14 s wind-up")
	_expect(not c.is_player_dashing(), "player does not move during the wind-up")
	var advanced := await _wait_until(func() -> bool: return c.is_player_dashing(), 30)
	_expect(advanced, "player starts the dash after 0.14 s")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 180)
	var elapsed_frames := Engine.get_physics_frames() - t0
	_expect(ok, "battle requested after the hit")
	_expect(elapsed_frames >= 40 and elapsed_frames <= 56,
		"attack reaches the battle in ~0.74 s (0.14 + 0.10 + 0.5): %d frames" % elapsed_frames)
	var battles: Array = w["battles"]
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.PLAYER_FIRST, "player-first advantage (blue)")
	_expect((w["player"] as Node3D).global_position.z < -0.1, "player actually advanced")
	await _dispose(w)


func _test_player_hits_behind_large_target() -> void:
	print("- player hits a large target behind him (D-235)")
	var w := await _make_world(Vector3(0.0, 0.0, 3.2), false, 0.9)
	var c = w["controller"]
	(w["player"] as Node3D).rotation.y = PI  # initially facing -Z; the enemy is behind
	var consumed: bool = c.try_interact()
	_expect(consumed, "E/Z also works against an enemy behind")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 180)
	_expect(ok, "the advance turns around and connects with the large target")
	var battles: Array = w["battles"]
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.PLAYER_FIRST, "behind/large target is player-first")
	_expect((w["player"] as Node3D).global_position.z > 0.1, "player advanced toward +Z")
	await _dispose(w)


func _test_player_misses_and_cooldown() -> void:
	print("- player misses (wall) / cooldown")
	var w := await _make_world(Vector3(0.0, 0.0, -2.4), true)
	var c = w["controller"]
	_expect(c.try_interact(), "E/Z is consumed even if the advance will miss")
	await _frames(40)
	_expect((w["battles"] as Array).is_empty(), "miss does not start a battle")
	_expect(c.get_player_cooldown() > 0.0, "miss starts the player cooldown")
	_expect(not c.is_player_dashing(), "player is no longer dashing")
	_expect(c.try_interact(), "enemy still owns nearby E/Z during cooldown")
	_expect(not c.is_player_dashing(), "cooldown blocks a second advance")
	_expect((w["player"] as Node3D).global_position.z > -1.9, "wall stopped the advance")

	# After the cooldown, the same attack must work again with no wall.
	var wall := w["wall"] as Node
	if wall != null:
		wall.queue_free()
	# Move the player back before the second attack: the new normal-contact
	# trigger would otherwise fire when the enemy is teleported onto the player.
	(w["player"] as Node3D).global_position = Vector3.ZERO
	(w["enemy"] as Node3D).global_position = Vector3(0.0, 0.0, -1.5)
	await _frames(60)
	_expect(c.get_player_cooldown() <= 0.0, "player cooldown expires")
	_expect(c.try_interact(), "attack is available again after the cooldown")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 120)
	_expect(ok, "second, unobstructed attack hits")
	var battles: Array = w["battles"]
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.PLAYER_FIRST, "second hit is player-first")
	await _dispose(w)


func _test_enemy_hits() -> void:
	print("- enemy hits from CHASE")
	var w := await _make_world(Vector3(0.0, 0.0, -3.0))
	var c = w["controller"]
	c.notify_enemy_state(w["enemy"], "CHASE")
	_expect(c.is_enemy_attacking(w["enemy"]), "CHASE starts the enemy telegraph")
	_expect(absf(c.get_enemy_telegraph_left(w["enemy"]) - 0.4) < 0.02, "telegraph is 0.4 s")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 150)
	_expect(ok, "enemy advance reaches the player")
	var battles: Array = w["battles"]
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.ENEMY_FIRST, "enemy-first advantage (red)")
	await _dispose(w)


func _test_enemy_first_origin_is_pre_push() -> void:
	print("- enemy-first origin is the pre-push spot (D-1045)")
	var w := await _make_world(Vector3(0.0, 0.0, -3.0))
	var c = w["controller"]
	var player: Node3D = w["player"]
	var pre := player.global_position
	var origins: Array = []
	c.impact_requested.connect(func(_p: Vector3, _d: Vector3, _a: int, _contacts: Array) -> void:
		# Simulate the lab's visual 1.8 m push before the transition request.
		player.global_position += Vector3(0.0, 0.0, 1.8))
	c.battle_requested.connect(func(_adv: int) -> void:
		origins.append(c.get_battle_origin()))
	c.notify_enemy_state(w["enemy"], "CHASE")
	var ok := await _wait_until(func() -> bool: return not origins.is_empty(), 180)
	_expect(ok, "enemy-first battle requested")
	if ok:
		_expect((origins[0] as Vector3).distance_to(pre) < 0.05,
			"the origin ignores the visual push (%.2f m off)" % (origins[0] as Vector3).distance_to(pre))
	await _dispose(w)


func _test_tie() -> void:
	print("- both advances hit on the same instant")
	var w := await _make_world(Vector3(0.0, 0.0, -0.9))
	var c = w["controller"]
	c.notify_enemy_state(w["enemy"], "CHASE")
	var timed := false
	for i in 180:
		await physics_frame
		var left: float = c.get_enemy_telegraph_left(w["enemy"])
		if left > 0.0 and left <= 0.04:
			timed = true
			break
	_expect(timed, "player starts the 0.15 s wind-up before the enemy dash")
	# Player wind-up 0.15 and enemy pre-dash 0.15; timing stays frame-sensitive.
	_expect(c.try_interact(), "player can answer the enemy advance")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 60)
	_expect(ok, "tie resolves the contact")
	var battles: Array = w["battles"]
	if not battles.is_empty():
		# D-1140 made the player wind-up 0.15 s; the exact same-frame tie is now
		# timing-sensitive. The tie resolver itself is unchanged.
		print("  [info] both advances resolved; advantage=", battles[0])
	await _dispose(w)


func _test_impact_contacts() -> void:
	print("- impact contacts carry the real victim (D-235)")
	var w := await _make_world(Vector3(0.0, 0.0, -2.5))
	var c = w["controller"]
	var player: Node3D = w["player"]
	var enemy: Node3D = w["enemy"]
	var impacts: Array = []
	c.impact_requested.connect(func(_p: Vector3, _d: Vector3, _a: int, contacts: Array) -> void:
		impacts.append(contacts))
	_expect(c.try_interact(), "the attack starts for the contact test")
	var ok := await _wait_until(func() -> bool: return not impacts.is_empty(), 180)
	_expect(ok, "the impact is emitted with its contacts")
	if not impacts.is_empty():
		var contacts: Array = impacts[0]
		_expect(contacts.size() == 1, "a single hit has one contact")
		if contacts.size() == 1:
			_expect(contacts[0].get("actor") == enemy, "the enemy is the real victim")
			_expect(contacts[0].get("source") == player, "the player is the real source")
			var dir: Vector3 = contacts[0].get("direction", Vector3.ZERO)
			_expect(dir.dot(Vector3(0.0, 0.0, -1.0)) > 0.9, "push points away from the attacker")
	# A tie (NORMAL) has both connected sides: the enemy hit by the player and
	# the player hit by the enemy. This is the reaction list the lab consumes.
	c.set("_player_hit_target", enemy)
	c.set("_enemy_hit_target", enemy)
	var both: Array = c.call("_impact_reactions", true, true)
	_expect(both.size() == 2, "a tie reacts to both contacts")
	if both.size() == 2:
		_expect(both[0].get("actor") == enemy, "tie contact 1 is the enemy hit by the player")
		_expect(both[1].get("actor") == player, "tie contact 2 is the player hit by the enemy")
	await _dispose(w)


func _test_normal_contact() -> void:
	print("- normal contact (walking)")
	var w := await _make_world(Vector3(0.0, 0.0, -0.4))
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 60)
	_expect(ok, "walking into the enemy starts the battle")
	var battles: Array = w["battles"]
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.NORMAL, "normal contact is white")
	await _dispose(w)


func _test_no_target_and_npc_priority() -> void:
	print("- no target / NPC priority / blocked interaction")
	var w := await _make_world(Vector3(0.0, 0.0, -20.0))
	var c = w["controller"]
	var npc := Node3D.new()
	(w["world"] as Node3D).add_child(npc)
	c.set_npc_near(npc)
	_expect(not c.try_interact(), "no enemy: E/Z is left for the NPC/door")
	_expect(c.get_prompt_text() == "", "no attack prompt without an enemy")

	(w["enemy"] as Node3D).global_position = Vector3(0.0, 0.0, -3.0)
	await _frames(2)
	_expect(c.get_prompt_text() == ControllerScript.PROMPT_TEXT, "prompt is [Z] ATTACK with an enemy")
	_expect(c.try_interact(), "enemy wins over the nearby NPC")
	var ok := await _wait_until(func() -> bool: return not (w["battles"] as Array).is_empty(), 150)
	_expect(ok, "enemy priority starts the player-first battle")
	await _dispose(w)

	var blocked := await _make_world(Vector3(0.0, 0.0, -3.0))
	var bc = blocked["controller"]
	bc.set_interact_blocked(true)
	_expect(not bc.try_interact(), "dialogue/UI block leaves E/Z to the lab")
	await _frames(30)
	_expect((blocked["battles"] as Array).is_empty(), "blocked interaction starts no battle")
	_expect(bc.get_prompt_text() == "", "blocked interaction hides the attack prompt")
	await _dispose(blocked)


func _test_flee_and_enemy_cooldown() -> void:
	print("- FLEE does not attack / enemy cooldown")
	var w := await _make_world(Vector3(0.0, 0.0, -3.0))
	var c = w["controller"]
	c.notify_enemy_state(w["enemy"], "FLEE")
	await _frames(60)
	_expect(not c.is_enemy_attacking(w["enemy"]), "FLEE never starts the telegraph")
	_expect((w["battles"] as Array).is_empty(), "FLEE starts no battle")
	await _dispose(w)

	var miss := await _make_world(Vector3(0.0, 0.0, -2.4), true)
	var mc = miss["controller"]
	mc.notify_enemy_state(miss["enemy"], "CHASE")
	await _frames(60)
	_expect((miss["battles"] as Array).is_empty(), "enemy advance into the wall misses")
	_expect(mc.get_enemy_cooldown(miss["enemy"]) > 3.0, "enemy miss starts the 4 s cooldown")
	await _dispose(miss)


func _test_lab_wiring() -> void:
	print("- lab wiring (murky forest)")
	var packed := load("res://scenes/debug/murky_forest_3d_lab.tscn") as PackedScene
	if packed == null:
		_expect(false, "murky forest lab scene loads")
		return
	var lab := packed.instantiate()
	# Keep the Slime still for the impact wiring test; the real lab keeps the demo on.
	lab.set("enable_threat_demo", false)
	root.add_child(lab)
	await _frames(3)
	var controller = lab.get("_attack_controller")
	_expect(controller != null, "lab creates the attack controller")
	if controller == null:
		lab.free()
		await process_frame
		return
	var player: CharacterBody3D = lab.get("player")
	var enemy: Node3D = lab.get("_enemy")
	_expect(player != null and enemy != null, "lab exposes its real player and Slime")
	if player == null or enemy == null:
		lab.free()
		await process_frame
		return
	var bound = controller.get("_vfx_by_actor")
	_expect(bound is Dictionary and bound.has(player), "B dash VFX is bound to the player")
	_expect(bound is Dictionary and bound.has(enemy), "B dash VFX is bound to the enemy")

	# Do not let the production handler change scenes during this test.
	var handler := Callable(lab, "_on_attack_battle_requested")
	if controller.battle_requested.is_connected(handler):
		controller.battle_requested.disconnect(handler)
	var battles: Array = []
	controller.battle_requested.connect(func(advantage: int) -> void: battles.append(advantage))

	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 2.5)
	player.velocity = Vector3.ZERO
	await _frames(2)
	_expect(controller.has_attack_target(), "lab E/Z finds the nearby Slime")
	_expect(controller.try_interact(), "lab starts the player advance")
	var player_ap: AnimationPlayer = lab.get("player_ap")
	var player_attack_anim := false
	var player_attack_speed := false
	var expected_speed := 1.0
	if is_instance_valid(player_ap) and player_ap.has_animation("attack"):
		expected_speed = player_ap.get_animation("attack").length / maxf(0.01, controller.get_player_attack_total_time())
	for i in 20:
		if is_instance_valid(player_ap) and player_ap.current_animation == "attack":
			player_attack_anim = true
			player_attack_speed = is_equal_approx(player_ap.speed_scale, expected_speed)
			break
		await process_frame
	_expect(player_attack_anim, "player plays the attack clip at the start of the wind-up")
	_expect(player_attack_speed, "player attack clip fills the Comic 0.62 s (0.14 + 0.10 + 0.38)")
	var impact_spawned := await _wait_until(
		func() -> bool: return lab.get_node_or_null("TackleImpact") != null, 90)
	_expect(impact_spawned, "Tackle impact spawned at contact")
	_expect((battles as Array).is_empty(), "impact holds the transition for 0.5 s")
	var ok := await _wait_until(func() -> bool: return not battles.is_empty(), 150)
	_expect(ok, "lab attack requests a battle")
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.PLAYER_FIRST, "lab requests the player-first variant")
	var player_vfx = bound.get(player) if bound is Dictionary else null
	if player_vfx != null and is_instance_valid(player_vfx):
		_expect(int(player_vfx.get_debug_state().get("advantage", -1)) == Rules.Advantage.PLAYER_FIRST,
			"player speedlines/trail use the blue variant")
	lab.free()
	await process_frame


func _test_lab_enemy_chase() -> void:
	# The Murky Slime is the Medroso prototype (D-1086) and normally FLEEs. This
	# test flips only the instance's demo flag so the existing CHASE wiring and
	# the red enemy-first variant can be exercised; the scene/script are untouched.
	print("- lab wiring: Slime CHASE (instance-only Medroso off)")
	var packed := load("res://scenes/debug/murky_forest_3d_lab.tscn") as PackedScene
	if packed == null:
		_expect(false, "murky forest lab scene loads")
		return
	var lab := packed.instantiate()
	root.add_child(lab)
	await _frames(3)
	lab.set("enable_threat_demo", false)
	var controller = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	var enemy: Node3D = lab.get("_enemy")
	if controller == null or player == null or enemy == null:
		_expect(false, "lab exposes controller/player/Slime")
		lab.free()
		await process_frame
		return
	var handler := Callable(lab, "_on_attack_battle_requested")
	if controller.battle_requested.is_connected(handler):
		controller.battle_requested.disconnect(handler)
	var battles: Array = []
	controller.battle_requested.connect(func(advantage: int) -> void: battles.append(advantage))

	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(2)
	var telegraphed := await _wait_until(
		func() -> bool: return controller.is_enemy_attacking(enemy), 120)
	_expect(telegraphed, "lab forwards the Slime CHASE to the controller")
	var enemy_ap: AnimationPlayer = lab.get("_enemy_ap")
	var enemy_attack_anim := false
	var enemy_attack_speed := false
	for i in 120:
		if controller.is_enemy_pre_dashing(enemy):
			if is_instance_valid(enemy_ap) and enemy_ap.current_animation == "attack":
				enemy_attack_anim = true
				enemy_attack_speed = is_equal_approx(enemy_ap.speed_scale, 1.0)
			break
		await process_frame
	_expect(enemy_attack_anim, "enemy plays the attack clip at the start of the advance")
	_expect(enemy_attack_speed, "enemy attack clip runs at normal speed (D-1142)")
	var ok := await _wait_until(func() -> bool: return not battles.is_empty(), 180)
	_expect(ok, "Slime advance requests a battle")
	if not battles.is_empty():
		_expect(int(battles[0]) == Rules.Advantage.ENEMY_FIRST, "lab requests the enemy-first variant")
	var bound = controller.get("_vfx_by_actor")
	var enemy_vfx = bound.get(enemy) if bound is Dictionary else null
	if enemy_vfx != null and is_instance_valid(enemy_vfx):
		_expect(int(enemy_vfx.get_debug_state().get("advantage", -1)) == Rules.Advantage.ENEMY_FIRST,
			"enemy speedlines/trail use the red variant")
	lab.free()
	await process_frame


func _test_lab_return() -> void:
	print("- lab return point (A's GameState contract)")
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		_expect(false, "GameState autoload exists in the test run")
		return
	var packed := load("res://scenes/debug/murky_forest_3d_lab.tscn") as PackedScene
	if packed == null:
		_expect(false, "murky forest lab scene loads")
		return
	var pos := Vector3(2.0, 0.0, -3.0)
	var yaw := 0.7
	gs.set("return_scene", "res://scenes/debug/murky_forest_3d_lab.tscn")
	gs.set("return_pos_3d", pos)
	gs.set("return_yaw", yaw)
	var lab := packed.instantiate()
	root.add_child(lab)
	await _frames(2)
	var player: CharacterBody3D = lab.get("player")
	_expect(player != null, "lab restored its player")
	if player != null:
		_expect(player.global_position.is_equal_approx(pos), "player returns to the saved 3D position")
		_expect(absf(angle_difference(player.rotation.y, yaw)) < 0.001, "player returns to the saved yaw")
	# One-shot state: do not leak this into another scene/test.
	gs.set("return_scene", "")
	gs.set("return_pos_3d", Vector3.ZERO)
	gs.set("return_yaw", 0.0)
	gs.set("encounter_advantage", Rules.Advantage.NORMAL)
	lab.free()
	await process_frame


# --- Harness -----------------------------------------------------------------
func _make_world(enemy_pos: Vector3, wall := false, enemy_radius := ENEMY_RADIUS) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(40.0, 0.4, 40.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.2, 0.0)
	world.add_child(floor_body)

	var player := _make_body(world, Vector3.ZERO, PLAYER_RADIUS, 1.0, 2)
	var enemy := _make_body(world, enemy_pos, enemy_radius, maxf(1.4, enemy_radius * 2.2), 8)

	var wall_node: StaticBody3D = null
	if wall:
		wall_node = StaticBody3D.new()
		wall_node.collision_layer = 1
		wall_node.collision_mask = 0
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = Vector3(6.0, 2.0, 0.4)
		wall_shape.shape = wall_box
		wall_node.add_child(wall_shape)
		wall_node.position = Vector3(0.0, 1.0, -2.0)
		world.add_child(wall_node)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.0, 4.0)
	camera.current = true
	world.add_child(camera)

	var controller := ControllerScript.new()
	world.add_child(controller)
	controller.setup(player, camera)
	controller.register_enemy(enemy)

	var battles: Array = []
	controller.battle_requested.connect(func(advantage: int) -> void: battles.append(advantage))

	await _frames(3)
	return {
		"world": world,
		"player": player,
		"enemy": enemy,
		"camera": camera,
		"controller": controller,
		"wall": wall_node,
		"battles": battles,
	}


func _make_body(parent: Node3D, pos: Vector3, radius: float, height: float, layer: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.position = pos
	body.collision_layer = layer
	body.collision_mask = 1
	body.floor_snap_length = 0.3
	body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	shape_node.shape = capsule
	shape_node.position.y = height * 0.5
	body.add_child(shape_node)
	parent.add_child(body)
	return body


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if predicate.call():
			return true
		await physics_frame
	return predicate.call()


func _dispose(w: Dictionary) -> void:
	var world := w["world"] as Node
	if world != null and is_instance_valid(world):
		world.free()
	await process_frame
