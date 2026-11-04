class_name MotionContext
extends RefCounted
## Contexto de avaliação (§4.2). O tempo vem de fora (laboratório ou, no futuro, o motor — D-019);
## nenhum comportamento lê relógio próprio, TIME ou Engine.time_scale.

## Tempo da instância, em segundos.
var time: float = 0.0
## Duração conhecida, em segundos (finita e positiva). Tempo e progresso são conceitos distintos.
var duration: float = 1.0
var seed: int = 0
## Revisão dos parâmetros que gerou este contexto; resultados de revisões diferentes não se misturam.
var revision: int = 0
## Transformação de referência: espaço local do efeito -> espaço global do laboratório/cena.
var reference_transform: Transform3D = Transform3D.IDENTITY
## Pose do emissor em função do tempo (float -> Transform3D), em espaço global. Vale para instantes passados.
var emitter_fn: Callable = Callable()
var origin: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
## Fluxo produzido pelas camadas ANTERIORES em um instante qualquer (float -> Array[MotionSample]).
## Preenchida pelo compositor só ao avaliar camadas PERSIST (M19, M20); é função pura do tempo, logo
## o histórico se reconstrói igual após seek, retrocesso ou reinício. `with_time` não a copia.
var history_fn: Callable = Callable()


## Progresso normalizado em [0, 1] = tempo / duração (saturado).
func progress() -> float:
	if not is_finite(duration) or duration <= 0.0:
		return 0.0
	return clampf(time / duration, 0.0, 1.0)


func emitter_at(t: float) -> Transform3D:
	if emitter_fn.is_valid():
		return emitter_fn.call(t)
	return Transform3D.IDENTITY


func with_time(t: float) -> MotionContext:
	var c := MotionContext.new()
	c.time = t
	c.duration = duration
	c.seed = seed
	c.revision = revision
	c.reference_transform = reference_transform
	c.emitter_fn = emitter_fn
	c.origin = origin
	c.target = target
	return c


func validate() -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	if not is_finite(duration) or duration <= 0.0:
		out.append(MotionDiagnostic.error(&"ctx_duration", "duração deve ser finita e positiva (recebido %s)" % duration))
	if not is_finite(time):
		out.append(MotionDiagnostic.error(&"ctx_time", "tempo não finito"))
	return out
