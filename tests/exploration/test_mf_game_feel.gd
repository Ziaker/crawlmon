extends SceneTree

# Teste isolado do decaimento de trauma do MfGameFeel.
# Sem cena, sem audio e sem regra de jogo: so mede a camada de game feel.

const START_TRAUMA := 0.45
const STEP_DELTA := 0.1
const STEP_COUNT := 10


func _initialize() -> void:
	var gf := MfGameFeel.new()
	root.add_child(gf)

	var cam := Camera3D.new()
	root.add_child(cam)
	gf.camera = cam

	gf.impulse("large")
	var start: float = gf.trauma

	for i in range(STEP_COUNT):
		gf.step(STEP_DELTA)

	var end: float = gf.trauma
	var offset_zero: bool = is_zero_approx(cam.h_offset) and is_zero_approx(cam.v_offset)
	var start_ok: bool = is_equal_approx(start, START_TRAUMA)
	var end_ok: bool = is_equal_approx(end, 0.0)
	var ok: bool = start_ok and end_ok and offset_zero

	print("GF_JSON: " + JSON.stringify({
		"start": start,
		"end": end,
		"ok": ok,
		"offset_zero": offset_zero,
	}))

	if ok:
		print("PASS: trauma 0.45 cai para 0.0 em 1.0s e offsets voltam a zero")
	else:
		print("FAIL: start=%.3f end=%.3f offset_zero=%s" % [start, end, str(offset_zero)])

	quit(0 if ok else 1)
