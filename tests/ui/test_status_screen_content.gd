extends SceneTree
## Teste automatizado para validacao da tela de status (StatusScreen).

const StatusScreen = preload("res://scripts/ui/status_screen.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")

func _init() -> void:
	print("[TEST] Iniciando suite: test_status_screen_content.gd")
	var success := true

	success = success and _test_nature_formatting_helpers()
	success = success and _test_status_screen_lifecycle()

	if success:
		print("[TEST SUCCESS] Testes de StatusScreen passaram com 100% de sucesso!")
		quit(0)
	else:
		push_error("[TEST FAILURE] Testes de StatusScreen falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
		return false
	return true


func _test_nature_formatting_helpers() -> bool:
	print("  -> Testando formatacao textual de Natures e perfis de IA...")
	var screen := StatusScreen.new()

	# Modest
	var modest := NatureData.get_nature("modest")
	var modest_mods: String = screen._format_nature_mods(modest["mods"])
	if not _assert_test("+3 MAG" in modest_mods and "-2 STR" in modest_mods and "-1 AGI" in modest_mods,
		"Modest mods formatado incorretamente: " + modest_mods):
		return false

	var modest_ai: String = screen._format_nature_ai(modest)
	if not _assert_test("Aggression 1.0×" in modest_ai and "ATB Reserve Default" in modest_ai,
		"Modest AI formatado incorretamente: " + modest_ai):
		return false

	# Hardy (neutra)
	var hardy := NatureData.get_nature("hardy")
	var hardy_mods: String = screen._format_nature_mods(hardy["mods"])
	if not _assert_test("Neutral" in hardy_mods, "Hardy mods deve indicar Neutral: " + hardy_mods):
		return false

	# Brave
	var brave := NatureData.get_nature("brave")
	var brave_mods: String = screen._format_nature_mods(brave["mods"])
	if not _assert_test("+2 STR" in brave_mods and "-2 AGI" in brave_mods,
		"Brave mods formatado incorretamente: " + brave_mods):
		return false

	var brave_ai: String = screen._format_nature_ai(brave)
	if not _assert_test("Aggression 1.3×" in brave_ai and "Aggressive" in brave_ai,
		"Brave AI formatado incorretamente: " + brave_ai):
		return false

	screen.free()
	return true


func _test_status_screen_lifecycle() -> bool:
	print("  -> Testando ciclo de vida, abertura e troca de personagens...")
	var screen := StatusScreen.new()
	root.add_child(screen)

	var c1 := Combatant.new("Abra", 37, 1, 0.5, true)
	c1.species_id = "abra"
	c1.nature_id = "modest"
	c1.innate_stats = {"STR": 1, "MAG": 5, "VIT": 1, "WIS": 2, "AGI": 4, "LUK": 2}
	c1.sync_effective_stats()
	c1.update_resource_maximums()
	c1.hp = c1.max_hp
	c1.mp = c1.max_mp

	var c2 := Combatant.new("Pancham", 41, 4, 0.425, true)
	c2.species_id = "pancham"
	c2.nature_id = "brave"
	c2.innate_stats = {"STR": 4, "MAG": 2, "VIT": 3, "WIS": 2, "AGI": 2, "LUK": 2}
	c2.sync_effective_stats()
	c2.update_resource_maximums()
	c2.hp = c2.max_hp
	c2.mp = c2.max_mp

	var party: Array[Combatant] = [c1, c2]
	screen.open(party, 0)
	if not _assert_test(screen.visible, "Screen deve estar visivel apos open()"):
		return false

	# Forca desenho
	screen.queue_redraw()

	# Troca para membro 1
	var ev_down := InputEventAction.new()
	ev_down.pressed = true
	ev_down.action = "ui_down"
	screen._unhandled_input(ev_down)
	if not _assert_test(screen._member == 1, "Membro selecionado deve ser 1 apos ui_down"):
		return false

	screen.free()
	return true
