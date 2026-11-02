class_name FxText
extends RefCounted
## Floating numbers and labels.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func heal_fx(_actor: Combatant, target: Combatant, amount: int) -> void:
	var home: Vector3 = fx._home[target]
	var green := Color(0.3, 1.0, 0.4)
	fx._ring(home + Vector3(0, 0.05, 0), green, Vector3.ONE * 2.0, Vector3.ONE * 0.5, 0.6)
	fx._burst(home + Vector3(0, 0.3, 0), green, 22, 2.0, Vector3(0, 4, 0), 0.08, 0.9)
	float_text(home + Vector3(0, 2.4, 0), "+%d" % amount, green, 64)


func float_text(pos: Vector3, text: String, color: Color, size := 48) -> void:
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
