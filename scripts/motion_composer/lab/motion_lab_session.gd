class_name MotionLabSession
extends RefCounted
## Estado do laboratório sem interface: composição, catálogo, relógio, modo de edição (D-042), emissor de
## demonstração e isolamento de uma camada. A interface só lê e comanda esta classe, que é testável sem tela.

## D-042: o que fazer quando um parâmetro é editado durante a reprodução.
enum EditMode { UPDATE_NOW, RESTART }
## Emissor de demonstração para inspecionar world_space (rastros que preservam a história do emissor).
enum Emitter { STATIC, LINE, ORBIT, RUN }
## Comparação A/B (§10.4): antes × depois de editar (A = instantâneo imutável), camada isolada × composição
## inteira, e representação neutra × a escolhida (mesmos dados, só o desenho muda).
enum AbMode { OFF, BEFORE_AFTER, ISOLATED, NEUTRAL }

var catalog: MotionCatalog = MotionCatalog.new()
var composition: MotionComposition = MotionComposition.new()
var clock: MotionClock = MotionClock.new()
## Proposta inicial (não persistida entre sessões): atualizar no instante atual.
var edit_mode: int = EditMode.UPDATE_NOW
var emitter_mode: int = Emitter.STATIC
## Se não vazio, avalia só esta camada (e as anteriores de que ela depende ficam desligadas).
var solo_layer: StringName = &""
var last_result: MotionResult = null
var ab_mode: int = AbMode.OFF
## Camada comparada no modo "isolada × combinada".
var ab_layer: StringName = &""
## Instantâneo A: cópia independente (ida e volta pelo formato de presets), com a revisão do momento em que foi
## fixado. Nada que se faça na composição viva o altera.
var snapshot_a: MotionComposition = null


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
		Emitter.RUN:
			return Transform3D(Basis.IDENTITY, Vector3(8.0 * t, 0.0, 0.0))
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


## Cópia só com a camada `layer_id` (as demais ficam de fora), sem alterar a original.
func _only_layer(src: MotionComposition, layer_id: StringName) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = src.id
	c.base_length = src.base_length
	c.sample_count = src.sample_count
	c.duration = src.duration
	c.seed = src.seed
	c.max_samples = src.max_samples
	c.revision = src.revision
	var only: Array[MotionLayer] = []
	for l in src.layers:
		if l.id == layer_id:
			only.append(l)
	c.layers = only
	return c


## Composição efetivamente avaliada (com isolamento aplicado, sem alterar a original).
func effective_composition() -> MotionComposition:
	if solo_layer == &"" or composition.find_layer(solo_layer) == null:
		return composition
	return _only_layer(composition, solo_layer)


## Avalia `c` no instante do relógio, com o emissor e a janela de histórico da sessão.
func _evaluate(c: MotionComposition) -> MotionResult:
	c.history_start = clock.history_start()
	var ctx := c.make_context(clock.time)
	var mode := emitter_mode
	ctx.emitter_fn = func(t: float) -> Transform3D: return MotionLabSession.emitter_transform(mode, t)
	return c.evaluate(catalog, ctx)


func evaluate() -> MotionResult:
	last_result = _evaluate(effective_composition())
	return last_result


## Fixa A: copia a composição viva pelo formato de presets (cópia profunda e validada). Devolve diagnósticos.
func capture_a() -> Array[MotionDiagnostic]:
	var r := MotionPresets.from_dict(MotionPresets.to_dict(composition, catalog), catalog)
	if r["composition"] == null:
		return r["diagnostics"]
	snapshot_a = r["composition"]
	snapshot_a.revision = composition.revision
	var none: Array[MotionDiagnostic] = []
	return none


func clear_a() -> void:
	snapshot_a = null


func evaluate_snapshot() -> MotionResult:
	return null if snapshot_a == null else _evaluate(snapshot_a)


## {"a": MotionResult|null, "b": MotionResult, "diff": Dictionary, "error": String}. B é sempre a composição viva
## (com o isolamento da sessão, se houver); A depende do modo. Mesmo tempo, mesmo emissor, semente de cada lado.
func evaluate_ab() -> Dictionary:
	var out := {"a": null, "b": evaluate(), "diff": {}, "error": ""}
	match ab_mode:
		AbMode.BEFORE_AFTER:
			if snapshot_a == null:
				out["error"] = "Fixe A primeiro (botão \"Fixar A agora\")."
			else:
				out["a"] = evaluate_snapshot()
		AbMode.ISOLATED:
			if composition.find_layer(ab_layer) == null:
				out["error"] = "Escolha uma camada existente para isolar."
			else:
				out["a"] = _evaluate(_only_layer(composition, ab_layer))
		AbMode.NEUTRAL:
			out["a"] = out["b"]
	if out["a"] != null:
		out["diff"] = diff(out["a"], out["b"])
	return out


## Compara dois resultados elemento a elemento (pelo id): quantos coincidem, quantos mudaram e o quanto.
static func diff(a: MotionResult, b: MotionResult) -> Dictionary:
	var out := {"matched": 0, "only_a": 0, "only_b": 0, "changed": 0, "max_distance": 0.0, "mean_distance": 0.0, "max_attribute": 0.0}
	if b == null:
		return out
	if a == null:
		out["only_b"] = b.samples.size()
		return out
	var by_id := {}
	for s in a.samples:
		by_id[s.element_id] = s
	var total := 0.0
	for s in b.samples:
		if not by_id.has(s.element_id):
			out["only_b"] += 1
			continue
		var o: MotionSample = by_id[s.element_id]
		out["matched"] += 1
		var d := o.position.distance_to(s.position)
		total += d
		out["max_distance"] = maxf(out["max_distance"], d)
		var attr := maxf(maxf(absf(o.width - s.width), absf(o.opacity - s.opacity)), absf(o.intensity - s.intensity))
		if o.visible != s.visible:
			attr = 1.0
		out["max_attribute"] = maxf(out["max_attribute"], attr)
		if d > 1e-6 or attr > 1e-6:
			out["changed"] += 1
	out["only_a"] = a.samples.size() - out["matched"]
	if out["matched"] > 0:
		out["mean_distance"] = total / float(out["matched"])
	return out
