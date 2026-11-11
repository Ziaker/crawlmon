extends SceneTree
## Scene-level check for move_drain_spear: the real battle scene creates the Motion Composer
## effect when the Move is declared, draws through its phases and frees it at the end.
##   godot --headless --path . --script res://tests/battle/test_drain_spear_scene.gd

const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")
var failures := 0
var _bs: Node3D


func _init() -> void:
	call_deferred("_run")


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		failures += 1


func _run() -> void:
	print("[*] Drain Spear na cena real de batalha")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	_bs = packed.instantiate()
	root.add_child(_bs)
	var battle: Battle = _bs.get_node("Battle")
	while not battle.running:
		await process_frame
	battle.debug_roll = 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 5.0
	var actor: Combatant = battle.party[0]
	var target: Combatant = battle.enemies[0]
	actor.skills.append(DrainSpearMove.make())
	target.buff_stat("atk", 1)
	target.apply_shield(12, 8.0)
	target.apply_magic_immunity(10.0)
	_expect(battle.use_skill(actor, DrainSpearMove.make(), target), "a cena aceita o Move")
	await process_frame
	var fx: BattleFx = _bs.fx
	_expect(fx.fx_drain_spear != null, "o módulo de VFX existe")
	_expect(fx.fx_drain_spear._active.size() == 1, "o efeito nasce no wind-up")
	var node = fx.fx_drain_spear._active.values()[0]
	_expect(is_instance_valid(node), "o nó DrainSpearVfx é válido")
	var frames := 0
	while frames < 600 and fx.fx_drain_spear._active.size() > 0:
		await process_frame
		frames += 1
	_expect(fx.fx_drain_spear._active.is_empty(), "o efeito é liberado no fim (%d frames)" % frames)
	_expect(target.hp < target.max_hp, "o dano mágico chegou na cena real")
	_expect(actor.atk_buff == 1, "o ATK foi transferido na cena real")
	_bs.queue_free()
	await process_frame
	await process_frame
	print("DRAIN_SPEAR_SCENE_" + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)
