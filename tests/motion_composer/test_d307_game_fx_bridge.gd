extends SceneTree
## D-307 — ponte do laboratório do Motion Composer com os efeitos do jogo (só uso do BattleFx).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_d307_game_fx_bridge.gd
## Obrigatório (D-235 / AGENTS §7): atacante e alvo reais derivados; lado espelhado; alvos de tamanhos diferentes.

var _fails := 0
var _checks := 0


func ok(c: bool, n: String) -> void:
	_checks += 1
	if c:
		print("  [PASS] ", n)
	else:
		_fails += 1
		print("  [FAIL] ", n)


func _bridge() -> GameFxBridge:
	var b := GameFxBridge.new()
	root.add_child(b)
	return b


func _init() -> void:
	print("\n=== D-307: PONTE LAB x EFEITOS DO JOGO ===")
	await t_layout()
	await t_effects_follow_layout()
	await t_sizes()
	await t_clear_and_time()
	await t_seek()
	await t_lab_ui()
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_layout() -> void:
	print("\n-- Layout derivado (sem nada fixo) --")
	var b := _bridge()
	var l := b.layout()
	ok((l["attacker"] as Vector3).x < 0.0 and (l["target"] as Vector3).x > 0.0, "normal: atacante à esquerda, alvo à direita")
	ok(is_equal_approx(((l["target"] as Vector3) - (l["attacker"] as Vector3)).length(), b.distance), "distância entre os dois = parâmetro")
	ok((l["dir"] as Vector3).is_equal_approx(Vector3.RIGHT), "direção atacante → alvo")
	b.set_layout(8.4, 2.0, 2.4, true)
	var m := b.layout()
	ok((m["attacker"] as Vector3).x > 0.0 and (m["target"] as Vector3).x < 0.0, "espelhado: lados trocados")
	ok((m["dir"] as Vector3).is_equal_approx(Vector3.LEFT), "espelhado: direção invertida")
	ok(is_equal_approx((m["target_center"] as Vector3).y, 1.2) and is_equal_approx((m["attacker_center"] as Vector3).y, 1.0), "centros na metade da altura de cada um")
	b.set_layout(5.0, 1.0, 4.0, false)
	var n := b.layout()
	ok(is_equal_approx((n["target_center"] as Vector3).y, 2.0) and is_equal_approx((n["attacker_center"] as Vector3).y, 0.5), "alturas diferentes mudam os centros")
	b.queue_free()
	await process_frame


func _near(b: GameFxBridge, p: Vector3, r: float) -> bool:
	var c := b.effect_centroid()
	return c.is_finite() and c.distance_to(p) <= r


func t_effects_follow_layout() -> void:
	print("\n-- Cada efeito acontece onde o layout manda, nos dois lados --")
	var bad := []
	for mirror in [false, true]:
		for e in GameFxBridge.EFFECTS:
			var b := _bridge()
			b.set_layout(8.4, 2.0, 2.4, mirror)
			var played := b.play(e)
			await process_frame
			await process_frame
			var l := b.layout()
			var on_caster: bool = e in ["media", "tarukaja"]
			var want: Vector3 = l["attacker_center"] if on_caster else l["target_center"]
			if e == "tackle":
				want = l["attacker"]
			if not played or b.effect_centroid() == Vector3.INF:
				bad.append("%s espelho=%s sem nós" % [e, mirror])
			elif b.effect_centroid().distance_to(want) > 3.0:
				bad.append("%s espelho=%s longe: %s vs %s" % [e, mirror, b.effect_centroid(), want])
			b.queue_free()
			await process_frame
	ok(bad.is_empty(), "9 efeitos × 2 lados criam nós perto do ponto certo %s" % [bad])
	var b2 := _bridge()
	ok(not b2.play("inexistente"), "efeito desconhecido é recusado")
	b2.queue_free()


