extends SceneTree
## Protótipo do bloco vertical de afinidades (D-1165) na StatusScreen.
## Gera 4 capturas: sem afinidades, 3, 5 e 6 entradas.

const StatusScreen = preload("res://scripts/ui/status_screen.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")
const Element = preload("res://scripts/data/element.gd")
const Affinity = preload("res://scripts/data/affinity.gd")
const Skill = preload("res://scripts/data/skill.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("test_captures")
	root.size = Vector2i(1280, 720)

	var screen := StatusScreen.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)

	var abra := _make_abra()
	abra.affinities = {
		Element.Type.RAIO: Affinity.Type.WEAK,
		Element.Type.SOM: Affinity.Type.WEAK,
		Element.Type.TREVAS: Affinity.Type.WEAK,
		Element.Type.MYSTIC: Affinity.Type.WEAK,
		Element.Type.PSIQUICO: Affinity.Type.RESIST,
	}
	var party: Array[Combatant] = [abra]
	screen.open(party, 0)
	screen._move = 1
	screen.force_nature_view = false

	screen.queue_redraw()
	for f in 8:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("test_captures/aff_final.png")
		print("[CAPTURE_SUCCESS] test_captures/aff_final.png")

	# Sem afinidades: todos os elementos em "–".
	abra.affinities.clear()
	screen.queue_redraw()
	for f in 8:
		await process_frame
	var img_none := root.get_viewport().get_texture().get_image()
	if img_none != null:
		img_none.save_png("test_captures/aff_final_none.png")
		print("[CAPTURE_SUCCESS] test_captures/aff_final_none.png")
	quit(0)


func _make_abra() -> Combatant:
	var base := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 20, "MAG": 105, "VIT": 15, "WIS": 55, "AGI": 90, "LUK": 57
	})
	var c := Combatant.new("Abra", 37, 1, 0.50, true)
	c.species_id = "abra"
	c.nature_id = "modest"
	c.level = 2
	c.xp = 10
	c.innate_stats = CrawlmonAttributeMath.consolidate_innate_attributes(
		base, {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
		NatureData.get_nature("modest")["mods"]
	)
	c.sync_effective_stats()
	c.update_resource_maximums()
	c.hp = 41
	c.mp = c.max_mp
	c.skills.assign([
		Skill.new("Confusion", 1.4, 2, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Psybeam", 1.7, 3, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Shock Wave", 1.3, 2, Element.Type.RAIO, Skill.Kind.CAST, false, false, false, 1.5),
		Skill.new("Megido", 1.6, 3, Element.Type.MYSTIC, Skill.Kind.PROJECTILE, false, true, false, 1.5),
	])
	return c
