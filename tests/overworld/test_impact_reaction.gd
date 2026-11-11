extends SceneTree
## D-235/D-1045/D-1100: integration tests for the overworld hit reaction.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/overworld/test_impact_reaction.gd
##
## Each case loads the real Murky Forest lab, attacks/gets hit with the real
## OverworldAttackController and checks the REAL victim: the `damage` clip is
## playing and the body moved away from the attacker. The lab's production
## battle handler is disconnected so the scene does not change mid-test.
##
## The last case calls the lab's generic react_to_hit() on a real follower. The
## current enemy AI only advances toward the player, so no enemy hit reaches an
## ally yet; the case proves the reaction path that a future ally hit uses.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

var _fail := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== OVERWORLD HIT REACTION (D-235/D-1045) ==")
	await _case_room_enemy("cyclops")
	await _case_room_enemy("orc")
	await _case_gible()
	await _case_player()
	await _case_room_enemy_hits_player("orc")
	await _case_follower()
	print("IMPACT_REACTION_TEST_" + ("PASS" if _fail == 0 else "FAIL"))
	quit(0 if _fail == 0 else 1)


func _case_room_enemy(id: String) -> void:
	print("- DQT room enemy: %s" % id)
	var lab := await _load_lab()
	var player: CharacterBody3D = lab.get("player")
	var controller = lab.get("_attack_controller")
	var entry := _room_entry(lab, id)
	if player == null or controller == null or entry.is_empty():
		_check(false, "lab exposes player/controller/%s" % id)
		_free_lab(lab)
		return
	var body: Node3D = entry["node"]
	var ap: AnimationPlayer = entry["ap"]
	player.global_position = body.global_position + Vector3(0.0, 0.0, 2.6)
	player.velocity = Vector3.ZERO
	await _frames(2)

	var impact: Array = []
	controller.impact_requested.connect(
		func(_p: Vector3, _d: Vector3, _a: int, contacts: Array) -> void:
			impact.append({"contacts": contacts, "start": body.global_position}))
	_check(controller.try_interact(), "Z starts the player advance toward %s" % id)
	var emitted := await _wait_until(func() -> bool: return not impact.is_empty(), 180)
	_check(emitted, "impact emitted against %s" % id)
	if emitted:
		var contacts: Array = impact[0]["contacts"]
		_check(contacts.size() == 1, "%s impact carries exactly one real contact" % id)
		if contacts.size() == 1:
			_check(contacts[0].get("actor") == body,
				"%s is the real victim, not a proximity guess" % id)
		_check(ap.current_animation == "damage",
			"%s plays the damage clip on impact (got %s)" % [id, ap.current_animation])
		var start: Vector3 = impact[0]["start"]
		var moved := await _wait_until(
			func() -> bool: return body.global_position.distance_to(start) > 0.35, 40)
		_check(moved, "%s is pushed more than 0.35 m" % id)
		await _frames(8)
		_check(ap.current_animation == "damage",
			"%s damage clip is not overwritten by idle/walk" % id)
		_check(body.global_position.distance_to(start) > 0.35,
			"%s stays displaced while the reaction runs" % id)
	_free_lab(lab)


