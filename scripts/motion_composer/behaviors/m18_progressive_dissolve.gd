class_name MotionM18ProgressiveDissolve
extends MotionBehavior
## M18 Dissolução progressiva — remove gradualmente regiões do efeito, com progressão espacial e temporal.
## Complementar de M17: com os mesmos parâmetros, crescimento + dissolução = 1 em cada canal.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M18"
	display_name = "Dissolução progressiva"
	description = "Remove gradualmente regiões do efeito, com progressão espacial e temporal."
	group = &"nascimento_dissipacao"
	kind = MotionTypes.Kind.ENVELOPE
	accepted_operations = [Op.MASK, Op.MULTIPLY_ATTRIBUTE]
	params = MotionProfile.envelope_params()


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	return MotionProfile.envelope_apply(samples, p, ctx, lt, true)
