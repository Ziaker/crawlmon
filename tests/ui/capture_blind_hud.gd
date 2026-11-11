extends SceneTree
## D-1121: captura o HUD com BLIND no cartão dos aliados e na etiqueta dos inimigos.
## Rodar SEM --headless:
##   Godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/ui/capture_blind_hud.gd

const OUT := "res://test_captures/d1121_blind_hud.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var also_stun := "--stun" in OS.get_cmdline_user_args()
	var out_path := "res://test_captures/d1121_blind_stun_hud.png" if also_stun else OUT
	var bs: Node3D = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 1200:
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.blind_timer = 6.0
	if also_stun:
		battle.enemies[0].stun_timer = 6.0
	bs.director.set_process(false)
	var a: Node3D = bs.models[battle.party[0]]
	var e: Node3D = bs.models[battle.enemies[0]]
	var mid: Vector3 = (a.global_position + e.global_position) * 0.5
	var cam: Camera3D = bs.get_node("Camera3D")
	cam.current = true
	cam.global_position = mid + Vector3(0.0, 3.2, 8.5)
	cam.look_at(mid + Vector3(0.0, 1.0, 0.0))
	cam.fov = 58.0
	# Dá tempo para _blind_k entrar (move_toward a 4/s) e o HUD redesenhar.
	for i in 40:
		await process_frame
	if "--video" in OS.get_cmdline_user_args():
		# Segura o BLIND, limpa e deixa a saída lenta aparecer (gravação).
		for i in 60:
			if i % 15 == 0:
				print("[BLIND-HUD] hold i=%d blind=%.2f k=%.2f" % [i, battle.party[0].blind_timer, float(bs.hud.blind_k(battle.party[0]))])
			await process_frame
		for c in battle.party + battle.enemies:
			c.blind_timer = 0.0
		for i in 60:
			if i % 15 == 0:
				print("[BLIND-HUD] out i=%d blind=%.2f k=%.2f" % [i, battle.party[0].blind_timer, float(bs.hud.blind_k(battle.party[0]))])
			await process_frame
		bs.queue_free()
		await process_frame
		quit(0)
		return
	var kh := float(bs.hud.blind_k(battle.party[0]))
	var ke := float(bs.hud.blind_k(battle.enemies[0]))
	print("[BLIND-HUD] ally_k=%.3f enemy_k=%.3f" % [kh, ke])
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err := img.save_png(out_path)
	print("[BLIND-HUD] saved=", out_path, " err=", err)
	bs.queue_free()
	await process_frame
	quit(0 if err == OK else 1)
