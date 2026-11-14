class_name FxText
extends RefCounted
## Floating numbers and labels.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func heal_fx(_actor: Combatant, target: Combatant, amount: int, ring := true) -> void:
	# D-348: let the HP/bar update first; the visual gain starts a beat after the real gain.
	await fx.get_tree().create_timer(0.10).timeout
	if not is_instance_valid(fx) or not is_instance_valid(target):
		return
	var home: Vector3 = fx._home[target]
	var green := Color(0.3, 1.0, 0.4)
	if ring:
		fx._ring(home + Vector3(0, 0.05, 0), green, Vector3.ONE * 2.0, Vector3.ONE * 0.5, 0.6)
		fx._burst(home + Vector3(0, 0.3, 0), green, 22, 2.0, Vector3(0, 4, 0), 0.08, 0.9)
	# D-347: the number is HUD above the owner's HP card (spawned by BattleHud); the green crosses
	# stay at the character, rising from its head.
	HealGainFx.spawn(fx, home + Vector3(0, 2.4, 0))


## The damage points, shown the instant the hit lands: a screen-sized number that pops,
## drifts up and fades. `fixed_size` keeps it readable at any camera distance.
func damage_number(pos: Vector3, value: int, crit: bool, weak: bool) -> void:
	var l := Label3D.new()
	l.text = str(value) if not crit else "%d!" % value
	l.font_size = 64
	l.pixel_size = 0.0026 if not crit else 0.0034
	l.fixed_size = true
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 26
	l.render_priority = 20
	l.outline_render_priority = 19
	l.outline_modulate = Color(0.05, 0.03, 0.02, 0.95)
	l.modulate = Color(1.0, 0.9, 0.2) if crit else (Color(1.0, 0.55, 0.2) if weak else Color.WHITE)
	l.position = pos + Vector3(randf_range(-1.4, 1.4), randf_range(-0.2, 0.5), 0.0)
	l.scale = Vector3.ONE * 0.4
	fx.add_child(l)
	var tw := fx.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.35, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector3.ONE, 0.1)
	var rise := fx.create_tween().set_parallel(true)
	rise.tween_property(l, "position:y", pos.y + 0.9, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.75)
	rise.tween_property(l, "outline_modulate:a", 0.0, 0.3).set_delay(0.75)
	rise.chain().tween_callback(l.queue_free)


func float_text(pos: Vector3, text: String, color: Color, size := 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.font_size = size
	l.pixel_size = 0.01
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	fx.add_child(l)
	var tw := fx.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.5, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
	return l
