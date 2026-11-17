extends SceneTree
## Cost of EyeShine.apply (+EyeBlink.attach) per model instantiation, in ms (cold = first, warm = next 5).
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	for id in ["pikachu", "eevee", "charmander", "bulbasaur", "gible", "pancham"]:
		var ps := load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene
		var ms := []
		for i in 6:
			var g := ps.instantiate()
			var t0 := Time.get_ticks_usec()
			preload("res://scripts/common/eye_shine.gd").apply(g)
			ms.append(snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1))
			g.queue_free()
		print("EYECOST ", id, " ms=", ms)
	quit(0)
