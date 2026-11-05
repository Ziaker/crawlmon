class_name MotionSpace
extends RefCounted
## Espaços de coordenadas (§5.3). `frame` devolve a transformação ESPAÇO DA CAMADA -> ESPAÇO LOCAL DO EFEITO.
## Uma camada vê as amostras em seu espaço, aplica o comportamento e o resultado volta ao espaço local.


static func frame(kind: int, ctx: MotionContext, s: MotionSample) -> Transform3D:
	match kind:
		MotionTypes.Space.GLOBAL:
			return ctx.reference_transform.affine_inverse()
		MotionTypes.Space.EMITTER:
			return ctx.reference_transform.affine_inverse() * ctx.emitter_at(ctx.time)
		MotionTypes.Space.TRAJECTORY:
			return Transform3D(s.basis, s.position)
	return Transform3D.IDENTITY


## Amostra (espaço local) -> espaço da camada.
static func to_space(s: MotionSample, f: Transform3D) -> MotionSample:
	var c := s.duplicate_sample()
	var inv := f.affine_inverse()
	c.position = inv * s.position
	c.basis = inv.basis * s.basis
	return c


## Amostra (espaço da camada) -> espaço local.
static func from_space(s: MotionSample, f: Transform3D) -> MotionSample:
	var c := s.duplicate_sample()
	c.position = f * s.position
	c.basis = f.basis * s.basis
	return c
