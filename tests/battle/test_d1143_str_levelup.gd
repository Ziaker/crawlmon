extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1143
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})
	var before := abra.attack
	abra.progression_points["STR"] = int(abra.progression_points.get("STR", 0)) + 1
	abra.sync_effective_stats()
	ok(abra.attack == before + 1, "1 STR point raises physical attack by 1 (%d -> %d)" % [before, abra.attack])

	abra.buff_stat("attack", 2)
	ok(abra.attack == maxi(1, roundi(float(abra.str) * 1.5)), "ATK buff still applies on top of STR")

	# An explicit test override must not be overwritten by a later sync.
	var over := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng, "attack": 99})
	ok(over.attack == 99, "explicit attack override is applied")
	over.sync_effective_stats()
	ok(over.attack == 99, "explicit attack override survives sync")

	# A bare Combatant (tests) keeps its explicit attack too.
	var bare := Combatant.new("Bare", 100, 10, 0.5, true)
	bare.innate_stats = {"STR": 5, "MAG": 5, "VIT": 5, "WIS": 5, "AGI": 5, "LUK": 5}
	bare.sync_effective_stats()
	ok(bare.attack == 10, "bare Combatant keeps explicit attack 10 after sync")

	print("D1143_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
