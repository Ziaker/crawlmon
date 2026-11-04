class_name MotionM17ProgressiveGrowth
extends MotionBehavior
## M17 Crescimento progressivo — revela o movimento gradualmente: a região ativa avança ao longo de `u`.
## Atua sobre os canais escolhidos (visibilidade, espessura, intensidade, opacidade); não exige um único método de render.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M17"
	display_name = "Crescimento progressivo"
	description = "Revela gradualmente um movimento, aumentando o trecho visível ou a região ativa ao longo do tempo."
	group = &"nascimento_dissipacao"
	kind = MotionTypes.Kind.ENVELOPE
	accepted_operations = [Op.MASK, Op.MULTIPLY_ATTRIBUTE]
	params = MotionProfile.envelope_params()


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	return MotionProfile.envelope_apply(samples, p, ctx, lt, false)
