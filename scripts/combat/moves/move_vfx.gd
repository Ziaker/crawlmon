class_name MoveVfx
extends RefCounted
## Base opcional de VFX autoral por Move (D-1079/D-308). O script só desenha:
## as decisões, as fases e o relógio continuam no Battle/BattleFx
## (D-019/D-1040). Nenhum hook pode criar Timer/Tween com tempo próprio.

var fx: BattleFx = null
var data: MoveData = null


func setup(p_fx: BattleFx, p_data: MoveData) -> void:
	fx = p_fx
	data = p_data


func windup(_inc: Incoming, _from: Vector3, _to: Vector3, _duration: float) -> Node3D:
	return null


func travel(_inc: Incoming, _from: Vector3, _to: Vector3) -> Node3D:
	return null


func tick(_inc: Incoming, _delta: float) -> void:
	pass


func impact(_inc: Incoming, _pos: Vector3, _big: bool, _dir: Vector3) -> Array[Node3D]:
	var empty: Array[Node3D] = []
	return empty


func finish(_inc: Incoming) -> void:
	pass


func cleanup() -> void:
	pass
