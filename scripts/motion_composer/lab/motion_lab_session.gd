class_name MotionLabSession
extends RefCounted
## Estado do laboratório sem interface: composição, catálogo, relógio, modo de edição (D-042), emissor de
## demonstração e isolamento de uma camada. A interface só lê e comanda esta classe, que é testável sem tela.

## D-042: o que fazer quando um parâmetro é editado durante a reprodução.
enum EditMode { UPDATE_NOW, RESTART }
## Emissor de demonstração para inspecionar world_space (rastros que preservam a história do emissor).
enum Emitter { STATIC, LINE, ORBIT }

var catalog: MotionCatalog = MotionCatalog.new()
var composition: MotionComposition = MotionComposition.new()
var clock: MotionClock = MotionClock.new()
## Proposta inicial (não persistida entre sessões): atualizar no instante atual.
var edit_mode: int = EditMode.UPDATE_NOW
var emitter_mode: int = Emitter.STATIC
## Se não vazio, avalia só esta camada (e as anteriores de que ela depende ficam desligadas).
var solo_layer: StringName = &""
var last_result: MotionResult = null


func _init() -> void:
	MotionBehaviors.register_all(catalog)
	composition.id = &"lab"
	composition.sample_count = 64
	composition.duration = 3.0
	clock.duration = composition.duration


static func emitter_transform(mode: int, t: float) -> Transform3D:
	match mode:
		Emitter.LINE:
			return Transform3D(Basis.IDENTITY, Vector3(1.5 * t, 0.0, 0.0))
		Emitter.ORBIT:
			var a := TAU * 0.25 * t
			return Transform3D(Basis(Vector3.BACK, a), Vector3(cos(a), sin(a), 0.0) * 1.2)
	return Transform3D.IDENTITY


## Toda edição de parâmetro/camada passa por aqui. Modo "reiniciar" volta ao nascimento;
## "atualizar" mantém o instante e reconstrói rastros pela avaliação direta (sem misturar revisões).
func notify_edited() -> void:
	clock.duration = composition.duration
	if edit_mode == EditMode.RESTART:
		clock.restart()


func set_solo(layer_id: StringName) -> void:
	solo_layer = layer_id


## Composição efetivamente avaliada (com isolamento aplicado, sem alterar a original).
func effective_composition() -> MotionComposition:
	if solo_layer == &"" or composition.find_layer(solo_layer) == null:
		return composition
	var c := MotionComposition.new()
	c.id = composition.id
	c.base_length = composition.base_length
	c.sample_count = composition.sample_count
	c.duration = composition.duration
	c.seed = composition.seed
	c.max_samples = composition.max_samples
	c.revision = composition.revision
	var only: Array[MotionLayer] = []
	for l in composition.layers:
		if l.id == solo_layer:
			only.append(l)
	c.layers = only
	return c


func evaluate() -> MotionResult:
	var c := effective_composition()
	c.history_start = clock.history_start()
	var ctx := c.make_context(clock.time)
	var mode := emitter_mode
	ctx.emitter_fn = func(t: float) -> Transform3D: return MotionLabSession.emitter_transform(mode, t)
	last_result = c.evaluate(catalog, ctx)
	return last_result
