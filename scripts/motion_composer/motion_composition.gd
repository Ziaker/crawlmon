class_name MotionComposition
extends RefCounted
## Composição: sequência ordenada de camadas (D-043, §5, §19.3). Avaliação sem estado e determinística:
## resultado = f(dados da composição, contexto). Nenhum Node, relógio, TIME ou aleatoriedade externa.

const Op := MotionTypes.Op
const Kind := MotionTypes.Kind
const Space := MotionTypes.Space

var id: StringName = &""
## Comprimento da trajetória de repouso ao longo de +Z (valor experimental, não aprovado).
var base_length: float = 1.0
var sample_count: int = 128
var duration: float = 3.0
var seed: int = 0
## Início da janela de histórico (ver MotionContext.history_start).
var history_start: float = 0.0
## Limite de amostras ativas; verificado ANTES de alocar (valor experimental, não aprovado).
var max_samples: int = 100000
var layers: Array[MotionLayer] = []
## Incrementa a cada edição. Resultados de revisões diferentes nunca se misturam (§9.4).
var revision: int = 0


# ------------------------------------------------------------------ edição
func touch() -> void:
	revision += 1


func find_layer(layer_id: StringName) -> MotionLayer:
	for l in layers:
		if l.id == layer_id:
			return l
	return null


func layer_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for l in layers:
		out.append(l.id)
	return out


func add_layer(l: MotionLayer, index: int = -1) -> bool:
	if find_layer(l.id) != null:
		return false
	if index < 0 or index >= layers.size():
		layers.append(l)
	else:
		layers.insert(index, l)
	touch()
	return true


func remove_layer(layer_id: StringName) -> bool:
	var l := find_layer(layer_id)
	if l == null:
		return false
	layers.erase(l)
	touch()
	return true


func move_layer(layer_id: StringName, to_index: int) -> bool:
	var l := find_layer(layer_id)
	if l == null:
		return false
	layers.erase(l)
	layers.insert(clampi(to_index, 0, layers.size()), l)
	touch()
	return true


func set_param(layer_id: StringName, param_name: StringName, value: Variant) -> bool:
	var l := find_layer(layer_id)
	if l == null:
		return false
	l.params[String(param_name)] = value
	touch()
	return true


func set_enabled(layer_id: StringName, value: bool) -> bool:
	var l := find_layer(layer_id)
	if l == null:
		return false
	l.enabled = value
	touch()
	return true


func make_context(t: float) -> MotionContext:
	var c := MotionContext.new()
	c.time = t
	c.duration = duration
	c.seed = seed
	c.revision = revision
	c.history_start = history_start
	return c


# ------------------------------------------------------------------ validação
func validate(catalog: MotionCatalog) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	if not is_finite(duration) or duration <= 0.0:
		out.append(MotionDiagnostic.error(&"comp_duration", "duração deve ser finita e positiva"))
	if sample_count < 2 or sample_count > max_samples:
		out.append(MotionDiagnostic.error(&"comp_sample_count", "sample_count deve estar em [2, max_samples]"))
	if not is_finite(base_length) or base_length <= 0.0:
		out.append(MotionDiagnostic.error(&"comp_base_length", "base_length deve ser finito e positivo"))

	var seen := {}
	for l in layers:
		if l.id == &"" or seen.has(l.id):
			out.append(MotionDiagnostic.error(&"layer_id_duplicate", "id de camada vazio ou duplicado: '%s'" % l.id, l.id))
		seen[l.id] = true
		out.append_array(l.mask.validate(l.id))
		if not is_finite(l.intensity) or l.intensity < 0.0 or l.intensity > 1.0:
			out.append(MotionDiagnostic.error(&"layer_intensity", "intensidade deve estar em [0, 1]", l.id))
		if not is_finite(l.time_offset) or not is_finite(l.active_from) or not is_finite(l.active_to):
			out.append(MotionDiagnostic.error(&"layer_time", "tempos da camada devem ser finitos", l.id))

		var b := catalog.get_behavior(l.behavior_id)
		if b == null:
			out.append(MotionDiagnostic.error(&"layer_behavior_unknown", "comportamento desconhecido: '%s'" % l.behavior_id, l.id))
			continue
		out.append_array(b.validate_params(l.params, l.id))
		if not (l.op in b.accepted_operations):
			out.append(MotionDiagnostic.error(&"layer_op_not_accepted",
				"%s não aceita a operação %s" % [b.id, Op.keys()[l.op]], l.id))
		if (l.op == Op.BRANCH or l.op == Op.MERGE) and b.kind != Kind.TOPOLOGY:
			out.append(MotionDiagnostic.error(&"layer_op_kind", "BRANCH/MERGE exigem comportamento TOPOLOGY", l.id))
		if l.op == Op.PERSIST and b.kind != Kind.HISTORICAL:
			out.append(MotionDiagnostic.error(&"layer_op_kind", "PERSIST exige comportamento HISTORICAL", l.id))
		if l.space == Space.TRAJECTORY and (l.op == Op.BRANCH or l.op == Op.MERGE or l.op == Op.PERSIST):
			out.append(MotionDiagnostic.error(&"layer_space_topology",
				"topologia/persistência não pode usar o espaço de trajetória (referencial por amostra)", l.id))
	return out


