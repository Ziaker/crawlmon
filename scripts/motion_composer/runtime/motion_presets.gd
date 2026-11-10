class_name MotionPresets
extends RefCounted
## D-308 / D-322: compositions (data) for the element moves, built from the V1 behaviors. A preset is only a list of
## layers; changing a number here changes the look of every move that uses it, on any side (D-235).


static func _layer(id: StringName, behavior: StringName, op: int, params: Dictionary, time_offset := 0.0) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = behavior
	l.op = op
	l.params = params
	l.time_offset = time_offset
	return l


static func _comp(id: StringName, seed_value: int, layers: Array[MotionLayer]) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = id
	c.seed = seed_value
	c.sample_count = 40
	c.duration = 3.0
	for l in layers:
		c.add_layer(l)
	return c


static func _c(id: StringName, seed_value: int, count: int, layers: Array[MotionLayer]) -> MotionComposition:
	var c := _comp(id, seed_value, layers)
	c.sample_count = count
	return c


static func _grow(t_duration: float, t_start := 0.0) -> MotionLayer:
	return _layer(&"grow", &"M17", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"direction": 0, "t_start": t_start, "t_duration": t_duration, "curve": 1.0, "width": 0.1, "jitter": 0.0,
		"affect_visibility": false, "affect_width": true, "affect_intensity": false, "affect_opacity": false})


static func _dissolve(t_start: float, t_duration: float, jitter := 0.0) -> MotionLayer:
	return _layer(&"dissolve", &"M18", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"direction": 0, "t_start": t_start, "t_duration": t_duration, "curve": 1.0, "width": 0.25, "jitter": jitter,
		"affect_visibility": false, "affect_width": false, "affect_intensity": false, "affect_opacity": true})


## A directional burst (M16) needs TWO layers, as the composer's operations dictate: one OFFSET that moves the samples
## along the cone, and one MULTIPLY_ATTRIBUTE that makes them dissipate (opacity). OFFSET alone never touches opacity.
static func _burst(_count: int, cone_deg: float, distance: float, t_duration: float, curve := 2.0, distribution := 0.9) -> Array[MotionLayer]:
	var params := {"direction": Vector3(0, 0, 1), "cone_deg": cone_deg, "distance": distance, "distribution": distribution,
		"t_start": 0.0, "t_duration": t_duration, "curve": curve, "dissipate": 1.0}
	var move := _layer(&"burst_move", &"M16", MotionTypes.Op.OFFSET, params)
	# They stay solid while they fly and dissipate during the last part of the flight.
	var fade_params := params.duplicate()
	fade_params["t_start"] = 0.3 * t_duration
	fade_params["t_duration"] = 0.7 * t_duration
	fade_params["curve"] = 1.0
	var fade := _layer(&"burst_fade", &"M16", MotionTypes.Op.MULTIPLY_ATTRIBUTE, fade_params)
	var out: Array[MotionLayer] = [move, fade]
	return out


# --- Fire, rebuilt from scratch (D-322): real 3D flame tubes and spheres (MotionMesh + mc_flame_body), game flipbooks and
# --- ember sprites, every motion a composition of the Motion Composer. All sizes are in METRES (the same in both views).

const FIRE_BODY := {"flow": 3.4, "lick": 0.9, "rise": 0.9, "noise_scale": 2.4, "swirl": 0.7, "tail_erode": 0.75, "core_sharp": 2.6, "bias": -0.04}
const FIRE_BALL := {"flow": 2.4, "lick": 0.7, "rise": 0.6, "noise_scale": 1.6, "swirl": 0.4, "head_pos": 0.92, "core_sharp": 2.4}
const FIRE_THIN := {"flow": 5.5, "lick": 0.5, "rise": 0.3, "noise_scale": 4.0, "swirl": 1.0, "bias": -0.08, "tail_erode": 0.5, "core_sharp": 1.6}
const FIRE_TONGUE := {"flow": 4.0, "lick": 0.7, "rise": 1.0, "noise_scale": 2.6, "swirl": 0.8, "tail_erode": 0.8, "core_sharp": 2.2}


## The flame body: a long strand that snakes, flutters, shakes and sags upward (heat rising).
static func fire_body(seed_value: int) -> MotionComposition:
	var c := _comp(&"fire_body", seed_value, [
		_layer(&"snake", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.28, "wavelength": 1.6, "speed": 2.6, "axis_deg": 90.0}),
		_layer(&"flutter", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.12, "wavelength": 0.6, "speed": -4.5, "axis_deg": 0.0, "phase_deg": 40.0}),
		_layer(&"shake", &"M07", MotionTypes.Op.OFFSET, {"scale": 0.5, "intensity": 0.16, "time_hz": 3.0, "seed": seed_value & 0xFFFF}),
		_layer(&"rise", &"M09", MotionTypes.Op.DEFORM, {"amount_deg": 18.0, "plane_deg": 90.0, "center": 0.5, "extent": 1.0}),
	] as Array[MotionLayer])
	c.sample_count = 120
	return c


static func _helix(seed_value: int, radius: float, growth: float, pitch: float, turns: float, direction: int, phase_deg: float, spin: float, extra: Array[MotionLayer]) -> MotionComposition:
	var layers: Array[MotionLayer] = [_layer(&"swirl", &"M01", MotionTypes.Op.REPLACE, {"radius": radius, "radius_growth": growth, "pitch": pitch, "turns": turns,
		"direction": direction, "phase_deg": phase_deg, "spin_deg_s": spin})]
	layers.append_array(extra)
	return _c(&"helix", seed_value, 72, layers)


# ---------------------------------------------------------------------------------------------------------------------
# FOGO v3 (D-332, D-308): CADA CHAMA É UMA COMPOSIÇÃO DO COMPOSITOR, com comportamentos e parâmetros próprios.
# Tutoriais (vfxapprentice, Mirza Beig, godotshaders): curva em S, base grossa e ponta fina, mordidas em C, tempo quantizado, ciclo de
# vida por chama com semente nova a cada ciclo. Aqui: a curva em S é M03, a inclinação é M09, o fluxo orgânico é M24, o "respirar" é M12
# (um inchaço que viaja pela chama), o nascimento é M17 e a morte pela ponta é M18. O shader `mc_fire_ribbon` só pinta (degraus chapados,
# preto de fuligem, opacidade variável). Nada de aparência na classe do Move (ElementMoveVfx só entrega posições e relógios).
# ---------------------------------------------------------------------------------------------------------------------

static func _sgn(r: RandomNumberGenerator) -> float:
	return 1.0 if r.randf() < 0.5 else -1.0


## UMA chama = uma composição, tudo sorteado por `seed_value` (cada chama, cada ciclo, é outra).
static func flame_comp(seed_value: int, height: float, life: float, die_from := Vector2(0.5, 0.72), die_dur := Vector2(0.24, 0.4)) -> MotionComposition:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var plane := r.randf_range(0.0, 360.0)
	var layers: Array[MotionLayer] = [
		_layer(&"swoop", &"M03", MotionTypes.Op.OFFSET, {"amplitude": height * r.randf_range(0.07, 0.3), "wavelength": height * r.randf_range(0.5, 1.6),
			"speed": r.randf_range(1.2, 4.8) * _sgn(r), "axis_deg": plane, "phase_deg": r.randf_range(0.0, 360.0)}),
		_layer(&"lean", &"M09", MotionTypes.Op.DEFORM, {"amount_deg": r.randf_range(8.0, 48.0) * _sgn(r), "plane_deg": plane + r.randf_range(-40.0, 40.0),
			"center": r.randf_range(0.25, 0.75), "extent": 1.0}),
		_layer(&"flow", &"M24", MotionTypes.Op.OFFSET, {"scale": height * r.randf_range(0.6, 1.5), "intensity": height * r.randf_range(0.025, 0.12),
			"time_hz": r.randf_range(0.4, 2.2), "seed": seed_value & 0xFFFF}),
		_layer(&"breathe", &"M12", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"speed": r.randf_range(0.5, 1.8), "start": r.randf_range(-0.3, 0.2), "width": r.randf_range(0.12, 0.35),
			"amplitude": 1.0, "thickness_gain": r.randf_range(0.2, 0.9), "tail": r.randf_range(1.5, 5.0), "loop": true}),
		_layer(&"grow", &"M17", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"direction": 0, "t_start": 0.0, "t_duration": life * r.randf_range(0.14, 0.34), "curve": r.randf_range(0.7, 1.6),
			"width": 0.12, "jitter": 0.0, "affect_visibility": false, "affect_width": true, "affect_intensity": false, "affect_opacity": false}),
		_layer(&"die", &"M18", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"direction": 1, "t_start": life * r.randf_range(die_from.x, die_from.y), "t_duration": life * r.randf_range(die_dur.x, die_dur.y),
			"curve": r.randf_range(0.8, 1.5), "width": r.randf_range(0.18, 0.4), "jitter": r.randf_range(0.1, 0.55), "affect_visibility": false,
			"affect_width": true, "affect_intensity": false, "affect_opacity": true}),
	]
	var c := _c(&"flame", seed_value, 22, layers)
	c.duration = maxf(life + 0.5, 0.6)
	c.base_length = height
	return c


## Registra um SLOT de chama no efeito: a cada ciclo uma composição nova (altura, vida, posição e inclinação sorteadas).
static func _add_flame(fx: MotionEffect, phase: String, slot: int, seed_value: int, h: Vector2, life: Vector2, width: float, spread: float, tilt_deg: float, opts := {}) -> void:
	var base := seed_value * 7919 + slot * 104729
	var rr := RandomNumberGenerator.new()
	rr.seed = base
	var loop := rr.randf_range(life.x, life.y)
	var z_spread := float(opts.get("z_spread", 0.0))
	var die_from: Vector2 = opts.get("die_from", Vector2(0.5, 0.72))
	var die_dur: Vector2 = opts.get("die_dur", Vector2(0.24, 0.4))
	var factory := func(cycle: int) -> MotionComposition:
		var r := RandomNumberGenerator.new()
		r.seed = base + cycle * 15485863
		return flame_comp(base + cycle * 31, r.randf_range(h.x, h.y), loop, die_from, die_dur)
	var offset_fn := func(cycle: int) -> Vector3:
		var r := RandomNumberGenerator.new()
		r.seed = base + cycle * 2654435 + 11
		var a := r.randf_range(0.0, TAU)
		return Vector3(cos(a), sin(a), 0.0) * spread * sqrt(r.randf()) + Vector3(0, 0, r.randf_range(0.0, z_spread))
	var rot_fn := func(cycle: int) -> Basis:
		var r := RandomNumberGenerator.new()
		r.seed = base + cycle * 7777 + 5
		var a := r.randf_range(0.0, TAU)
		return Basis(Vector3(cos(a), sin(a), 0.0), deg_to_rad(r.randf_range(0.0, tilt_deg)))
	var o := {"factory": factory, "loop": loop, "cycle_phase": rr.randf(), "offset_fn": offset_fn, "rot_fn": rot_fn, "length": "keep"}
	o.merge(opts, true)
	o.erase("z_spread")
	o.erase("die_from")
	o.erase("die_dur")
	var first: MotionComposition = factory.call(0)
	fx.add(phase, first, [MotionRep.make("surface", {"shape": "flame", "shader": "mc_fire_ribbon", "radius": width, "profile_pow": 0.8, "max_rings": 22,
		"look": {"soot": 1.0}})], o)


