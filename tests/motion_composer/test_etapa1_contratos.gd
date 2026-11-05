extends SceneTree
## Motion Composer V1 — Etapa 1: testes dos contratos (D-300).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa1_contratos.gd
## Os comportamentos abaixo são DUBLÊS de teste, não os M01–M20 (Etapa 2).

const Op := MotionTypes.Op
const Kind := MotionTypes.Kind
const Space := MotionTypes.Space

var _fails: int = 0
var _checks: int = 0


# --------------------------------------------------------------------------------------
# Dublês
# --------------------------------------------------------------------------------------
class FakeShift extends MotionBehavior:
	func _init() -> void:
		id = &"T_SHIFT"
		kind = Kind.MODIFIER
		accepted_operations = [Op.REPLACE, Op.DEFORM]
		params = [MotionParam.make_float(&"amount", 1.0, -10.0, 10.0, "m")]

	func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.position += Vector3(float(p["amount"]), 0.0, 0.0)
			out.append(c)
		return out


class FakeSwirl extends MotionBehavior:
	func _init() -> void:
		id = &"T_SWIRL"
		kind = Kind.MODIFIER
		accepted_operations = [Op.REPLACE, Op.DEFORM]
		params = [MotionParam.make_float(&"deg_per_u", 90.0, -720.0, 720.0, "deg")]

	func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			var a := deg_to_rad(float(p["deg_per_u"])) * s.u
			c.position = s.position.rotated(Vector3.BACK, a)
			out.append(c)
		return out


class FakeWave extends MotionBehavior:
	func _init() -> void:
		id = &"T_WAVE"
		kind = Kind.MODIFIER
		accepted_operations = [Op.REPLACE, Op.DEFORM]
		params = [MotionParam.make_float(&"amp", 1.0, 0.0, 10.0, "m")]

	func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.position.y += float(p["amp"]) * sin(TAU * (lt + s.u))
			out.append(c)
		return out


class FakeWidth extends MotionBehavior:
	func _init() -> void:
		id = &"T_WIDTH"
		kind = Kind.ENVELOPE
		accepted_operations = [Op.MULTIPLY_ATTRIBUTE]
		params = [MotionParam.make_float(&"value", 0.5, 0.0, 10.0, "")]

	func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.width = float(p["value"])
			out.append(c)
		return out


class FakeHide extends MotionBehavior:
	func _init() -> void:
		id = &"T_HIDE"
		kind = Kind.ENVELOPE
		accepted_operations = [Op.MASK]
		params = []

	func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.visible = s.u <= 0.5
			out.append(c)
		return out


class FakeNoise extends MotionBehavior:
	func _init() -> void:
		id = &"T_NOISE"
		kind = Kind.FIELD
		accepted_operations = [Op.OFFSET]
		params = [MotionParam.make_float(&"amount", 1.0, 0.0, 10.0, "m")]

	func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		var tick := int(floor(lt * 10.0))
		for s in samples:
			var c := s.duplicate_sample()
			var d := Vector3(
				MotionHash.float01(ctx.seed, s.element_id, tick, 0) - 0.5,
				MotionHash.float01(ctx.seed, s.element_id, tick, 1) - 0.5,
				0.0)
			c.position = d * float(p["amount"])  # OFFSET: posição de saída é deslocamento
			out.append(c)
		return out


class FakeSplit extends MotionBehavior:
	func _init() -> void:
		id = &"T_SPLIT"
		kind = Kind.TOPOLOGY
		accepted_operations = [Op.BRANCH]
		params = [MotionParam.make_int(&"count", 3, 1, 64, "")]

	func output_count(n_in: int, p: Dictionary) -> int:
		return n_in * int(p["count"])

	func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, _lt: float, lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		var n := int(p["count"])
		for s in samples:
			for i in n:
				var c := s.duplicate_sample()
				c.branch = MotionSample.branch_path(s.branch, lid, i)
				c.element_id = MotionSample.derive_id(s.element_id, lid, i, ctx.seed)
				c.position += Vector3(0.0, float(i) * 0.1, 0.0)
				out.append(c)
		return out


class FakeBad extends MotionBehavior:
	func _init() -> void:
		id = &"T_BAD"
		kind = Kind.MODIFIER
		accepted_operations = [Op.REPLACE]
		params = []

	func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.position = Vector3(INF, 0.0, 0.0)
			out.append(c)
		return out


class FakeGhost extends MotionBehavior:
	func _init() -> void:
		id = &"T_GHOST"
		kind = Kind.HISTORICAL
		accepted_operations = [Op.PERSIST]
		needs_history = true
		params = []

	func output_count(n_in: int, _p: Dictionary) -> int:
		return n_in

	func apply(samples: Array[MotionSample], _p: Dictionary, ctx: MotionContext, lt: float, lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			var c := s.duplicate_sample()
			c.element_id = MotionSample.derive_id(s.element_id, lid, 0, ctx.seed)
			c.branch = MotionSample.branch_path(s.branch, lid, 0)
			c.opacity = 0.5
			c.position += ctx.emitter_at(ctx.time - 0.1).origin - ctx.emitter_at(ctx.time).origin
			out.append(c)
		return out


## Viola o contrato: altera a ENTRADA e devolve valores não finitos.
class FakeMutNaN extends MotionBehavior:
	func _init() -> void:
		id = &"T_MUTNAN"
		kind = Kind.MODIFIER
		accepted_operations = [Op.REPLACE]
		params = []

	func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		for s in samples:
			s.position.x = 99.0
			s.width = NAN
		return samples


## Viola o contrato: altera a ENTRADA mas devolve cópias válidas (anteriores à mutação).
class FakeMutSilent extends MotionBehavior:
	func _init() -> void:
		id = &"T_MUTSILENT"
		kind = Kind.ENVELOPE
		accepted_operations = [Op.MULTIPLY_ATTRIBUTE]
		params = []

	func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			out.append(s.duplicate_sample())
			s.position.x = 99.0
		return out


class FakeDupId extends MotionBehavior:
	func _init() -> void:
		id = &"T_DUPID"
		kind = Kind.TOPOLOGY
		accepted_operations = [Op.BRANCH]
		params = []

	func output_count(n_in: int, _p: Dictionary) -> int:
		return n_in * 2

	func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _lt: float, _lid: StringName) -> Array[MotionSample]:
		var out: Array[MotionSample] = []
		for s in samples:
			out.append(s.duplicate_sample())
			out.append(s.duplicate_sample())  # mesmo element_id: contrato quebrado
		return out


