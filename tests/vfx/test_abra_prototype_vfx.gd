extends SceneTree
## D-170: the Abra move VFX ported from prototype v9 (Confusion, Psybeam, Shock Wave).
## Visual only: no combat rule is asserted or changed here. Teleport is intentionally absent.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	await process_frame
	_test_windups(battle_fx)
	_test_travel_layers(battle_fx)
	_test_impacts(battle_fx)
	_test_telegraph_hook(battle_fx)
	await _test_frames_and_cleanup(battle_fx)
	battle_fx.queue_free()
	if failures == 0:
		print("ABRA_PROTOTYPE_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_windups(battle_fx: BattleFx) -> void:
	for move in ["confusao", "raio_psiquico", "onda_choque", "teleporte_rapido"]:
		var v := AbraMoveVfx.windup(battle_fx, move, Vector3(-3, 0, 6), Vector3(8, 0, -20), 0.5)
		_expect(v.get_parent() == battle_fx, "%s wind-up must live under the FX root" % move)
		_expect(v.stage == AbraMoveVfx.Stage.WINDUP, "%s wind-up stage" % move)
		_step(v, 0.25)
		_expect(v.get_child_count() > 0, "%s wind-up must build its layers" % move)
		v.queue_free()


func _test_travel_layers(battle_fx: BattleFx) -> void:
	var from := Vector3(-3, 1, 6)
	var to := Vector3(8, 1, -20)
	var shock_layer := AbraMoveVfx.travel(battle_fx, "onda_choque", from, to)
	shock_layer.set_travel(from, to, 0.6, false)
	_step(shock_layer, 0.05)
	_expect(shock_layer._bolts.size() >= 3 and shock_layer._bolts[0].visible, "Shock Wave must draw its descending lightning quads (shader)")
	shock_layer.queue_free()
	var cube_layer := AbraMoveVfx.travel(battle_fx, "confusao", from, to)
	cube_layer.set_travel(from, to, 0.5, false)
	_step(cube_layer, 0.05)
	_expect(cube_layer._solid.mesh.get_surface_count() > 0, "Confusion flight must draw its cubes and ribbon trails")
	var beam_layer := AbraMoveVfx.travel(battle_fx, "raio_psiquico", from, to)
	beam_layer.set_travel(from, to, 1.0, false)
	_step(beam_layer, 0.05)
	_expect(beam_layer._beams.size() >= 2 and beam_layer._beams[0].visible, "Psybeam must fire its laser (shader quads)")
	beam_layer.set_travel(from, to, 0.5, true)
	_step(beam_layer, 0.05)
	cube_layer.queue_free()
	beam_layer.queue_free()


func _test_impacts(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -8)
	battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color("bd9afd"), false, Vector3.FORWARD, "confusao")
	_expect(battle_fx.find_children("AbraConfusaoImpact*", "Node3D", true, false).size() == 1, "Confusion impact must add the prototype layer")
	battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color("bd9afd"), true, Vector3.FORWARD, "raio_psiquico")
	_expect(battle_fx.find_children("AbraRaioPsiquicoImpact*", "Node3D", true, false).size() == 1, "Psybeam impact must add the prototype layer")
	battle_fx.fx_impacts._impact(Element.Type.RAIO, pos, Color("d6fa66"), true, Vector3.FORWARD, "onda_choque")
	_expect(battle_fx.find_children("AbraOndaChoqueImpact*", "Node3D", true, false).size() == 1, "Shock Wave impact must add the prototype layer")
	battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color("63d9ec"), false, Vector3.FORWARD, "teleporte_rapido")
	_expect(battle_fx.find_children("AbraTeleporteRapidoImpact*", "Node3D", true, false).size() == 1, "Teleport impact must add the tesseract palm and Mach rings")


func _test_telegraph_hook(battle_fx: BattleFx) -> void:
	var dict: Dictionary = battle_fx.fx_telegraph._telegraph_move(null, "confusao", Vector3(-3, 0, 6), Vector3(8, 0, -20), Color.RED, Color.RED, 0.5)
	var nodes: Array = dict.get("nodes", [])
	var found := false
	for n in nodes:
		if n is AbraMoveVfx:
			found = true
	_expect(found, "Confusion telegraph must hand its wind-up layer to clear_telegraph")
	for n in nodes:
		(n as Node).queue_free()
	var tele: Dictionary = battle_fx.fx_telegraph._telegraph_move(null, "teleporte_rapido", Vector3.ZERO, Vector3(0, 0, -8), Color.RED, Color.RED, 0.5)
	var tele_nodes: Array = tele.get("nodes", [])
	var tele_found := false
	for n in tele_nodes:
		if n is AbraMoveVfx:
			tele_found = true
		(n as Node).queue_free()
	_expect(tele_found, "Teleport wind-up must hand its scan rings, seal and streaks to clear_telegraph")


func _test_frames_and_cleanup(battle_fx: BattleFx) -> void:
	var v := AbraMoveVfx.impact(battle_fx, "onda_choque", Vector3(0, 1, -8), false)
	for i in 2:
		await process_frame
	_expect(is_instance_valid(v), "an impact layer lives for its own span")
	_step(v, 1.0)
	await process_frame
	_expect(not is_instance_valid(v) or v.is_queued_for_deletion(), "an impact layer frees itself after its span")
	AbraPops.teleport_pop(battle_fx, Vector3(0, 0, -8), true, null)
	_expect(battle_fx.find_children("*", "MeshInstance3D", true, false).size() >= 6, "the Teleport pop must spawn its column, rings and streaks")
	var c := AbraMoveVfx.impact(battle_fx, "confusao", Vector3(0, 1, -8), true)
	_step(c, 0.3)
	_expect(c._canvas.mesh.get_surface_count() > 0, "Confusion impact must fill the neon canvas")
	c.queue_free()


## Drives a layer by hand with a fixed step (the tree also advances it per frame).
func _step(v: AbraMoveVfx, seconds: float) -> void:
	var left := seconds
	while left > 0.0 and is_instance_valid(v) and not v.is_queued_for_deletion():
		v._process(0.05)
		left -= 0.05


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