static func _soot_puff(size: float) -> MotionRep:
	return MotionRep.make("puff", {"element": "fire", "size": size, "drift": Vector3(0, 0.6, 0),
		"look": {"light_col": Color(0.24, 0.22, 0.22), "mid_col": Color(0.12, 0.11, 0.11), "dark_col": Color(0.04, 0.035, 0.035), "alpha": 0.55}})


static func _spark_layers(count: int, cone: float, dist: float, dur: float, speed: float, seed_v: int) -> Array[MotionLayer]:
	var l: Array[MotionLayer] = _burst(count, cone, dist, dur, 1.3, 0.95)
	l.append(_layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "speed": speed, "drag": 1.6, "spread": 0.6, "t_start": 0.0}))
	l.append(_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.9, "intensity": 0.28, "time_hz": 0.9, "seed": seed_v}))
	return l


## Escala do fogo em METROS do mundo (fixa, igual nas duas vistas, D-308 item 6 e D-334). 1.0 = o tamanho da versão v3 aprovada como base;
## o criador mandou aumentar SÓ o vórtice do release e o impacto (médio), não tudo.
const FIRE_K := 1.0


static func fire_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var K := FIRE_K
	var spark := MotionRep.make("spark", {"element": "fire", "size": 0.05 * K, "size_jitter": 0.5, "trail": true, "trail_gain": 0.75})
	var soot := _soot_puff(0.4 * K)
	# ================================================================ WIND-UP: a bola de fogo da carga (fica até o disparo)
	fx.add("windup", _c(&"charge_halo", s, 2, [] as Array[MotionLayer]), [MotionRep.make("halo", {"element": "fire", "size": 1.2 * K, "strength": 0.6})], {"length": 0.01, "dir": "up", "z_offset": 0.45 * K})
	for i in 9:
		_add_flame(fx, "windup", i, s, Vector2(0.55, 1.15) * K, Vector2(0.45, 0.9), 0.2 * K, 0.28 * K, 24.0, {"dir": "up"})
	fx.add("windup", _c(&"charge_sparks", s + 1, 18, _spark_layers(18, 70.0, 1.6 * K, 0.9, 1.6 * K, 4)), [spark], {"length": 0.01, "dir": "up", "z_offset": 0.4 * K, "trail_dt": 0.05})
	# ================================================================ TRAVEL: a mesma bola vira o tiro; as chamas escorrem para trás
	fx.add("travel", _c(&"head_halo", s + 2, 2, [] as Array[MotionLayer]), [MotionRep.make("halo", {"element": "fire", "size": 1.5 * K, "strength": 0.7})], {"frame": "head", "length": 0.01, "until_landed": true})
	for i in 8:  # cabeça: chamas curtas e rápidas em torno do ponto, apontando para trás
		_add_flame(fx, "travel", i, s + 10, Vector2(0.8, 1.5) * K, Vector2(0.3, 0.6), 0.22 * K, 0.28 * K, 26.0, {"frame": "head", "back": true, "until_landed": true})
	for i in 10:  # rastro: chamas mais finas e compridas atrás da cabeça, em distâncias diferentes
		_add_flame(fx, "travel", 20 + i, s + 20, Vector2(0.9, 1.9) * K, Vector2(0.5, 1.0), 0.14 * K, 0.2 * K, 18.0, {"frame": "head", "back": true, "until_landed": true, "z_spread": 3.4 * K})
	# vórtices (D-308): seguem a bola e descem por 0,2 s, depois somem em brasa e fumaça em 0,5 s
	for i in 3:
		var vortex := _helix(s + 40 + i, 0.6 * K, -0.2 * K, 1.1 * K, 2.0, 1 if i % 2 == 0 else -1, 120.0 * float(i), 900.0, [_dissolve(0.2, 0.5, 0.8)] as Array[MotionLayer])
		fx.add("travel", vortex, [
			MotionRep.make("surface", {"shape": "flame", "shader": "mc_fire_ribbon", "radius": 0.07 * K, "profile_pow": 0.5, "max_rings": 40}),
			MotionRep.make("spark", {"element": "fire", "size": 0.06 * K, "size_jitter": 0.5, "stretch": 1.0}),
			_soot_puff(0.35 * K)],
			{"frame": "head", "back": true, "length": 1.5 * K, "window": Vector2(0.0, 0.5), "slide": Vector2(0.0, 0.5), "follow_until": 0.2})
	fx.add("travel", _c(&"travel_sparks", s + 50, 30, _spark_layers(30, 38.0, 2.6 * K, 1.2, 2.2 * K, 8)), [spark], {"frame": "head", "back": true, "length": 0.01, "trail_dt": 0.05})
	# ================================================================ IMPACTO: médio, e a opacidade cai durante toda a duração
	var IK := 1.8
	var fade_all := {"die_from": Vector2(0.05, 0.15), "die_dur": Vector2(0.7, 0.85)}
	fx.add("impact", _c(&"impact_halo", s + 60, 2, [_grow(0.1), _dissolve(0.1, 0.7)] as Array[MotionLayer]), [MotionRep.make("halo", {"element": "fire", "size": 1.8 * IK, "strength": 1.0})], {"length": 0.01, "z_offset": -0.3 * IK})
	for i in 10:
		var o1 := {"once": true, "start": float(i) * 0.012, "z_offset": -0.2 * IK}
		o1.merge(fade_all)
		_add_flame(fx, "impact", i, s + 70, Vector2(0.9, 1.7) * IK, Vector2(0.7, 1.0), 0.24 * IK, 0.34 * IK, 38.0, o1)
	for i in 5:
		var o2 := {"once": true, "dir": "up", "start": 0.1 + float(i) * 0.05}
		o2.merge(fade_all)
		_add_flame(fx, "impact", 20 + i, s + 80, Vector2(0.6, 1.2) * IK, Vector2(0.8, 1.2), 0.18 * IK, 0.6 * IK, 10.0, o2)
	fx.add("impact", _c(&"impact_sparks", s + 90, 44, _spark_layers(44, 46.0, 3.6 * IK, 1.3, 2.8 * IK, 9)), [spark], {"length": 0.01, "trail_dt": 0.05})
	var im_layers: Array[MotionLayer] = _burst(7, 30.0, 2.0 * IK, 1.8, 1.4, 0.7)
	im_layers.append(_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.4 * IK, "intensity": 0.3 * IK, "time_hz": 0.4, "seed": 2}))
	fx.add("impact", _c(&"impact_smoke", s + 91, 7, im_layers), [_soot_puff(0.7 * IK)], {"length": 0.01, "start": 0.15})
	fx.add("impact", _c(&"burn_mark", s + 92, 2, [_dissolve(0.5, 1.4)] as Array[MotionLayer]), [MotionRep.make("mark", {"element": "fire", "size": 0.5 * IK})], {"length": 0.01})
	return fx


# ---------------------------------------------------------------------------------------------------------------------
# SPLITTER FLAMES (D-236, atelier.html D-331): efeitos do protótipo HTML implementados no Godot sobre o Motion Composer, mantendo o
# visual do atelier e melhorando com shaders do Godot (fbm no lugar de simplex, bandas de cel opcionais, tempo explícito).
# Fases (tempos do atelier): WIND-UP 0,70 s (duas esferas, uma em cada mão, crescem 0,05 -> 1,05 com brasas convergindo);
# RELEASE (no instante do disparo): dois vórtices PARADOS nas mãos, expandem por 0,30 s e somem, com 26 brasas girando;
# TRAJETO: cada bola faz um arco (uma pela esquerda, outra pela direita) e converge no alvo, deixando rastro de chama que esfria em cinza;
# IMPACTO (alvo único): pilar de fogo de 1,05 s que vira cinza + 90 chamas subindo + chuva de cinzas.
# Tudo derivado do atacante e do alvo reais (D-235): mãos = origem +- lado, arco = eixo atacante->alvo; nada de personagem, time ou lado.
# ---------------------------------------------------------------------------------------------------------------------

const SPLIT_HAND := 0.7  ## afastamento lateral de cada mão em relação ao centro da carga (m)