# --------------------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------------------
func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func near(a: float, b: float, eps: float = 1e-4) -> bool:
	return absf(a - b) <= eps


func vnear(a: Vector3, b: Vector3, eps: float = 1e-4) -> bool:
	return a.distance_to(b) <= eps


func make_catalog() -> MotionCatalog:
	var cat := MotionCatalog.new()
	for b in [FakeShift.new(), FakeSwirl.new(), FakeWave.new(), FakeWidth.new(), FakeHide.new(),
			FakeNoise.new(), FakeSplit.new(), FakeBad.new(), FakeGhost.new(), FakeDupId.new(),
			FakeMutNaN.new(), FakeMutSilent.new()]:
		var d := cat.register(b)
		if not d.is_empty():
			print("  catálogo de teste falhou: ", d[0].message)
	return cat


func make_comp(n: int = 16) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = &"teste"
	c.sample_count = n
	c.duration = 2.0
	c.seed = 1234
	return c


func layer(lid: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = lid
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func ctx_at(c: MotionComposition, t: float) -> MotionContext:
	return c.make_context(t)


func positions(r: MotionResult) -> PackedVector3Array:
	var out := PackedVector3Array()
	for s in r.samples:
		out.append(s.position)
	return out


func same_positions(a: PackedVector3Array, b: PackedVector3Array, eps: float = 1e-5) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not vnear(a[i], b[i], eps):
			return false
	return true


func has_code(diags: Array[MotionDiagnostic], code: StringName) -> bool:
	for d in diags:
		if d.code == code:
			return true
	return false


# --------------------------------------------------------------------------------------
func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 1: CONTRATOS (D-300)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	t_hash()
	t_params()
	t_context()
	t_catalog()
	t_rest()
	t_order_and_revision()
	t_disabled_and_neutral()
	t_operations()
	t_mask()
	t_time()
	t_spaces()
	t_determinism()
	t_validation()
	t_branches()
	t_guards()
	t_persist()
	t_multi_instance()
	t_no_nodes(nodes_before)
	t_cost_report()

	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


# --------------------------------------------------------------------------------------
func t_hash() -> void:
	print("\n-- Determinismo: hash --")
	ok(MotionHash.mix(1, 2, 3, 4) == MotionHash.mix(1, 2, 3, 4), "mesma entrada, mesma saída")
	ok(MotionHash.mix(1, 2, 3, 4) != MotionHash.mix(2, 2, 3, 4), "semente diferente muda a saída")
	ok(MotionHash.mix(1, 2, 3, 4) != MotionHash.mix(1, 3, 2, 4), "a ordem dos argumentos importa")
	var in_range := true
	var distinct := {}
	for i in 1000:
		var f := MotionHash.float01(77, i)
		if f < 0.0 or f >= 1.0:
			in_range = false
		distinct[f] = true
	ok(in_range, "float01 sempre em [0, 1)")
	ok(distinct.size() > 990, "float01 pouco repetitivo (%d distintos de 1000)" % distinct.size())
	ok(MotionHash.mix(-5, -9, -1) == MotionHash.mix(-5, -9, -1), "aceita inteiros negativos")


func t_params() -> void:
	print("\n-- Parâmetros: domínio e unidade --")
	var p := MotionParam.make_float(&"r", 1.0, 0.0, 2.0, "m")
	ok(p.check(1.0) == "", "valor dentro do domínio")
	ok(p.check(2) == "", "int aceito em parâmetro float")
	ok(p.check(2.5) != "", "acima do máximo é recusado")
	ok(p.check(-0.1) != "", "abaixo do mínimo é recusado")
	ok(p.check(NAN) != "", "NaN é recusado")
	ok(p.check(INF) != "", "infinito é recusado")
	ok(p.check("x") != "", "tipo errado é recusado")
	ok(p.unit == "m", "unidade preservada")
	var pi := MotionParam.make_int(&"n", 3, 1, 8, "")
	ok(pi.check(3) == "" and pi.check(3.5) != "", "int recusa float")
	var pb := MotionParam.make_bool(&"b", true)
	ok(pb.check(false) == "" and pb.check(1) != "", "bool recusa não-bool")
	var pv := MotionParam.make_vec3(&"v", Vector3.UP, -5.0, 5.0, "m")
	ok(pv.check(Vector3(1, 2, 3)) == "" and pv.check(Vector3(0, 9, 0)) != "" and pv.check(Vector3(NAN, 0, 0)) != "",
		"Vector3: domínio por componente e finitude")
	var b := FakeShift.new()
	ok(b.resolve_params({})["amount"] == 1.0, "padrão preenchido")
	ok(b.resolve_params({"amount": 3.0})["amount"] == 3.0, "valor dado prevalece")
	ok(has_code(b.validate_params({"nope": 1.0}, &"L"), &"param_unknown"), "parâmetro desconhecido é diagnosticado")
	ok(has_code(b.validate_params({"amount": 99.0}, &"L"), &"param_domain"), "fora do domínio é diagnosticado")


func t_context() -> void:
	print("\n-- Contexto: tempo em segundos ≠ progresso normalizado --")
	var c := MotionContext.new()
	c.duration = 3.0
	c.time = 1.5
	ok(near(c.progress(), 0.5), "progresso = tempo / duração")
	c.time = 9.0
	ok(near(c.progress(), 1.0), "progresso saturado em 1")
	c.time = -1.0
	ok(near(c.progress(), 0.0), "progresso saturado em 0")
	c.time = 1.5
	ok(c.validate().is_empty(), "contexto válido não gera diagnóstico")
	c.duration = 0.0
	ok(has_code(c.validate(), &"ctx_duration"), "duração zero é erro")
	c.duration = INF
	ok(has_code(c.validate(), &"ctx_duration"), "duração infinita é erro")
	c.duration = 3.0
	c.time = NAN
	ok(has_code(c.validate(), &"ctx_time"), "tempo NaN é erro")
	c.time = 1.0
	var c2 := c.with_time(2.0)
	ok(near(c2.time, 2.0) and near(c.time, 1.0) and near(c2.duration, 3.0), "with_time copia sem alterar o original")
	ok(c.emitter_at(5.0) == Transform3D.IDENTITY, "sem emissor, identidade")
	c.emitter_fn = func(t: float) -> Transform3D: return Transform3D(Basis.IDENTITY, Vector3(t, 0, 0))
	ok(vnear(c.emitter_at(2.5).origin, Vector3(2.5, 0, 0)), "emissor consultável em qualquer instante")


func t_catalog() -> void:
	print("\n-- Catálogo --")
	var cat := MotionCatalog.new()
	ok(cat.register(FakeShift.new()).is_empty(), "registro válido")
	ok(has_code(cat.register(FakeShift.new()), &"cat_duplicate"), "id duplicado é recusado")
	var anon := MotionBehavior.new()
	ok(has_code(cat.register(anon), &"cat_empty_id"), "id vazio é recusado")
	var norm := FakeShift.new()
	norm.id = &"T_NOOP"
	norm.accepted_operations = []
	ok(has_code(cat.register(norm), &"cat_no_ops"), "comportamento sem operação aceita é recusado")
	ok(cat.has(&"T_SHIFT") and not cat.has(&"X"), "consulta por id")
	ok(MotionCatalog.V1_IDS.size() == 20, "conjunto V1 tem exatamente 20 ids")
	ok(MotionCatalog.V1_IDS[0] == &"M01" and MotionCatalog.V1_IDS[19] == &"M20", "M01..M20")
	ok(cat.missing_v1().size() == 20, "catálogo sem M01–M20 lista os 20 como ausentes")


func t_rest() -> void:
	print("\n-- Trajetória de repouso --")
	var c := make_comp(11)
	var r := c.evaluate(make_catalog(), ctx_at(c, 0.0))
	ok(not r.has_errors(), "composição vazia avalia sem erro")
	ok(r.samples.size() == 11, "quantidade de amostras = sample_count")
	ok(near(r.samples[0].u, 0.0) and near(r.samples[10].u, 1.0), "u cobre 0..1")
	ok(vnear(r.samples[5].position, Vector3(0, 0, 0.5 * c.base_length)), "repouso ao longo de +Z")
	ok(vnear(r.samples[5].basis.z, Vector3.BACK), "tangente de repouso = +Z")
	var ids := {}
	for s in r.samples:
		ids[s.element_id] = true
	ok(ids.size() == 11, "ids de elemento únicos")
	ok(r.samples[0].branch == "root", "ramo inicial é 'root'")
	ok(r.samples[3].opacity == 1.0 and r.samples[3].visible and r.samples[3].width == 1.0, "atributos neutros")
	var r2 := c.evaluate(make_catalog(), ctx_at(c, 1.7))
	ok(r2.samples[4].element_id == r.samples[4].element_id, "id de elemento não depende do tempo")


func t_order_and_revision() -> void:
	print("\n-- Ordem das camadas e revisão --")
	var cat := make_catalog()
	var c := make_comp()
	var rev0 := c.revision
	c.add_layer(layer(&"A", &"T_SHIFT", Op.DEFORM, {"amount": 2.0}))
	c.add_layer(layer(&"B", &"T_SWIRL", Op.DEFORM, {"deg_per_u": 180.0}))
	ok(c.revision == rev0 + 2, "cada edição incrementa a revisão")
	var ab := positions(c.evaluate(cat, ctx_at(c, 0.0)))
	c.move_layer(&"B", 0)
	ok(c.layer_ids() == [&"B", &"A"], "move_layer reordena preservando ids")
	var ba := positions(c.evaluate(cat, ctx_at(c, 0.0)))
	ok(not same_positions(ab, ba), "deslocar→girar ≠ girar→deslocar (a ordem faz parte da definição)")
	c.move_layer(&"B", 1)
	ok(same_positions(ab, positions(c.evaluate(cat, ctx_at(c, 0.0)))), "voltar à ordem original restaura o resultado")
	var rev1 := c.revision
	ok(not c.add_layer(layer(&"A", &"T_SHIFT", Op.DEFORM)), "id de camada duplicado é recusado")
	ok(c.revision == rev1, "edição recusada não altera a revisão")
	c.set_param(&"A", &"amount", 4.0)
	ok(c.revision == rev1 + 1, "set_param incrementa a revisão")
	var r := c.evaluate(cat, ctx_at(c, 0.0))
	ok(r.revision == c.revision, "resultado carrega a revisão que o gerou")
	c.remove_layer(&"A")
	ok(c.layer_ids() == [&"B"] and c.revision == rev1 + 2, "remove_layer")


func t_disabled_and_neutral() -> void:
	print("\n-- Camada desligada e intensidade neutra --")
	var cat := make_catalog()
	var base := make_comp()
	var base_pos := positions(base.evaluate(cat, ctx_at(base, 0.5)))

	var c := make_comp()
	var l := layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 3.0})
	l.enabled = false
	c.add_layer(l)
	ok(same_positions(base_pos, positions(c.evaluate(cat, ctx_at(c, 0.5)))), "camada desligada = composição sem ela")

	var ops_and_behaviors := [
		[Op.REPLACE, &"T_SHIFT"], [Op.DEFORM, &"T_SWIRL"], [Op.OFFSET, &"T_NOISE"],
		[Op.MULTIPLY_ATTRIBUTE, &"T_WIDTH"], [Op.MASK, &"T_HIDE"],
	]
	var all_neutral := true
	for pair in ops_and_behaviors:
		var c2 := make_comp()
		var l2 := layer(&"N", pair[1], pair[0])
		l2.intensity = 0.0
		c2.add_layer(l2)
		var r2 := c2.evaluate(cat, ctx_at(c2, 0.5))
		var b0 := base.evaluate(cat, ctx_at(base, 0.5))
		for i in r2.samples.size():
			var a := r2.samples[i]
			var b := b0.samples[i]
			if not (vnear(a.position, b.position) and near(a.width, b.width) and near(a.opacity, b.opacity) and a.visible == b.visible):
				all_neutral = false
	ok(all_neutral, "intensidade 0 preserva a entrada em REPLACE/DEFORM/OFFSET/MULTIPLY/MASK")

	var c3 := make_comp()
	c3.add_layer(layer(&"H", &"T_SHIFT", Op.REPLACE, {"amount": 4.0}))
	var full := positions(c3.evaluate(cat, ctx_at(c3, 0.0)))
	c3.layers[0].intensity = 0.5
	var half := positions(c3.evaluate(cat, ctx_at(c3, 0.0)))
	ok(near(half[3].x, full[3].x * 0.5), "intensidade 0,5 interpola entre entrada e efeito pleno")


