class_name MotionLooks
extends RefCounted
## Motion Composer V1.2 (D-323): biblioteca de ACABAMENTOS ESTILIZADOS por elemento (fogo, água, terra, ar). Cada "look" é só
## dado: os uniforms dos shaders mc_surface / mc_spark / mc_puff / mc_halo / mc_mark. Estilo do jogo (D-038): cel-shading em
## bandas duras, com volume (lado sombreado, borda clara, gradiente por idade). Trocar o elemento troca a linguagem visual
## de uma receita sem mexer no movimento (movimento e aparência são independentes, spec 2.1). Nada aqui conhece
## personagem, time ou lado (D-235).

const ELEMENTS := ["fire", "water", "earth", "air", "electric"]  ## V1.11 (D-957): electric = spark look only; other kinds fall back to fire


static func _c(r: float, g: float, b: float) -> Color:
	return Color(r, g, b, 1.0)


## kind: "surface" | "spark" | "puff" | "halo" | "mark". Devolve uma cópia (pode ser alterada pelo chamador).
static func get_look(kind: String, element: String) -> Dictionary:
	var e := element if element in ELEMENTS else "fire"
	match kind:
		"surface":
			return _surface(e).duplicate()
		"spark":
			return _spark(e).duplicate()
		"puff":
			return _puff(e).duplicate()
		"halo":
			return _halo(e).duplicate()
		"mark":
			return _mark(e).duplicate()
	return {}


static func _surface(e: String) -> Dictionary:
	match e:
		"water":
			# Lâminas e jatos: azul fundo -> ciano -> espuma branca na crista; ondulam e escorrem; a cauda se desfaz em gotas.
			return {"c0": _c(0.04, 0.16, 0.42), "c1": _c(0.08, 0.38, 0.75), "c2": _c(0.2, 0.62, 0.92), "c3": _c(0.58, 0.88, 1.0), "c4": _c(0.95, 1.0, 1.0),
				"bands": 5.0, "core_sharp": 1.6, "noise_amp": 0.55, "age_cool": 0.45, "tail_age": 0.4,
				"shade_amount": 0.55, "shade_tint": _c(0.35, 0.5, 0.8), "rim_amount": 1.0, "rim_width": 0.22, "rim_color": _c(0.96, 1.0, 1.0),
				"flow": 4.2, "noise_scale": 3.0, "swirl": 0.35, "lick": 0.22, "rise": 0.0, "wave_amp": 0.1, "wave_freq": 4.0, "wave_speed": 5.0,
				"tail_erode": 0.4, "erode_edge_color": _c(0.7, 0.92, 1.0)}
		"earth":
			# Blocos: marrom escuro -> areia, faces bem sombreadas, quase sem escorrer, borda clara de aresta.
			return {"c0": _c(0.18, 0.12, 0.08), "c1": _c(0.35, 0.24, 0.15), "c2": _c(0.52, 0.38, 0.24), "c3": _c(0.7, 0.56, 0.37), "c4": _c(0.86, 0.76, 0.55),
				"bands": 4.0, "core_sharp": 1.1, "noise_amp": 0.5, "age_cool": 0.5, "tail_age": 0.3,
				"shade_amount": 0.8, "shade_tint": _c(0.5, 0.4, 0.45), "rim_amount": 0.35, "rim_width": 0.2, "rim_color": _c(0.95, 0.85, 0.62),
				"flow": 0.3, "noise_scale": 2.0, "swirl": 0.0, "lick": 0.04, "rise": 0.0, "wave_amp": 0.0, "pulse_amp": 0.0,
				"tail_erode": 0.15, "erode_edge_color": _c(0.12, 0.08, 0.05)}
		"air":
			# Fitas de vento: quase brancas, finas, esverdeadas na borda, rápidas e se desfazendo em listras.
			return {"c0": _c(0.5, 0.74, 0.8), "c1": _c(0.7, 0.88, 0.92), "c2": _c(0.84, 0.95, 0.96), "c3": _c(0.95, 1.0, 1.0), "c4": _c(1.0, 1.0, 1.0),
				"bands": 3.0, "core_sharp": 1.4, "noise_amp": 0.45, "age_cool": 0.5, "tail_age": 0.6,
				"shade_amount": 0.2, "shade_tint": _c(0.7, 0.85, 0.9), "rim_amount": 0.6, "rim_width": 0.3, "rim_color": _c(1.0, 1.0, 1.0),
				"flow": 6.5, "noise_scale": 3.5, "swirl": 1.2, "lick": 0.18, "rise": 0.0, "wave_amp": 0.06, "wave_freq": 5.0, "wave_speed": 6.0,
				"tail_erode": 0.85, "erode_edge_color": _c(0.6, 0.85, 0.9)}
	# fogo
	return {"c0": _c(0.62, 0.1, 0.03), "c1": _c(0.93, 0.24, 0.04), "c2": _c(1.0, 0.5, 0.06), "c3": _c(1.0, 0.8, 0.2), "c4": _c(1.0, 0.97, 0.72),
		"bands": 5.0, "core_sharp": 2.4, "noise_amp": 0.7, "age_cool": 0.6, "tail_age": 0.5,
		"shade_amount": 0.3, "shade_tint": _c(0.6, 0.35, 0.3), "rim_amount": 0.0,
		"flow": 3.4, "noise_scale": 2.4, "swirl": 0.7, "lick": 0.9, "rise": 0.9, "wave_amp": 0.0,
		"tail_erode": 0.75, "erode_edge_color": _c(0.4, 0.07, 0.02)}


