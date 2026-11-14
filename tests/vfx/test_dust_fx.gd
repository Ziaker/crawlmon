extends SceneTree
## D-1196: smoke + leak test of the dust library (headless, no rendering): every effect is built,
## runs to its end and leaves no node behind. Run: godot --headless --path . --script tests/vfx/test_dust_fx.gd

const DustFxScript = preload("res://scripts/vfx/combat/dust/dust_fx.gd")
const DustParticlesScript = preload("res://scripts/vfx/combat/dust/dust_particles.gd")
const DustGroundScript = preload("res://scripts/vfx/combat/dust/dust_fx_ground.gd")
const DustMaterialsScript = preload("res://scripts/vfx/combat/dust/dust_materials.gd")


func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var earth: Dictionary = DustMaterialsScript.PALETTE_EARTH_DIG
	DustFxScript.cloud_ring(root, Vector3(1, 0, 1), 8, 0.72, 0.88, 1.15, 0.0, earth)
	DustFxScript.veil_and_shock_ring(root, Vector3(1, 0, 1), 1.05, 1.85, 1.15, 0.0, earth)
	DustFxScript.lotus_crown(root, Vector3(1, 0, 1), "entry", 1.0, 0.0)
	DustFxScript.lotus_crown(root, Vector3(1, 0, 1), "impact", 1.3, 0.2)
	DustFxScript.soil_mound(root, Vector3(1, 0, 1), 0.1)
	DustGroundScript.boulder_barrage(root, Vector3(1, 0, 1), 6, Vector2(3.5, 6.8), Vector2(0.14, 0.24), 1.15, 0.0)
	DustGroundScript.crater(root, Vector3(1, 0, 1), 1.95, 1.55, 0.0)
	DustParticlesScript.spawn_dig_dust(root, Vector3(2, 0, 2), 1.0, 0.85)
	var peak := _count(root)
	print("DUST_TEST peak_nodes=", peak)
	var elapsed := 0.0
	while elapsed < 4.0:
		await process_frame
		elapsed += 1.0 / 60.0 * 4.0  # coarse upper bound of the frame delta
	# Let the real clock run: wait wall time for the longest effect (particles free at 0.85 + 1.35 = 2.2 s).
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	var left := _count(root)
	print("DUST_TEST leaks=", left, " (expected 0)")
	quit(0 if left == 0 and peak > 0 else 1)


func _count(node: Node) -> int:
	var n := 0
	for child in node.get_children():
		n += 1 + _count(child)
	return n