func t_operations() -> void:
	print("\n-- Semântica das operações --")
	var cat := make_catalog()
	var base := make_comp()
	var b0 := base.evaluate(cat, ctx_at(base, 0.0))

	var c := make_comp()
	c.add_layer(layer(&"W", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.25}))
	var r := c.evaluate(cat, ctx_at(c, 0.0))
	ok(near(r.samples[2].width, 0.25) and vnear(r.samples[2].position, b0.samples[2].position),
		"MULTIPLY_ATTRIBUTE altera atributos e preserva a geometria")

	var c2 := make_comp()
	c2.add_layer(layer(&"W1", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.5}))
	c2.add_layer(layer(&"W2", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.5}))
	ok(near(c2.evaluate(cat, ctx_at(c2, 0.0)).samples[0].width, 0.25), "atributos multiplicam entre camadas")

	var c3 := make_comp()
	c3.add_layer(layer(&"H", &"T_HIDE", Op.MASK))
	var r3 := c3.evaluate(cat, ctx_at(c3, 0.0))
	ok(r3.samples[0].visible and not r3.samples[r3.samples.size() - 1].visible, "MASK altera só a visibilidade")
	ok(vnear(r3.samples[5].position, b0.samples[5].position), "MASK preserva a geometria")

	var c4 := make_comp()
	c4.add_layer(layer(&"O1", &"T_NOISE", Op.OFFSET, {"amount": 2.0}))
	var r4 := c4.evaluate(cat, ctx_at(c4, 0.0))
	var s4 := r4.samples[4]
	var d4 := Vector3(MotionHash.float01(c4.seed, s4.element_id, 0, 0) - 0.5, MotionHash.float01(c4.seed, s4.element_id, 0, 1) - 0.5, 0.0) * 2.0
	ok(vnear(s4.position, b0.samples[4].position + d4),
		"OFFSET: a saída do comportamento é um deslocamento somado à posição anterior")
	c4.add_layer(layer(&"O2", &"T_NOISE", Op.OFFSET, {"amount": 2.0}))
	ok(vnear(c4.evaluate(cat, ctx_at(c4, 0.0)).samples[4].position, b0.samples[4].position + d4 * 2.0),
		"OFFSET acumula entre camadas")
	c4.remove_layer(&"O2")
	c4.layers[0].intensity = 0.5
	ok(vnear(c4.evaluate(cat, ctx_at(c4, 0.0)).samples[4].position, b0.samples[4].position + d4 * 0.5),
		"OFFSET: a intensidade escala o deslocamento")

	var c6 := make_comp()
	var lh := layer(&"H", &"T_HIDE", Op.MASK)
	lh.intensity = 0.4
	c6.add_layer(lh)
	ok(c6.evaluate(cat, ctx_at(c6, 0.0)).samples[c6.sample_count - 1].visible,
		"MASK: peso abaixo de 0,5 não esconde (visibilidade é binária, limiar em 0,5)")

	var c7 := make_comp()
	var lw := layer(&"W", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.0})
	lw.intensity = 0.5
	c7.add_layer(lw)
	ok(near(c7.evaluate(cat, ctx_at(c7, 0.0)).samples[2].width, 0.5), "MULTIPLY_ATTRIBUTE: multiplicador interpola de 1 até o valor pleno")

	var c8 := make_comp()
	var lr := layer(&"R", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.5})
	c8.add_layer(lr)
	c8.add_layer(layer(&"SH", &"T_SHIFT", Op.DEFORM, {"amount": 1.0}))
	ok(near(c8.evaluate(cat, ctx_at(c8, 0.0)).samples[2].width, 0.5), "DEFORM posterior não apaga atributos já multiplicados")

	var c5 := make_comp()
	c5.add_layer(layer(&"D", &"T_SHIFT", Op.DEFORM, {"amount": 1.0}))
	var r5 := c5.evaluate(cat, ctx_at(c5, 0.0))
	ok(near(r5.samples[4].width, 1.0) and vnear(r5.samples[4].position, b0.samples[4].position + Vector3(1, 0, 0)),
		"DEFORM transforma a geometria e mantém atributos")


