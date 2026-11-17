extends SceneTree

# D-1204: os valores abaixo são conferidos contra as FONTES reais em
# _verify_sources() (leitura de texto, sem preload — preload do lab puxa o
# autoload GameState e gera erro de compilação em teste headless isolado).
const SOLO_CAMERA_DISTANCE := 3.4
const SOLO_CAMERA_HEIGHT := 0.85
const SOLO_CAMERA_PITCH := 8.0

const PARTY_CAMERA_DISTANCE := 6.2
const PARTY_CAMERA_HEIGHT := 1.5
const PARTY_CAMERA_PITCH := 22.0

const TRIANGLE_LEG_A := 0.9
const TRIANGLE_LEG_B := 1.7
const TRIANGLE_MAX_LEG := 1.7
const WALL_LENGTH := 4.2
# Corredor/célula/copa/porta não têm constante nomeada na fonte; valores
# literais das decisões D-1028/D-1245 (documentados aqui como origem).
const CORRIDOR_LENGTH := 6.0
const CELL_SIZE := 3.0
const PANTRY_SIZE := 5.5
const DOOR_CLEARANCE := 3.0
const MARGIN := 0.3

const VIEW_SOLO := "solo"
const VIEW_PARTY := "party"

var _strict := false
var _summary_json := false
var _anomalies := 0

func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_strict = "--strict-asserts" in args
	_summary_json = "--summary-json" in args
	print("STRICT_ASSERTS: %s" % ("on" if _strict else "off"))
	_verify_sources()

	var report := {
		"views": {
			VIEW_SOLO: {},
			VIEW_PARTY: {},
		},
		"layout": {
			"wall": WALL_LENGTH,
			"corridor": CORRIDOR_LENGTH,
			"cell": CELL_SIZE,
			"pantry": PANTRY_SIZE,
			"door_free": DOOR_CLEARANCE,
			"margin": MARGIN,
		},
	}

	report["views"][VIEW_SOLO] = _evaluate_view(
		VIEW_SOLO,
		{"distance": SOLO_CAMERA_DISTANCE, "height": SOLO_CAMERA_HEIGHT, "pitch": SOLO_CAMERA_PITCH},
		{"camera_distance": SOLO_CAMERA_DISTANCE, "camera_height": SOLO_CAMERA_HEIGHT, "camera_pitch": SOLO_CAMERA_PITCH}
	)
	report["views"][VIEW_PARTY] = _evaluate_view(
		VIEW_PARTY,
		{"distance": PARTY_CAMERA_DISTANCE, "height": PARTY_CAMERA_HEIGHT, "pitch": PARTY_CAMERA_PITCH},
		{"camera_distance": PARTY_CAMERA_DISTANCE, "camera_height": PARTY_CAMERA_HEIGHT, "camera_pitch": PARTY_CAMERA_PITCH}
	)

	if _summary_json:
		var short := {
			"ok": _anomalies == 0,
			"views": [VIEW_SOLO, VIEW_PARTY],
			"door_fits_triangle": DOOR_CLEARANCE >= TRIANGLE_LEG_B + MARGIN,
		}
		print("METRICS_JSON: " + JSON.stringify(short))
	else:
		print("METRICS_JSON: " + JSON.stringify(report))

	if _anomalies == 0:
		print("PASS: solo and party views match layout metrics")
	else:
		print("FAIL: %d anomalies across solo/party views" % _anomalies)

	quit(1 if _anomalies > 0 else 0)

## D-1204: confere os literais do teste contra as constantes reais das fontes.
## Usa leitura de texto para não compilar o lab (que depende do autoload GameState).
func _verify_sources() -> void:
	var checks := {
		"res://scripts/debug/third_person_3d_lab.gd|CAM_DISTANCE": SOLO_CAMERA_DISTANCE,
		"res://scripts/debug/third_person_3d_lab.gd|CAM_HEIGHT": SOLO_CAMERA_HEIGHT,
		"res://scripts/debug/third_person_3d_lab.gd|SOLO_CAM_PITCH": SOLO_CAMERA_PITCH,
		"res://scripts/debug/third_person_3d_lab.gd|PARTY_CAM_DISTANCE": PARTY_CAMERA_DISTANCE,
		"res://scripts/debug/third_person_3d_lab.gd|PARTY_CAM_HEIGHT": PARTY_CAMERA_HEIGHT,
		"res://scripts/debug/third_person_3d_lab.gd|PARTY_CAM_PITCH": PARTY_CAMERA_PITCH,
		"res://scripts/debug/murky_forest_3d_lab.gd|FOREST_WALL_HEIGHT": WALL_LENGTH,
	}
	for key in checks:
		var parts: Array = key.split("|")
		var actual := _read_const(parts[0], parts[1])
		if actual < 0.0:
			_anomalies += 1
			print("FAIL source %s: constante nao encontrada" % key)
		elif not is_equal_approx(actual, float(checks[key])):
			_anomalies += 1
			print("FAIL source %s: fonte=%.3f teste=%.3f" % [key, actual, float(checks[key])])


func _read_const(path: String, name: String) -> float:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1.0
	var text := file.get_as_text()
	file.close()
	var re := RegEx.new()
	re.compile("const\\s+" + name + "\\s*:?=\\s*([0-9]+(?:\\.[0-9]+)?)")
	var m := re.search(text)
	if m == null:
		return -1.0
	return float(m.get_string(1))


func _evaluate_view(view: String, camera: Dictionary, expected_camera: Dictionary) -> Dictionary:
	var metrics := {
		"camera_distance": float(camera["distance"]),
		"camera_height": float(camera["height"]),
		"camera_pitch": float(camera["pitch"]),
		"distance_clears_triangle": float(camera["distance"]) > TRIANGLE_MAX_LEG,
		"pitch_in_range": float(camera["pitch"]) >= 0.0 and float(camera["pitch"]) <= 45.0,
		"door_fits_triangle": DOOR_CLEARANCE >= TRIANGLE_LEG_B + MARGIN,
		"triangle_within_cell": TRIANGLE_MAX_LEG + MARGIN <= CELL_SIZE,
		"corridor_holds_wall": WALL_LENGTH + MARGIN <= CORRIDOR_LENGTH,
		"pantry_holds_cell": CELL_SIZE + MARGIN <= PANTRY_SIZE,
	}

	var expected := expected_camera.duplicate()
	expected["distance_clears_triangle"] = true
	expected["pitch_in_range"] = true
	expected["door_fits_triangle"] = true
	expected["triangle_within_cell"] = true
	expected["corridor_holds_wall"] = true
	expected["pantry_holds_cell"] = true

	var checks := {}
	for key in expected:
		var exp = expected[key]
		var actual = metrics[key]
		var ok := false
		if typeof(exp) == TYPE_BOOL:
			ok = actual == exp
		else:
			ok = is_equal_approx(float(actual), float(exp))
		checks[key] = ok
		if not ok:
			_anomalies += 1
			print("FAIL [%s] %s: expected %s, got %s" % [view, key, str(exp), str(actual)])
			if _strict:
				quit(1)
				return {"camera": camera, "assertions": checks, "ok": false}

	return {"camera": camera, "assertions": checks, "ok": true}
