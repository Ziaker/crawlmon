class_name MotionHistory
extends RefCounted
## Auxiliares de M19 e M20 (Etapa 4, D-304). O histórico NUNCA vem de quadros já desenhados: é o fluxo
## produzido pelas camadas anteriores, reavaliado pela função de tempo em instantes passados
## (`MotionContext.history_fn`), e o emissor vem de `emitter_at(t)`. Resultado: determinístico em
## seek, retrocesso e reinício (§9.3).

## Máximo de amostras de rastro por elemento (proposta do agente).
const MAX_TRAIL_SAMPLES := 256


## Fluxo anterior no instante `t`, indexado por element_id. Vazio se não houver histórico.
static func stream_at(ctx: MotionContext, t: float) -> Dictionary:
	var out := {}
	if not ctx.history_fn.is_valid():
		return out
	var arr: Array = ctx.history_fn.call(t)
	for s in arr:
		out[(s as MotionSample).element_id] = s
	return out


## Estado histórico `hs` no instante `t_past`, posto no referencial local do instante atual.
## world_space=false: o rastro acompanha o emissor (coordenadas locais do instante passado).
## world_space=true: fica no mundo, E(t)⁻¹·E(t_past)·p (a história do emissor é preservada).
static func place(hs: MotionSample, ctx: MotionContext, t_past: float, world_space: bool) -> MotionSample:
	var c := hs.duplicate_sample()
	if world_space:
		var rel := ctx.emitter_at(ctx.time).affine_inverse() * ctx.emitter_at(t_past)
		c.position = rel * hs.position
		c.basis = rel.basis * hs.basis
	return c


## Cópia invisível (antes do nascimento ou sem histórico): mantém contagem e ids estáveis.
static func hidden_copy(s: MotionSample) -> MotionSample:
	var c := s.duplicate_sample()
	c.visible = false
	c.opacity = 0.0
	return c
