class_name FxDig
extends RefCounted
## Dig (investida_escavadora), opção A do HTML "dust shaders unificados" (D-1196).
##
## O `Battle`/`Incoming` continua dono do relógio (D-019): este módulo só lê `phase`, `phase_time`,
## `plan`, `total_windup`, `time_left`, `stand`, `hold` e `hop_t`, e põe a pose do corpo e os efeitos
## de poeira nos instantes do HTML (castDigMove, linhas 2079-2354). Nada depende de personagem, time,
## lado ou coordenada fixa (D-235): início = casa do atacante, fim = ponto do alvo, escala = escala do
## alvo, eixos laterais = câmera.
##
## Linha do tempo (segundos desde o início do Move; HTML -> jogo):
##   0.000-0.229  WINDUP: pulinho (burrowDriver p<0.44)
##   0.229-1.380  TRAVEL: mergulho, some em 0.26, 6 tremores (0.58 + 0.13 n), intangível
##   1.380        STRIKE (0 s): erupção + dano; reaparece em cima do alvo; alvo treme e sobe
##   1.380-2.480  RETURN: emerge 0.38 s no alvo, volta 0.57 s com cambalhota, 0.15 s parado

const Phase = Incoming.Phase
const MOVE_ID := "investida_escavadora"
const DUST_FX := preload("res://scripts/vfx/combat/dust/dust_fx.gd")
const GROUND := preload("res://scripts/vfx/combat/dust/dust_fx_ground.gd")
const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")

const HIDE_AT := 0.26  ## HTML 2127: scheduleAfter(260) esconde o modelo.
const BURROW_TIME := 0.52  ## HTML 2113: burrowDriver.
const BURROW_SPLIT := 0.44  ## HTML 2115: fração do pulo.
const TREMORS := 6  ## HTML 2158.
const TREMOR_BASE := 0.45  ## HTML 2160: 450 + step * 130 ms.
const TREMOR_STEP := 0.13
const UPPERCUT_TIME := 0.38  ## HTML 2322: p < 0.4 de 0.95 s
const UPPERCUT_SPINS := 3.0  ## voltas inteiras no uppercut (HTML: 18 rad ~ 2,9 voltas); inteiro para aterrissar de frente
const RETURN_ARC_MIN := 2.45  ## HTML 2330
const RETURN_ARC_RATIO := 0.214  ## 2,45 m sobre os 11,45 m entre os slots do HTML: o arco proporcional à distância

var fx: BattleFx
var _active: Dictionary = {}  ## Incoming -> estado do Dig


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


static func is_dig(inc) -> bool:
	return inc != null and (String(inc.move_id) == MOVE_ID or BattleFx.normalize_move_id(String(inc.label)) == MOVE_ID)


## Telegraph: o Move foi declarado e o wind-up (o pulinho) começou.
func start(inc) -> void:
	if not is_dig(inc) or _active.has(inc):
		return
	var a: Combatant = inc.attacker
	if not fx._models.has(a):
		return
	var h: Vector3 = fx._home[a]
	# creator: the attacker's HUD tag stays where it normally is while the Dig plays (it does not follow the body to the target)
	fx._models[a].set_meta("tag_home", Vector3(h.x, 0.0, h.z))
	_active[inc] = {
		"start_pos": Vector3(h.x, 0.0, h.z),
		"end_pos": Vector3(h.x, 0.0, h.z),
		"base_yaw": float(fx._home_yaw[a]),
		"entry": false,
		"tremors": 0,
		"erupted": false,
	}


func cancel(inc) -> void:
	if _active.has(inc):
		_restore(inc)
		_active.erase(inc)


func clear_all() -> void:
	for inc in _active.keys().duplicate():
		cancel(inc)


## Segundos desde o início do Move, pelas fases reais do jogo (a pausa congela os relógios do Battle).
func cast_time(inc) -> float:
	if inc.phase == Phase.WINDUP:
		return clampf(float(inc.total_windup) - maxf(float(inc.time_left), 0.0), 0.0, float(inc.total_windup))
	var t := float(inc.total_windup)
	for i in range(mini(int(inc.plan_i), inc.plan.size())):
		t += float(inc.plan[i][1])
	return t + float(inc.phase_time)


