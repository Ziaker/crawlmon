extends SceneTree
## D-274 (item 6): runs the perception tools (VfxPerception) over reference recipes built from VfxLib,
## on all four layouts (left/right, near/far) and two target sizes, as D-235 / AGENTS section 7 demand.
##
## Windowed, fixed step (headless draws nothing):
##   godot --path . --fixed-fps 30 --script res://tests/fx_lab/perception/run_perception.gd
## Env: PERCEPTION_OUT (output dir, default user://perception), PERCEPTION_SET (small | full | repeat | guard).
## Output: contact_sheet.png (rows = beauty / closeup / silhouette per variant, columns = times), per-variant PNGs,
## perception.json with the numbers and warnings.

const TIMES := [0.1, 0.25, 0.4, 0.6, 0.9]
const GUARD_TIMES := [0.15, 0.4, 0.85, 0.97, 1.3, 1.9, 2.3]


func _init() -> void:
	call_deferred("_go")


func _go() -> void:
	var out_dir := OS.get_environment("PERCEPTION_OUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("user://perception")
	var which := OS.get_environment("PERCEPTION_SET")
	var variants: Array = []
	var times: Array = TIMES
	match which:
		"guard":  # The real Guard shield (FxGuard) on every layout and two sizes (D-235).
			times = GUARD_TIMES
			variants = [
				_variant("guard_expire", "side_lr", 1.4), _variant("guard_hit", "side_rl", 1.4),
				_variant("guard_broken", "near_to_far", 0.8), _variant("guard_hit", "far_to_near", 2.4),
				_variant("guard_expire", "near_to_far", 2.4),
			]
		"repeat":
			variants = [_variant("projectile", "side_lr", 1.4), _variant("burst", "side_lr", 1.4)]
		"small":
			variants = [_variant("projectile", "side_lr", 1.4), _variant("projectile", "far_to_near", 1.4)]
		_:
			for layout in VfxPerception.LAYOUTS:
				variants.append(_variant("projectile", layout, 1.4))
			for h in [0.8, 2.4]:
				variants.append(_variant("burst", "side_rl", h))
				variants.append(_variant("slash", "near_to_far", h))
	var res: Dictionary = await VfxPerception.run(self, {
		"out_dir": out_dir, "times": times, "fps": 30, "seed": 7,
		"variants": variants, "check_repeat": which == "repeat" or which == "",
	})
	print("PERCEPTION_DONE ", JSON.stringify({"sheet": res["sheet"], "json": res["json"]}))
	for k in res["variants"]:
		var e: Dictionary = res["variants"][k]
		print("  ", k, " layout=", e["layout"], " warnings=", e["warnings"], " repeat_mismatch=", e.get("repeat_mismatch", "-"))
	quit(0)


func _variant(recipe: String, layout: String, target_height: float) -> Dictionary:
	return {
		"name": "%s_%s_h%s" % [recipe, layout, str(target_height).replace(".", "_")],
		"factory": Callable(PerceptionRecipes, recipe),
		"layout": layout, "target_height": target_height, "target_radius": 0.25 + target_height * 0.12,
	}
