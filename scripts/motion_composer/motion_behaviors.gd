class_name MotionBehaviors
extends RefCounted
## Registro dos comportamentos implementados da V1. Etapa 2: M01–M13 (D-172).


static func all() -> Array[MotionBehavior]:
	return [
		MotionM01Helix.new(), MotionM02Zigzag.new(), MotionM03Serpentine.new(), MotionM04Bezier.new(),
		MotionM05Vortex.new(), MotionM06Convergence.new(), MotionM07Turbulence.new(),
		MotionM08Twist.new(), MotionM09Bend.new(), MotionM10Stretch.new(), MotionM11Compression.new(),
		MotionM12TravelingPulse.new(), MotionM13RadialWave.new(),
	]


static func register_all(catalog: MotionCatalog) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	for b in all():
		out.append_array(catalog.register(b))
	return out
