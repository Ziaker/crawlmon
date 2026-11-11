extends SceneTree
## D-1172: shatter encounter transition (36 shards + flat parallelogram cut-in).
## Run: godot --headless --path . --script res://tests/overworld/test_d1172_shatter_transition.gd
var _f := 0
var _revealed_at := -1.0
var _finished := false


func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_f += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var a := EncounterRules.Advantage
	ok(EncounterShatterTransition.callout_for(a.NORMAL) == "CONTATO", "NORMAL = CONTATO")
	ok(EncounterShatterTransition.callout_for(a.PLAYER_FIRST) == "OPORTUNIDADE", "PLAYER_FIRST = OPORTUNIDADE")
	ok(EncounterShatterTransition.callout_for(a.ENEMY_FIRST) == "EMBOSCADA", "ENEMY_FIRST = EMBOSCADA")
	ok(EncounterShatterTransition.color_for(a.NORMAL) == Color("#FBF8EA"), "NORMAL = white/cream")
	ok(EncounterShatterTransition.color_for(a.PLAYER_FIRST) == Color("#38BDF8"), "PLAYER_FIRST = blue")
	ok(EncounterShatterTransition.color_for(a.ENEMY_FIRST) == Color("#FF5555"), "ENEMY_FIRST = red")
	ok(is_equal_approx(EncounterShatterTransition.TOTAL_DURATION, 1.65)
		and is_equal_approx(EncounterShatterTransition.RUPTURE_START, 0.33)
		and is_equal_approx(EncounterShatterTransition.ARENA_REVEALED, 1.0)
		and EncounterShatterTransition.SWAP_AT < EncounterShatterTransition.RUPTURE_START,
		"timeline 1.65 s / rupture 0.33 / arena 1.00 / swap while covered")

	var tr := EncounterShatterTransition.new()
	root.add_child(tr)
	await process_frame
	ok(tr._shards.size() == 36, "36 shards (%d)" % tr._shards.size())
	tr.revealed.connect(func() -> void: _revealed_at = tr.time)
	tr.finished.connect(func() -> void: _finished = true)
	tr.play_to("", a.ENEMY_FIRST, Vector2(0.9, 0.1))  # empty target: no scene swap in the test
	ok(tr.active and paused, "active and the tree is paused under the cracked screen")
	ok(is_equal_approx(tr._impact_uv.x, 0.85) and is_equal_approx(tr._impact_uv.y, 0.85), "impact point clamped to 0.15..0.85")
	var guard := 0
	while tr.active and guard < 2000:
		await process_frame
		guard += 1
	ok(not paused, "tree unpaused after the swap point")
	ok(_revealed_at >= 0.33 and _revealed_at < 0.60, "revealed at the rupture (%.3f s)" % _revealed_at)
	ok(_finished and not tr.active and tr.has_revealed, "finished after the timeline")
	ok(not tr._root.visible and not tr._arena_rect.visible, "nothing left on screen")
	ok(tr._shards_view.render_target_update_mode == SubViewport.UPDATE_DISABLED, "shard stage stops rendering")
	tr.play_to("", a.NORMAL)
	ok(tr.active and is_zero_approx(tr.time), "can play again")
	print("D1172_%s" % ("PASS" if _f == 0 else "FAIL"))
	paused = false
	quit(1 if _f > 0 else 0)