# ------------------------------------------------------------------ avaliação
func evaluate(catalog: MotionCatalog, ctx: MotionContext) -> MotionResult:
	var res := MotionResult.new()
	res.revision = revision
	res.time = ctx.time
	res.diagnostics.append_array(ctx.validate())
	res.diagnostics.append_array(validate(catalog))
	if res.has_errors():
		return res  # sem correção silenciosa: erros e nenhuma amostra

	var t0 := Time.get_ticks_usec()
	res.samples = _run_layers(layers.size(), catalog, ctx, res.diagnostics)
	var hist := 0
	for s in res.samples:
		if s.age > 0.0:
			hist += 1
	var active := 0
	for l in layers:
		if l.is_active(ctx) and l.intensity > 0.0:
			active += 1
	res.stats = {"samples": res.samples.size(), "history_samples": hist, "layers_active": active, "eval_usec": Time.get_ticks_usec() - t0}
	return res


## Avalia as primeiras `count` camadas. Camadas PERSIST recebem `history_fn`: o fluxo das camadas
## anteriores em qualquer instante, reavaliado do zero (sem estado, sem depender de quadros anteriores).
func _run_layers(count: int, catalog: MotionCatalog, ctx: MotionContext, diags: Array[MotionDiagnostic]) -> Array[MotionSample]:
	var samples := _rest_samples()
	for idx in count:
		var l := layers[idx]
		if not l.is_active(ctx) or l.intensity <= 0.0:
			continue
		var lctx := ctx
		if l.op == Op.PERSIST:
			var pb := catalog.get_behavior(l.behavior_id)
			if pb.needs_history and bool(pb.resolve_params(l.params).get("world_space", false)) and not ctx.emitter_fn.is_valid():
				diags.append(MotionDiagnostic.warning(&"layer_emitter_history_missing",
					"world_space pede a história do emissor, mas o contexto não a fornece (emitter_fn); o rastro usa o emissor parado, sem inventar movimento", l.id))
			lctx = ctx.with_time(ctx.time)
			lctx.history_fn = func(t: float) -> Array[MotionSample]:
				var scratch: Array[MotionDiagnostic] = []
				return _run_layers(idx, catalog, ctx.with_time(t), scratch)
		var next: Variant = _apply_layer(l, catalog.get_behavior(l.behavior_id), samples, lctx, diags)
		if next != null:
			samples = next
	return samples


func _rest_samples() -> Array[MotionSample]:
	var out: Array[MotionSample] = []
	var last := float(sample_count - 1)
	for i in sample_count:
		out.append(MotionSample.make_rest(float(i) / last, i, base_length))
	return out