func t_mask() -> void:
	print("\n-- Máscaras --")
	var cat := make_catalog()
	var base := make_comp(21)
	var b0 := base.evaluate(cat, ctx_at(base, 0.0))

	var c := make_comp(21)
	var l := layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 2.0})
	l.mask.u_from = 0.5
	l.mask.u_to = 1.0
	c.add_layer(l)
	var r := c.evaluate(cat, ctx_at(c, 0.0))
	ok(vnear(r.samples[3].position, b0.samples[3].position), "máscara espacial: fora da faixa nada muda")
	ok(vnear(r.samples[15].position, b0.samples[15].position + Vector3(2, 0, 0)), "máscara espacial: dentro da faixa aplica")

	l.mask.invert = true
	var ri := c.evaluate(cat, ctx_at(c, 0.0))
	ok(vnear(ri.samples[3].position, b0.samples[3].position + Vector3(2, 0, 0)) and vnear(ri.samples[15].position, b0.samples[15].position),
		"máscara invertida")

	l.mask.invert = false
	l.mask.feather = 0.2
	var rf := c.evaluate(cat, ctx_at(c, 0.0))
	var dx := rf.samples[9].position.x  # u = 0.45, no degradê
	ok(dx > 0.0 and dx < 2.0, "degradê (feather) produz peso intermediário (dx=%.3f)" % dx)

	l.mask.feather = 0.0
	l.mask.time_enabled = true
	l.mask.t_from = 1.0
	l.mask.t_to = 2.0
	ok(vnear(c.evaluate(cat, ctx_at(c, 0.5)).samples[15].position, b0.samples[15].position), "máscara temporal: antes da janela")
	ok(vnear(c.evaluate(cat, ctx_at(c, 1.5)).samples[15].position, b0.samples[15].position + Vector3(2, 0, 0)), "máscara temporal: na janela")

	var c2 := make_comp(21)
	var l2 := layer(&"E", &"T_SHIFT", Op.REPLACE, {"amount": 2.0})
	l2.mask.elements = PackedInt64Array([b0.samples[7].element_id])
	c2.add_layer(l2)
	var r2 := c2.evaluate(cat, ctx_at(c2, 0.0))
	ok(not vnear(r2.samples[7].position, b0.samples[7].position) and vnear(r2.samples[8].position, b0.samples[8].position),
		"máscara por identificador de elemento")


