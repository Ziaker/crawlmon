extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1

func _icon(id: StringName) -> String:
	var sk := Skill.from_id(id)
	return sk.type_icon_name() if sk != null else "MISSING"

func _init() -> void:
	ok(_icon(&"confusao") == "magical", "Confusion type icon is magical")
	ok(_icon(&"raio_psiquico") == "magical", "Psybeam type icon is magical")
	ok(_icon(&"onda_choque") == "magical", "Shock Wave type icon is magical")
	ok(_icon(&"teleporte_rapido") == "dodge", "Teleport type icon is dodge (D-396)")
	ok(_icon(&"megido") == "magical", "Megido type icon is magical")
	ok(_icon(&"tackle") == "physical", "Tackle type icon is physical")
	ok(_icon(&"media") == "status", "Media shows the status type icon (D-1190)")
	ok(_icon(&"sukunda") == "status", "Sukunda shows the status type icon (D-1190)")
	ok(_icon(&"golpe_carate") == "physical", "Karate Chop type icon is physical")

	print("D1145_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