## Devolve as novas amostras ou null (camada ignorada; um diagnóstico explica quando é erro).
func _apply_layer(l: MotionLayer, b: MotionBehavior, samples: Array[MotionSample], ctx: MotionContext, diags: Array[MotionDiagnostic]) -> Variant:
	var lt := l.local_time(ctx)
	var p := b.resolve_params(l.params)

	var sel: Array[int] = []
	var is_sel := PackedByteArray()
	is_sel.resize(samples.size())
	for i in samples.size():
		if l.selects(samples[i].branch):
			sel.append(i)
			is_sel[i] = 1
	if sel.is_empty():
		diags.append(MotionDiagnostic.error(&"layer_branch_missing",
			"nenhum ramo corresponde à seleção %s" % [l.branches], l.id))
		return null

	var topo := l.op == Op.BRANCH or l.op == Op.MERGE
	var persist := l.op == Op.PERSIST
	var n_out := b.output_count(sel.size(), p)
	var projected := samples.size()
	if topo:
		projected = samples.size() - sel.size() + n_out
	elif persist:
		projected = samples.size() + n_out
	if projected > max_samples:
		diags.append(MotionDiagnostic.error(&"layer_sample_limit",
			"a camada produziria %d amostras (limite %d)" % [projected, max_samples], l.id))
		return null

	# O comportamento sempre recebe CÓPIAS: se violar o contrato e alterar a entrada, o fluxo anterior
	# continua íntegro e a camada pode ser descartada sem contaminar o resultado. No espaço LOCAL
	# (identidade) só é preciso copiar, sem a conversão de ida e volta.
	var local_space := l.space == Space.LOCAL
	var frames: Array[Transform3D] = []
	var subset: Array[MotionSample] = []
	for i in sel:
		if local_space:
			frames.append(Transform3D.IDENTITY)
			subset.append(samples[i].duplicate_sample())
		else:
			var f := MotionSpace.frame(l.space, ctx, samples[i])
			frames.append(f)
			subset.append(MotionSpace.to_space(samples[i], f))

	var out := b.apply(subset, p, ctx, lt, l.id)

	var result: Array[MotionSample] = []
	if topo or persist:
		if out.size() != n_out:
			diags.append(MotionDiagnostic.error(&"layer_count_mismatch",
				"%s devolveu %d amostras, declarou %d" % [b.id, out.size(), n_out], l.id))
			return null
		var conv: Array[MotionSample] = []
		for o in out:
			var c := o if local_space else MotionSpace.from_space(o, frames[0])
			if persist:
				c.opacity *= l.intensity
			conv.append(c)
		if persist:
			result.append_array(samples)
			result.append_array(conv)
		else:
			var inserted := false
			if n_out == sel.size():
				# mesma contagem: substitui no lugar, preservando a ordem (D-303)
				result = samples.duplicate()
				for j in sel.size():
					result[sel[j]] = conv[j]
				inserted = true
			for i in (0 if n_out == sel.size() else samples.size()):
				if is_sel[i] == 1:
					if not inserted:
						result.append_array(conv)
						inserted = true
				else:
					result.append(samples[i])
	else:
		if out.size() != sel.size():
			diags.append(MotionDiagnostic.error(&"layer_count_mismatch",
				"%s devolveu %d amostras para %d de entrada (use TOPOLOGY para mudar a quantidade)" % [b.id, out.size(), sel.size()], l.id))
			return null
		result = samples.duplicate()
		for j in sel.size():
			var i := sel[j]
			var o := out[j]
			if o.element_id != samples[i].element_id:
				diags.append(MotionDiagnostic.error(&"layer_element_id_changed",
					"%s alterou o id de elemento %d fora de uma operação de topologia" % [b.id, samples[i].element_id], l.id))
				return null
			var w := l.intensity * l.mask.weight(samples[i], lt)
			var oc := o if local_space else MotionSpace.from_space(o, frames[j])
			if l.op == Op.OFFSET and not local_space:
				oc.position = frames[j].basis * o.position  # deslocamento: só a parte linear do referencial
			result[i] = _merge(l.op, samples[i], oc, w)

	# Finitude: sempre. Unicidade de ids: só onde ids podem mudar (topologia/persistência); nas demais
	# operações o id de cada amostra já foi verificado igual ao da entrada.
	var check_ids := topo or persist
	var seen := {}
	for s in result:
		if not s.is_finite_sample():
			diags.append(MotionDiagnostic.error(&"layer_nonfinite", "saída com valores não finitos", l.id))
			return null
		if check_ids:
			if seen.has(s.element_id):
				diags.append(MotionDiagnostic.error(&"layer_duplicate_elements",
					"id de elemento duplicado: %d" % s.element_id, l.id))
				return null
			seen[s.element_id] = true
	return result


static func _merge(op: int, orig: MotionSample, o: MotionSample, w: float) -> MotionSample:
	var r := orig.duplicate_sample()
	if w <= 0.0:
		return r
	match op:
		Op.REPLACE:
			r.position = orig.position.lerp(o.position, w)
			r.basis = _slerp_basis(orig.basis, o.basis, w)
			r.width = lerpf(orig.width, o.width, w)
			r.intensity = lerpf(orig.intensity, o.intensity, w)
			r.opacity = lerpf(orig.opacity, o.opacity, w)
			if w >= 0.5:
				r.visible = o.visible
		Op.DEFORM:
			r.position = orig.position.lerp(o.position, w)
			r.basis = _slerp_basis(orig.basis, o.basis, w)
		Op.OFFSET:
			r.position = orig.position + o.position * w
		Op.MULTIPLY_ATTRIBUTE:
			r.width = orig.width * lerpf(1.0, o.width, w)
			r.intensity = orig.intensity * lerpf(1.0, o.intensity, w)
			r.opacity = orig.opacity * lerpf(1.0, o.opacity, w)
		Op.MASK:
			if w >= 0.5 and not o.visible:
				r.visible = false
	return r


static func _slerp_basis(a: Basis, b: Basis, w: float) -> Basis:
	return Basis(Quaternion(a.orthonormalized()).slerp(Quaternion(b.orthonormalized()), w))
