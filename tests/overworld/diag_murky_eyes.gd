extends SceneTree
## D-1268: a cena real da Murky Forest (e o NPC Pikachu dela) cria os modelos com EyeShine/EyeBlink?
## Uso: godot --path . --script tests/overworld/diag_murky_eyes.gd  (janela, ~15 s)

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (load("res://scenes/debug/murky_forest_3d_lab.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for i in 90:
		await process_frame
	var blinks := scene.find_children("EyeBlink", "Node", true, false)
	print("DIAG_MURKY blinks=", blinks.size())
	for b in blinks:
		var holder := b.get_parent()
		var mats := int((b as Node).get("_mats").size()) if (b as Node).get("_mats") != null else -1
		print("  ", holder.name, " (", holder.get_parent().name if holder.get_parent() else "", ") mats=", mats, " lid_k=", (b as Node).get("lid_k"))
	await create_timer(6.0).timeout
	var total := 0
	for b in blinks:
		total += int((b as Node).get("blinks"))
	print("DIAG_MURKY piscadas_em_6s=", total)
	quit(0 if blinks.size() > 0 else 1)
