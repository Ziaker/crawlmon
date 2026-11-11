extends SceneTree
## Continuous capture of move_drain_spear in the real battle, one view per run.
##   Godot --path . --resolution 1280x720 --fixed-fps 30 --script res://tests/vfx/record_drain_spear_video.gd -- --dqt
##   Godot --path . --resolution 1280x720 --fixed-fps 30 --script res://tests/vfx/record_drain_spear_video.gd -- --dqt-mirror --mirror

const FRAMES := 180
const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")

var _bs: Node3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mirror := "--mirror" in OS.get_cmdline_user_args()
	var view := "mirror" if mirror else "normal"
	var out_dir := "res://test_captures/drain_spear_battle/video/%s" % view
	DirAccess.make_dir_recursive_absolute(out_dir)
	_bs = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	root.add_child(_bs)
	var battle: Battle = _bs.get_node("Battle")
	while not battle.running:
		await process_frame
	battle.incoming.clear()
	battle._landing.clear()
	battle._returning.clear()
	battle._status_pause = null
	battle._status_tail = -1.0
	battle.debug_roll = 1
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
	var orc: Combatant = null
	for c in battle.party + battle.enemies:
		if c.species_id == "dqt_orc" and (orc == null or c.is_player):
			orc = c
	var target: Combatant = null
	if orc != null:
		for c in (battle.enemies if orc.is_player else battle.party):
			if c != orc and c.is_alive():
				target = c
				break
	if orc == null or target == null:
		print("VIDEO_FAIL missing unit")
		quit(1)
		return
	orc.skills.append(DrainSpearMove.make())
	target.buff_stat("atk", 1)
	target.apply_shield(18, 8.0)
	target.apply_magic_immunity(10.0)
	print("VIDEO ", view, " ", orc.name, " -> ", target.name)
	if not battle.use_skill(orc, DrainSpearMove.make(), target):
		print("VIDEO_FAIL use_skill")
		quit(1)
		return
	var vp := root.get_viewport()
	for i in FRAMES:
		await process_frame
		if _bs.get("hud") != null:
			_bs.hud._skill_info.visible = false
		var img := vp.get_texture().get_image()
		if img != null:
			img.save_png("%s/frame_%04d.png" % [out_dir, i])
	print("VIDEO_PASS ", out_dir)
	_bs.queue_free()
	await process_frame
	await process_frame
	quit(0)