## Chamado no fim de BattleFx._process: depois de a pose ociosa e do fx_motion, para ter a última palavra.
func process(delta: float) -> void:
	for inc in _active.keys().duplicate():
		var st: Dictionary = _active.get(inc, {})
		var a: Combatant = inc.attacker
		if a == null or not fx._models.has(a) or inc.phase == Phase.DONE or inc.interrupted or inc.phase == Phase.STAGGER:
			cancel(inc)
			continue
		_drive(inc, st, delta)


func _drive(inc, st: Dictionary, _delta: float) -> void:
	var a: Combatant = inc.attacker
	var m: Node3D = fx._models[a]
	var t := cast_time(inc)
	var start_pos: Vector3 = st["start_pos"]
	var base_yaw: float = float(st["base_yaw"])
	if inc.phase != Phase.WINDUP:
		var yaw_out = inc.data.get("yaw_out", null) if inc.data is Dictionary else null
		if yaw_out != null:
			base_yaw = float(yaw_out)
		if inc.phase == Phase.TRAVEL:
			st["end_pos"] = Vector3(inc.stand.x, 0.0, inc.stand.z)  # o ponto do alvo, que ele acompanha (D-044)
		elif not st.get("frozen_end", false):
			st["frozen_end"] = true
			st["end_pos"] = Vector3(inc.stand.x, 0.0, inc.stand.z)
	var end_pos: Vector3 = st["end_pos"]
	var pos := start_pos
	var y := 0.0
	var spin := 0.0
	var rot_x := 0.0
	var visible := true

	if inc.phase == Phase.WINDUP or inc.phase == Phase.TRAVEL:
		if t < BURROW_TIME:
			var p := t / BURROW_TIME
			if p < BURROW_SPLIT:  # HTML 2116-2119: o pulinho
				y = sin(p / BURROW_SPLIT * PI) * 2.25
				spin = p * 28.0
			else:  # HTML 2121-2123: o mergulho
				var q := (p - BURROW_SPLIT) / (1.0 - BURROW_SPLIT)
				y = 0.85 * (1.0 - q) - 2.5 * q
				spin = p * 38.0
			rot_x = 0.48
		else:
			y = -2.5
			rot_x = 0.48
		visible = t < HIDE_AT
		if t >= HIDE_AT and not st["entry"]:
			st["entry"] = true
			_entry_effects(start_pos)
			var travel_left := float(inc.total_windup) + float(inc.plan[0][1]) - t if inc.plan.size() > 0 else 1.1
			DUST_FX.burrow_ridge(fx, start_pos, end_pos, maxf(travel_left, 0.2), 1.3, 0.0)  # trajeto: cume de terra contínuo
		if inc.phase == Phase.TRAVEL:
			_tremors(st, t, start_pos, end_pos)
	else:
		visible = true
		if not st["erupted"]:
			st["erupted"] = true
			_erupt(inc, end_pos)
		var e := float(inc.phase_time) if inc.phase == Phase.RETURN else 0.0
		var hold := maxf(float(inc.hold), 0.001)
		var hop := maxf(float(inc.hop_t), 0.001)
		var uppercut := minf(UPPERCUT_TIME, hold)
		var landing := end_pos  # o recuo do atacante (attacker_push do MoveData) é desenhado pelo FxKnock
		if e < uppercut:  # HTML 2322-2326: o uppercut ao sair do chão em cima do alvo (agora sobe e aterrissa)
			var q1 := e / uppercut
			pos = end_pos.lerp(landing, q1)
			y = sin(q1 * PI) * 2.65
			spin = q1 * TAU * UPPERCUT_SPINS
			rot_x = 0.48 * (1.0 - q1)
		elif e < hold:  # criador: depois de aterrissar fica parado, no mínimo 1 s, antes de pular
			pos = landing
			if not st.get("landed_idle", false):
				st["landed_idle"] = true
				fx.fx_motion._play(inc.attacker, "battle_idle")  # criador: depois de aterrissar fica no idle, não na corrida
		else:  # HTML 2327-2333: pulo de volta em arco, com a cambalhota
			var q2 := clampf((e - hold) / hop, 0.0, 1.0)
			pos = landing.lerp(start_pos, q2)
			var flat := Vector3(landing.x - start_pos.x, 0.0, landing.z - start_pos.z).length()
			var arc := maxf(RETURN_ARC_MIN, RETURN_ARC_RATIO * flat)  # a altura do arco cresce com a distância (D-235)
			y = sin(q2 * PI) * arc
			rot_x = -q2 * TAU

	m.visible = visible
	m.position = Vector3(pos.x, y, pos.z)
	m.rotation = Vector3(rot_x, base_yaw + spin, 0.0)


