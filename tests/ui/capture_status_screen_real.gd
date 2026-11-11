extends SceneTree

const StatusScreen = preload("res://scripts/ui/status_screen.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")
const Element = preload("res://scripts/data/element.gd")
const Skill = preload("res://scripts/data/skill.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("test_captures")
	root.size = Vector2i(1280, 720)

	var screen := StatusScreen.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)

	# 1. Abra (Nível 2, EXP 10, Modest)
	var abra_base := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 20, "MAG": 105, "VIT": 15, "WIS": 55, "AGI": 90, "LUK": 57
	})
	var abra := Combatant.new("Abra", 37, 1, 0.50, true)
	abra.species_id = "abra"
	abra.nature_id = "modest"
	abra.level = 2
	abra.xp = 10
	abra.innate_stats = CrawlmonAttributeMath.consolidate_innate_attributes(
		abra_base, {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}, NatureData.get_nature("modest")["mods"]
	)
	abra.sync_effective_stats()
	abra.update_resource_maximums()
	abra.hp = 41
	abra.mp = abra.max_mp
	abra.weaknesses.assign([Element.Type.TREVAS, Element.Type.SOM])
	abra.skills.assign([
		Skill.new("Confusion", 1.4, 2, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Psybeam", 1.7, 3, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE, false, false, false, 1.5),
		Skill.new("Shock Wave", 1.3, 2, Element.Type.RAIO, Skill.Kind.CAST, false, false, false, 1.5),
		Skill.new("Teleport", 0.7, 1, Element.Type.PSIQUICO, Skill.Kind.MELEE, false, false, false, 0.5),
		Skill.new("Media", 0.0, 2, Element.Type.LUZ, Skill.Kind.STATUS, false, true, true, 0.5),
		Skill.new("Sukunda", 0.0, 1, Element.Type.VENTO, Skill.Kind.STATUS, false, false, false, 0.5),
		Skill.new("Megido", 1.6, 3, Element.Type.MYSTIC, Skill.Kind.PROJECTILE, false, true, false, 1.5),
	])

	# 2. Pancham (Nível 2, EXP 10, Brave)
	var pancham_base := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 82, "MAG": 46, "VIT": 62, "WIS": 48, "AGI": 43, "LUK": 56
	})
	var pancham := Combatant.new("Pancham", 41, 4, 0.425, true)
	pancham.species_id = "pancham"
	pancham.nature_id = "brave"
	pancham.level = 2
	pancham.xp = 10
	pancham.innate_stats = CrawlmonAttributeMath.consolidate_innate_attributes(
		pancham_base, {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}, NatureData.get_nature("brave")["mods"]
	)
	pancham.sync_effective_stats()
	pancham.update_resource_maximums()
	pancham.hp = 35
	pancham.mp = pancham.max_mp
	pancham.weaknesses.assign([Element.Type.PSIQUICO, Element.Type.VENTO])
	pancham.skills.assign([
		Skill.new("Mach Punch", 0.5, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.2),
		Skill.new("Karate Chop", 1.5, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.0),
		Skill.new("Brick Break", 1.8, 3, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5),
		Skill.new("Taunt", 0.0, 1, Element.Type.FISICO, Skill.Kind.STATUS, false, false, false, 0.5),
		Skill.new("Tarukaja", 0.0, 2, Element.Type.FOGO, Skill.Kind.STATUS, false, true, true, 0.5),
		Skill.new("Hassou Tobi", 1.4, 3, Element.Type.FISICO, Skill.Kind.MELEE, false, true, false, 1.5),
	])

	var party: Array[Combatant] = [abra, pancham]

	# Snapshot 1: Abra with Confusion, Nature Inspection OFF (D-422)
	screen.open(party, 0)
	screen._move = 1
	screen.force_nature_view = false
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img1 := root.get_viewport().get_texture().get_image()
	if img1 != null:
		img1.save_png("test_captures/01_status_screen_abra_shift_off.png")
		print("[CAPTURE_SUCCESS] 01_status_screen_abra_shift_off.png")

	# Snapshot 2: Abra with Modest Nature Tooltip & Combat Personality Panel ON (D-422)
	screen.force_nature_view = true
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img2 := root.get_viewport().get_texture().get_image()
	if img2 != null:
		img2.save_png("test_captures/02_status_screen_abra_nature_on.png")
		print("[CAPTURE_SUCCESS] 02_status_screen_abra_nature_on.png")

	# Snapshot 3: Pancham with Raised ALLY Tag (No Collision) & Nature OFF (D-422)
	screen.force_nature_view = false
	screen.open(party, 1)
	screen._move = 2
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img3 := root.get_viewport().get_texture().get_image()
	if img3 != null:
		img3.save_png("test_captures/03_status_screen_pancham_tag_ok.png")
		print("[CAPTURE_SUCCESS] 03_status_screen_pancham_tag_ok.png")

	# Snapshot 4: Pancham with Brave Nature Tooltip & Combat Personality Panel ON (D-422)
	screen.force_nature_view = true
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img4 := root.get_viewport().get_texture().get_image()
	if img4 != null:
		img4.save_png("test_captures/04_status_screen_pancham_nature_on.png")
		print("[CAPTURE_SUCCESS] 04_status_screen_pancham_nature_on.png")

	# Snapshot 5: Abra with Expanded Technical Dossier Modal (Z Key - D-420)
	screen.force_nature_view = false
	screen.open(party, 0)
	screen._move = 1
	screen._detail_open = true
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img5 := root.get_viewport().get_texture().get_image()
	if img5 != null:
		img5.save_png("test_captures/05_status_screen_abra_detail_z.png")
		print("[CAPTURE_SUCCESS] 05_status_screen_abra_detail_z.png")

	# Snapshot 6: Expedition Satchel Clean State (10 slots bright - D-424, D-427)
	screen._detail_open = false
	screen.force_nature_view = false
	screen.open(party, 1) # Pancham
	screen._move = 2
	screen.force_inventory_selected_id = ""
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img6 := root.get_viewport().get_texture().get_image()
	if img6 != null:
		img6.save_png("test_captures/06_status_screen_satchel_clean.png")
		print("[CAPTURE_SUCCESS] 06_status_screen_satchel_clean.png")

	# Snapshot 7A: Option A - Shear / Italic Skew at 9 deg (D-429)
	screen.force_inventory_selected_id = "potion"
	screen.desc_tilt_mode = 0
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img7a := root.get_viewport().get_texture().get_image()
	if img7a != null:
		img7a.save_png("test_captures/07_status_screen_satchel_potion_focused.png")
		img7a.save_png("test_captures/07a_status_screen_satchel_potion_shear.png")
		print("[CAPTURE_SUCCESS] 07a_status_screen_satchel_potion_shear.png")

	# Snapshot 7B: Option B - Angular Rotation at -9 deg (D-429)
	screen.desc_tilt_mode = 1
	screen.queue_redraw()
	for i in 6:
		await process_frame
	var img7b := root.get_viewport().get_texture().get_image()
	if img7b != null:
		img7b.save_png("test_captures/07b_status_screen_satchel_potion_rotation.png")
		print("[CAPTURE_SUCCESS] 07b_status_screen_satchel_potion_rotation.png")

	screen.desc_tilt_mode = 0
	quit(0)
