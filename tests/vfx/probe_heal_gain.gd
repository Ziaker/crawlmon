extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var fx := MotionPresets.heal_gain_effect(1234, Vector3(0, 1.75, 0))
	print("layers: ", fx.layers.size())
	var l: Dictionary = fx.layers[0]
	var comp: MotionComposition = l["comp"]
	print("samples: ", comp.sample_count, " duration: ", comp.duration, " layers: ", comp.layers.size())
	for t in [0.05, 0.2, 0.5, 0.9]:
		var res := comp.evaluate(MotionStrand.catalog(), comp.make_context(t))
		print("t=", t, " errors=", res.has_errors(), " samples=", res.samples.size())
		for d in res.diagnostics:
			print("  diag: ", d)
		var shown := 0
		for s in res.samples:
			if s.visible:
				shown += 1
				if shown <= 3:
					print("  pos=", s.position, " width=", s.width, " opacity=", s.opacity, " intensity=", s.intensity)
		print("  visible: ", shown)
	quit(0)
