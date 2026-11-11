extends SceneTree
## D-1100/D-1101 end-to-end: lab attack -> EncounterTransition -> BattleScene
## (ATB advantage applied) -> GameState.end_battle -> lab at the saved spot.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/overworld/test_end_to_end_attack_flow.gd
##
## This complements the unit tests: it does not replace the controller/VFX
## harnesses, it proves the scene hand-off and the one-shot return point.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const BATTLE := "res://scenes/battle.tscn"

var _fail := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== END-TO-END D-1100: lab attack -> transition -> battle -> return ==")
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		_check(false, "GameState autoload exists in the test run")
		_finish()
		return
	await _run_player_first(gs)
	await _run_enemy_first(gs)
	await _run_second_enemy_defeat(gs)
	_finish()


func _finish() -> void:
	# Never leak the one-shot return/advantage into another test in the same process.
	var gs = root.get_node_or_null("GameState")
	if gs != null:
		gs.set("return_scene", "")
		gs.set("return_pos_3d", Vector3.ZERO)
		gs.set("return_yaw", 0.0)
		gs.set("encounter_advantage", 0)
	print("END_TO_END_ATTACK: ", "OK" if _fail == 0 else "%d FALHAS" % _fail)
	quit(0 if _fail == 0 else 1)


func _run_player_first(gs) -> void:
	print("- player-first (blue)")
	var lab := await _load_lab()
	if lab == null:
		return
	# Keep the Medroso still; the test is about the player advance, not FLEE.
	lab.set("enable_threat_demo", false)
	var controller = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	var enemy: Node3D = lab.get("_enemy")
	if controller == null or player == null or enemy == null:
		_check(false, "lab exposes controller/player/enemy")
		lab.free()
		return

	# The Murky Slime is the Medroso demo; the player can still attack it.
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 2.5)
	player.velocity = Vector3.ZERO
	await _frames(2)
	var pre_pos := player.global_position
	var pre_yaw := player.rotation.y
	_check(controller.try_interact(), "E/Z starts the player advance")

	if not await _wait_for_scene(BATTLE, 900):
		_check(false, "transition loaded BattleScene (player-first)")
		return
	var bs = await _wait_for_battle_running(900)
	if bs == null:
		_check(false, "battle.running after the transition (player-first)")
		return
	_check_all_atb(bs.battle.party, 4.0, "player-first party starts at 4")
	_check_all_atb(bs.battle.enemies, 2.0, "player-first enemies start at 2")

	var saved_pos: Vector3 = gs.get("return_pos_3d")
	var saved_yaw: float = gs.get("return_yaw")
	_check(saved_pos.distance_to(pre_pos) < 0.60,
		"player-first return point is the pre-advance spot (%.2f m off)" % saved_pos.distance_to(pre_pos))
	gs.end_battle(true)
	_check(await _wait_for_scene(LAB, 900), "battle returned to the lab (player-first)")
	var lab2 = current_scene
	var p2: CharacterBody3D = lab2.get("player") if lab2 != null else null
	_check(p2 != null and p2.global_position.distance_to(saved_pos) < 0.20,
		"lab restored the player position (player-first)")
	_check(p2 != null and absf(angle_difference(p2.rotation.y, saved_yaw)) < 0.02,
		"lab restored the player yaw (player-first)")


func _run_enemy_first(gs) -> void:
	print("- enemy-first (red)")
	var lab := await _load_lab()
	if lab == null:
		return
	# Instance-only: the Slime is the Medroso demo (D-1086) and would FLEE.
	# Flipping this flag proves the CHASE -> telegraph -> red variant wiring.
	lab.set("enable_threat_demo", false)
	var controller = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	var enemy: Node3D = lab.get("_enemy")
	if controller == null or player == null or enemy == null:
		_check(false, "lab exposes controller/player/enemy (enemy-first)")
		lab.free()
		return

	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(2)
	var pre_pos := player.global_position
	var pre_yaw := player.rotation.y
	var telegraphed := false
	for i in 180:
		if is_instance_valid(enemy) and is_instance_valid(controller) and controller.is_enemy_attacking(enemy):
			telegraphed = true
			break
		await process_frame
	_check(telegraphed, "Slime entered CHASE and telegraphed")

	if not await _wait_for_scene(BATTLE, 900):
		_check(false, "transition loaded BattleScene (enemy-first)")
		return
	var bs = await _wait_for_battle_running(900)
	if bs == null:
		_check(false, "battle.running after the transition (enemy-first)")
		return
	_check_all_atb(bs.battle.party, 2.0, "enemy-first party starts at 2")
	_check_all_atb(bs.battle.enemies, 4.0, "enemy-first enemies start at 4")

	var saved_pos: Vector3 = gs.get("return_pos_3d")
	var saved_yaw: float = gs.get("return_yaw")
	_check(saved_pos.distance_to(pre_pos) < 0.60,
		"enemy-first return point is the player spot (%.2f m off)" % saved_pos.distance_to(pre_pos))
	gs.end_battle(true)
	_check(await _wait_for_scene(LAB, 900), "battle returned to the lab (enemy-first)")
	var lab2 = current_scene
	var p2: CharacterBody3D = lab2.get("player") if lab2 != null else null
	_check(p2 != null and p2.global_position.distance_to(saved_pos) < 0.20,
		"lab restored the player position (enemy-first)")
	_check(p2 != null and absf(angle_difference(p2.rotation.y, saved_yaw)) < 0.02,
		"lab restored the player yaw (enemy-first)")


