class_name MotionLayer
extends RefCounted
## Uma camada ordenada da composição (D-043, §19.3). Reordenar altera a sequência de avaliação e
## preserva o `id`.

var id: StringName = &""
var behavior_id: StringName = &""
var enabled: bool = true
var op: int = MotionTypes.Op.REPLACE
## Ramos que a camada afeta (prefixo de caminho; vazio = todos).
var branches: PackedStringArray = PackedStringArray()
var space: int = MotionTypes.Space.LOCAL
var params: Dictionary = {}
var mask: MotionMask = MotionMask.new()
## Intensidade de aplicação, 0..1. 0 = neutro (preserva a entrada).
var intensity: float = 1.0
## Defasagem: o relógio local da camada é (tempo - time_offset); antes de começar a camada fica inativa.
var time_offset: float = 0.0
## Janela de atividade no relógio local. active_to < 0 = sem fim.
var active_from: float = 0.0
var active_to: float = -1.0


func local_time(ctx: MotionContext) -> float:
	return ctx.time - time_offset


func is_active(ctx: MotionContext) -> bool:
	if not enabled:
		return false
	var lt := local_time(ctx)
	if lt < active_from:
		return false
	return active_to < 0.0 or lt <= active_to


func selects(branch: String) -> bool:
	if branches.is_empty():
		return true
	for b in branches:
		if branch == b or branch.begins_with(b + "/"):
			return true
	return false