func t_sizes() -> void:
	print("\n-- Alvos de tamanhos diferentes --")
	var ys := []
	for h in [1.0, 2.4, 4.0]:
		var b := _bridge()
		b.set_layout(8.4, 2.0, h, false)
		b.play("rakunda")
		await process_frame
		await process_frame
		ys.append(b.effect_centroid().y)
		b.queue_free()
		await process_frame
	ok(ys[0] < ys[1] and ys[1] < ys[2], "o efeito sobe com a altura do alvo (%s)" % [ys])


func t_clear_and_time() -> void:
	print("\n-- Limpar, reiniciar e ritmo --")
	var b := _bridge()
	b.play("megido")
	await process_frame
	ok(b.is_active() and b.scene_stats()["nodes"] > 0, "efeito ativo conta nós")
	b.clear()
	await process_frame
	ok(not b.is_active() and b.scene_stats()["nodes"] == 0, "limpar remove tudo")
	b.play("tackle")
	await process_frame
	b.play("tackle")
	await process_frame
	var n1: int = b.scene_stats()["nodes"]
	ok(n1 > 0 and n1 < 200, "reiniciar não acumula efeitos (%d nós)" % n1)
	b.set_speed(0.25)
	ok(is_equal_approx(Engine.time_scale, 0.25), "ritmo muda o time_scale")
	b.set_speed(0.0)
	ok(Engine.time_scale == 0.0, "pausa = time_scale 0")
	b.queue_free()
	await process_frame
	ok(is_equal_approx(Engine.time_scale, 1.0), "sair da cena restaura o ritmo normal")


var _adv := -1.0


func _seek_to(b: GameFxBridge, e: String, t: float) -> Dictionary:
	_adv = -1.0
	b.seek(e, t)
	var n := 0
	while _adv < 0.0 and n < 1500:
		await process_frame
		n += 1
	var out := {"frames": n, "adv": _adv, "nodes": b.scene_stats()["nodes"], "scale": Engine.time_scale, "c": b.effect_centroid()}
	Engine.time_scale = 1.0
	return out