func t_time() -> void:
	print("\n-- Defasagem e janela temporal da camada --")
	var cat := make_catalog()
	var c := make_comp()
	c.add_layer(layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 1.0}))
	var ref := positions(c.evaluate(cat, ctx_at(c, 0.4)))

	var c2 := make_comp()
	var l2 := layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 1.0})
	l2.time_offset = 0.25
	c2.add_layer(l2)
	ok(same_positions(ref, positions(c2.evaluate(cat, ctx_at(c2, 0.65)))), "defasagem: avaliar em t+d com offset d = avaliar em t sem offset")

	var c3 := make_comp()
	var l3 := layer(&"S", &"T_SHIFT", Op.REPLACE, {"amount": 5.0})
	l3.active_from = 0.5
	l3.active_to = 1.0
	c3.add_layer(l3)
	var base := positions(make_comp().evaluate(cat, ctx_at(make_comp(), 0.0)))
	ok(same_positions(base, positions(c3.evaluate(cat, ctx_at(c3, 0.2)))), "antes da janela: camada inativa")
	ok(not same_positions(base, positions(c3.evaluate(cat, ctx_at(c3, 0.7)))), "dentro da janela: camada ativa")
	ok(same_positions(base, positions(c3.evaluate(cat, ctx_at(c3, 1.2)))), "depois da janela: camada inativa")

	var c4 := make_comp()
	c4.add_layer(layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 1.0}))
	var a1 := positions(c4.evaluate(cat, ctx_at(c4, 0.4)))
	var a2 := positions(c4.evaluate(cat, ctx_at(c4, 0.4)))
	ok(same_positions(a1, a2), "pausa: mesmo instante, mesmo resultado")
	var pa := positions(c4.evaluate(cat, ctx_at(c4, 0.4)))
	var pb := positions(c4.evaluate(cat, ctx_at(c4, 0.4 + 1e-3)))
	ok(not same_positions(pa, pb, 1e-7), "instantes diferentes produzem estados diferentes")


