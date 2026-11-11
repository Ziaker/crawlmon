extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1

func _init() -> void:
	var megido := Skill.from_id(&"megido")
	ok(megido != null, "Megido exists in the catalog")
	ok(megido.element == Element.Type.MYSTIC, "Megido element is Mystic")
	ok(Element.name_of(megido.element) == "Mystic", "element name is Mystic")
	ok(megido.is_magical(), "Megido is magical")
	ok(megido.data.effect_line_text.contains("MAG"), "sheet says MAG, not ATK")
	ok(megido.data.effect_line_text.contains("Mystic"), "sheet says Mystic, not light")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1144
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})
	var dummy := Combatant.new("Dummy", 9999, 0, 0.5, false)
	dummy.place(Vector3.ZERO, 0.0)
	dummy.wis = 0
	var expected := maxi(1, roundi(float(abra.mag) * megido.power))
	ok(Battle.estimate_damage(abra, dummy, megido) == expected,
		"Megido damage scales with MAG (%d)" % expected)

	print("D1144_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