static func splitter_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var ash_look := {"light_col": Color(0.33, 0.3, 0.3), "mid_col": Color(0.2, 0.19, 0.19), "dark_col": Color(0.09, 0.085, 0.09), "alpha": 0.85}
	for side_i in 2:
		var side := -1.0 if side_i == 0 else 1.0
		var off := Vector3(side * SPLIT_HAND, 0.0, 0.0)
		# ---------------------------------------------------------------- WIND-UP: a esfera de cada mão cresce 0,05 -> 1,05 em 0,70 s
		fx.add("windup", _c(&"sp_ball_w", s + side_i, 2, [] as Array[MotionLayer]), [
			MotionRep.make("halo", {"element": "fire", "size": 1.6, "strength": 0.7}),
			MotionRep.make("fireball", {"size": 0.42, "grow": 0.7})], {"length": 0.01, "local_offset": off})
		# brasas convergindo para a mão (35, escalonadas)
		var inward := _c(&"sp_inward", s + 10 + side_i, 35, [
			_layer(&"cloud", &"M01", MotionTypes.Op.REPLACE, {"radius": 1.15, "radius_growth": 0.0, "pitch": 1.0, "turns": 6.0, "direction": -1, "spin_deg_s": 260.0}),
			_layer(&"suck", &"M06", MotionTypes.Op.OFFSET, {"target": Vector3(0, 0, 0.5), "strength": 0.97, "reach": 4.0, "curve": 0.6, "t_start": 0.0, "t_duration": 0.5}),
			_dissolve(0.15, 0.4, 0.8)] as Array[MotionLayer])
		fx.add("windup", inward, [MotionRep.make("spark", {"element": "fire", "size": 0.09, "size_jitter": 0.5})], {"length": 1.0, "z_offset": -0.5, "local_offset": off})
		# ---------------------------------------------------------------- RELEASE: vórtice parado na mão, 0,30 s
		fx.add("travel", _c(&"sp_vortex", s + 20 + side_i, 2, [] as Array[MotionLayer]), [MotionRep.make("vortex_disc", {"duration": 0.30})], {"length": 0.01, "local_offset": off})
		var orbit := _c(&"sp_orbit", s + 30 + side_i, 26, [
			_layer(&"ring", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.45, "radius_growth": 0.0, "pitch": 0.2, "turns": 1.0, "direction": 1, "spin_deg_s": 573.0}),
			_layer(&"out", &"M25", MotionTypes.Op.OFFSET, {"center": Vector3(0, 0, 0), "strength": 0.5, "reach": 2.0, "curve": 0.3, "t_start": 0.0, "t_duration": 0.3}),
			_dissolve(0.0, 0.3, 0.7)] as Array[MotionLayer])
		fx.add("travel", orbit, [MotionRep.make("spark", {"element": "fire", "size": 0.11, "size_jitter": 0.5})], {"length": 1.0, "z_offset": -0.5, "local_offset": off})
		# ---------------------------------------------------------------- TRAJETO: arco para o lado de cada mão, convergindo no alvo
		var arc := {"frame": "head", "side_start": side * SPLIT_HAND, "arc_rel": side * 0.17, "arc_up": 0.675, "until_landed": true}
		var o1 := {"length": 0.01}
		o1.merge(arc)
		fx.add("travel", _c(&"sp_ball_f", s + 40 + side_i, 2, [] as Array[MotionLayer]), [
			MotionRep.make("halo", {"element": "fire", "size": 1.6, "strength": 0.7}),
			MotionRep.make("fireball", {"size": 0.42, "grow": 0.0})], o1)
		# rastro: chamas (flipbook do jogo) que esfriam e viram cinza ao longo da cauda
		var tail_flames := _c(&"sp_trail", s + 50 + side_i, 34, [
			_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.9, "intensity": 0.12, "time_hz": 1.2, "seed": 3 + side_i})] as Array[MotionLayer])
		var o2 := {"length": 3.2, "back": true, "trail": true}
		o2.merge(arc)
		fx.add("travel", tail_flames, [
			MotionRep.make("flipbook", {"sheet": "fire", "size": 0.7, "energy": 0.9, "color": Color(1.0, 0.45, 0.12, 1.0), "age_u": true}),
			MotionRep.make("puff", {"element": "fire", "size": 0.5, "appear": 0, "age_u": true, "look": ash_look})], o2)
	# ---------------------------------------------------------------- IMPACTO (alvo único): pilar de 1,05 s, 90 chamas subindo, chuva de cinzas
	fx.add("impact", _c(&"sp_pillar", s + 60, 2, [] as Array[MotionLayer]), [MotionRep.make("pillar", {"duration": 1.05})], {"length": 0.01, "ground": true})
	fx.add("impact", _c(&"sp_flash", s + 61, 2, [_grow(0.1), _dissolve(0.1, 0.45)] as Array[MotionLayer]), [MotionRep.make("halo", {"element": "fire", "size": 4.0, "strength": 1.0})], {"length": 0.01, "ground": true, "dir": "up", "z_offset": 1.6})
	var burst: Array[MotionLayer] = _burst(90, 18.0, 8.0, 0.8, 1.4, 0.95)
	burst.append(_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.3, "intensity": 0.35, "time_hz": 0.8, "seed": 5}))
	fx.add("impact", _c(&"sp_burst", s + 62, 90, burst), [MotionRep.make("flipbook", {"sheet": "fire", "size": 1.2, "energy": 1.0, "color": Color(1.0, 0.5, 0.15, 1.0), "size_jitter": 0.4})],
		{"length": 0.01, "ground": true, "dir": "up", "z_offset": 0.2})
	var ash: Array[MotionLayer] = _burst(75, 80.0, 2.0, 1.55, 1.2, 0.95)
	ash.append(_layer(&"fall", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, -1), "gravity": 2.8, "spread": 0.4, "t_start": 0.0}))
	fx.add("impact", _c(&"sp_ash", s + 63, 75, ash), [MotionRep.make("puff", {"element": "fire", "size": 0.5, "appear": 0, "look": ash_look})],
		{"length": 0.01, "ground": true, "dir": "up", "z_offset": 2.4, "start": 0.24})
	return fx


# ---------------------------------------------------------------------------------------------------------------------
# MEDIA (D-337, atelier.html): Círculo Sagrado central + círculo individual sob cada aliado + Pilar Volumétrico
# translúcido + hélice de 90 glows + 34 cruzes + 60 sparkles contra-rotativos, e o pulso de 50 sparkles no peito no
# instante da cura. As posições vêm dos aliados reais (`anchors`), o tempo do relógio do efeito (D-019); nenhuma
# posição, time ou personagem fixo (D-235).
# ---------------------------------------------------------------------------------------------------------------------

const MEDIA_GLOW := Color(0.0, 1.0, 0.616, 1.0)      # #00ff9d
const MEDIA_GOLD := Color(1.0, 0.902, 0.427, 1.0)    # #ffe66d
const MEDIA_MINT := Color(0.494, 1.0, 0.773, 1.0)    # #7effc5
const MEDIA_LIME := Color(0.847, 1.0, 0.0, 1.0)      # #d8ff00
const MEDIA_CYAN := Color(0.0, 0.898, 1.0, 1.0)      # #00e5ff
const MEDIA_WHITE := Color(1.0, 1.0, 1.0, 1.0)


static func _atelier_emit(id: StringName, count: int, p: Dictionary) -> MotionLayer:
	return _layer(id, &"M26", MotionTypes.Op.REPLACE, p)


static func _layers(l: MotionLayer) -> Array[MotionLayer]:
	var out: Array[MotionLayer] = [l]
	return out


static func _ptcl(shape_id: int, c0: Color, c1: Color, km := 1.0, add := true, spin := 4.0) -> MotionRep:
	return MotionRep.make("atelier", {"shape": "ptcl", "size": 1.0, "look": {"shape_id": shape_id, "c0": c0, "c1": c1, "km": km, "add": add, "spin": spin}})


## Emissor de hélice/círculo do HTML: partículas nascem em um anel, sobem com `speed` e giram com `orbit_speed`.
static func _media_ring(seed_value: int, count: int, radius: float, orbit_speed: float, speed: Vector2, life: Vector2,
		size_p: Vector2, stagger: float, bell := true) -> MotionLayer:
	return _atelier_emit(&"emit", count, {
		"shape": 3, "radius": radius, "orbit_speed": orbit_speed, "radial_rate": -0.25,
		"speed_min": speed.x, "speed_max": speed.y, "life_min": life.x, "life_max": life.y,
		"size_min": size_p.x, "size_max": size_p.y, "size_bell": bell, "stagger": stagger, "drag": 0.98})


static func media_effect(seed_value: int, anchors: Array, center: Vector3, windup := 0.5) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	for i in anchors.size():
		var a: Vector3 = anchors[i]
		var off_y := 0.0
		# Círculo individual sob o aliado (raio 2,2 m, 2,4 s), 20% menos opaco em todos os lados (D-353).
		fx.add("windup", _c(&"media_circle_%d" % i, s + 1 + i, 2, [] as Array[MotionLayer]),
			[MotionRep.make("atelier", {"shape": "heal_circle", "size": 2.2, "duration": 2.4,
				"look": {"alpha_scale": 0.8}})], 
			{"length": 0.01, "world_anchor": Vector3(a.x, 0.0, a.z)})
		# Pilar volumétrico translúcido (1,85 s, atraso 0,35 + 0,08 por aliado).
		fx.add("windup", _c(&"media_pillar_%d" % i, s + 11 + i, 2, [] as Array[MotionLayer]),
			[MotionRep.make("atelier", {"shape": "heal_pillar", "size": 1.0, "duration": 1.85})],
			{"length": 0.01, "start": 0.35 + float(i) * 0.08, "world_anchor": Vector3(a.x, 0.0, a.z)})
		# 90 glows em hélice subindo (raio 1,45 m; 4,8 rad/s; vida 1,1..1,85 s; tamanho 0,55..1,15; stagger 0,75 s).
		fx.add("windup", _c(&"media_glow_%d" % i, s + 21 + i, 90,
			_layers(_media_ring(s + 21 + i, 90, 1.45, 4.8, Vector2(1.8, 3.3), Vector2(1.1, 1.85), Vector2(0.55, 1.15), 0.75))),
			[_ptcl(0, MEDIA_GLOW, MEDIA_GOLD)], {"length": 0.01, "world_anchor": Vector3(a.x, 0.1, a.z)})
		# 34 cruzes médicas luminosas (raio 1,3 m; 1,2 rad/s; vida 1,0..1,65 s; stagger 0,85 s; giro 0,6).
		fx.add("windup", _c(&"media_cross_%d" % i, s + 41 + i, 34,
			_layers(_media_ring(s + 41 + i, 34, 1.3, 1.2, Vector2(1.3, 2.4), Vector2(1.0, 1.65), Vector2(0.45, 0.85), 0.85))),
			[_ptcl(2, MEDIA_MINT, MEDIA_LIME, 0.66, true, 0.6)], {"length": 0.01, "world_anchor": Vector3(a.x, 0.25, a.z)})
		# 60 sparkles contra-rotativos (raio 1,6 m; -2,6 rad/s; vida 0,9..1,6 s; stagger 0,8 s; giro 3,5).
		fx.add("windup", _c(&"media_sparkle_%d" % i, s + 61 + i, 60,
			_layers(_media_ring(s + 61 + i, 60, 1.6, -2.6, Vector2(1.5, 3.6), Vector2(0.9, 1.6), Vector2(0.5, 1.05), 0.8))),
			[_ptcl(1, MEDIA_WHITE, MEDIA_CYAN, 0.66, true, 3.5)], {"length": 0.01, "world_anchor": Vector3(a.x, 0.2, a.z)})
		# Pulso de cura no peito (50 sparkles, esfera, no instante do cast).
		fx.add("impact", _c(&"media_pulse_%d" % i, s + 91 + i, 50,
			_layers(_atelier_emit(&"pulse", 50, {"shape": 0, "radius": 0.5, "speed_min": 2.2, "speed_max": 5.2,
				"drag": 0.94, "life_min": 0.65, "life_max": 1.15, "size_min": 0.65, "size_max": 1.25, "size_bell": false}))),
			[_ptcl(1, MEDIA_LIME, MEDIA_GLOW)], {"length": 0.01, "start": 0.0, "world_anchor": Vector3(a.x, 1.3 + off_y, a.z)})
	return fx