## HTML 2127-2156: o modelo some; cratera, anel de nuvens, véu, 4 pedras e a coroa de entrada.
func _entry_effects(origin: Vector3) -> void:
	var earth: Dictionary = MATERIALS.PALETTE_EARTH_DIG
	GROUND.crater(fx, origin, 1.55, 1.85)
	DUST_FX.cloud_ring(fx, origin, 8, 0.72, 0.88, 1.15, 0.0, earth)
	DUST_FX.veil_and_shock_ring(fx, origin, 1.05, 1.85, 1.15, 0.0, earth)
	GROUND.boulder_barrage(fx, origin, 4, Vector2(2.8, 5.2), Vector2(0.11, 0.20), 0.85, 0.0)
	DUST_FX.lotus_crown(fx, origin, "entry", 1.0, 0.0)


## HTML 2158-2210 (variante tectonic): monte de terra + anel de 5 nuvens, 6 vezes ao longo do trajeto.
func _tremors(st: Dictionary, t: float, start_pos: Vector3, end_pos: Vector3) -> void:
	var earth: Dictionary = MATERIALS.PALETTE_EARTH_DIG
	while int(st["tremors"]) < TREMORS:
		var step := int(st["tremors"]) + 1
		if t < TREMOR_BASE + float(step) * TREMOR_STEP:
			return
		st["tremors"] = step
		var frac := float(step) / float(TREMORS + 1)
		var tremor_pos := start_pos.lerp(end_pos, frac)
		DUST_FX.cloud_ring(fx, tremor_pos, 5, 0.42, 0.58, 0.68, 0.0, earth)


## HTML 2212-2341 (variante tectonic): cratera, 10 nuvens, véu, 6 pedras, coroa de impacto; o alvo treme e sobe.
func _erupt(_inc, end_pos: Vector3) -> void:
	# Metros fixos do HTML (D-1196): `targetScale` é 1.0, como no HTML com o alvo padrão. A escala do corpo no jogo
	# (inimigos ~1.5-1.6x) inflava só o impacto em relação ao trajeto, que não é escalado.
	var ts := 1.0
	var earth: Dictionary = MATERIALS.PALETTE_EARTH_DIG
	GROUND.crater(fx, end_pos, 1.95 * ts, 1.55)
	DUST_FX.cloud_ring(fx, end_pos, 10, 0.92 * ts, 1.0 * ts, 1.35, 0.0, earth)
	DUST_FX.veil_and_shock_ring(fx, end_pos, 1.25 * ts, 2.15 * ts, 1.35, 0.0, earth)
	GROUND.boulder_barrage(fx, end_pos, 6, Vector2(3.5, 6.8), Vector2(0.14 * ts, 0.24 * ts), 1.15, 0.0)
	DUST_FX.lotus_crown(fx, end_pos, "impact", ts, 0.0)


## Câmera: enquanto o Dig e o alvo estão sendo desenhados em movimento (pulo, mergulho, knock-up, recuo), o
## enquadramento usa o ponto de repouso deles, não o corpo no ar. Assim a câmera não se mexe por causa disso.
func anchor(c: Combatant, current: Vector3) -> Vector3:
	var involved := false
	for inc in _active.keys():
		if inc.attacker == c or inc.target == c:
			involved = true
			break
	if not involved or not fx._home.has(c):
		return current
	var h: Vector3 = fx._home[c]
	return Vector3(h.x, 0.0, h.z)


func _restore(inc) -> void:
	var a: Combatant = inc.attacker
	if a == null or not fx._models.has(a):
		return
	var m: Node3D = fx._models[a]
	m.remove_meta("tag_home")
	m.visible = true
	m.rotation.x = 0.0
	m.rotation.z = 0.0
	m.position.y = 0.0
