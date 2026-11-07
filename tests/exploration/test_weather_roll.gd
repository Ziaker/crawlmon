extends SceneTree
## Testes determinísticos do clima (D-382/D-384). Fora do jogo.
##
## godot --headless --path . --script res://tests/exploration/test_weather_roll.gd

var _fail := 0


func _init() -> void:
	var weather_script = load("res://scripts/dungeon/weather_controller.gd")
	_check(weather_script != null, "weather_controller.gd carrega")
	if weather_script == null:
		quit(1)
		return

	var hits := 0
	for i in 1000:
		if weather_script.roll_for(12345, i + 1):
			hits += 1
	_check(hits >= 150 and hits <= 250, "20% +-5% em 1000 andares: " + str(hits))

	_check(weather_script.roll_for(2, 1), "seed 2, andar 1 passa na rolagem")
	_check(weather_script.weather_for("temporal_tower", 2, 1) == "mist",
		"seed 2, andar 1 escolhe neblina")

	var biomes := [
		"temporal_tower", "murky_forest", "barren_valley", "4th_station_pass",
		"dark_ice_mountain", "spacial_cliffs",
	]
	for biome in biomes:
		var kind: String = weather_script.weather_for(biome, 12345, 1)
		_check(kind != "", "bioma %s tem clima: %s" % [biome, kind])

	print("WEATHER TESTS: ", "OK" if _fail == 0 else "%d FALHAS" % _fail)
	quit(0 if _fail == 0 else 1)


func _check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_fail += 1