## D-353: the old 5.2 m team circle, taken out of Media and kept for a future superior Media
## move. Not referenced by the current game.
static func media_superior_effect(seed_value: int, center: Vector3) -> MotionEffect:
	var fx := MotionEffect.new()
	fx.add("windup", _c(&"media_superior_center", seed_value, 2, [] as Array[MotionLayer]),
		[MotionRep.make("atelier", {"shape": "heal_circle", "size": 5.2, "duration": 2.4})],
		{"length": 0.01, "world_anchor": Vector3(center.x, 0.0, center.z)})
	return fx


## D-343: Heal Gain — cruzes verdes que sobem em volta do número de cura. O M26 dá o anel, a subida,
## o arrasto e a idade de cada cruz; o flipbook `heal_cross` pinta a cruz e avança pelo `intensity`
## (t de vida do M26), não pelo fade. A origem é passada a cada quadro pelo HealGainFx, que segue o
## número real; a escala vem da distância da câmera para ler igual nas duas vistas. Não há personagem,
## time, lado nem coordenada fixa (D-235).
static func heal_gain_effect(seed_value: int, _origin: Vector3) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var count := 12
	var emit := _layer(&"heal_cross_emit", &"M26", MotionTypes.Op.REPLACE, {
		"shape": 3, "radius": 1.25, "orbit_speed": 0.90, "radial_rate": -0.08,
		"speed_min": 0.85, "speed_max": 1.55, "drag": 0.982,
		"life_min": 0.65, "life_max": 0.95, "stagger": 0.30,
		"size_min": 0.90, "size_max": 1.30, "size_bell": true,
	})
	var comp := _c(&"heal_gain_crosses", s, count, [emit])
	var reps: Array[MotionRep] = [
		MotionRep.make("flipbook", {
			"sheet": "heal_cross", "size": 1.05, "energy": 1.30,
			"color": Color(0.20, 1.0, 0.40, 1.0), "progress_source": "intensity",
		}),
	]
	fx.add("windup", comp, reps, {"length": 0.01})
	return fx


