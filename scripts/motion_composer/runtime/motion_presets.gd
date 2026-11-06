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
	# Círculo sagrado central da equipe (raio 5,2 m no HTML), no chão do grupo.
	fx.add("windup", _c(&"media_center", s, 2, [] as Array[MotionLayer]),
		[MotionRep.make("atelier", {"shape": "heal_circle", "size": 5.2, "duration": 2.4})],
		{"length": 0.01, "world_anchor": Vector3(center.x, 0.0, center.z)})
	for i in anchors.size():
		var a: Vector3 = anchors[i]
		var off_y := 0.0
		# Círculo individual sob o aliado (raio 2,2 m, 2,4 s).
		fx.add("windup", _c(&"media_circle_%d" % i, s + 1 + i, 2, [] as Array[MotionLayer]),
			[MotionRep.make("atelier", {"shape": "heal_circle", "size": 2.2, "duration": 2.4})],
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


## O efeito de cada Move de elemento (D-308 / D-236): um MotionEffect por `move_id` (nunca por personagem, D-235).
static func effect_for(move_id: String, seed_value: int, anchors_ := [], center := Vector3.ZERO) -> MotionEffect:
	if move_id == "splitter_flames":
		return splitter_effect(seed_value)
	if move_id == "media":
		return media_effect(seed_value, anchors_, center)
	return fire_effect(seed_value)