static func _spark(e: String) -> Dictionary:
	match e:
		"water":
			return {"hot": _c(0.9, 1.0, 1.0), "cool": _c(0.25, 0.65, 1.0), "energy": 1.6, "hard": 1.0}
		"earth":
			return {"hot": _c(0.95, 0.85, 0.6), "cool": _c(0.55, 0.38, 0.22), "energy": 1.2, "hard": 1.0}
		"air":
			return {"hot": _c(1.0, 1.0, 1.0), "cool": _c(0.6, 0.9, 0.95), "energy": 1.3, "hard": 0.0}
		"electric":
			return {"hot": _c(1.0, 0.97, 0.78), "cool": _c(0.98, 0.7, 0.12), "energy": 1.8, "hard": 1.0}
	return {"hot": _c(1.0, 0.85, 0.45), "cool": _c(1.0, 0.28, 0.05), "energy": 2.0, "hard": 0.0}


static func _puff(e: String) -> Dictionary:
	match e:
		"water":
			return {"light_col": _c(0.92, 0.98, 1.0), "mid_col": _c(0.62, 0.82, 0.96), "dark_col": _c(0.4, 0.6, 0.85), "alpha": 0.7, "churn": 0.5}
		"earth":
			return {"light_col": _c(0.78, 0.66, 0.5), "mid_col": _c(0.56, 0.46, 0.34), "dark_col": _c(0.36, 0.29, 0.22), "alpha": 0.85, "churn": 0.7}
		"air":
			return {"light_col": _c(1.0, 1.0, 1.0), "mid_col": _c(0.82, 0.93, 0.95), "dark_col": _c(0.62, 0.8, 0.85), "alpha": 0.5, "churn": 0.45}
	return {"light_col": _c(0.62, 0.6, 0.6), "mid_col": _c(0.42, 0.4, 0.42), "dark_col": _c(0.26, 0.25, 0.28), "alpha": 0.8, "churn": 0.6}


static func _halo(e: String) -> Dictionary:
	match e:
		"water":
			return {"color": _c(0.3, 0.7, 1.0), "bands": 0.0, "falloff": 2.4}
		"earth":
			return {"color": _c(0.8, 0.6, 0.35), "bands": 0.0, "falloff": 2.6}
		"air":
			return {"color": _c(0.8, 1.0, 1.0), "bands": 0.0, "falloff": 2.6}
	return {"color": _c(1.0, 0.6, 0.2), "bands": 0.0, "falloff": 2.6}


static func _mark(e: String) -> Dictionary:
	match e:
		"water":
			return {"base_col": _c(0.05, 0.16, 0.32), "line_col": _c(0.65, 0.92, 1.0), "rim_col": _c(0.3, 0.6, 0.9), "line_amount": 0.5, "rim_amount": 1.0, "alpha": 0.7, "radial": 0.0}
		"earth":
			return {"base_col": _c(0.1, 0.07, 0.05), "line_col": _c(0.78, 0.56, 0.3), "rim_col": _c(0.32, 0.23, 0.15), "line_amount": 0.7, "rim_amount": 0.8, "alpha": 0.9, "cracks": 7.0, "radial": 1.0}
		"air":
			return {"base_col": _c(0.8, 0.86, 0.86), "line_col": _c(1.0, 1.0, 1.0), "rim_col": _c(0.9, 0.95, 0.95), "line_amount": 0.9, "rim_amount": 0.2, "alpha": 0.35, "cracks": 11.0, "radial": 1.0}
	return {"base_col": _c(0.04, 0.03, 0.03), "line_col": _c(1.0, 0.45, 0.1), "rim_col": _c(0.2, 0.12, 0.08), "line_amount": 0.8, "rim_amount": 0.5, "alpha": 0.85, "cracks": 5.0, "radial": 1.0}