func t_spaces() -> void:
	print("\n-- Espaços de coordenadas --")
	var cat := make_catalog()
	var base := make_comp()
	var b0 := positions(base.evaluate(cat, ctx_at(base, 0.0)))

	var ref_xf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(10, 0, 0))
	var all_identity := true
	for sp in [Space.LOCAL, Space.GLOBAL, Space.EMITTER, Space.TRAJECTORY]:
		var c := make_comp()
		var l := layer(&"I", &"T_SHIFT", Op.REPLACE, {"amount": 0.0})
		l.space = sp
		c.add_layer(l)
		var ctx := ctx_at(c, 0.0)
		ctx.reference_transform = ref_xf
		ctx.emitter_fn = func(t: float) -> Transform3D: return Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(1, 2, 3 + t))
		var r := c.evaluate(cat, ctx)
		if not same_positions(b0, positions(r), 1e-4):
			all_identity = false
	ok(all_identity, "ida e volta de espaço com comportamento neutro preserva as amostras (4 espaços)")

	# deslocamento de +1 em X no espaço escolhido, visto no espaço local do efeito
	var cl := make_comp()
	cl.add_layer(layer(&"S", &"T_SHIFT", Op.REPLACE, {"amount": 1.0}))
	var rl := positions(cl.evaluate(cat, ctx_at(cl, 0.0)))
	ok(vnear(rl[4], b0[4] + Vector3(1, 0, 0)), "LOCAL: +X local")

	var cg := make_comp()
	var lg := layer(&"S", &"T_SHIFT", Op.REPLACE, {"amount": 1.0})
	lg.space = Space.GLOBAL
	cg.add_layer(lg)
	var ctxg := ctx_at(cg, 0.0)
	ctxg.reference_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3.ZERO)
	var rg := positions(cg.evaluate(cat, ctxg))
	var expect_g: Vector3 = ctxg.reference_transform.affine_inverse().basis * Vector3(1, 0, 0)
	ok(vnear(rg[4], b0[4] + expect_g), "GLOBAL: +X global convertido para o espaço local do efeito")

	var ce := make_comp()
	var le := layer(&"S", &"T_SHIFT", Op.REPLACE, {"amount": 1.0})
	le.space = Space.EMITTER
	ce.add_layer(le)
	var ctxe := ctx_at(ce, 0.0)
	ctxe.emitter_fn = func(_t: float) -> Transform3D: return Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3.ZERO)
	var re := positions(ce.evaluate(cat, ctxe))
	var expect_e: Vector3 = ctxe.emitter_at(0.0).basis * Vector3(1, 0, 0)
	ok(vnear(re[4], b0[4] + expect_e), "EMITTER: +X do emissor convertido para o espaço local")

	var ct := make_comp()
	var lt := layer(&"S", &"T_SHIFT", Op.REPLACE, {"amount": 1.0})
	lt.space = Space.TRAJECTORY
	ct.add_layer(lt)
	var rt := positions(ct.evaluate(cat, ctx_at(ct, 0.0)))
	ok(vnear(rt[4], b0[4] + Vector3(1, 0, 0)), "TRAJECTORY sobre trajetória reta em +Z coincide com LOCAL")

	var cs := make_comp()
	var ls := layer(&"S", &"T_SPLIT", Op.BRANCH)
	ls.space = Space.TRAJECTORY
	cs.add_layer(ls)
	ok(has_code(cs.validate(cat), &"layer_space_topology"), "topologia em espaço de trajetória é recusada")


func t_determinism() -> void:
	print("\n-- Determinismo e avaliação direta --")
	var cat := make_catalog()
	var c := make_comp(32)
	c.add_layer(layer(&"N", &"T_NOISE", Op.OFFSET, {"amount": 1.0}))
	c.add_layer(layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 0.5}))
	var r1 := positions(c.evaluate(cat, ctx_at(c, 0.8)))
	var r2 := positions(c.evaluate(cat, ctx_at(c, 0.8)))
	ok(same_positions(r1, r2, 0.0), "mesma semente, tempo e parâmetros: resultado idêntico (bit a bit)")

	# avaliação direta: percorrer outros instantes antes não altera o resultado
	for t in [0.0, 0.3, 1.9, 0.1]:
		c.evaluate(cat, ctx_at(c, t))
	ok(same_positions(r1, positions(c.evaluate(cat, ctx_at(c, 0.8))), 0.0), "avaliar outros instantes antes (seek) não altera o resultado")

	# partição temporal: chegar em t por passos pequenos ou grandes dá o mesmo resultado
	var step_a := 0.0
	while step_a < 0.8 - 1e-9:
		c.evaluate(cat, ctx_at(c, step_a))
		step_a += 1.0 / 60.0
	ok(same_positions(r1, positions(c.evaluate(cat, ctx_at(c, 0.8))), 0.0), "invariância ao particionamento temporal")

	var c2 := make_comp(32)
	c2.seed = 999
	c2.add_layer(layer(&"N", &"T_NOISE", Op.OFFSET, {"amount": 1.0}))
	c2.add_layer(layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 0.5}))
	ok(not same_positions(r1, positions(c2.evaluate(cat, ctx_at(c2, 0.8)))), "semente diferente muda o resultado")

	# o resultado depende só dos dados da composição, não da instância
	var c3 := make_comp(32)
	c3.add_layer(layer(&"N", &"T_NOISE", Op.OFFSET, {"amount": 1.0}))
	c3.add_layer(layer(&"W", &"T_WAVE", Op.DEFORM, {"amp": 0.5}))
	ok(same_positions(r1, positions(c3.evaluate(cat, ctx_at(c3, 0.8))), 0.0), "composição recriada com os mesmos dados: mesmo resultado")

	# velocidade de reprodução não faz parte do contrato: só o tempo da instância
	var ra := positions(c.evaluate(cat, ctx_at(c, 0.5)))
	var rb := positions(c.evaluate(cat, ctx_at(c, 0.25 * 2.0)))
	ok(same_positions(ra, rb, 0.0), "o resultado é função apenas do tempo da instância")


