class_name FxProjectiles
extends RefCounted
## Projectiles and their trails.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## The projectile leaves when Battle enters the TRAVEL phase; it ends on the target, or
## sails past it if the attack was dodged. Its position is drawn from the phase progress.
func spawn(inc) -> void:
	var from: Vector3 = fx.rest_pos(inc.attacker) + Vector3(0, 1, 0)
	var to: Vector3 = fx.rest_pos(inc.target) + Vector3(0, 1, 0)
	var missed: bool = inc.dodged or inc.auto_dodged or inc.void_miss
	var end := to + fx._flat_dir(from, to) * 7.0 if missed else to
	var node := _make_projectile(from, end, fx.COLORS[inc.element], inc.element)
	inc.data["proj"] = {"node": node, "from": from, "to": end}


func drive(inc) -> void:
	var p: Dictionary = inc.data.get("proj", {})
	if p.is_empty() or inc.phase != Battle.Phase.TRAVEL or not is_instance_valid(p["node"]):
		return
	(p["node"] as Node3D).position = (p["from"] as Vector3).lerp(p["to"], inc.progress())


func finish(inc) -> void:
	var p: Dictionary = inc.data.get("proj", {})
	if not p.is_empty() and is_instance_valid(p["node"]):
		(p["node"] as Node3D).queue_free()
	inc.data.erase("proj")


## A glowing orb (or an ice shard) flying from `from` to `to`, with a 3D twisted
## ribbon wake (`ribbon_trail.glb`) and particle trail.
func _make_projectile(from: Vector3, to: Vector3, color: Color, element: Element.Type) -> Node3D:
	var node := Node3D.new()
	node.position = from
	fx.add_child(node)
	node.look_at_from_position(from, to)
	if element == Element.Type.AGUA_GELO:
		var shard := fx._node(fx._box(Vector3(0.28, 0.28, 1.3)), Color(0.7, 0.95, 1.0, 0.95), Vector3.ZERO)
		shard.material_override.emission_enabled = true
		shard.material_override.emission = Color(0.4, 0.85, 1.0)
		shard.material_override.emission_energy_multiplier = 2.5
		fx.remove_child(shard)
		node.add_child(shard)
	else:
		for layer in [[2.2, color, 0.9], [1.0, Color(1, 1, 1), 1.0]]:
			var quad := QuadMesh.new()
			quad.size = Vector2.ONE * layer[0]
			var mat := VfxLib.particle_mat(VfxLib.glow_tex(), true)
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat.vertex_color_use_as_albedo = false
			mat.albedo_color = Color(layer[1].r * 1.5, layer[1].g * 1.5, layer[1].b * 1.5, layer[2])
			quad.material = mat
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			node.add_child(mi)
	# Attach 3D twisted ribbon wake (`ribbon_trail.glb`)
	var rib_mesh := VfxLib.vfx_mesh("ribbon_trail")
	if rib_mesh != null:
		var rib := MeshInstance3D.new()
		rib.mesh = rib_mesh
		rib.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rib_mat := VfxLib.shader_mat("mesh_slash", {
			"trail_tex": VfxLib.slash_trail_tex(),
			"color": color,
			"core_color": Color(1.0, 0.98, 0.92, 1.0),
			"energy": 3.0,
			"progress": 0.45,
		})
		rib.material_override = rib_mat
		rib.position = Vector3(0, 0, 1.8)
		node.add_child(rib)
	var trail_ramp := VfxLib.ramp([Color(1, 1, 1, 0.9), color, Color(color, 0)], [0.0, 0.3, 1.0])
	if element == Element.Type.FOGO:
		trail_ramp = VfxLib.ramp([Color(1, 0.9, 0.5, 0.9), Color(1, 0.45, 0.1, 0.8), Color(0.2, 0.08, 0.05, 0)], [0.0, 0.35, 1.0])
	VfxLib.trail(node, {"tex": VfxLib.smoke_tex() if element == Element.Type.FOGO else VfxLib.glow_tex(), "amount": 40, "life": 0.45,
		"speed": Vector2(0.2, 1.2), "size": Vector2(0.8, 1.4), "end_scale": 0.0, "radius": 0.15, "ramp": trail_ramp})
	return node


# --- Dodge visuals -------------------------------------------------------------------


func _has_projectile(element: Element.Type) -> bool:
	return not (element in [Element.Type.FISICO, Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA])
