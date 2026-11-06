extends SceneTree
## Motion Composer V1.2 (D-323): os acabamentos (MotionLooks) só podem usar uniforms que o shader tem. Um nome errado é
## IGNORADO em silêncio pelo Godot (o efeito sai com a aparência padrão), então este teste é a rede de segurança.
## godot --headless --path . --script res://tests/motion_composer/test_v12_looks.gd

var _fails := 0
var _checks := 0

const SHADER_OF := {"surface": "mc_surface", "spark": "mc_spark", "puff": "mc_puff", "halo": "mc_halo", "mark": "mc_mark"}


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func _init() -> void:
	var uniforms := {}
	for kind in SHADER_OF.keys():
		var sh := load("res://shaders/%s.gdshader" % SHADER_OF[kind]) as Shader
		ok(sh != null, "o shader %s carrega" % SHADER_OF[kind])
		var names := {}
		if sh != null:
			for u in sh.get_shader_uniform_list():
				names[String(u["name"])] = true
		uniforms[kind] = names
	for el in MotionLooks.ELEMENTS:
		for kind in SHADER_OF.keys():
			var look := MotionLooks.get_look(kind, el)
			ok(not look.is_empty(), "%s/%s existe" % [el, kind])
			var bad: Array[String] = []
			for k in look.keys():
				if not (uniforms[kind] as Dictionary).has(String(k)):
					bad.append(String(k))
			ok(bad.is_empty(), "%s/%s só usa uniforms do shader (sobram: %s)" % [el, kind, str(bad)])
	# o look é uma cópia: mexer nele não contamina a próxima chamada
	var a := MotionLooks.get_look("surface", "fire")
	a["bands"] = 99.0
	ok(float(MotionLooks.get_look("surface", "fire")["bands"]) == 5.0, "get_look devolve cópia")
	ok(MotionLooks.get_look("surface", "inexistente").hash() == MotionLooks.get_look("surface", "fire").hash(), "elemento desconhecido cai no fogo")
	ok(MotionLooks.get_look("coisa", "fire").is_empty(), "tipo desconhecido devolve vazio")
	# os quatro elementos têm aparências diferentes (mesmo movimento, outra linguagem)
	var h := {}
	for el in MotionLooks.ELEMENTS:
		h[MotionLooks.get_look("surface", el).hash()] = true
	ok(h.size() == 4, "fogo, água, terra e ar têm looks distintos")
	# a galeria monta as oito células para cada elemento, sem erros de composição
	for el in MotionLooks.ELEMENTS:
		var cells := MotionGallery.build(el, 5)
		ok(cells.size() == MotionGallery.CELLS.size(), "galeria %s: %d células" % [el, cells.size()])
		var errs := 0
		for name in cells.keys():
			for l in (cells[name] as MotionEffect).layers:
				var comp: MotionComposition = l["comp"]
				if comp.evaluate(MotionStrand.catalog(), comp.make_context(0.5)).has_errors():
					errs += 1
		ok(errs == 0, "galeria %s: nenhuma camada com erro de composição" % el)
	print("%d verificações, %d falhas" % [_checks, _fails])
	if _fails == 0:
		print("MC_V12_LOOKS_PASS")
	quit(1 if _fails > 0 else 0)
