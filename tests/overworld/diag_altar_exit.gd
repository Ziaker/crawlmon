extends SceneTree
## Walks the leader off the summon altar in 4 directions and prints how far it got (stuck = ~0 m).
const HUB := "res://scenes/debug/hub_3d_prototype.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for id in ["abra", "dqt_orc", "dqt_cyclops", "gible"]:
		for tgt in [Vector3(0, 0, 8), Vector3(0, 0, -6), Vector3(7, 0, 1), Vector3(-7, 0, 1)]:
			var lab: Node = (load(HUB) as PackedScene).instantiate()
			root.add_child(lab)
			for i in 6: await physics_frame
			lab.call("_set_player_species", id)
			await physics_frame
			var player: CharacterBody3D = lab.get("player")
			player.global_position = Vector3(0, 0.3, 1.0)
			lab.set("_auto_nav_target", tgt)
			for i in 150: await physics_frame
			var p := player.global_position
			print("ALTAR_EXIT %s to=%s end=(%.2f, %.2f, %.2f) moved=%.2f" % [id, tgt, p.x, p.y, p.z, Vector2(p.x, p.z).distance_to(Vector2(0, 1))])
			lab.queue_free()
			await physics_frame
	quit(0)
