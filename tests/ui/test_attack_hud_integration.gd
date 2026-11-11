extends SceneTree
## Integração do GLIFO (opção C) no lab do overworld.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/ui/test_attack_hud_integration.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Attack HUD GLIFO no overworld ==")
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(30)
	var hud = lab.get("_attack_hud")
	var prompt = lab.get("_npc_prompt")
	var player = lab.get("player")
	var enemy = lab.get("_enemy")
	_expect(hud != null, "lab creates the attack HUD")
	_expect(prompt != null, "talk prompt still exists")
	if hud != null:
		_expect(int(hud.get("mode")) == 2, "HUD uses GLIFO (mode 2)")

	# Perto do Slime: alvo, nome, distância e sem o prompt antigo.
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 1.8)
	player.velocity = Vector3.ZERO
	await _frames(10)
	_expect(int(hud.get("state")) == 0, "near enemy = READY")
	_expect(str(hud.get("target_name")) == "SLIME", "HUD receives the target name")
	_expect(hud.visible, "HUD visible with a target")
	_expect(not prompt.visible, "old [Z] ATTACK prompt is gone")

	# Longe: sem alvo, Z fantasma.
	player.global_position = enemy.global_position + Vector3(12.0, 0.0, 12.0)
	await _frames(10)
	_expect(int(hud.get("state")) == 2, "far from enemy = NO_TARGET")
	_expect(not hud.visible, "HUD hides completely without a target")

	print("ATTACK_HUD_INTEGRATION_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1
