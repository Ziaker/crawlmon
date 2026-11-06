class_name MotionGallery
extends RefCounted
## Motion Composer V1.2 (D-323): galeria de AVALIAÇÃO. Oito amostras neutras (NÃO são Moves) que exercitam cada forma, cada
## representação e os campos novos, para um elemento qualquer (fogo, água, terra, ar). Serve às ferramentas de percepção:
## comparar elementos, fundos, vistas espelhadas e sementes. Não substitui nem altera nenhum efeito; não decide dano,
## alcance nem duração (D-019). Tudo é derivado de um contexto (origem, eixo), nunca de personagem, time ou lado (D-235).

const CELLS := ["tube", "ribbon", "arc", "shell", "fragments", "drops", "sparks", "puff_mark"]


static func _layer(id: StringName, behavior: StringName, op: int, params: Dictionary) -> MotionLayer:
	return MotionPresets._layer(id, behavior, op, params)


static func _cells(element: String, seed_value: int) -> Dictionary:
	var out := {}
	var el := {"element": element}
	# 1. tubo curvo: corpo que serpenteia e flui (M03 + M24), nasce (M17) e se dissolve na ponta (M18)
	var tube := MotionPresets._c(&"g_tube", seed_value, 70, [
		_layer(&"snake", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.22, "wavelength": 1.3, "speed": 2.4, "axis_deg": 90.0}),
		_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.2, "intensity": 0.1, "time_hz": 0.6, "seed": 2}),
		MotionPresets._grow(0.45),
		MotionPresets._dissolve(0.7, 0.45, 0.2)] as Array[MotionLayer])
	out["tube"] = [[tube, [MotionRep.make("surface", {"shape": "tube", "element": element, "radius": 0.3, "profile_pow": 0.8, "head_bulge": 0.2})], {"length": 3.0}]]
	# 2. fita de vento/água: espiral (M01) com fita voltada para a câmera
	var rib := MotionPresets._c(&"g_ribbon", seed_value + 1, 60, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.55, "radius_growth": -0.2, "pitch": 0.55, "turns": 2.0, "direction": 1, "spin_deg_s": 160.0}),
		MotionPresets._grow(0.5), MotionPresets._dissolve(0.75, 0.4, 0.2)] as Array[MotionLayer])
	out["ribbon"] = [[rib, [MotionRep.make("surface", {"shape": "ribbon", "element": element, "radius": 0.2, "profile_pow": 0.7, "head_bulge": 0.0})], {"length": 3.0}]]
	# 3. arco / meia-lua (corte): meia volta de hélice (M01) com largura que afina nas duas pontas
	var arc := MotionPresets._c(&"g_arc", seed_value + 2, 40, [
		_layer(&"half", &"M01", MotionTypes.Op.REPLACE, {"radius": 1.1, "radius_growth": 0.0, "pitch": 0.01, "turns": 0.5, "direction": 1, "phase_deg": 180.0}),
		MotionPresets._grow(0.35), MotionPresets._dissolve(0.55, 0.5, 0.15)] as Array[MotionLayer])
	out["arc"] = [[arc, [MotionRep.make("surface", {"shape": "arc", "element": element, "radius": 0.28, "profile_pow": 0.8})], {"length": 2.0}]]
	# 4. casca (cone/cúpula): cresce (M17: a largura da ponta) e some
	var shell := MotionPresets._c(&"g_shell", seed_value + 3, 4, [
		MotionPresets._grow(0.5), MotionPresets._dissolve(0.8, 0.4)] as Array[MotionLayer])
	out["shell"] = [[shell, [MotionRep.make("surface", {"shape": "shell", "element": element, "radius": 0.9, "profile_pow": 0.7, "sides": 20})], {"length": 1.7}]]
	# 5. fragmentos: explosão direcional (M16) + queda (M23) + arrasto (M22)
	var frag_layers: Array[MotionLayer] = MotionPresets._burst(18, 55.0, 2.0, 1.1, 1.6, 0.9)
	frag_layers.append(_layer(&"gravity", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": 4.0, "spread": 0.3, "t_start": 0.3}))
	var frag := MotionPresets._c(&"g_frag", seed_value + 4, 18, frag_layers)
	out["fragments"] = [[frag, [MotionRep.make("surface", {"shape": "fragments", "element": element, "size": 0.2, "spin": 5.0, "size_jitter": 0.5})], {"length": 0.01}]]
	# 6. gotas: explosão em cone + gravidade, esferas esticadas ao longo do movimento
	var drop_layers: Array[MotionLayer] = MotionPresets._burst(24, 40.0, 2.2, 1.0, 1.5, 0.9)
	drop_layers.append(_layer(&"gravity", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": 6.0, "spread": 0.3, "t_start": 0.2}))
	var dr := MotionPresets._c(&"g_drops", seed_value + 5, 24, drop_layers)
	out["drops"] = [[dr, [MotionRep.make("drops", {"element": element, "size": 0.07, "stretch": 2.2, "size_jitter": 0.5})], {"length": 0.01}]]
	# 7. fagulhas com arrasto (M22) e halo
	var sp_layers: Array[MotionLayer] = MotionPresets._burst(40, 50.0, 1.6, 0.9, 1.4, 0.9)
	sp_layers.append(_layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "speed": 2.0, "drag": 3.0, "spread": 0.4, "t_start": 0.0}))
	var sparks := MotionPresets._c(&"g_sparks", seed_value + 6, 40, sp_layers)
	var halo := MotionPresets._c(&"g_halo", seed_value + 7, 2, [MotionPresets._grow(0.2), MotionPresets._dissolve(0.3, 0.6)] as Array[MotionLayer])
	out["sparks"] = [
		[sparks, [MotionRep.make("spark", {"element": element, "size": 0.07, "stretch": 3.0, "size_jitter": 0.5})], {"length": 0.01}],
		[halo, [MotionRep.make("halo", {"element": element, "size": 2.2, "strength": 0.8})], {"length": 0.01}]]
	# 8. nuvem estilizada (M16 + M21 fluxo) e marca no chão
	var pf_layers: Array[MotionLayer] = MotionPresets._burst(6, 35.0, 1.0, 1.1, 1.4, 0.7)
	pf_layers.append(_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 1, 0), "center": Vector3.ZERO, "distance": 0.8, "radius": 0.0, "core_radius": 0.0, "edge_noise": 0.0, "seed": 0, "t_start": 0.0, "t_duration": 1.1}))
	var puffs := MotionPresets._c(&"g_puff", seed_value + 8, 6, pf_layers)
	var mark := MotionPresets._c(&"g_mark", seed_value + 9, 2, [MotionPresets._dissolve(0.5, 0.8)] as Array[MotionLayer])
	out["puff_mark"] = [
		[puffs, [MotionRep.make("puff", {"element": element, "size": 0.55, "drift": Vector3(0, 0.4, 0)})], {"length": 0.01}],
		[mark, [MotionRep.make("mark", {"element": element, "size": 0.85})], {"length": 0.01}]]
	return out


## Um MotionEffect por célula (fase "impact"). Devolve { nome: MotionEffect }.
static func build(element: String, seed_value: int) -> Dictionary:
	var out := {}
	var cells := _cells(element, seed_value)
	for name in cells.keys():
		var fx := MotionEffect.new()
		for spec in cells[name]:
			fx.add("impact", spec[0], spec[1], spec[2])
		out[name] = fx
	return out