func _run_second_enemy_defeat(gs) -> void:
	print("- second enemy (Gible) + defeat without resetting the 2D expedition")
	var floor_before: int = gs.get("visual_floor")
	var seed_before: int = gs.get("dungeon_seed")
	var inventory_before: Dictionary = (gs.get("inventory") as Dictionary).duplicate()
	var lab := await _load_lab()
	if lab == null:
		return
	var controller = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	var second_enemy: Node3D = lab.get("_second_enemy")
	if controller == null or player == null or second_enemy == null:
		_check(false, "lab exposes the second enemy")
		lab.free()
		return
	player.global_position = second_enemy.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(2)

	var telegraphed := false
	for i in 180:
		if is_instance_valid(second_enemy) and is_instance_valid(controller) \
				and controller.is_enemy_attacking(second_enemy):
			telegraphed = true
			break
		await process_frame
	_check(telegraphed, "Gible entered CHASE and telegraphed")
	var pre := false
	for i in 180:
		if is_instance_valid(second_enemy) and is_instance_valid(controller) \
				and controller.is_enemy_pre_dashing(second_enemy):
			pre = true
			break
		await process_frame
	_check(pre, "Gible entered the 0.15 s pre-advance")
	var gible_ap: AnimationPlayer = lab.get("_second_enemy_ap")
	_check(is_instance_valid(gible_ap) and gible_ap.current_animation == "attack" \
			and is_equal_approx(gible_ap.speed_scale, 1.0),
		"Gible plays the attack clip at normal speed (D-1142)")
	var dashing := false
	for i in 180:
		if is_instance_valid(second_enemy) and is_instance_valid(controller) \
				and controller.is_enemy_dashing(second_enemy):
			dashing = true
			break
		await process_frame
	_check(dashing, "Gible started the dash")
	var bound: Dictionary = controller.get("_vfx_by_actor")
	var second_vfx: Node = bound.get(second_enemy) if bound is Dictionary else null
	_check(second_vfx != null, "Gible has its own dash VFX")
	if second_vfx != null:
		_check(int(second_vfx.get_debug_state().get("advantage", -1)) == 2,
			"Gible dash VFX uses the red variant")

	if not await _wait_for_scene(BATTLE, 900):
		_check(false, "Gible attack loaded BattleScene")
		return
	var bs = await _wait_for_battle_running(900)
	if bs == null:
		_check(false, "battle.running after the Gible attack")
		return
	_check_all_atb(bs.battle.party, 2.0, "Gible enemy-first party starts at 2")
	_check_all_atb(bs.battle.enemies, 4.0, "Gible enemy-first enemies start at 4")

	gs.end_battle(false)
	_check(await _wait_for_scene(LAB, 900), "defeat returned to the lab")
	_check(int(gs.get("visual_floor")) == floor_before, "defeat did not reset the 2D floor")
	_check(int(gs.get("dungeon_seed")) == seed_before, "defeat did not reset the 2D dungeon seed")
	_check((gs.get("inventory") as Dictionary) == inventory_before, "defeat did not reset the 2D inventory")
	var party: Array = gs.get("party")
	_check(not party.is_empty() and party[0].hp > 0, "defeat revived the party")


func _load_lab() -> Node:
	var packed := load(LAB) as PackedScene
	if packed == null:
		_check(false, "murky forest lab scene loads")
		return null
	var lab := packed.instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(5)
	return lab


func _wait_for_scene(path: String, max_frames: int) -> bool:
	for i in max_frames:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path:
			return true
	return current_scene != null and current_scene.scene_file_path == path


func _wait_for_battle_running(max_frames: int) -> Node:
	for i in max_frames:
		await process_frame
		var bs = root.get_node_or_null("BattleScene")
		if bs != null and bs.get("battle") != null and bool(bs.get("battle").running):
			return bs
	return null


func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if predicate.call():
			return true
		await process_frame
	return predicate.call()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check_all_atb(units: Array, expected: float, label: String) -> void:
	_check(not units.is_empty(), label + " (has combatants)")
	for c in units:
		_check(is_equal_approx(c.atb, expected),
			"%s: %s atb=%.2f (expected %.2f)" % [label, c.name, c.atb, expected])


func _check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_fail += 1
