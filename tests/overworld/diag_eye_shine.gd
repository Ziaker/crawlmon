extends SceneTree
## Counts how many eye surfaces EyeShine patches per species (expected: only flat-black eyes).
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var d := DirAccess.open("res://assets/modelos")
	for id in d.get_directories():
		var p := "res://assets/modelos/%s/%s.glb" % [id, id]
		if not ResourceLoader.exists(p): continue
		var glb := (load(p) as PackedScene).instantiate()
		print("EYESHINE ", id, " patched=", preload("res://scripts/common/eye_shine.gd").apply(glb))
		glb.queue_free()
	quit(0)