## D-377 / V1.10: Drain Spear. O efeito é um `MotionEffect` (nada de aparência na classe do Move): a lança 3D, a
## formação, a estocada, o leque de shotgun, o sifão reverso do Badge Steal, a órbita e a dissolução. Todas as posições
## vêm do atacante/alvo reais; não há personagem, time, lado nem coordenada fixa (D-235). `opts.steal_distance` é a
## distância real contato→atacante, usada só pelo sifão (o alvo do M06 é local).
static func drain_spear_effect(seed_value: int, opts := {}) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var sd := s % 999983  # M24/M21 'seed' domain is [0, 1000000]; 20261106 would be rejected and the layer dropped.
	var steal_distance := maxf(float(opts.get("steal_distance", 16.3)), 0.5)
	var with_crown := bool(opts.get("crown", true))
	var spark_look := {"hot": Color(0.92, 1.0, 1.0), "cool": Color(0.10, 0.52, 1.0), "energy": 2.6, "hard": 0.15}
	var steal_look := {"hot": Color(0.55, 0.90, 1.0), "cool": Color(0.12, 0.45, 1.0), "energy": 1.1, "hard": 0.0}
	var puff_look := {"light_col": Color(0.62, 0.86, 1.0), "mid_col": Color(0.30, 0.54, 0.80), "dark_col": Color(0.10, 0.22, 0.38), "churn": 0.5}
	var mark_look := {"base_col": Color(0.02, 0.06, 0.12), "line_col": Color(0.38, 0.95, 1.0), "rim_col": Color(0.10, 0.30, 0.50), "line_amount": 0.9, "alpha": 0.55}
	var spear_look := {"tip_color": Color(0.48, 0.92, 1.0), "edge_color": Color(0.62, 0.96, 1.0), "rim": 1.15}
	var aura_look := {"rim_color": Color(0.72, 1.0, 1.0), "flow_speed": 0.75, "rim_power": 1.8, "edge_soft": 0.32, "light_dir": Vector3(-0.35, 0.85, 0.42)}

	# --- WIND-UP: a lança nasce no chão (cabo → ponta), com 6 faixas de aura, sparkles, órbita da ponta e luz. ---
	var spear_reveal := MotionRep.make("spear", {"spear_mode": "reveal", "spear_part": "full", "blade_length": 1.0,
		"energy": 1.35, "color": Color(0.30, 0.80, 1.0), "look": spear_look})
	fx.add("windup", _ds_spear_comp(s), [spear_reveal], {"length": "dest", "scalable": false, "dir": "axis"})
	var aura_windup := MotionRep.make("aura", {"look": aura_look})
	fx.add("windup", _ds_spear_comp(s + 1), [aura_windup], {"length": "dest", "scalable": false, "dir": "axis"})
	var motes := _ds_rest(&"ds_motes", s + 2, 54, 6.4, [
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.2, "intensity": 0.28, "time_hz": 1.1, "seed": sd}),
		_grow(0.85, 0.0),
		_dissolve(0.80, 0.45, 0.30),
	] as Array[MotionLayer])
	fx.add("windup", motes, [MotionRep.make("spark", {"size": 0.13, "look": spark_look, "trail": true, "trail_gain": 2.2, "stride": 2})],
		{"length": "dest", "scalable": false, "dir": "axis", "trail_dt": 0.05})
	var tip_orbit := _ds_rest(&"ds_tip_orbit", s + 3, 24, 0.6, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.32, "radius_growth": 0.05, "pitch": 0.16, "turns": 2.0, "phase_deg": 0.0, "direction": 1, "spin_deg_s": 220.0}),
		_dissolve(0.65, 0.40, 0.20),
	] as Array[MotionLayer])
	fx.add("windup", tip_orbit, [MotionRep.make("spark", {"size": 0.10, "look": spark_look, "trail": true, "trail_gain": 2.4})],
		{"length": 0.6, "scalable": false, "frame": "head", "dir": "axis", "trail_dt": 0.03})
	var aura_tip := _ds_rest(&"ds_aura_tip", s + 4, 2, 0.05, [] as Array[MotionLayer])
	fx.add("windup", aura_tip, [
		MotionRep.make("halo", {"size": 1.9, "strength": 0.9, "look": {"color": Color(0.30, 0.80, 1.0), "bands": 3.0, "falloff": 2.2}}),
		MotionRep.make("light", {"color": Color(0.30, 0.78, 1.0), "size": 4.0, "strength": 1.1, "light_range": 4.5}),
	], {"length": 0.05, "scalable": false, "frame": "head", "dir": "axis"})

	# --- THRUST: uma lança única e conectada; o cabo cresce e a lâmina fica na ponta. Sem feixe, sem projétil. ---
	var spear_thrust := MotionRep.make("spear", {"spear_mode": "none", "spear_part": "full", "blade_length": 1.0,
		"ghosts": 2, "ghost_gap": 0.12, "ghost_alpha": 0.13, "energy": 1.55, "color": Color(0.34, 0.86, 1.0), "look": spear_look})
	fx.add("thrust", _ds_spear_comp(s + 10), [
		spear_thrust,
		MotionRep.make("light", {"color": Color(0.34, 0.86, 1.0), "size": 4.5, "strength": 1.4, "light_range": 5.0}),
	], {"length": "dest", "scalable": false, "dir": "axis"})
	fx.add("thrust", _ds_spear_comp(s + 11), [MotionRep.make("aura", {"look": aura_look})],
		{"length": "dest", "scalable": false, "dir": "axis"})
	var speedlines := _ds_rest(&"ds_speedlines", s + 12, 28, 6.4, [
		_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, -1), "distance": 1.8, "radius": 1.0, "core_radius": 0.1, "edge_noise": 0.25, "seed": sd, "t_start": 0.0, "t_duration": 0.25}),
		_dissolve(0.10, 0.35, 0.20),
	] as Array[MotionLayer])
	fx.add("thrust", speedlines, [MotionRep.make("spark", {"size": 0.12, "look": spark_look, "trail": true, "trail_gain": 2.4, "stride": 2})],
		{"length": "dest", "scalable": false, "dir": "axis", "trail_dt": 0.04})
	var thrust_motes := _ds_rest(&"ds_thrust_motes", s + 13, 40, 6.4, [
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.9, "intensity": 0.22, "time_hz": 2.4, "seed": (sd + 3) % 999983}),
		_dissolve(0.05, 0.40, 0.25),
	] as Array[MotionLayer])
	fx.add("thrust", thrust_motes, [MotionRep.make("spark", {"size": 0.10, "look": spark_look, "trail": true, "trail_gain": 2.0, "stride": 2})],
		{"length": "dest", "scalable": false, "dir": "axis", "trail_dt": 0.035})

	# --- DRILL (D-379): boost burst helicoidal no INÍCIO da estocada. Dura 0,6 s; após 0,4 s começa a
	# desaparecer em opacidade; o giro é de ventilador. ---
	var vortex := MotionRep.make("vortex", {"vortex_bands": 10, "vortex_length": 3.0, "vortex_radius": 1.10, "vortex_end_radius": 0.08,
		"vortex_turns": 3.2, "vortex_spin": 4.2, "vortex_width": 0.12, "vortex_opacity": 0.41, "vortex_energy": 3.2, "vortex_split": 1.6,  # D-1015: -25% opacity, bands split apart on fade
		"vortex_base_length": 5.0, "vortex_base_radius": 1.80, "vortex_base_end_radius": 0.22,
		"vortex_cone_opacity": 0.0,  # D-1015: no solid cone (it read as an umbrella) "vortex_cone_energy": 3.2,
		"vortex_color": Color(0.55, 0.95, 1.0), "look": {"flow_speed": 2.5, "rim_power": 1.4, "edge_soft": 0.35}})
	var drill_comp := _c(&"ds_drill", s + 60, 2, [_dissolve(0.10, 0.15, 0.0)] as Array[MotionLayer])  # D-1016: gone 0.25 s after it appears
	fx.add("drill", drill_comp, [vortex], {"length": "dest", "scalable": false, "dir": "axis"})
	var drill_shock_base := _c(&"ds_drill_shock_base", s + 62, 2, [_dissolve(0.0, 0.24, 0.0)] as Array[MotionLayer])
	fx.add("drill", drill_shock_base, [
		MotionRep.make("halo", {"size": 5.0, "strength": 2.5, "look": {"color": Color(0.55, 0.95, 1.0), "bands": 3.0, "falloff": 1.9}}),
		MotionRep.make("shock", {"size": 4.5, "strength": 3.0}),
		MotionRep.make("light", {"color": Color(0.55, 0.95, 1.0), "size": 8.0, "strength": 6.0, "light_range": 8.0}),
	], {"length": 0.01, "scalable": false, "frame": "origin", "dir": "axis"})
	var drill_shock_tip := _c(&"ds_drill_shock_tip", s + 63, 2, [_dissolve(0.0, 0.26, 0.0)] as Array[MotionLayer])
	fx.add("drill", drill_shock_tip, [
		MotionRep.make("halo", {"size": 3.0, "strength": 1.8, "look": {"color": Color(0.55, 0.95, 1.0), "bands": 3.0, "falloff": 2.0}}),
		MotionRep.make("shock", {"size": 2.6, "strength": 2.4}),
	], {"length": 0.01, "scalable": false, "frame": "head", "dir": "axis"})
	var drill_sparks := _c(&"ds_drill_sparks", s + 61, 64, [
		_layer(&"burst", &"M16", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "cone_deg": 30.0, "distance": 2.6, "distribution": 0.9, "t_start": 0.0, "t_duration": 0.40, "curve": 1.2, "dissipate": 0.0}),
		_dissolve(0.10, 0.30, 0.10),
	] as Array[MotionLayer])
	drill_sparks.base_length = 0.01
	fx.add("drill", drill_sparks, [MotionRep.make("spark", {"size": 0.26, "look": spark_look, "trail": true, "trail_gain": 3.0})],
		{"length": 0.01, "scalable": false, "frame": "head", "dir": "axis", "trail_dt": 0.03})
	var drill_sparks_wide := _c(&"ds_drill_sparks_wide", s + 64, 40, [
		_layer(&"burst", &"M16", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "cone_deg": 75.0, "distance": 3.2, "distribution": 0.8, "t_start": 0.0, "t_duration": 0.34, "curve": 1.4, "dissipate": 0.0}),
		_dissolve(0.05, 0.30, 0.10),
	] as Array[MotionLayer])
	drill_sparks_wide.base_length = 0.01
	fx.add("drill", drill_sparks_wide, [MotionRep.make("spark", {"size": 0.20, "look": spark_look, "trail": true, "trail_gain": 2.5})],
		{"length": 0.01, "scalable": false, "frame": "origin", "dir": "axis", "trail_dt": 0.03})

	# --- IMPACT (comum): leque de shotgun a partir do contato, para além do alvo. ---
	var spines := _ds_burst(&"ds_spines", s + 20, 86, 55.0, 4.8, 0.55, 2.2, 0.9, 18.0, 6.0, 6.0)
	fx.add("impact", spines, [MotionRep.make("spark", {"size": 0.28, "look": spark_look, "trail": true, "trail_gain": 2.8})],
		{"length": 0.01, "scalable": true, "dir": "axis", "trail_dt": 0.035})
	var shards := _ds_burst(&"ds_shards", s + 21, 36, 42.0, 3.4, 0.55, 1.8, 0.85, 10.0, 5.0, 5.0)
	fx.add("impact", shards, [MotionRep.make("surface", {"shape": "fragments", "element": "water", "size": 0.35, "spin": 6.0})],
		{"length": 0.01, "scalable": true, "dir": "axis"})
	var fines := _ds_burst(&"ds_fines", s + 22, 60, 70.0, 2.4, 0.45, 1.4, 0.9, 8.0, 4.0, 4.0)
	fx.add("impact", fines, [MotionRep.make("spark", {"size": 0.12, "look": spark_look})], {"length": 0.01, "scalable": true, "dir": "axis"})
	var flash := _c(&"ds_flash", s + 23, 2, [_dissolve(0.0, 0.45, 0.15)] as Array[MotionLayer])
	fx.add("impact_flash", flash, [
		MotionRep.make("halo", {"size": 3.6, "strength": 1.6, "look": {"color": Color(0.85, 1.0, 1.0), "bands": 3.0, "falloff": 1.9}}),
		MotionRep.make("light", {"color": Color(0.55, 0.90, 1.0), "size": 8.0, "strength": 4.0, "light_range": 8.0}),
		MotionRep.make("shock", {"size": 3.4, "strength": 2.0}),
	], {"length": 0.05, "scalable": true, "dir": "axis"})
	var dust := _ds_burst(&"ds_dust", s + 24, 24, 80.0, 2.6, 0.55, 1.2, 0.9, 5.0, 3.0, 6.0)
	fx.add("impact_flash", dust, [MotionRep.make("puff", {"size": 0.55, "appear": 0, "look": puff_look})], {"length": 0.01, "scalable": true, "dir": "axis"})
	var ground := _c(&"ds_ground", s + 25, 2, [_dissolve(0.0, 0.60, 0.12)] as Array[MotionLayer])
	fx.add("impact_flash", ground, [MotionRep.make("mark", {"size": 1.4, "look": mark_look})], {"length": 0.02, "scalable": true, "ground": true, "dir": "up"})

	# --- BADGE STEAL (D-380, igual ao HTML): 56+36 streaks azuis + 34 orbes verdes + órbita única no atacante. ---
	var reverse_streaks := _c(&"ds_reverse_streaks", s + 30, 56, [
		_layer(&"burst", &"M16", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "cone_deg": 18.0, "distance": steal_distance, "distribution": 0.9, "t_start": 0.0, "t_duration": 0.42, "curve": 1.25, "dissipate": 0.0}),
		_layer(&"pull", &"M06", MotionTypes.Op.OFFSET, {"target": Vector3(0, 0, steal_distance), "strength": 0.35, "reach": steal_distance * 1.25, "curve": 1.0, "t_start": 0.0, "t_duration": 0.42}),
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.8, "intensity": 0.22, "time_hz": 2.2, "seed": sd}),
		_dissolve(0.45, 0.24, 0.0),
	] as Array[MotionLayer])
	reverse_streaks.base_length = 1.0
	fx.add("steal", reverse_streaks, [MotionRep.make("spark", {"size": 0.07, "size_jitter": 0.5, "look": steal_look, "stretch": 2.0})],
		{"length": "dest", "scalable": false, "dir": "axis"})
	var reverse_streaks_b := _c(&"ds_reverse_streaks_b", s + 32, 36, [
		_layer(&"burst", &"M16", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "cone_deg": 18.0, "distance": steal_distance, "distribution": 0.9, "t_start": 0.0, "t_duration": 0.42, "curve": 1.25, "dissipate": 0.0}),
		_layer(&"pull", &"M06", MotionTypes.Op.OFFSET, {"target": Vector3(0, 0, steal_distance), "strength": 0.35, "reach": steal_distance * 1.25, "curve": 1.0, "t_start": 0.0, "t_duration": 0.42}),
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.8, "intensity": 0.22, "time_hz": 2.2, "seed": (sd + 9) % 999983}),
		_dissolve(0.46, 0.23, 0.0),
	] as Array[MotionLayer])
	reverse_streaks_b.base_length = 1.0
	fx.add("steal", reverse_streaks_b, [MotionRep.make("spark", {"size": 0.07, "size_jitter": 0.5, "look": steal_look, "stretch": 2.0})],
		{"length": "dest", "scalable": false, "dir": "axis"})
	var reverse_orbs := _c(&"ds_reverse_orbs", s + 31, 240, [
		_layer(&"burst", &"M16", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "cone_deg": 10.0, "distance": steal_distance, "distribution": 0.55, "t_start": 0.0, "t_duration": 0.50, "curve": 1.1, "dissipate": 0.0}),
		_layer(&"pull", &"M06", MotionTypes.Op.OFFSET, {"target": Vector3(0, 0, steal_distance), "strength": 0.40, "reach": steal_distance * 1.3, "curve": 1.0, "t_start": 0.0, "t_duration": 0.69}),
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.6, "intensity": 0.16, "time_hz": 1.8, "seed": (sd + 5) % 999983}),
		_dissolve(0.39, 0.30, 0.0),
	] as Array[MotionLayer])
	reverse_orbs.base_length = 1.0
	fx.add("steal", reverse_orbs, [MotionRep.make("spark", {"size": 0.075, "size_jitter": 0.35,
		"look": {"soft": 1.0, "energy": 0.95, "cam_fade": 1.0}, "stretch": 1.0})],
		{"length": "dest", "scalable": false, "dir": "axis"})
	# Órbita única no atacante, como o orbPoint do HTML, só depois que as esferas chegam.
	var stolen_orbit := _c(&"ds_stolen_orbit", s + 40, 30, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 1.20, "radius_growth": 0.0, "pitch": 0.0, "turns": 1.0, "phase_deg": 0.0, "direction": 1, "spin_deg_s": 260.0}),
		_dissolve(0.55, 0.14, 0.0),
	] as Array[MotionLayer])
	stolen_orbit.base_length = 0.01
	if with_crown:
		fx.add("steal", stolen_orbit, [MotionRep.make("spark", {"size": 0.17, "look": steal_look, "trail": true, "trail_gain": 1.6})],
			{"length": 0.01, "scalable": false, "frame": "dest", "dir": "up", "z_offset": 1.20, "start": 0.30, "trail_dt": 0.04})

	# --- DISSOLVE: a lança dá ré e some lentamente do cabo à ponta; brasas e faixas se apagam junto. ---
	var spear_dissolve := MotionRep.make("spear", {"spear_mode": "dissolve", "spear_part": "full", "blade_length": 1.0,
		"energy": 1.15, "color": Color(0.28, 0.74, 1.0), "look": spear_look})
	fx.add("dissolve", _ds_spear_comp(s + 50), [spear_dissolve], {"length": "dest", "scalable": false, "dir": "axis"})
	var lance_motes := _ds_rest(&"ds_lance_motes", s + 52, 48, 6.4, [
		_layer(&"turb", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.9, "intensity": 0.30, "time_hz": 1.8, "seed": (sd + 7) % 999983}),
		_dissolve(0.05, 0.72, 0.18),
	] as Array[MotionLayer])
	fx.add("dissolve", lance_motes, [MotionRep.make("spark", {"size": 0.11, "look": spark_look, "trail": true, "trail_gain": 1.6, "stride": 2})],
		{"length": "dest", "scalable": false, "dir": "axis", "trail_dt": 0.04})
	var embers := _ds_burst(&"ds_embers", s + 53, 30, 60.0, 1.8, 0.45, 1.5, 0.9, 4.0, 5.0, 4.0)
	fx.add("dissolve", embers, [MotionRep.make("spark", {"size": 0.09, "look": spark_look})], {"length": 0.01, "scalable": false, "dir": "up"})
	return fx


