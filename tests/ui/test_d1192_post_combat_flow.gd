extends SceneTree
## Headless test of the non-visual post-combat flow (D-1192).

const Flow := preload("res://scripts/progression/post_combat_flow.gd")
const Inspect := preload("res://scripts/ui/post_combat/move_inspect_info.gd")

const LEADER_MOVES := [&"tackle", &"confusao", &"raio_psiquico", &"onda_choque", &"teleporte_rapido", &"soco_rapido", &"golpe_carate"]
const FULL_MOVES := [&"tackle", &"confusao", &"raio_psiquico", &"onda_choque", &"teleporte_rapido", &"soco_rapido", &"golpe_carate", &"quebra_telha"]

var _failures := 0


func _initialize() -> void:
	_case_victory_without_level_up()
	_case_leader_level_up()
	_case_learning_into_free_slot()
	_case_full_slots()
	_case_ko_ally()
	_case_inspect_all_moves()
	quit(1 if _failures > 0 else 0)


func _ok(name: String, condition: bool, reason: String) -> void:
	if condition:
		print("PASS %s" % name)
	else:
		print("FAIL %s: %s" % [name, reason])
		_failures += 1


func _make(species: String, player: bool) -> Combatant:
	return CharacterFactory.create(species, {
		"is_player": player,
		"test_bare": true,
		"max_hp": 40,
		"max_mp": 20,
		"attack": 9,
		"speed": 0.425,
	})


func _make_leader(species: String) -> Combatant:
	var c := _make(species, true)
	var game_state := root.get_node_or_null("GameState")
	if game_state != null:
		var arr: Array[Combatant] = [c]
		game_state.set("party", arr)
	return c


func _skill_ids(c: Combatant) -> String:
	var ids: Array[String] = []
	for s in c.skills:
		ids.append(String(Flow.move_id_of(s)))
	return "|".join(PackedStringArray(ids))


func _join(segments: Array) -> String:
	var text := ""
	for segment in segments:
		text += String(segment.get("text", ""))
	return text


func _has_color(segments: Array) -> bool:
	for segment in segments:
		var color: Color = segment.get("color", Color(0, 0, 0, 0))
		if color.a > 0.0:
			return true
	return false


func _case_victory_without_level_up() -> void:
	var leader := _make_leader("abra")
	var summaries := Flow.grant_xp([leader], 10)
	var steps := Flow.build_steps(summaries)
	var only_xp := steps.size() == 1 and String(steps[0].get("kind", "")) == "xp"
	_ok("victory_without_level_up", only_xp, "steps=%s" % str(steps))


func _case_leader_level_up() -> void:
	var leader := _make_leader("abra")
	var summaries := Flow.grant_xp([leader], 60)
	var gained := int(summaries[0].get("levels_gained", 0))
	var has_lv := false
	for step in Flow.build_steps(summaries):
		if String(step.get("kind", "")) == "lv":
			has_lv = true
	_ok("leader_level_up_step", gained > 0 and has_lv, "gained=%d has_lv=%s" % [gained, str(has_lv)])

	var pending := leader.distributable_points
	var before := int(leader.progression_points.get("MAG", 0))
	Flow.apply_leader_allocation(leader, {"MAG": pending})
	var allocated := int(leader.progression_points.get("MAG", 0)) - before
	_ok("leader_allocation", pending > 0 and allocated == pending and leader.distributable_points == 0,
		"pending=%d allocated=%d left=%d" % [pending, allocated, leader.distributable_points])


func _case_learning_into_free_slot() -> void:
	Flow.learnset_override = {"abra": {3: [&"media"]}}
	var leader := _make_leader("abra")
	leader.skills.clear()
	for id in LEADER_MOVES:
		leader.skills.append(Skill.from_id(StringName(id)))

	var learned := Flow.moves_learned_at(leader, 3)
	var found := learned.size() == 1 and learned[0] == &"media"
	_ok("learnset_override_level", found, "learned=%s" % str(learned))

	var move_id := learned[0] if found else StringName("media")
	var index := Flow.learn_into_free_slot(leader, move_id)
	_ok("learn_into_slot_7", index == 7 and leader.skills.size() == 8,
		"index=%d size=%d" % [index, leader.skills.size()])
	Flow.learnset_override = {}


func _case_full_slots() -> void:
	var c := _make_leader("abra")
	c.skills.clear()
	for id in FULL_MOVES:
		c.skills.append(Skill.from_id(StringName(id)))
	var first_id := Flow.move_id_of(c.skills[0])
	var snapshot := _skill_ids(c)

	var rejected := Flow.learn_into_free_slot(c, &"media")
	var unchanged := _skill_ids(c) == snapshot and c.skills.size() == 8
	_ok("full_slots_refuse", rejected == -1 and unchanged,
		"rejected=%d unchanged=%s" % [rejected, str(unchanged)])

	var forgotten := Flow.forget_and_learn(c, 0, &"media")
	_ok("forget_and_learn_swaps", forgotten == first_id and Flow.move_id_of(c.skills[0]) == &"media",
		"forgotten=%s slot0=%s" % [String(forgotten), String(Flow.move_id_of(c.skills[0]))])


func _case_ko_ally() -> void:
	var ally := _make("pancham", false)
	ally.hp = 0
	var old_xp := ally.xp
	var summaries := Flow.grant_xp([ally], 500)
	var summary: Dictionary = summaries[0]
	var steps := Flow.build_steps(summaries)
	var ok := not bool(summary.get("is_alive", true)) \
		and int(summary.get("current_xp", -1)) == old_xp \
		and int(summary.get("levels_gained", -1)) == 0 \
		and steps.size() == 1 \
		and String(steps[0].get("kind", "")) == "xp"
	_ok("ko_ally_zero_xp_no_lv", ok, "summary=%s steps=%s" % [str(summary), str(steps)])


func _case_inspect_all_moves() -> void:
	var media := Skill.from_id(&"media")
	var media_ok := is_equal_approx(Inspect.effective_windup(media), 0.5) \
		and is_equal_approx(Inspect.engine_pause(media), 1.5)
	_ok("media_windup_and_pause", media_ok,
		"windup=%.2f pause=%.2f" % [Inspect.effective_windup(media), Inspect.engine_pause(media)])

	var sample := "STR +2, 50% MAG 1,5 s STUN HP MP ATB"
	var sample_segments := Inspect.highlight(sample)
	_ok("highlight_roundtrip", _join(sample_segments) == sample and _has_color(sample_segments),
		"joined='%s'" % _join(sample_segments))

	for move in MoveCatalog.all_moves():
		if move == null:
			continue
		var skill := Skill.from_data(move)
		var id := String(move.id)
		if skill == null:
			_ok("inspect:%s" % id, false, "Skill.from_data returned null")
			continue
		var value_rows := Inspect.vals(skill)
		var windup := Inspect.effective_windup(skill)
		var text := skill.effect_line()
		var joined := _join(Inspect.highlight(text))
		var windup_ok := windup > 0.0 or is_zero_approx(move.windup)
		var ok := value_rows.size() > 0 and windup_ok and joined == text
		_ok("inspect:%s" % id, ok,
			"vals=%d windup=%.2f roundtrip=%s" % [value_rows.size(), windup, str(joined == text)])
