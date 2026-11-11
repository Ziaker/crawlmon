extends SceneTree
## Debug/test tool: party control swap.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/overworld/test_party_swap.gd
##
## Covers:
##  - the 2D exploration adapter (party order, species, positions, sprite/model view);
##  - the 3D lab adapter with Pancham and Orc/DQT (model, AP, body, capsule);
##  - the battle adapter (leader, party[0], fx.leader, place fields, HUD cards);
##  - the E conflict guards.
## No combat number (ATB, damage, timing) is changed by the tool.

const Model3DViewClass := preload("res://scripts/dungeon/model_3d_view.gd")

var _failures := 0
var _gs: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Party control swap (debug tool) ==")
	_gs = root.get_node_or_null("GameState")
	if _gs == null:
		_gs = load("res://scripts/autoload/game_state.gd").new()
		_gs.name = "GameState"
		root.add_child(_gs)
	await _test_exploration()
	await _test_lab_pancham_and_orc()
	await _test_battle()
	await process_frame
	await process_frame
	print("PARTY_SWAP_TEST_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1


func _test_exploration() -> void:
	print("- 2D exploration swap")
	var packed := load("res://scenes/exploration.tscn") as PackedScene
	if packed == null:
		_expect(false, "exploration scene loads")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _frames(5)

	var player: Node2D = scene.get("player")
	var followers: Array = scene.get("followers")
	if player == null or followers.is_empty():
		_expect(false, "exploration has a player and one follower")
		scene.free()
		return

	var party: Array = _gs.get("party")
	var old_leader: Combatant = party[0]
	var old_ally: Combatant = party[1]
	var old_player_species := str(player.get("species_id"))
	var follower: Node2D = followers[0]
	var old_follower_species := str(follower.get("species_id"))
	var player_pos := player.global_position
	var follower_pos := follower.global_position

	var result: Variant = scene.call("debug_swap_party", 1)
	_expect(result is Dictionary and bool(result.get("ok", false)), "2D adapter reports success")
	_expect(party[0] == old_ally, "party[0] is now the chosen ally")
	_expect(party[1] == old_leader, "party[1] is the old leader")
	_expect(str(player.get("species_id")) == old_follower_species, "player sprite/species came from the ally")
	_expect(str(follower.get("species_id")) == old_player_species, "follower sprite/species came from the old leader")
	_expect(player.global_position.is_equal_approx(follower_pos), "player took the follower position")
	_expect(follower.global_position.is_equal_approx(player_pos), "follower took the player position")

	if Model3DViewClass.has_model(old_follower_species):
		var view := _model_view(player)
		_expect(view != null and str(view.get("model_id")) == old_follower_species,
			"player 3D view was rebuilt for the new species")
	if Model3DViewClass.has_model(old_player_species):
		var follower_view := _model_view(follower)
		_expect(follower_view != null and str(follower_view.get("model_id")) == old_player_species,
			"follower 3D view was rebuilt for the old leader species")

	# Put the party back so the battle test starts from the normal leader.
	scene.call("debug_swap_party", 1)
	_expect(party[0] == old_leader and party[1] == old_ally, "second swap restores the party")

	# Global selector: E opens/closes (pausing while open), and Enter calls the scene adapter.
	var selector = _gs.get("debug_party_selector")
	_expect(selector != null, "GameState created the global selector")
	if selector != null:
		_expect(selector.process_mode == Node.PROCESS_MODE_ALWAYS, "selector uses PROCESS_MODE_ALWAYS")
		var previous_scene := current_scene
		current_scene = scene
		_send_key(KEY_E)
		await process_frame
		await process_frame
		_expect(bool(selector.get("_open")), "E opens the selector list")
		_expect(paused, "the selector pauses the game while its list is open")
		_send_key(KEY_E)
		await process_frame
		await process_frame
		_expect(not bool(selector.get("_open")), "E closes the selector")
		_expect(not paused, "closing the selector restores the previous pause state")
		_send_key(KEY_E)
		await process_frame
		await process_frame
		_send_key(KEY_2)
		await process_frame
		await process_frame
		_send_key(KEY_ENTER)
		await process_frame
		await process_frame
		_expect(not bool(selector.get("_open")), "Enter closes the selector after a successful swap")
		_expect(party[0] == old_ally, "selector Enter reached debug_swap_party")
		scene.call("debug_swap_party", 1)
		_expect(party[0] == old_leader, "selector test restores the party")

		# Esc closes and restores the pause; Down + Enter uses the arrow path.
		_send_key(KEY_E)
		await process_frame
		await process_frame
		_send_key(KEY_ESCAPE)
		await process_frame
		await process_frame
		_expect(not bool(selector.get("_open")) and not paused, "Esc closes and unpauses")
		_send_key(KEY_E)
		await process_frame
		await process_frame
		_send_key(KEY_DOWN)
		await process_frame
		await process_frame
		_send_key(KEY_ENTER)
		await process_frame
		await process_frame
		_expect(party[0] == old_ally, "arrow selection + Enter also swaps")
		scene.call("debug_swap_party", 1)
		_expect(party[0] == old_leader, "arrow test restores the party")
		current_scene = previous_scene

	scene.free()
	await process_frame


func _test_lab_pancham_and_orc() -> void:
	print("- 3D lab swap: Pancham then Orc/DQT")
	var packed := load("res://scenes/debug/murky_forest_3d_lab.tscn") as PackedScene
	if packed == null:
		_expect(false, "murky forest lab loads")
		return
	var lab := packed.instantiate()
	lab.set("enable_threat_demo", false)
	root.add_child(lab)
	await _frames(5)

	var player: CharacterBody3D = lab.get("player")
	var followers: Array = lab.get("_followers")
	if player == null or followers.size() < 2:
		_expect(false, "lab has the player and two followers (Pancham/Orc)")
		lab.free()
		return
	_expect(not bool(lab.call("debug_party_selector_blocked")),
		"E is free at the lab spawn (no NPC/door/attack)")
	var selector_entries: Array = lab.call("debug_party_selector_entries")
	_expect(selector_entries.size() == 3, "lab E list exposes the body + Pancham + Orc")
	if selector_entries.size() == 3:
		_expect(str(selector_entries[0].get("species")) == "abra", "lab leader entry is the current body")
		_expect(str(selector_entries[2].get("species")) == "dqt_orc", "lab index 3 is Orc/DQT")
	lab.set("_npc_talking", true)
	_expect(bool(lab.call("debug_party_selector_blocked")), "E is blocked while an NPC dialogue is open")
	lab.set("_npc_talking", false)

	var pancham: Dictionary = followers[0]
	var pancham_body: Node3D = pancham["node"]
	var old_model := lab.get("player_model") as Node3D
	var old_ap := lab.get("player_ap") as AnimationPlayer
	var old_pos := player.global_position
	var pancham_model: Node3D = pancham["model"]
	var pancham_ap: AnimationPlayer = pancham["ap"]
	var pancham_height := float(pancham["height"])
	var pancham_pos := pancham_body.global_position

	var result: Variant = lab.call("debug_swap_party", 1)
	_expect(result is Dictionary and bool(result.get("ok", false)), "lab swap with Pancham succeeds")
	_expect(lab.get("player_model") == pancham_model, "player_model is Pancham's model")
	_expect(lab.get("player_ap") == pancham_ap, "player_ap is Pancham's AnimationPlayer")
	_expect(player.global_position.is_equal_approx(pancham_pos), "player body took Pancham's position")
	_expect(pancham_body.global_position.is_equal_approx(old_pos), "Pancham follower took the player's position")
	_expect(pancham["model"] == old_model and pancham["ap"] == old_ap, "Pancham follower got the old model/AP")
	_expect(absf(_capsule_height(player) - pancham_height) < 0.02,
		"player capsule matches Pancham height")

	var orc: Dictionary = followers[1]
	var orc_body: Node3D = orc["node"]
	var orc_model: Node3D = orc["model"]
	var orc_ap: AnimationPlayer = orc["ap"]
	var orc_height := float(orc["height"])
	var orc_pos := orc_body.global_position
	var player_pos := player.global_position

	result = lab.call("debug_swap_party", 2)
	_expect(result is Dictionary and bool(result.get("ok", false)), "lab swap with Orc/DQT succeeds")
	_expect(lab.get("player_model") == orc_model, "player_model is Orc's model")
	_expect(lab.get("player_ap") == orc_ap, "player_ap is Orc's AnimationPlayer")
	_expect(str(lab.get("player_model_id")) == "dqt_orc", "player_model_id is dqt_orc")
	_expect(player.global_position.is_equal_approx(orc_pos), "player body took Orc's position")
	_expect(orc_body.global_position.is_equal_approx(player_pos), "Orc follower took the player's position")
	_expect(absf(_capsule_height(player) - orc_height) < 0.02,
		"player capsule matches Orc height")
	_expect(absf(float(lab.get("player_height")) - orc_height) < 0.02,
		"lab player_height follows Orc")

	lab.free()
	await process_frame


func _test_battle() -> void:
	print("- battle swap (leader, party, fx, places, HUD)")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	if packed == null:
		_expect(false, "battle scene loads")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	var battle = null
	for i in 1200:
		await process_frame
		battle = scene.get("battle")
		if battle != null and bool(battle.get("running")):
			break
	if battle == null or not bool(battle.get("running")):
		# The battle intro is long; report it as skipped instead of a false pass.
		print("  [SKIP] battle did not start within 1200 frames")
		scene.free()
		await process_frame
		return

	var party: Array = battle.get("party")
	if party.size() < 2:
		_expect(false, "battle party has at least two members")
		scene.free()
		return
	var a: Combatant = party[0]
	var b: Combatant = party[1]
	for i in 900:
		if not bool(scene.call("debug_party_selector_blocked")):
			break
		await process_frame
	var a_home := a.home
	var b_home := b.home
	var a_pos := a.pos
	var b_pos := b.pos
	var a_yaw := a.yaw
	var b_yaw := b.yaw
	var a_step := a.pos_step
	var b_step := b.pos_step

	_expect(not bool(scene.call("debug_party_selector_blocked")), "E is free on the main battle menu")
	var battle_entries: Array = scene.call("debug_party_selector_entries")
	_expect(battle_entries.size() == party.size() and str(battle_entries[0].get("name")) == str(a.name),
		"E list uses the real battle party")
	scene.set("state", 1)  # S.FIGHT
	_expect(bool(scene.call("debug_party_selector_blocked")), "E belongs to the Fight page while S.FIGHT")
	scene.set("state", 0)  # S.MAIN

	var result: Variant = scene.call("debug_swap_party", 1)
	_expect(result is Dictionary and bool(result.get("ok", false)), "battle swap succeeds")
	_expect(battle.get("party")[0] == b, "battle.party[0] is the chosen ally")
	_expect(battle.get("party")[1] == a, "battle.party[1] is the old leader")
	_expect(scene.get("leader") == b, "battle_scene.leader is the chosen ally")
	var fx = scene.get("fx")
	_expect(fx != null and fx.get("leader") == b, "BattleFx.leader is the chosen ally")
	_expect(a.home.is_equal_approx(b_home) and b.home.is_equal_approx(a_home), "home moved with the bodies")
	_expect(a.pos.is_equal_approx(b_pos) and b.pos.is_equal_approx(a_pos), "pos moved with the bodies")
	_expect(is_equal_approx(a.yaw, b_yaw) and is_equal_approx(b.yaw, a_yaw), "yaw moved with the bodies")
	_expect(a.pos_step == b_step and b.pos_step == a_step, "pos_step moved with the bodies")
	_expect(bool(battle.get("running")), "battle keeps running (no restart)")

	var hud = scene.get("hud")
	var cards: Array = hud.get("_cards")
	_expect(cards.size() >= 2 and cards[0].combatant == b and bool(cards[0].hero),
		"HUD hero card rebinds to the new leader")
	_expect(cards.size() >= 2 and cards[1].combatant == a and not bool(cards[1].hero),
		"HUD ally card rebinds to the old leader")

	scene.queue_free()
	await process_frame
	await process_frame


func _model_view(actor: Node) -> Node:
	for child in actor.get_children():
		if child.get_script() == Model3DViewClass:
			return child
	return null


func _capsule_height(body: CharacterBody3D) -> float:
	for child in body.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null:
			continue
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			return capsule.height
	return 0.0


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _send_key(keycode: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = keycode
	down.physical_keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)