static func _ds_spear_comp(seed_value: int) -> MotionComposition:
	var c := _c(&"ds_spear", seed_value, 2, [] as Array[MotionLayer])
	c.base_length = 1.0
	c.duration = 3.0
	return c


static func _ds_rest(id: StringName, seed_value: int, count: int, length: float, layers: Array[MotionLayer]) -> MotionComposition:
	var c := _c(id, seed_value, count, layers)
	c.base_length = length
	c.duration = 1.5
	return c


static func _ds_burst(id: StringName, seed_value: int, count: int, cone: float, distance: float, duration: float,
		curve: float, distribution: float, speed: float, drag: float, gravity: float) -> MotionComposition:
	var layers := _burst(count, cone, distance, duration, curve, distribution)
	layers.append(_layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "speed": speed, "drag": drag, "spread": 0.6, "t_start": 0.0}))
	layers.append(_layer(&"gravity", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": gravity, "spread": 0.4, "t_start": 0.0}))
	var c := _c(id, seed_value, count, layers)
	c.base_length = 0.01
	c.duration = duration + 0.1
	return c


## D-953: a directional burst for the melee contract. `dir` is in the layer's local frame (+Z = along the
## shot, so (0,0,-1) is behind the attacker, (0,0,1) is beyond the target). Two M16 layers: OFFSET + fade.
static func _melee_burst(id: StringName, seed_value: int, count: int, dir: Vector3, cone: float, distance: float,
		duration: float, curve: float, distribution: float, speed: float, drag: float, gravity: float,
		floor_y := -1000.0, restitution := 0.0) -> MotionComposition:
	var params := {"direction": dir, "cone_deg": cone, "distance": distance, "distribution": distribution,
		"t_start": 0.0, "t_duration": duration, "curve": curve, "dissipate": 1.0}
	var move := _layer(&"burst_move", &"M16", MotionTypes.Op.OFFSET, params)
	var fade_params := params.duplicate()
	fade_params["t_start"] = 0.3 * duration
	fade_params["t_duration"] = 0.7 * duration
	fade_params["curve"] = 1.0
	var fade := _layer(&"burst_fade", &"M16", MotionTypes.Op.MULTIPLY_ATTRIBUTE, fade_params)
	var layers: Array[MotionLayer] = [move, fade]
	layers.append(_layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": dir, "speed": speed, "drag": drag, "spread": 0.6, "t_start": 0.0}))
	layers.append(_layer(&"gravity", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": gravity, "spread": 0.4, "t_start": 0.0,
		"floor_y": floor_y, "restitution": restitution}))
	var c := _c(id, seed_value, count, layers)
	c.base_length = 0.01
	c.duration = duration + 0.1
	return c


## REJECTED (D-953, 2026-11-06): kept only as a lab experiment; no Move uses it. The creator discarded the
## melee results and pointed to the procedural motion itself as the cause.
##
## D-953: PRIMEIRO CORTE do Composer de Fases — MELEE. Tackle e Brick Break usam o mesmo contrato visual;
## `brick` troca o acento (ciano -> vermelho) e o caco. Fases: windup, release, travel, impact, return.
## O pós-wind-up é suportado pelo contrato, mas fica vazio nesses dois Moves (não seguram carga).
## Tudo em metros do mundo, fixo nas duas vistas (D-334); nenhum personagem, time ou lado (D-235).
static func tackle_rush_effect(seed_value: int, brick := false) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var accent := Color(1.0, 0.46, 0.28) if brick else Color(0.36, 0.86, 0.95)
	var warm := Color(1.0, 0.93, 0.72)
	var spark_look := {"hot": Color(1.0, 0.97, 0.84), "cool": accent, "energy": 2.3, "hard": 0.1}
	var shard_look := {"c0": Color(0.16, 0.14, 0.12), "c1": Color(0.42, 0.38, 0.32), "c2": Color(0.66, 0.61, 0.52), "c3": Color(0.86, 0.81, 0.69), "c4": Color(1.0, 0.97, 0.86),
		"bands": 4.0, "core_sharp": 1.2, "noise_amp": 0.4, "shade_amount": 0.8, "rim_amount": 0.5, "rim_color": Color(0.95, 0.90, 0.78),
		"flow": 0.2, "noise_scale": 2.0, "swirl": 0.0, "lick": 0.03, "rise": 0.0, "tail_erode": 0.1}
	var air_look := {"c0": Color(0.18, 0.52, 0.60), "c1": Color(0.34, 0.74, 0.82), "c2": Color(0.56, 0.90, 0.95), "c3": Color(0.82, 0.98, 1.0), "c4": Color(1, 1, 1),
		"bands": 3.0, "core_sharp": 1.5, "noise_amp": 0.45, "shade_amount": 0.2, "shade_tint": Color(0.7, 0.85, 0.9), "rim_amount": 0.8, "rim_width": 0.28, "rim_color": Color(1, 1, 1),
		"flow": 6.0, "noise_scale": 3.2, "swirl": 1.0, "lick": 0.1, "rise": 0.0, "wave_amp": 0.05, "wave_freq": 5.0, "wave_speed": 6.0, "tail_erode": 0.75, "erode_edge_color": Color(0.6, 0.85, 0.9)}
	var hit_look := {"c0": Color(0.40, 0.15, 0.05), "c1": Color(1.0, 0.55, 0.12), "c2": Color(1.0, 0.85, 0.45), "c3": Color(1.0, 0.97, 0.82), "c4": Color(1, 1, 1),
		"bands": 4.0, "core_sharp": 1.8, "noise_amp": 0.5, "shade_amount": 0.3, "shade_tint": Color(0.7, 0.45, 0.25), "rim_amount": 0.8, "rim_width": 0.26, "rim_color": Color(1.0, 0.98, 0.82),
		"flow": 2.0, "noise_scale": 2.4, "swirl": 0.2, "lick": 0.1, "rise": 0.0, "tail_erode": 0.5, "erode_edge_color": Color(0.8, 0.4, 0.08)}
	var mark_look := {"base_col": Color(0.10, 0.08, 0.06), "line_col": accent, "rim_col": Color(0.35, 0.28, 0.20), "line_amount": 0.55, "rim_amount": 0.6, "alpha": 0.6, "cracks": 5.0, "radial": 0.6}

	var dust_look := {"light_col": Color(0.75, 0.70, 0.61), "mid_col": Color(0.62, 0.56, 0.47), "dark_col": Color(0.48, 0.43, 0.36), "alpha": 0.50, "churn": 0.55}
	var dust := MotionRep.make("puff", {"size": 0.55, "appear": 0, "look": dust_look})
	var ground_dust := MotionRep.make("puff", {"size": 0.85, "appear": 0, "look": dust_look})
	var spark := MotionRep.make("spark", {"size": 0.06, "look": spark_look, "trail": true, "trail_gain": 1.4})
	var pebble := MotionRep.make("drops", {"size": 0.06, "stretch": 1.2, "stride": 3, "element": "earth", "look": shard_look})
	var shard := MotionRep.make("surface", {"shape": "fragments", "element": "earth", "size": 0.28, "spin": 9.0, "look": shard_look})
	var streak := MotionRep.make("streaks", {"size": 0.10, "length": 1.5, "width": 0.050, "radial": false, "strength": 0.9, "hot_every": 2})
	var radial_streak := MotionRep.make("streaks", {"size": 0.10, "length": 1.5, "width": 0.045, "radial": true, "strength": 0.9, "hot_every": 2})
	var ring := MotionRep.make("ring", {"element": "earth", "size": 1.6, "strength": 1.0})
	var shock_ring := MotionRep.make("ring", {"element": "earth", "size": 3.0, "strength": 0.9, "expand": true})
	var ground_ring := MotionRep.make("ring", {"element": "earth", "size": 4.5, "strength": 0.8, "expand": true})
	var halo := MotionRep.make("halo", {"element": "air", "size": 2.0, "strength": 1.0, "look": {"color": Color(1.0, 0.85, 0.50), "falloff": 2.0}})
	var impact_halo := MotionRep.make("halo", {"element": "air", "size": 5.2, "strength": 1.4, "look": {"color": warm, "falloff": 1.9}})
	var flip := MotionRep.make("flipbook", {"sheet": "impact", "size": 5.2, "color": warm, "energy": 2.8, "size_jitter": 0.0})
	var mark := MotionRep.make("mark", {"element": "earth", "size": 1.0, "look": mark_look})

	# WINDUP: o chão puxa poeira e pedras para os pés; um anel fecha; linhas de pressão apontam para o alvo.
	var gather := _ds_rest(&"melee_gather", s + 1, 24, 0.01, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 2.0, "radius_growth": -0.85, "pitch": 0.16, "turns": 1.1, "direction": 1, "phase_deg": 0.0, "spin_deg_s": 90.0}),
		_layer(&"pull", &"M06", MotionTypes.Op.OFFSET, {"target": Vector3.ZERO, "strength": 0.55, "reach": 2.4, "curve": 1.2, "t_start": 0.0, "t_duration": 1.5}),
		_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.7, "intensity": 0.12, "time_hz": 1.4, "seed": s + 1}),
		_dissolve(0.95, 0.55, 0.25),
	] as Array[MotionLayer])
	fx.add("windup", gather, [dust], {"length": 0.01, "dir": "up", "ground": true})
	fx.add("windup", gather, [pebble], {"length": 0.01, "dir": "up", "ground": true, "start": 0.15})
	fx.add("windup", _ds_rest(&"melee_wind_ring", s + 2, 2, 0.01, [] as Array[MotionLayer]), [ring], {"length": 0.01, "dir": "up", "ground": true})
	fx.add("windup", _ds_rest(&"melee_wind_halo", s + 3, 2, 0.01, [] as Array[MotionLayer]), [halo], {"length": 0.01, "dir": "up", "z_offset": 0.85})
	var wind_lines := _ds_rest(&"melee_wind_lines", s + 4, 30, 3.0, [
		_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "distance": 0.6, "radius": 0.5, "core_radius": 0.1, "edge_noise": 0.2, "seed": s + 4, "t_start": 0.0, "t_duration": 1.2}),
		_dissolve(0.9, 0.5, 0.2),
	] as Array[MotionLayer])
	fx.add("windup", wind_lines, [streak], {"length": 2.2, "dir": "axis", "start": 0.2})
	var charge_orbit := _ds_rest(&"melee_charge_orbit", s + 5, 24, 1.6, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.65, "radius_growth": 0.10, "pitch": 0.50, "turns": 2.0, "direction": 1, "phase_deg": 0.0, "spin_deg_s": 180.0}),
		_dissolve(0.9, 0.5, 0.2),
	] as Array[MotionLayer])
	fx.add("windup", charge_orbit, [MotionRep.make("spark", {"size": 0.06, "look": spark_look, "trail": true, "trail_gain": 1.8})],
		{"length": 1.6, "dir": "up", "ground": true, "z_offset": 1.10, "trail_dt": 0.04, "start": 0.10})

	# RELEASE: o impulso para trás, a rachadura e o anel de saída.
	fx.add("release", _ds_rest(&"melee_release_ring", s + 10, 2, 0.01, [] as Array[MotionLayer]), [shock_ring], {"length": 0.01, "dir": "up", "ground": true})
	fx.add("release", _ds_rest(&"melee_release_crack", s + 11, 2, 0.01, [_dissolve(0.15, 0.5)] as Array[MotionLayer]), [mark], {"length": 0.01, "dir": "up", "ground": true})
	fx.add("release", _ds_rest(&"melee_release_flash", s + 14, 2, 0.01, [_dissolve(0.05, 0.28)] as Array[MotionLayer]), [halo], {"length": 0.01, "dir": "up", "ground": true, "z_offset": 0.25})
	fx.add("release", _melee_burst(&"melee_push", s + 12, 30, Vector3(0, 0, -1), 55.0, 4.0, 0.35, 1.5, 0.9, 3.0, 2.2, 2.0), [ground_dust], {"length": 0.01, "dir": "axis", "ground": true})
	fx.add("release", _melee_burst(&"melee_push_sparks", s + 13, 32, Vector3(0, 0, -1), 70.0, 3.2, 0.30, 1.4, 0.9, 5.0, 2.5, 4.0, 0.0, 0.25), [spark], {"length": 0.01, "dir": "axis", "ground": true, "trail_dt": 0.04})

	# TRAVEL: a esteira de poeira, as pedras chutadas, as linhas de velocidade e o rastro de pressão.
	var wake := _ds_rest(&"melee_wake", s + 20, 44, 3.5, [
		_layer(&"lift", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 1, 0), "gravity": 0.9, "spread": 0.4, "t_start": 0.0}),
		_layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.8, "intensity": 0.12, "time_hz": 1.8, "seed": s + 20}),
		_dissolve(0.35, 0.65, 0.2),
	] as Array[MotionLayer])
	fx.add("travel", wake, [ground_dust], {"length": 3.5, "frame": "head", "back": true, "trail": true, "until_landed": true, "ground": true})
	var kicked := _ds_rest(&"melee_kicked", s + 21, 20, 2.2, [
		_layer(&"fall", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": 9.0, "spread": 0.4, "t_start": 0.0,
			"floor_y": 0.0, "restitution": 0.3}),
		_layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, -1), "speed": 1.5, "drag": 1.5, "spread": 0.5, "t_start": 0.0}),
		_dissolve(0.2, 0.7, 0.2),
	] as Array[MotionLayer])
	fx.add("travel", kicked, [pebble], {"length": 2.2, "frame": "head", "back": true, "trail": true, "until_landed": true, "ground": true})
	var speed := _ds_rest(&"melee_speed", s + 22, 20, 3.0, [
		_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "distance": 1.0, "radius": 0.5, "core_radius": 0.1, "edge_noise": 0.2, "seed": s + 22, "t_start": 0.0, "t_duration": 0.6}),
		_dissolve(0.1, 0.6, 0.2),
	] as Array[MotionLayer])
	fx.add("travel", speed, [streak], {"length": 3.0, "frame": "head", "back": true, "trail": true, "until_landed": true})
	var after := _ds_rest(&"melee_after", s + 23, 24, 2.4, [
		_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "distance": 0.8, "radius": 0.5, "core_radius": 0.1, "edge_noise": 0.2, "seed": s + 23, "t_start": 0.0, "t_duration": 0.6}),
		_dissolve(0.15, 0.7, 0.2),
	] as Array[MotionLayer])
	fx.add("travel", after, [MotionRep.make("streaks", {"size": 0.14, "length": 2.0, "width": 0.060, "radial": false, "strength": 0.8, "hot_every": 2})],
		{"length": 2.4, "frame": "head", "back": true, "trail": true, "until_landed": true})

	# PRELUDE (D-953): the hit-windup / dodge prelude at the target. A 3D tube from the attacking
	# limb to the contact, a charge at the limb, the arrival skid and a target lock. The game node
	# feeds the real limb position, so this follows the character's attack motion (not a vertical plane).
	var prelude := _ds_rest(&"melee_prelude", s + 60, 20, 1.4, [
		_grow(0.10),
		_dissolve(0.35, 0.30, 0.10),
	] as Array[MotionLayer])
	fx.add("prelude", prelude, [MotionRep.make("surface", {"shape": "tube", "element": "air", "radius": 0.11, "sides": 10, "max_rings": 18, "look": hit_look})],
		{"length": 1.4, "dir": "axis"})
	fx.add("prelude", _ds_rest(&"melee_prelude_halo", s + 61, 2, 0.01, [_dissolve(0.0, 0.30)] as Array[MotionLayer]),
		[MotionRep.make("halo", {"element": "air", "size": 1.4, "strength": 1.0, "look": {"color": warm, "falloff": 2.0}})],
		{"length": 0.01, "dir": "axis"})
	fx.add("prelude", _melee_burst(&"melee_skid", s + 62, 14, Vector3(0, 0, -1), 70.0, 1.6, 0.30, 1.5, 0.9, 3.0, 2.0, 1.0), [ground_dust], {"length": 0.01, "dir": "axis", "ground": true})
	fx.add("prelude", _ds_rest(&"melee_lock", s + 63, 2, 0.01, [] as Array[MotionLayer]), [ring], {"length": 0.01, "frame": "dest", "ground": true, "dir": "up"})
	fx.add("prelude", _ds_rest(&"melee_prelude_lines", s + 64, 12, 2.2, [_grow(0.08), _dissolve(0.30, 0.30, 0.1)] as Array[MotionLayer]), [streak], {"length": 2.2, "dir": "axis"})

	# IMPACT: flash, flipbook, cone, arcos, faíscas, cacos, poeira radial, anel, marca e linhas.
	fx.add("impact", _ds_rest(&"melee_impact_halo", s + 30, 2, 0.01, [_dissolve(0.05, 0.35)] as Array[MotionLayer]), [impact_halo], {"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5})
	fx.add("impact", _c(&"melee_flip", s + 31, 2, [_grow(0.05), _dissolve(0.08, 0.30)] as Array[MotionLayer]), [flip], {"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5})
	fx.add("impact", _ds_rest(&"melee_cone", s + 32, 24, 4.0, [_dissolve(0.05, 0.35)] as Array[MotionLayer]),
		[MotionRep.make("surface", {"shape": "shell", "element": "air", "radius": 1.5, "profile_pow": 0.45, "sides": 16, "max_rings": 18, "look": hit_look})],
		{"length": 4.0, "frame": "dest", "dir": "axis", "z_offset": -0.5})
	fx.add("impact", _ds_rest(&"melee_arc_a", s + 33, 24, 3.2, [
		_layer(&"bend", &"M09", MotionTypes.Op.DEFORM, {"amount_deg": 35.0, "plane_deg": 45.0, "center": 0.5, "extent": 1.0}),
		_dissolve(0.05, 0.3),
	] as Array[MotionLayer]),
		[MotionRep.make("surface", {"shape": "arc", "element": "air", "radius": 0.80, "profile_pow": 0.55, "sides": 10, "camera_facing": true, "look": hit_look})],
		{"length": 3.2, "frame": "dest", "dir": "axis", "z_offset": -0.6})
	fx.add("impact", _ds_rest(&"melee_arc_b", s + 34, 24, 3.2, [
		_layer(&"bend", &"M09", MotionTypes.Op.DEFORM, {"amount_deg": -35.0, "plane_deg": 45.0, "center": 0.5, "extent": 1.0}),
		_dissolve(0.05, 0.3),
	] as Array[MotionLayer]),
		[MotionRep.make("surface", {"shape": "arc", "element": "air", "radius": 0.65, "profile_pow": 0.55, "sides": 10, "camera_facing": true, "look": hit_look})],
		{"length": 3.2, "frame": "dest", "dir": "axis", "z_offset": -0.6})
	fx.add("impact", _melee_burst(&"melee_sparks", s + 35, 60, Vector3(0, 0, 1), 80.0, 8.0, 0.45, 1.6, 0.95, 10.0, 3.0, 4.0, -1.2, 0.25), [spark], {"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5, "trail_dt": 0.04})
	fx.add("impact", _melee_burst(&"melee_shards", s + 36, 34, Vector3(0, 0, 1), 70.0, 5.5, 0.50, 1.5, 0.95, 6.0, 2.5, 9.0, -1.2, 0.35), [shard], {"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5})
	fx.add("impact", _melee_burst(&"melee_ground_dust", s + 37, 40, Vector3(0, 1, 0), 85.0, 5.0, 0.50, 1.4, 0.9, 4.0, 2.0, 0.0), [ground_dust], {"length": 0.01, "frame": "dest", "ground": true, "dir": "up"})
	fx.add("impact", _ds_rest(&"melee_ground_ring", s + 38, 2, 0.01, [] as Array[MotionLayer]), [ground_ring], {"length": 0.01, "frame": "dest", "ground": true, "dir": "up"})
	fx.add("impact", _melee_burst(&"melee_impact_lines", s + 40, 30, Vector3(0, 0, 1), 90.0, 5.0, 0.35, 1.2, 0.9, 6.0, 2.0, 0.0), [radial_streak], {"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5})
	fx.add("impact", _ds_rest(&"melee_light", s + 41, 2, 0.01, [_dissolve(0.02, 0.16)] as Array[MotionLayer]),
		[MotionRep.make("light", {"color": Color(1.0, 0.72, 0.32), "strength": 2.2, "light_range": 7.0})],
		{"length": 0.01, "frame": "dest", "dir": "axis", "z_offset": -0.5})

	# RETURN: o salto de volta, o rastro e a poeira da chegada.
	fx.add("return", _melee_burst(&"melee_return_dust", s + 50, 18, Vector3(0, 1, 0), 55.0, 2.2, 0.35, 2.0, 0.9, 3.0, 2.0, 0.0), [ground_dust], {"length": 0.01, "frame": "origin", "ground": true, "dir": "up"})
	var ret_trail := _ds_rest(&"melee_return_trail", s + 51, 24, 2.4, [
		_layer(&"flow", &"M21", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "distance": 0.8, "radius": 0.5, "core_radius": 0.1, "edge_noise": 0.2, "seed": s + 51, "t_start": 0.0, "t_duration": 0.6}),
		_dissolve(0.15, 0.7, 0.2),
	] as Array[MotionLayer])
	fx.add("return", ret_trail, [MotionRep.make("surface", {"shape": "tube", "element": "air", "radius": 0.20, "sides": 10, "max_rings": 20, "look": air_look})],
		{"length": 2.4, "frame": "head", "back": true, "trail": true})
	fx.add("return", _ds_rest(&"melee_return_sparks", s + 52, 16, 0.01, [_dissolve(0.0, 0.6, 0.2)] as Array[MotionLayer]), [MotionRep.make("spark", {"size": 0.10, "look": spark_look, "trail": true, "trail_gain": 2.4})], {"length": 0.01, "frame": "head", "trail_dt": 0.05})
	fx.add("return", _ds_rest(&"melee_landing_ring", s + 53, 2, 0.01, [] as Array[MotionLayer]), [MotionRep.make("ring", {"element": "earth", "size": 1.8, "strength": 0.6, "expand": true})], {"length": 0.01, "frame": "dest", "ground": true, "dir": "up", "start": 0.80})
	fx.add("return", _melee_burst(&"melee_landing_dust", s + 54, 20, Vector3(0, 1, 0), 60.0, 1.8, 0.30, 2.0, 0.9, 2.5, 2.0, 0.0), [ground_dust], {"length": 0.01, "frame": "dest", "ground": true, "dir": "up", "start": 0.80})
	return fx


## D-1026: Armored Bulk, option A ("Flexão e Cromagem de baixo para cima"). Start and release are one gesture (the wind-up is
## instant). WINDUP = chrome glints climbing the body with the wave the model shader draws (0..0.38 s); IMPACT = the release at
## 0.38 s: a short flash and short metal sparks (the shock rings were removed at the creator's request). The chrome film that settles on the model
## is a surface material (shaders/armor_chrome.gdshader), not a particle. Fixed metres here; the node scales it by the real body
## and the camera distance (D-235). No character, team or side.
static func armored_bulk_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var spark_look := {"hot": Color(1.0, 1.0, 1.0), "cool": Color(0.62, 0.72, 0.86), "energy": 2.0, "hard": 0.15}
	var dust_look := {"light_col": Color(0.74, 0.71, 0.66), "mid_col": Color(0.60, 0.57, 0.52), "dark_col": Color(0.46, 0.43, 0.40), "alpha": 0.45, "churn": 0.5}
	var spark := MotionRep.make("spark", {"size": 0.05, "look": spark_look, "trail": true, "trail_gain": 1.5})
	var glint := MotionRep.make("spark", {"size": 0.045, "look": spark_look, "trail": false})
	var halo := MotionRep.make("halo", {"element": "air", "size": 3.0, "strength": 1.1, "look": {"color": Color(0.85, 0.92, 1.0), "falloff": 2.0}})
	var dust := MotionRep.make("puff", {"size": 0.55, "appear": 0, "look": dust_look})
	# WINDUP: the chrome glints climb with the wave (helix that GROWS upward over the wave's 0.38 s, then dissolves).
	var rise := _ds_rest(&"armor_rise", s + 1, 22, 2.2, [
		_layer(&"helix", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.8, "radius_growth": 0.0, "pitch": 0.55, "turns": 1.6, "direction": 1, "phase_deg": 0.0, "spin_deg_s": 380.0}),
		_layer(&"grow", &"M17", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"direction": 0, "t_start": 0.0, "t_duration": 0.36, "curve": 1.0, "width": 0.12, "jitter": 0.0,
			"affect_visibility": true, "affect_width": false, "affect_intensity": false, "affect_opacity": false}),
		_dissolve(0.28, 0.2, 0.2),
	] as Array[MotionLayer])
	fx.add("windup", rise, [glint], {"length": 2.2, "dir": "up", "ground": true})
	# IMPACT (the release, 0.38 s in): a short flash and short metal sparks (the shock rings were removed at the creator's request).
	fx.add("impact", _ds_rest(&"armor_flash", s + 12, 2, 0.01, [_dissolve(0.04, 0.26)] as Array[MotionLayer]), [halo], {"length": 0.01, "dir": "up", "z_offset": 1.0})
	fx.add("impact", _melee_burst(&"armor_sparks", s + 13, 34, Vector3(0, 0, 1), 80.0, 2.6, 0.32, 1.5, 0.9, 6.0, 2.6, 5.0, 0.0, 0.2), [spark], {"length": 0.01, "dir": "up", "ground": true, "z_offset": 0.15, "trail_dt": 0.04})
	fx.add("impact", _melee_burst(&"armor_dust", s + 14, 14, Vector3(0, 1, 0), 85.0, 2.4, 0.4, 1.6, 0.9, 3.0, 2.0, 0.0), [dust], {"length": 0.01, "dir": "up", "ground": true})
	return fx


## D-1026: the ARMOR aura, drawn for as long as the badge lasts: small white sparkles that appear at random over the body, drift a
## little and fade at random. A life cycle (V1.6) of M26 emitters: every cycle is a new composition (own seed) and each sparkle is born at a random moment inside it,
## so they are sporadic, not a constant stream. NOTE: `ground` resets the layer's height AFTER `z_offset`, so a layer centred on the body must not use it. Fixed metres for a 1.6 m body (the node scales it by the real body, D-235); centred on the chest.
static func armor_aura_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var sparkle := _ptcl(1, Color(1, 1, 1), Color(0.85, 0.92, 1.0), 1.0, true, 2.5)
	for slot in 3:
		var base := seed_value * 7919 + slot * 104729
		var factory := func(cycle: int) -> MotionComposition:
			var emit := _atelier_emit(&"aura_emit", 9, {
				"shape": 0, "radius": 3.6, "speed_min": 0.1, "speed_max": 0.7, "drag": 0.9, "delay": 1.1,
				"life_min": 0.45, "life_max": 0.9, "size_min": 0.34, "size_max": 0.62, "size_bell": true})
			return _c(&"armor_aura", base + cycle * 31, 5, _layers(emit))
		var first: MotionComposition = factory.call(0)
		fx.add("aura", first, [sparkle], {"factory": factory, "loop": 1.6, "cycle_phase": float(slot) / 3.0, "length": "keep", "dir": "up", "z_offset": 1.1})
	return fx


## D-1026 (option A, creator): the ARMOR badge breaks on the first contact: a white flash of 0.08 s and the chrome film comes off as
## flat angular PLATES that fly outward from the body, fall with gravity and fade in 0.5 s. The node places the origin at the real
## chest (measured from the model) and scales by the real body, so nothing here is tied to a character or a side (D-235).
static func armor_break_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var plate := MotionRep.make("plate", {"size": 0.7, "spin": 6.0})
	var halo := MotionRep.make("halo", {"element": "air", "size": 3.0, "strength": 1.4, "look": {"color": Color(1.0, 1.0, 1.0), "falloff": 2.0}})
	fx.add("break", _ds_rest(&"armor_break_flash", s + 1, 2, 0.01, [_dissolve(0.0, 0.08)] as Array[MotionLayer]), [halo], {"length": 0.01, "dir": "up"})
	# The plates are born over the whole body (a sphere of emission around the chest) and leave it outward; M26 gives the size and alpha curves.
	var emit := _atelier_emit(&"armor_plates", 18, {"shape": 0, "radius": 3.0, "speed_min": 2.5, "speed_max": 5.5, "drag": 0.97, "gravity": 8.0,
		"life_min": 0.5, "life_max": 0.7, "size_min": 0.6, "size_max": 1.1, "size_bell": false})
	fx.add("break", _c(&"armor_plates", s + 2, 18, _layers(emit)), [plate], {"length": 0.01, "dir": "up"})
	return fx


## O efeito de cada Move de elemento (D-308 / D-236): um MotionEffect por `move_id` (nunca por personagem, D-235).
static func effect_for(move_id: String, seed_value: int, anchors_ := [], center := Vector3.ZERO) -> MotionEffect:
	if move_id == "armored_bulk":
		return armored_bulk_effect(seed_value)
	if move_id == "armor_break":
		return armor_break_effect(seed_value)
	if move_id == "armor_aura":
		return armor_aura_effect(seed_value)
	if move_id == "electric_beam":
		return electric_beam_effect(seed_value)
	if move_id == "drain_spear":
		return drain_spear_effect(seed_value)
	if move_id == "splitter_flames":
		return splitter_effect(seed_value)
	if move_id == "media":
		return media_effect(seed_value, anchors_, center)
	return fire_effect(seed_value)


## V1.11 (D-957): the SECONDARY of the library's electric beam. The beam, the charge, the flashes and the impact arcs are
## hand-made (D-954/D-956: ElectricBeamVfx); the Composer only paints the golden crackle around the held charge and the
## spark burst of the impact. Fixed metres (D-308 item 6). No travel layer.
static func electric_beam_effect(seed_value: int) -> MotionEffect:
	var fx := MotionEffect.new()
	var s := seed_value
	var spark := MotionRep.make("spark", {"element": "electric", "size": 0.045, "size_jitter": 0.6, "trail": true, "trail_gain": 0.9})
	fx.add("windup", _c(&"el_crackle", s, 10, _spark_layers(10, 180.0, 0.55, 0.35, 0.6, s + 1)), [spark],
		{"length": 0.01, "z_offset": 0.0, "trail_dt": 0.03})
	fx.add("impact", _c(&"el_burst", s + 2, 26, _spark_layers(26, 150.0, 1.5, 0.45, 2.2, s + 3)), [spark],
		{"length": 0.01, "trail_dt": 0.04})
	return fx
