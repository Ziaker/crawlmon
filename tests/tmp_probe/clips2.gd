extends SceneTree
func _init() -> void:
	for f in ["dqt_orc/dqt_orc", "dqt_cyclops/dqt_cyclops"]:
		var n := (load("res://assets/modelos/%s.glb" % f) as PackedScene).instantiate()
		var ap := n.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var out := []
		for a in ap.get_animation_list():
			out.append("%s(%.2f)" % [String(a).get_slice("_", 3), ap.get_animation(a).length])
		print(f, " ", out)
		n.free()
	quit()