func _case_gible() -> void:
	print("- Gible")
	var lab := await _load_lab()
	var player: CharacterBody3D = lab.get("player")
	var controller = lab.get("_attack_controller")
	var body: Node3D = lab.get("_second_enemy")
	var ap: AnimationPlayer = lab.get("_second_enemy_ap")
	if player == null or controller == null or body == null or ap == null:
		_check(false, "lab exposes player/controller/Gible")
		_free_lab(lab)
		return
	player.global_position = body.global_position + Vector3(0.0, 0.0, 2.6)
	player.velocity = Vector3.ZERO
	await _frames(2)

	var impact: Array = []
	controller.impact_requested.connect(
		func(_p: Vector3, _d: Vector3, _a: int, contacts: Array) -> void:
			impact.append({"contacts": contacts, "start": body.global_position}))
	_check(controller.try_interact(), "Z starts the player advance toward Gible")
	var emitted := await _wait_until(func() -> bool: return not impact.is_empty(), 180)
	_check(emitted, "impact emitted against Gible")
	if emitted:
		var contacts: Array = impact[0]["contacts"]
		_check(contacts.size() == 1, "Gible impact carries exactly one real contact")
		if contacts.size() == 1:
			_check(contacts[0].get("actor") == body, "Gible is the real victim")
		_check(ap.current_animation == "damage",
			"Gible plays the damage clip on impact (got %s)" % ap.current_animation)
		var start: Vector3 = impact[0]["start"]
		var moved := await _wait_until(
			func() -> bool: return body.global_position.distance_to(start) > 0.35, 40)
		_check(moved, "Gible is pushed more than 0.35 m")
		await _frames(8)
		_check(ap.current_animation == "damage",
			"Gible damage clip is not overwritten by idle/walk")
	_free_lab(lab)


func _case_player() -> void:
	print("- player hit by the enemy advance")
	var lab := await _load_lab(false)
	var player: CharacterBody3D = lab.get("player")
	var controller = lab.get("_attack_controller")
	var enemy: Node3D = lab.get("_enemy")
	var ap: AnimationPlayer = lab.get("player_ap")
	if player == null or controller == null or enemy == null or ap == null:
		_check(false, "lab exposes player/controller/Slime/player_ap")
		_free_lab(lab)
		return
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(2)

	var impact: Array = []
	controller.impact_requested.connect(
		func(_p: Vector3, _d: Vector3, _a: int, contacts: Array) -> void:
			impact.append({"contacts": contacts, "start": player.global_position}))
	var telegraphed := await _wait_until(
		func() -> bool: return controller.is_enemy_attacking(enemy), 180)
	_check(telegraphed, "Slime enters the enemy advance/telegraph")
	var emitted := await _wait_until(func() -> bool: return not impact.is_empty(), 240)
	_check(emitted, "enemy impact emitted against the player")
	if emitted:
		var contacts: Array = impact[0]["contacts"]
		var player_hit := false
		for contact in contacts:
			if contact.get("actor") == player:
				player_hit = true
		_check(player_hit, "the player is the real victim of the enemy hit")
		_check(ap.current_animation == "damage",
			"player plays the damage clip on impact (got %s)" % ap.current_animation)
		var start: Vector3 = impact[0]["start"]
		var moved := await _wait_until(
			func() -> bool: return player.global_position.distance_to(start) > 0.35, 40)
		_check(moved, "player is pushed more than 0.35 m")
		await _frames(8)
		_check(ap.current_animation == "damage",
			"player damage clip is not overwritten during the reaction")
	_free_lab(lab)


