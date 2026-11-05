class_name MotionHistory
extends RefCounted
## Auxiliares de M19 e M20 (Etapa 4, D-304). O histórico NUNCA vem de quadros já desenhados: é o fluxo
## produzido pelas camadas anteriores, reavaliado pela função de tempo em instantes passados
## (`MotionContext.history_fn`), e o emissor vem de `emitter_at(t)`. Resultado: determinístico em
## seek, retrocesso e reinício (§9.3).


## Fluxo anterior no instante `t`, indexado por element_id. Vazio se `t` é anterior ao início do
## histórico (`ctx.history_start`: 0 por padrão; o laboratório o move ao repetir um trecho, para que a
## cauda não se conecte ao ciclo anterior, §19.4) ou se não há histórico disponível.
static func stream_at(ctx: MotionContext, t: float) -> Dictionary:
	var out := {}
	if t < ctx.history_start or not ctx.history_fn.is_valid():
		return out
	var arr: Array = ctx.history_fn.call(t)
	for s in arr:
		out[(s as MotionSample).element_id] = s
	return out


## Transformação que leva o estado local do instante `t_past` ao referencial local do instante atual.
## world_space=false: identidade (o efeito acompanha o emissor).
## world_space=true: E(t)⁻¹·E(t_past), preservando a história de posição e direção do emissor.
static func relative(ctx: MotionContext, t_past: float, world_space: bool) -> Transform3D:
	if not world_space:
		return Transform3D.IDENTITY
	return ctx.emitter_at(ctx.time).affine_inverse() * ctx.emitter_at(t_past)


## Estado histórico `hs` posto no referencial local atual.
static func place(hs: MotionSample, rel: Transform3D, world_space: bool) -> MotionSample:
	var c := hs.duplicate_sample()
	if world_space:
		c.position = rel * hs.position
		c.basis = rel.basis * hs.basis
	return c


## Cópia invisível (antes do nascimento ou sem histórico): mantém contagem e ids estáveis.
static func hidden_copy(s: MotionSample) -> MotionSample:
	var c := s.duplicate_sample()
	c.visible = false
	c.opacity = 0.0
	return c
