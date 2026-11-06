class_name MotionBehaviors
extends RefCounted
## Registro dos comportamentos implementados da V1. Etapa 2: M01–M13 (D-231). Etapa 2b: M16–M18 (D-232).


static func all() -> Array[MotionBehavior]:
	return [
		MotionM01Helix.new(), MotionM02Zigzag.new(), MotionM03Serpentine.new(), MotionM04Bezier.new(),
		MotionM05Vortex.new(), MotionM06Convergence.new(), MotionM07Turbulence.new(),
		MotionM08Twist.new(), MotionM09Bend.new(), MotionM10Stretch.new(), MotionM11Compression.new(),
		MotionM12TravelingPulse.new(), MotionM13RadialWave.new(),
		MotionM14Bifurcation.new(), MotionM15Recombination.new(),
		MotionM16DirectionalBurst.new(), MotionM17ProgressiveGrowth.new(), MotionM18ProgressiveDissolve.new(),
	]


static func register_all(catalog: MotionCatalog) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	for b in all():
		out.append_array(catalog.register(b))
	return out


## V1.2 (D-323) e V1.8 (D-337): campos e geradores acrescentados depois da V1 fechada (M01-M20 intactos). Não entram em `V1_IDS`.
static func v12() -> Array[MotionBehavior]:
	return [MotionM21Flow.new(), MotionM22Drag.new(), MotionM23Gravity.new(), MotionM24CurlNoise.new(), MotionM25Repulsion.new(), MotionM26AtelierEmitter.new()]


static func register_v12(catalog: MotionCatalog) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	for b in v12():
		out.append_array(catalog.register(b))
	return out