func _case_room_enemy_hits_player(id: String) -> void:
	print("- DQT room enemy %s hits the player (D-235, other side)" % id)
	var lab := await _load_lab()
	var player: CharacterBody3D = lab.get("player")
	var controller = lab.get("_attack_controller")
	var entry := _room_entry(lab, id)
	var ap: AnimationPlayer = lab.get("player_ap")
	if player == null or controller == null or entry.is_empty() or ap == null:
		_check(false, "lab exposes player/controller/%s/player_ap" % id)
		_free_lab(lab)
		return
	var body: Node3D = entry["node"]
	player.global_position = body.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(2)

	var impact: Array = []
	controller.impact_requested.connect(
		func(_p: Vector3, _d: Vector3, adv: int, contacts: Array) -> void:
			impact.append({"contacts": contacts, "start": player.global_position, "adv": adv}))
	var telegraphed := await _wait_until(
		func() -> bool: return controller.is_enemy_attacking(body), 240)
	_check(telegraphed, "%s enters the enemy advance/telegraph" % id)
	var emitted := await _wait_until(func() -> bool: return not impact.is_empty(), 240)
	_check(emitted, "%s impact emitted against the player" % id)
	if emitted:
		var contacts: Array = impact[0]["contacts"]
		var player_hit := false
		for contact in contacts:
			if contact.get("actor") == player:
				player_hit = true
		print("  [info] %s adv=%d contacts=%s player_pos=%s start=%s" % [
			id, int(impact[0].get("adv", -1)), _contact_names(contacts),
			player.global_position, impact[0]["start"]])
		_check(player_hit, "the player is the real victim of the %s hit" % id)
		_check(ap.current_animation == "damage",
			"player plays the damage clip on the %s hit (got %s)" % [id, ap.current_animation])
		var start: Vector3 = impact[0]["start"]
		var moved := await _wait_until(
			func() -> bool: return player.global_position.distance_to(start) > 0.35, 40)
		_check(moved, "player is pushed more than 0.35 m by the %s hit" % id)
		await _frames(8)
		_check(ap.current_animation == "damage",
			"player damage clip is not overwritten after the %s hit" % id)
	_free_lab(lab)


func _case_follower() -> void:
	print("- ally reaction path (no enemy targets allies yet)")
	var lab := await _load_lab()
	var followers: Array = lab.get("_followers")
	if followers.is_empty():
		_check(false, "lab exposes its followers")
		_free_lab(lab)
		return
	var follower: Dictionary = followers[0]
	var body: Node3D = follower["node"]
	var ap: AnimationPlayer = follower["ap"]
	var start := body.global_position
	var reacted: bool = lab.react_to_hit(body, Vector3(0.0, 0.0, 1.0))
	_check(reacted, "react_to_hit accepts a real ally body")
	_check(ap.current_animation == "damage",
		"ally plays the damage clip (got %s)" % ap.current_animation)
	var moved := await _wait_until(
		func() -> bool: return body.global_position.distance_to(start) > 0.35, 40)
	_check(moved, "ally is pushed more than 0.35 m")
	var full_push := await _wait_until(
		func() -> bool: return body.global_position.distance_to(start) >= 1.7, 45)
	_check(full_push, "ally reaches the ~1.8 m push in open space")
	await _frames(8)
	_check(ap.current_animation == "damage",
		"ally damage clip is not overwritten by the follower update")
	_free_lab(lab)


func _room_entry(lab: Node, id: String) -> Dictionary:
	var rooms: Array = lab.get("_room_enemies")
	for entry in rooms:
		var body: Node3D = entry.get("node")
		if body != null and body.name.to_lower().contains(id):
			return entry
	return {}


func _load_lab(threat_demo := false) -> Node:
	var packed := load(LAB) as PackedScene
	if packed == null:
		_check(false, "murky forest lab scene loads")
		return null
	var lab := packed.instantiate()
	root.add_child(lab)
	# `_ready()` turns the Medroso demo on for this lab; flip it for the instance
	# right after the nodes exist and before the first physics frame.
	lab.set("enable_threat_demo", threat_demo)
	current_scene = lab
	await _frames(4)
	var controller = lab.get("_attack_controller")
	if controller != null:
		# Keep the test inside the lab: the production handler would change scenes.
		var handler := Callable(lab, "_on_attack_battle_requested")
		if controller.battle_requested.is_connected(handler):
			controller.battle_requested.disconnect(handler)
	return lab


func _free_lab(lab: Node) -> void:
	if lab != null and is_instance_valid(lab):
		lab.free()
	await process_frame


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if predicate.call():
			return true
		await physics_frame
	return predicate.call()


func _check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_fail += 1


func _contact_names(contacts: Array) -> Array:
	var names: Array = []
	for contact in contacts:
		var actor: Node = contact.get("actor")
		var source: Node = contact.get("source")
		names.append("%s<-%s" % [
			actor.name if actor != null else "null",
			source.name if source != null else "null"])
	return names