func t_seek() -> void:
	print("
-- Busca no tempo (reinicia com a mesma semente e avança por quadros) --")
	var b := _bridge()
	b.seek_finished.connect(func(a: float) -> void: _adv = a)
	await process_frame
	var r := await _seek_to(b, "titanomachia", 0.4)
	ok(r["adv"] >= 0.3999 and r["adv"] <= 0.45, "avança até o tempo pedido, sem passar mais de 0,05 s (%.3f)" % r["adv"])
	ok(r["scale"] == 0.0, "ao chegar, pausa (time_scale 0)")
	ok(is_equal_approx(GameFxBridge.seek_step(5.0), 1.0 / 60.0) and is_equal_approx(GameFxBridge.seek_step(0.004), 0.004) and GameFxBridge.seek_step(-1.0) == 0.0, "o passo pedido por quadro é no máximo 1/60 s e nunca passa do que falta")
	ok(r["frames"] >= 6, "a busca leva vários quadros, não um salto único (%d quadros para 0,4 s)" % r["frames"])
	ok(r["nodes"] > 0, "titanomachia em 0,4 s ainda tem nós")
	var bad := []
	for e in ["megido", "titanomachia", "media", "tarukaja", "rakunda"]:  # sukunda fica de fora: nasce um nó entre 0,25 e 0,4 s e, conforme o quadro, a contagem varia em 1 (limitação registrada na §34)
		var a1 := await _seek_to(b, e, 0.25)
		var a2 := await _seek_to(b, e, 0.25)
		var dc: float = (a1["c"] as Vector3).distance_to(a2["c"]) if (a1["c"] as Vector3).is_finite() and (a2["c"] as Vector3).is_finite() else 0.0
		print("    [info] %s: nós %d/%d, centro difere %.3f m, avançou %.3f/%.3f" % [e, a1["nodes"], a2["nodes"], dc, a1["adv"], a2["adv"]])
		if a1["nodes"] != a2["nodes"] or dc > 0.3:
			bad.append(e)
	ok(bad.is_empty(), "buscar duas vezes o mesmo tempo (0,25 s) dá o mesmo estado (mesmos nós; centro a menos de 0,3 m, pois o tempo varia até um quadro) %s" % [bad])
	var late := await _seek_to(b, "media", 1.5)
	ok(late["nodes"] == 0, "depois do fim do efeito não sobra nada (media em 1,5 s)")
	var early := await _seek_to(b, "media", 0.15)
	ok(early["nodes"] > late["nodes"], "voltar no tempo recria o efeito (0,15 s tem nós)")
	var zero := await _seek_to(b, "megido", 0.0)
	ok(zero["nodes"] >= 0 and zero["scale"] == 0.0, "t = 0 deixa pausado")
	b.set_layout(8.4, 2.0, 2.4, true)
	var mir := await _seek_to(b, "megido", 0.15)
	b.set_layout(8.4, 2.0, 2.4, false)
	var nor := await _seek_to(b, "megido", 0.15)
	ok((mir["c"] as Vector3).x < 0.0 and (nor["c"] as Vector3).x > 0.0, "a busca respeita o lado: espelhado à esquerda, normal à direita")
	ok(not b.seek("inexistente", 0.3) and not b.is_seeking(), "efeito desconhecido não inicia busca")
	b.queue_free()
	await process_frame
	ok(is_equal_approx(Engine.time_scale, 1.0), "sair da cena restaura o ritmo")


func t_lab_ui() -> void:
	print("
-- Seção na interface do laboratório (cena real) --")
	var lab: Node = load("res://scenes/motion_lab/motion_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	var g: GameFxBridge = lab.game_fx
	ok(g != null and g._ui_effect != null and g._ui_effect.item_count == GameFxBridge.EFFECTS.size(), "a seção existe e lista os 9 efeitos")
	var d0: float = lab._dist
	g.set_layout(12.0, 2.0, 2.4, false)
	g.request_framing()
	ok(lab._dist > d0 and is_equal_approx(lab._dist, 12.0 * 2.1), "Enquadrar afasta a câmera conforme a distância dos dois (%.1f)" % lab._dist)
	g.composition_visible_requested.emit(false)
	ok(not lab.view_set.visible, "Ocultar a composição esconde o conjunto de desenho")
	g.composition_visible_requested.emit(true)
	ok(lab.view_set.visible, "desmarcar volta a mostrar")
	# Disparar depois de uma busca (pausado) volta ao ritmo normal
	g._ui_effect.selected = GameFxBridge.EFFECTS.find("megido")
	_adv = -1.0
	g.seek_finished.connect(func(a: float) -> void: _adv = a)
	g.seek("megido", 0.2)
	var n := 0
	while _adv < 0.0 and n < 600:
		await process_frame
		n += 1
	ok(Engine.time_scale == 0.0, "depois da busca o laboratório está pausado")
	g.fire_from_ui()
	ok(is_equal_approx(Engine.time_scale, 1.0) and g.is_active(), "Disparar tira da pausa e dispara o efeito escolhido")
	# o slider de busca pede uma busca e ela chega ao tempo
	_adv = -1.0
	g._ui_time.value = 0.3
	n = 0
	while _adv < 0.0 and n < 600:
		await process_frame
		n += 1
	ok(_adv >= 0.2999 and _adv < 0.35, "mexer no slider de tempo busca o efeito até lá (%.3f)" % _adv)
	g.seek("rakunda", 0.45)
	ok(g._ui_effect.selected == GameFxBridge.EFFECTS.find("rakunda") and is_equal_approx(g._ui_time.value, 0.45), "a interface acompanha o efeito e o tempo buscados por código (seletor e slider)")
	Engine.time_scale = 1.0
	lab.queue_free()
	await process_frame