func t_validation() -> void:
	print("\n-- Validação: diagnóstico explícito, sem conversão silenciosa --")
	var cat := make_catalog()

	var c := make_comp()
	c.add_layer(layer(&"A", &"NAO_EXISTE", Op.REPLACE))
	ok(has_code(c.validate(cat), &"layer_behavior_unknown"), "comportamento desconhecido")

	c = make_comp()
	c.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"nope": 1.0}))
	ok(has_code(c.validate(cat), &"param_unknown"), "parâmetro desconhecido na camada")

	c = make_comp()
	c.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 99.0}))
	ok(has_code(c.validate(cat), &"param_domain"), "parâmetro fora do domínio na camada")

	c = make_comp()
	c.add_layer(layer(&"A", &"T_SHIFT", Op.MASK))
	ok(has_code(c.validate(cat), &"layer_op_not_accepted"), "operação não aceita pelo comportamento")

	c = make_comp()
	var li := layer(&"A", &"T_SHIFT", Op.REPLACE)
	li.intensity = 1.5
	c.layers.append(li)
	ok(has_code(c.validate(cat), &"layer_intensity"), "intensidade fora de 0..1")

	c = make_comp()
	var lm := layer(&"A", &"T_SHIFT", Op.REPLACE)
	lm.mask.u_from = 0.9
	lm.mask.u_to = 0.1
	c.layers.append(lm)
	ok(has_code(c.validate(cat), &"mask_range"), "máscara com intervalo invertido")

	c = make_comp()
	c.layers.append(layer(&"A", &"T_SHIFT", Op.REPLACE))
	c.layers.append(layer(&"A", &"T_SHIFT", Op.REPLACE))
	ok(has_code(c.validate(cat), &"layer_id_duplicate"), "ids de camada duplicados (inserção direta)")

	c = make_comp()
	c.duration = 0.0
	ok(has_code(c.validate(cat), &"comp_duration"), "duração zero")
	c = make_comp()
	c.sample_count = 1
	ok(has_code(c.validate(cat), &"comp_sample_count"), "menos de 2 amostras")
	c = make_comp()
	c.base_length = NAN
	ok(has_code(c.validate(cat), &"comp_base_length"), "comprimento-base não finito")

	c = make_comp()
	c.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 99.0}))
	var r := c.evaluate(cat, ctx_at(c, 0.0))
	ok(r.has_errors() and r.samples.is_empty(), "composição inválida: erros e nenhuma amostra (sem correção silenciosa)")

	c = make_comp()
	var ctx_bad := ctx_at(c, 0.0)
	ctx_bad.duration = -1.0
	ok(c.evaluate(cat, ctx_bad).has_errors(), "contexto inválido é propagado como erro")


func t_branches() -> void:
	print("\n-- Ramos identificados --")
	var cat := make_catalog()
	var c := make_comp(8)
	c.add_layer(layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 3}))
	var r := c.evaluate(cat, ctx_at(c, 0.3))
	ok(not r.has_errors() and r.samples.size() == 24, "bifurcação em 3 fluxos: 8 × 3 amostras")
	var branches := {}
	var ids := {}
	for s in r.samples:
		branches[s.branch] = true
		ids[s.element_id] = true
	ok(branches.size() == 3 and branches.has("root/S.0") and branches.has("root/S.2"), "caminhos de ramo derivados do id da camada e do índice")
	ok(ids.size() == 24, "ids de elemento únicos após bifurcar")

	var r_later := c.evaluate(cat, ctx_at(c, 1.9))
	var same_ids := true
	for i in r.samples.size():
		if r.samples[i].element_id != r_later.samples[i].element_id or r.samples[i].branch != r_later.samples[i].branch:
			same_ids = false
	ok(same_ids, "identidades de ramo/elemento estáveis no tempo")

	var c2 := make_comp(8)
	c2.add_layer(layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 3}))
	var pick := layer(&"W", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.1})
	pick.branches = PackedStringArray(["root/S.1"])
	c2.add_layer(pick)
	var r2 := c2.evaluate(cat, ctx_at(c2, 0.0))
	var only := true
	for s in r2.samples:
		if (s.branch == "root/S.1") != near(s.width, 0.1):
			only = false
	ok(only, "camada posterior com seleção atua só no ramo escolhido")

	var c3 := make_comp(8)
	c3.add_layer(layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 3}))
	var miss := layer(&"W", &"T_WIDTH", Op.MULTIPLY_ATTRIBUTE, {"value": 0.1})
	miss.branches = PackedStringArray(["root/S.7"])
	c3.add_layer(miss)
	var r3 := c3.evaluate(cat, ctx_at(c3, 0.0))
	ok(has_code(r3.diagnostics, &"layer_branch_missing"), "seleção de ramo inexistente gera diagnóstico")
	ok(r3.samples.size() == 24 and near(r3.samples[0].width, 1.0), "camada com ramo inexistente é ignorada, sem efeito parcial")

	var c4 := make_comp(8)
	c4.add_layer(layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 2}))
	c4.add_layer(layer(&"T", &"T_SPLIT", Op.BRANCH, {"count": 2}))
	var r4 := c4.evaluate(cat, ctx_at(c4, 0.0))
	var nested := false
	for s in r4.samples:
		if s.branch == "root/S.1/T.1":
			nested = true
	ok(r4.samples.size() == 32 and nested, "ramos aninhados: 8 × 2 × 2 e caminho 'root/S.1/T.1'")

	var c5 := make_comp(8)
	var sp := layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 2})
	sp.branches = PackedStringArray(["root"])
	c5.add_layer(sp)
	ok(c5.evaluate(cat, ctx_at(c5, 0.0)).samples.size() == 16, "seleção por prefixo ('root' pega todo o subárvore)")


