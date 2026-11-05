class_name PerceptionRecipes
extends RefCounted
## D-274 (item 6): small reference effects to exercise the perception tools. Each one is built from VfxLib
## and takes EVERYTHING from ctx (origin, destination, direction, target size), never from a character,
## a team or a side (D-235). They are test subjects, not game effects, and replace nothing.

## A glowing ball that flies from the attacker to the target, leaving a trail, then bursts on arrival.
static func projectile(ctx: Dictionary) -> void:
	var parent: Node3D = ctx["parent"]
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18 + float(ctx["target_height"]) * 0.05
	sphere.height = sphere.radius * 2.0
	ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.7, 0.25)
	ball.material_override = mat
	ball.position = ctx["origin"]
	parent.add_child(ball)
	VfxLib.trail(ball, {"amount": 24, "life": 0.35, "size": Vector2(0.15, 0.3), "speed": Vector2(0.1, 0.4), "spread": 20.0,
		"ramp": VfxLib.ramp([Color(1, 0.8, 0.3, 0.9), Color(1, 0.3, 0.05, 0)])})
	var tw := ball.create_tween()
	tw.tween_property(ball, "position", ctx["dest"], 0.45)
	tw.tween_callback(func() -> void:
		VfxLib.burst(parent, ctx["dest"], {"amount": 18, "life": 0.5, "speed": Vector2(2.0, 4.5), "size": Vector2(0.2, 0.45), "radius": float(ctx["target_radius"]) * 0.5})
		VfxLib.flash_star(parent, ctx["dest"], Color(1.0, 0.8, 0.4), 1.2 + float(ctx["target_height"]) * 0.5)
		ball.queue_free())


## A radial burst centred on the target, sized by the target.
static func burst(ctx: Dictionary) -> void:
	var h: float = ctx["target_height"]
	VfxLib.burst(ctx["parent"], ctx["dest"], {"amount": 28, "life": 0.7, "speed": Vector2(1.5, 4.0 + h), "size": Vector2(0.18, 0.4 + h * 0.15),
		"radius": float(ctx["target_radius"]) * 0.6, "ramp": VfxLib.ramp([Color(0.6, 0.9, 1.0, 1.0), Color(0.2, 0.4, 1.0, 0.0)])})
	VfxLib.flash_star(ctx["parent"], ctx["dest"], Color(0.7, 0.9, 1.0), 1.0 + h * 0.6)


## A curved slash mesh across the target, oriented along the attacker-to-target axis.
static func slash(ctx: Dictionary) -> void:
	var h: float = ctx["target_height"]
	VfxLib.mesh_slash(ctx["parent"], ctx["dest"], ctx["dir"], Color(1.0, 0.4, 0.5), 20.0, 0.8 + h * 0.6, 0.5)


## The real Guard shield (FxGuard) on a stand-in character, facing the attacker. mode: "expire" (the 2 s run
## out), "hit" (contact at hit_at) or "broken" (Brick Break at hit_at). The guarding character is the TARGET
## of the layout, so every side and distance is exercised (D-235).
static func guard_fx(ctx: Dictionary, mode: String, hit_at: float) -> void:
	var parent: Node3D = ctx["parent"]
	var fx := BattleFx.new()
	parent.add_child(fx)
	var c := Combatant.new("Guarda", 100, 10, 1.0, false)
	var model := Node3D.new()
	parent.add_child(model)
	model.position = (ctx["target"] as Node3D).position - Vector3(0, float(ctx["target_height"]) * 0.5, 0)
	var body := MeshInstance3D.new()  # Invisible: only gives the shield the character's size.
	var capsule := CapsuleMesh.new()
	capsule.height = float(ctx["target_height"])
	capsule.radius = float(ctx["target_radius"])
	body.mesh = capsule
	body.position.y = capsule.height * 0.5
	body.visible = false
	model.add_child(body)
	var toward: Vector3 = (ctx["attacker"] as Node3D).position
	toward.y = model.position.y
	model.look_at(toward, Vector3.UP, true)  # +Z (the front) toward the opponent.
	fx._models[c] = model
	fx._home_yaw[c] = model.rotation.y
	fx.set_process(false)  # The stand-in has no battle: only the shield is under test.
	var guard := FxGuard.new(fx)
	var driver := PerceptionGuardDriver.new()
	driver.combatant = c
	driver.fx_guard = guard
	driver.end_reason = "hit" if mode == "expire" else mode
	driver.hit_at = -1.0 if mode == "expire" else hit_at
	parent.add_child(driver)
	c.guard_timer = Battle.GUARD_SECONDS
	guard.start(c)


static func guard_expire(ctx: Dictionary) -> void:
	guard_fx(ctx, "expire", -1.0)


static func guard_hit(ctx: Dictionary) -> void:
	guard_fx(ctx, "hit", 0.9)


static func guard_broken(ctx: Dictionary) -> void:
	guard_fx(ctx, "broken", 0.9)
