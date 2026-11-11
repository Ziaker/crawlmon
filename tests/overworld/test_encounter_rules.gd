extends SceneTree
## D-1100/D-1101: encounter variant resolver and ATB advantage. Pure rules, no scene.
##
## .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/overworld/test_encounter_rules.gd

var _fail := 0


func _init() -> void:
	_test_resolve()
	_test_apply_atb()
	_test_transition_variants()
	print("ENCOUNTER RULES TESTS: ", "OK" if _fail == 0 else "%d FALHAS" % _fail)
	quit(0 if _fail == 0 else 1)


func _test_resolve() -> void:
	var normal := EncounterRules.Advantage.NORMAL
	var player_first := EncounterRules.Advantage.PLAYER_FIRST
	var enemy_first := EncounterRules.Advantage.ENEMY_FIRST

	_check(EncounterRules.resolve(false, false, false, false) == normal,
		"contato normal sem ataques = NORMAL")
	_check(EncounterRules.resolve(true, false, true, false) == normal,
		"contato normal com os dois errando = NORMAL")
	_check(EncounterRules.resolve(true, true, false, false) == player_first,
		"só o jogador acerta = PLAYER_FIRST")
	_check(EncounterRules.resolve(false, false, true, true) == enemy_first,
		"só o inimigo acerta = ENEMY_FIRST")
	_check(EncounterRules.resolve(true, true, true, true) == normal,
		"os dois acertam no mesmo instante = NORMAL")
	_check(EncounterRules.resolve(true, false, false, false) == normal,
		"ataque do jogador sem alvo/errado = NORMAL")
	_check(EncounterRules.resolve(false, false, true, false) == normal,
		"ataque do inimigo sem alvo/errado = NORMAL")


func _test_apply_atb() -> void:
	var nothing := EncounterRules.Advantage.NORMAL
	var player_first := EncounterRules.Advantage.PLAYER_FIRST
	var enemy_first := EncounterRules.Advantage.ENEMY_FIRST

	# D-1101: base 3 -> winner 4, loser 2, every combatant on the side.
	var party := _units([3.0, 3.0])
	var enemies := _units([3.0, 3.0, 3.0])
	EncounterRules.apply_atb(party, enemies, player_first)
	_check_atb(party, [4.0, 4.0], "PLAYER_FIRST: party inteira vai a 4")
	_check_atb(enemies, [2.0, 2.0, 2.0], "PLAYER_FIRST: todos os inimigos vão a 2")

	party = _units([3.0, 3.0])
	enemies = _units([3.0])
	EncounterRules.apply_atb(party, enemies, enemy_first)
	_check_atb(party, [2.0, 2.0], "ENEMY_FIRST: party inteira vai a 2")
	_check_atb(enemies, [4.0], "ENEMY_FIRST: todos os inimigos vão a 4")

	# Normal contact / tie: 3 vs 3 unchanged.
	party = _units([3.0, 3.0])
	enemies = _units([3.0, 3.0])
	EncounterRules.apply_atb(party, enemies, nothing)
	_check_atb(party, [3.0, 3.0], "NORMAL: party intacta em 3")
	_check_atb(enemies, [3.0, 3.0], "NORMAL: inimigos intactos em 3")

	# Clamp 0..5.
	party = _units([5.0, 0.0])
	enemies = _units([5.0, 0.0])
	EncounterRules.apply_atb(party, enemies, player_first)
	_check_atb(party, [5.0, 1.0], "clamp: 5 continua 5, 0 vira 1")
	_check_atb(enemies, [4.0, 0.0], "clamp: 5 vira 4, 0 continua 0")

	# D-1101: only the normal ATB is used; `extra` is neither read nor written.
	var full := Combatant.new("Full", 10, 1, 0.5, true)
	full.atb = 5.0
	full.extra = 2.0
	EncounterRules.apply_atb([full], [], player_first)
	_check(is_equal_approx(full.atb, 5.0) and is_equal_approx(full.extra, 2.0),
		"extra não entra na conta e não é alterado")

	# Empty/null sides do not crash.
	EncounterRules.apply_atb([], [], player_first)
	EncounterRules.apply_atb([null], [null], enemy_first)
	_check(true, "lados vazios/nulos não quebram")


func _test_transition_variants() -> void:
	var normal := EncounterRules.Advantage.NORMAL
	var player_first := EncounterRules.Advantage.PLAYER_FIRST
	var enemy_first := EncounterRules.Advantage.ENEMY_FIRST

	_check(EncounterTransition.accent_for(normal) == EncounterTransition.CREAM, "NORMAL = branco/creme")
	_check(EncounterTransition.accent_for(player_first) == EncounterTransition.BLUE, "PLAYER_FIRST = azul")
	_check(EncounterTransition.accent_for(enemy_first) == EncounterTransition.CORAL, "ENEMY_FIRST = vermelho")
	_check(EncounterTransition.subtitle_for(normal) == "CONTATO", "selo NORMAL = CONTATO")
	_check(EncounterTransition.subtitle_for(player_first) == "VANTAGEM", "selo PLAYER_FIRST = VANTAGEM")
	_check(EncounterTransition.subtitle_for(enemy_first) == "EMBOSCADA", "selo ENEMY_FIRST = EMBOSCADA")
	_check(is_equal_approx(EncounterTransition.DURATION, 1.0)
		and is_equal_approx(EncounterTransition.SWAP_AT, 0.46)
		and is_equal_approx(EncounterTransition.REVEAL_AT, 0.60),
		"timeline 1.0 s / swap 0.46 / reveal 0.60 preservada")


func _units(values: Array) -> Array:
	var units := []
	for i in values.size():
		var c := Combatant.new("U%d" % i, 10, 1, 0.5, true)
		c.atb = float(values[i])
		units.append(c)
	return units


func _check_atb(units: Array, expected: Array, label: String) -> void:
	var ok := units.size() == expected.size()
	if ok:
		for i in units.size():
			if not is_equal_approx(units[i].atb, float(expected[i])):
				ok = false
				break
	_check(ok, label + " (obtido " + str(_atb_values(units)) + ")")


func _atb_values(units: Array) -> Array:
	var values := []
	for unit in units:
		values.append(unit.atb)
	return values


func _check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_fail += 1
