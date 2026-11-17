extends SceneTree
## Which species get an EyeBlink node (blinkable eyes)?
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var d := DirAccess.open("res://assets/modelos")
	var out := []
	for id in d.get_directories():
		var p := "res://assets/modelos/%s/%s.glb" % [id, id]
		if not ResourceLoader.exists(p): continue
		var glb := (load(p) as PackedScene).instantiate()
		preload("res://scripts/common/eye_shine.gd").apply(glb)
		out.append("%s=%s" % [id, glb.find_child("EyeBlink", true, false) != null])
		glb.queue_free()
	print("EYEBLINK ", out)
	quit(0)