func t_guards() -> void:
	print("\n-- Proteções --")
	var cat := make_catalog()
	var c := make_comp(1000)
	c.max_samples = 2500
	c.add_layer(layer(&"S", &"T_SPLIT", Op.BRANCH, {"count": 3}))
	var r := c.evaluate(cat, ctx_at(c, 0.0))
	ok(has_code(r.diagnostics, &"layer_sample_limit"), "limite de amostras diagnosticado antes de alocar")
	ok(r.samples.size() == 1000, "camada que estouraria o limite é ignorada")

	var cb := make_comp()
	cb.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 1.0}))
	cb.add_layer(layer(&"B", &"T_BAD", Op.REPLACE))
	var rb := cb.evaluate(cat, ctx_at(cb, 0.0))
	ok(has_code(rb.diagnostics, &"layer_nonfinite"), "saída não finita é detectada")
	var ca := make_comp()
	ca.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 1.0}))
	ok(same_positions(positions(rb), positions(ca.evaluate(cat, ctx_at(ca, 0.0)))), "camada com saída inválida não contamina o resultado")

	# Comportamento que viola "não alterar a entrada" não pode corromper o fluxo (nem no espaço LOCAL).
	var cm := make_comp()
	cm.add_layer(layer(&"A", &"T_SHIFT", Op.REPLACE, {"amount": 1.0}))
	cm.add_layer(layer(&"M", &"T_MUTNAN", Op.REPLACE))
	var rm := cm.evaluate(cat, ctx_at(cm, 0.0))
	ok(has_code(rm.diagnostics, &"layer_nonfinite"), "mutação + saída inválida: camada diagnosticada")
	ok(same_positions(positions(rm), positions(ca.evaluate(cat, ctx_at(ca, 0.0)))) and near(rm.samples[2].width, 1.0),
		"mutação da entrada não corrompe o fluxo quando a camada é ignorada")
	var cs := make_comp()
	cs.add_layer(layer(&"S", &"T_MUTSILENT", Op.MULTIPLY_ATTRIBUTE))
	ok(same_positions(positions(cs.evaluate(cat, ctx_at(cs, 0.0))), positions(make_comp().evaluate(cat, ctx_at(cs, 0.0)))),
		"mutação silenciosa da entrada não vaza para o resultado")

	var cd := make_comp(4)
	cd.add_layer(layer(&"D", &"T_DUPID", Op.BRANCH))
	var rd := cd.evaluate(cat, ctx_at(cd, 0.0))
	ok(has_code(rd.diagnostics, &"layer_duplicate_elements"), "ids de elemento duplicados são detectados")
	ok(rd.samples.size() == 4, "camada que duplica ids é revertida")


func t_persist() -> void:
	print("\n-- Operação PERSIST (histórico) --")
	var cat := make_catalog()
	var c := make_comp(8)
	c.add_layer(layer(&"G", &"T_GHOST", Op.PERSIST))
	var ctx := ctx_at(c, 1.0)
	ctx.emitter_fn = func(t: float) -> Transform3D: return Transform3D(Basis.IDENTITY, Vector3(t * 10.0, 0, 0))
	var r := c.evaluate(cat, ctx)
	ok(not r.has_errors() and r.samples.size() == 16, "PERSIST acrescenta amostras ao fluxo")
	ok(near(r.samples[8].opacity, 0.5) and near(r.samples[0].opacity, 1.0), "amostras históricas distinguíveis")
	ok(near(r.samples[8].position.x - r.samples[0].position.x, -1.0), "estado histórico usa o emissor do instante anterior")
	var c2 := make_comp(8)
	var lz := layer(&"G", &"T_GHOST", Op.PERSIST)
	lz.intensity = 0.0
	c2.add_layer(lz)
	ok(c2.evaluate(cat, ctx_at(c2, 1.0)).samples.size() == 8, "intensidade 0 não acrescenta histórico")


func t_multi_instance() -> void:
	print("\n-- Várias instâncias do mesmo comportamento --")
	var cat := make_catalog()
	var c := make_comp()
	c.add_layer(layer(&"S1", &"T_SHIFT", Op.REPLACE, {"amount": 1.0}))
	c.add_layer(layer(&"S2", &"T_SHIFT", Op.REPLACE, {"amount": 2.5}))
	var base := positions(make_comp().evaluate(cat, ctx_at(make_comp(), 0.0)))
	var r := positions(c.evaluate(cat, ctx_at(c, 0.0)))
	ok(vnear(r[3], base[3] + Vector3(3.5, 0, 0)), "duas camadas do mesmo comportamento com parâmetros distintos")


func t_no_nodes(nodes_before: int) -> void:
	print("\n-- Independência de representação --")
	var after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	ok(after == nodes_before, "avaliar composições não cria nós (resultado é dado puro)")


func t_cost_report() -> void:
	print("\n-- Custo de avaliação (apenas medição, sem limite aprovado) --")
	var cat := make_catalog()
	var c := make_comp(128)
	for i in 8:
		c.add_layer(layer(StringName("L%d" % i), &"T_WAVE", Op.DEFORM, {"amp": 0.1}))
	c.add_layer(layer(&"SP", &"T_SPLIT", Op.BRANCH, {"count": 3}))
	var t0 := Time.get_ticks_usec()
	var n := 200
	var out_n := 0
	for i in n:
		out_n = c.evaluate(cat, ctx_at(c, float(i) * 0.01)).samples.size()
	var per := float(Time.get_ticks_usec() - t0) / float(n) / 1000.0
	print("  [INFO] 9 camadas, 128→%d amostras: %.3f ms por avaliação (GDScript, headless, sem render)" % [out_n, per])
	ok(out_n == 384, "medição usou 128 × 3 amostras")
