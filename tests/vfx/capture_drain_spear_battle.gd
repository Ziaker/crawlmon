extends SceneTree
## Windowed proof frames for move_drain_spear in the real battle scene.
##   Godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/vfx/capture_drain_spear_battle.gd -- --dqt
##   Godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/vfx/capture_drain_spear_battle.gd -- --dqt-mirror --mirror
## Saves frame_XX.png under test_captures/drain_spear_battle/<normal|mirror>/.

const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")

var _bs: Node3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mirror := "--mirror" in OS.get_cmdline_user_args()
	var out_dir := "res://test_captures/drain_spear_battle/%s" % ("mirror" if mirror else "normal")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var packed := load("res://scenes/battle.tscn") as PackedScene
	_bs = packed.instantiate()
	root.add_child(_bs)
	var battle: Battle = _bs.get_node("Battle")
	while not battle.running:
		await process_frame
	# The crossover trio can start an action on the first frame: clear it before the take.
	battle.incoming.clear()
	battle._landing.clear()
	battle._returning.clear()
	battle._status_pause = null
	battle._status_tail = -1.0
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 5.0
		c.hp = c.max_hp
		c.is_invulnerable = false
		c.stun_timer = 0.0
		c.blind_timer = 0.0
		c.guard_timer = 0.0
		c.taunted_by = null
		c.taunt_atk_bonus = false
		c.engaged_with = null
		c.counter_ready = false
		c.queued_skill = null
		c.queued_target = null
	for i in 4:
		await process_frame

	var orc: Combatant = null
	for c in battle.party + battle.enemies:
		if c.species_id == "dqt_orc" and (orc == null or c.is_player):
			orc = c
	var target: Combatant = null
	if orc == null:
		print("CAPTURE_FAIL no dqt_orc")
		quit(1)
		return
	for c in (battle.enemies if orc.is_player else battle.party):
		if c != orc and c.is_alive():
			target = c
			break
	if target == null:
		print("CAPTURE_FAIL no target")
		quit(1)
		return
	battle.debug_roll = 1  # deterministic hit (no 10% automatic evade in the proof take)
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 5.0
	orc.skills.append(DrainSpearMove.make())
	target.buff_stat("atk", 1)
	target.apply_shield(18, 8.0)
	target.apply_magic_immunity(10.0)
	print("CAPTURE ", "mirror" if mirror else "normal", " ", orc.name, " -> ", target.name)
	var ok := battle.use_skill(orc, DrainSpearMove.make(), target)
	if not ok:
		print("CAPTURE_FAIL use_skill")
		quit(1)
		return
	# Wind-up 1.0 s + Orc advance 1.25 s + thrust 0.30 s at 60 fps.
	for f in [12, 36, 54, 66, 90, 126, 150, 158, 160, 162, 163, 164, 165, 172, 180, 195, 210, 240, 280]:
		while _frames < f:
			await process_frame
			_frames += 1
		if _bs.get("hud") != null:
			_bs.hud._skill_info.visible = false
		_save(out_dir, f)
	print("CAPTURE_PASS ", out_dir)
	_bs.queue_free()
	await process_frame
	await process_frame
	quit(0)


var _frames := 0


func _save(dir_path: String, frame: int) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/frame_%03d.png" % [dir_path, frame])
